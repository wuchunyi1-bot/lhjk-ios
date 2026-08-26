import Foundation

/// `GET /v1/scheme/getUserToDayMonitorTask` 单条任务
///
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330787e0.md
/// `data` schema 未展开；字段对齐旧端 `tasks`（AngelDoctor）。
struct UserTodayMonitorTask: Decodable, Equatable {
    let id: String?
    let taskId: String?
    let taskName: String?
    /// 0 未完成 / 1 已完成
    let isComplete: Int?
    let monitorTime: String?
    let monitorValue: String?
    /// 监测类型（基础字典「监测类型」）：1 睡眠 / 2 血压 / 3 运动 / 4 体重 / 5 血糖 / 6 体温 / 7 血氧
    let type: Int?
    let mealType: Int?
    let userId: String?
    let doctorId: String?
    let sessionId: String?
    let createTime: String?
    /// 可选跳转；以 `/` 开头时视为 App 内路由
    let skipUrl: String?

    private enum CodingKeys: String, CodingKey {
        case id, taskId, taskName, isComplete, monitorTime, monitorValue
        case type, mealType, userId, doctorId, sessionId, createTime, skipUrl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.decodeFlexibleString(c, key: .id)
        taskId = Self.decodeFlexibleString(c, key: .taskId)
        taskName = try c.decodeIfPresent(String.self, forKey: .taskName)
        isComplete = Self.decodeFlexibleInt(c, key: .isComplete)
        monitorTime = try c.decodeIfPresent(String.self, forKey: .monitorTime)
        monitorValue = try c.decodeIfPresent(String.self, forKey: .monitorValue)
        type = Self.decodeFlexibleInt(c, key: .type)
        mealType = Self.decodeFlexibleInt(c, key: .mealType)
        userId = Self.decodeFlexibleString(c, key: .userId)
        doctorId = Self.decodeFlexibleString(c, key: .doctorId)
        sessionId = Self.decodeFlexibleString(c, key: .sessionId)
        createTime = try c.decodeIfPresent(String.self, forKey: .createTime)
        skipUrl = try c.decodeIfPresent(String.self, forKey: .skipUrl)
    }

    private static func decodeFlexibleString<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> String? {
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
        if let i = try? container.decodeIfPresent(Int64.self, forKey: key) { return String(i) }
        if let d = try? container.decodeIfPresent(Double.self, forKey: key) { return String(Int64(d)) }
        return nil
    }

    private static func decodeFlexibleInt<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> Int? {
        if let i = try? container.decodeIfPresent(Int.self, forKey: key) { return i }
        if let i = try? container.decodeIfPresent(Int64.self, forKey: key) { return Int(i) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key), let i = Int(s) { return i }
        return nil
    }
}

extension UserTodayMonitorTask {

    /// 映射为首页 / 详情共用的展示模型
    func asDailyHealthTask() -> DailyHealthTask {
        let done = isComplete == 1
        let resolvedId = id ?? taskId ?? UUID().uuidString
        let name = (taskName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let meta = Self.displayMeta(for: type)
        let title = name.isEmpty ? "\(meta.shortTitle)提醒" : name
        let shortTitle = name.isEmpty ? meta.shortTitle : Self.shorten(name)

        let formattedPlanTime = Self.formatPlanTime(monitorTime)
        var rows: [DailyHealthTask.Row] = []
        if !formattedPlanTime.isEmpty {
            rows.append(.init(label: "计划时间", value: formattedPlanTime))
        }
        if done, let v = monitorValue, !v.isEmpty {
            rows.append(.init(label: "监测值", value: v))
        }

        return DailyHealthTask(
            id: resolvedId,
            iconKey: meta.iconKey,
            title: title,
            shortTitle: shortTitle,
            desc: meta.defaultDesc,
            done: done,
            category: "监测任务",
            planTime: formattedPlanTime,
            actionRoute: resolvedActionRoute(fallback: meta.actionRoute),
            detailRows: rows,
            instructions: meta.instructions,
            completedAt: done ? (createTime ?? monitorTime) : nil
        )
    }

    private static func formatPlanTime(_ raw: String?) -> String {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return ""
        }
        if raw.count == 8 && raw.filter({ $0 == ":" }).count == 2 {
            return String(raw.prefix(5))
        }
        if raw.count >= 16 && raw.contains(" ") {
            let timePart = raw.split(separator: " ").last.map(String.init) ?? raw
            if timePart.count >= 5 {
                return String(timePart.prefix(5))
            }
        }
        return raw
    }

