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
    /// 1 血糖 / 2 血压 / 3 体重 / 4 心率（旧端胎心）
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

        var rows: [DailyHealthTask.Row] = []
        if let t = monitorTime, !t.isEmpty {
            rows.append(.init(label: "计划时间", value: t))
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
            planTime: monitorTime ?? "",
            actionRoute: resolvedActionRoute(fallback: meta.actionRoute),
            detailRows: rows,
            instructions: meta.instructions,
            completedAt: done ? (createTime ?? monitorTime) : nil
        )
    }

    private func resolvedActionRoute(fallback: String) -> String {
        if let skip = skipUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
           skip.hasPrefix("/") {
            return Self.normalizeToAddRouteIfNeeded(skip)
        }
        return fallback
    }

    /// 指标展示首页 → 录入 add；已是 add/manual 则不变
    private static func normalizeToAddRouteIfNeeded(_ route: String) -> String {
        let path = route.split(separator: "?", maxSplits: 1).first.map(String.init) ?? route
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let parts = trimmed.split(separator: "/").map(String.init)
        // /health/metrics/{key}
        if parts.count == 3, parts[0] == "health", parts[1] == "metrics" {
            let key = parts[2]
            let addable: Set<String> = ["blood-pressure", "blood-sugar", "weight", "heart-rate"]
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
        switch type {
        case 1:
            return .init(
                iconKey: "glucose",
                shortTitle: "血糖监测",
                actionRoute: "/health/metrics/blood-sugar/add",
                defaultDesc: "请按时完成今日血糖监测并上传数据。",
                instructions: "采血前清洁双手；空腹监测需至少禁食 8 小时。"
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
                iconKey: "weight",
                shortTitle: "体重监测",
                actionRoute: "/health/metrics/weight/add",
                defaultDesc: "请完成今日体重测量并上传数据。",
                instructions: "建议固定时间、空腹、着轻便衣物测量。"
            )
        case 4:
            return .init(
                iconKey: "heart-rate",
                shortTitle: "心率监测",
                actionRoute: "/health/metrics/heart-rate/add",
                defaultDesc: "请完成今日心率监测并上传数据。",
                instructions: "保持安静状态后测量，避免剧烈运动后立刻读数。"
            )
        default:
            return .init(
                iconKey: "pressure",
                shortTitle: "健康监测",
                actionRoute: "/health/metrics",
                defaultDesc: "请按时完成今日健康监测任务。",
                instructions: nil
            )
        }
    }
}