    private func resolvedActionRoute(fallback: String) -> String {
        guard Self.isNavigableMonitorType(type) else { return "" }
        if let skip = skipUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
           skip.hasPrefix("/") {
            return Self.normalizeToAddRouteIfNeeded(skip)
        }
        return fallback
    }

    /// 2–7 为可跳转类型；路由以字典校验 + 本地 path 表，展示文案仍用硬编码 meta
    private static func isNavigableMonitorType(_ type: Int?) -> Bool {
        DictionaryCacheService.shared.isNavigableMonitorTaskType(type)
    }

    /// 指标展示首页 → 录入 add；已是 add/manual 则不变
    private static func normalizeToAddRouteIfNeeded(_ route: String) -> String {
        let path = route.split(separator: "?", maxSplits: 1).first.map(String.init) ?? route
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let parts = trimmed.split(separator: "/").map(String.init)
        // /health/metrics/{key}
        if parts.count == 3, parts[0] == "health", parts[1] == "metrics" {
            let key = parts[2]
            let addable: Set<String> = [
                "blood-pressure", "blood-sugar", "weight", "heart-rate",
                "temperature", "spo2",
            ]
            if addable.contains(key) {
                return "/health/metrics/\(key)/add"
            }
        }
        return route
    }

    private static func shorten(_ name: String) -> String {
        let trimmed = name
            .replacingOccurrences(of: "提醒", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? name : trimmed
    }

    private struct DisplayMeta {
        let iconKey: String
        let shortTitle: String
        let actionRoute: String
        let defaultDesc: String
        let instructions: String?
    }

    private static func displayMeta(for type: Int?) -> DisplayMeta {
        let base = legacyDisplayMeta(for: type)
        let route = DictionaryCacheService.shared.monitorTaskActionRoute(type) ?? base.actionRoute
        return DisplayMeta(
            iconKey: base.iconKey,
            shortTitle: base.shortTitle,
            actionRoute: route,
            defaultDesc: base.defaultDesc,
            instructions: base.instructions
        )
    }

    private static func legacyDisplayMeta(for type: Int?) -> DisplayMeta {
        switch type {
        case 1:
            return .init(
                iconKey: "sleep",
                shortTitle: "睡眠监测",
                actionRoute: "",
                defaultDesc: "请按时完成今日睡眠记录并上传数据。",
                instructions: "建议固定作息时间，记录真实睡眠时长与质量。"
            )
        case 2:
            return .init(
                iconKey: "pressure",
                shortTitle: "血压监测",
                actionRoute: "/health/metrics/blood-pressure/add",
                defaultDesc: "请静坐休息后测量并上传今日血压数据。",
                instructions: "测量前静坐休息 5 分钟；上臂与心脏同高，袖带松紧适中。"
            )
        case 3:
            return .init(
                iconKey: "exercise",
                shortTitle: "运动记录",
                actionRoute: "/health/metrics/exercise/home",
                defaultDesc: "请完成今日饮食或运动记录并上传数据。",
                instructions: "如实记录当日饮食与运动情况，便于健管师评估。"
            )
        case 4:
            return .init(
                iconKey: "weight",
                shortTitle: "体重监测",
                actionRoute: "/health/metrics/weight/add",
                defaultDesc: "请完成今日体重测量并上传数据。",
                instructions: "建议固定时间、空腹、着轻便衣物测量。"
            )
        case 5:
            return .init(
                iconKey: "glucose",
                shortTitle: "血糖监测",
                actionRoute: "/health/metrics/blood-sugar/add",
                defaultDesc: "请按时完成今日血糖监测并上传数据。",
                instructions: "采血前清洁双手；空腹监测需至少禁食 8 小时。"
            )
        case 6:
            return .init(
                iconKey: "temperature",
                shortTitle: "体温监测",
                actionRoute: "/health/metrics/temperature/add",
                defaultDesc: "请完成今日体温测量并上传数据。",
                instructions: "测量前静息 5 分钟；避免刚运动、进食或沐浴后立即测温。"
            )
        case 7:
            return .init(
                iconKey: "oxygen",
                shortTitle: "血氧监测",
                actionRoute: "/health/metrics/spo2/add",
                defaultDesc: "请完成今日血氧测量并上传数据。",
                instructions: "保持手指温暖、清洁；测量时保持静止直至读数稳定。"
            )
        default:
            return .init(
                iconKey: "pressure",
                shortTitle: "健康监测",
                actionRoute: "",
                defaultDesc: "请按时完成今日健康监测任务。",
                instructions: nil
            )
        }
    }
}
