import Foundation

/// `GET /v1/scheme/getUserToDayMonitorTask` 单条任务（Apifox `UserMonitorTaskObject`）
///
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330787e0.md
struct UserTodayMonitorTask: Decodable, Equatable {
    let id: String?
    let taskId: String?
    let taskName: String?
    /// 0 未完成 / 1 已完成
    let isComplete: Int?
    let monitorTime: String?
    let monitorValue: String?
  /// 监测类型（基础字典 `monitorType`，含义与跳转以字典 value 为准，不以 Apifox 文档枚举为准）
    let type: Int?
    /// 餐次：1 空腹 … 8 睡前（见 Apifox `mealType` 说明）
    let mealType: Int?
    let userId: String?
    let schemeId: String?
    let doctorId: String?
    let sessionId: String?
    let hospitalId: String?
    let createTime: String?
    let timeStamp: Int64?
    /// 可选跳转；以 `/` 开头时视为 App 内路由
    let skipUrl: String?
    /// 该类任务今日已完成次数
    let completeTaskNumber: Int?
    /// 该类任务今日总次数
    let taskNumber: Int?
    /// 消息提醒开关：1 开启 / 0 关闭
    let remindSwitch: Int?
    /// 监测说明（优先于本地默认文案）
    let monitorSpecification: String?
    /// 完成一次任务可获得积分
    let quantity: Int?
    /// 该类任务今日已获得积分
    let pointsEarned: Int?
    /// 该类任务今日可获得总积分
    let pointsTotal: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case getId = "get_id"
        case taskId, taskName, isComplete, monitorTime, monitorValue
        case type, mealType, userId, schemeId, doctorId, sessionId, hospitalId
        case createTime, timeStamp, skipUrl
        case completeTaskNumber, taskNumber, remindSwitch, monitorSpecification
        case quantity, pointsEarned, pointsTotal
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.decodeFlexibleString(c, key: .id)
            ?? Self.decodeFlexibleString(c, key: .getId)
        taskId = Self.decodeFlexibleString(c, key: .taskId)
        taskName = try c.decodeIfPresent(String.self, forKey: .taskName)
        isComplete = Self.decodeFlexibleInt(c, key: .isComplete)
        monitorTime = try c.decodeIfPresent(String.self, forKey: .monitorTime)
        monitorValue = try c.decodeIfPresent(String.self, forKey: .monitorValue)
        type = Self.decodeFlexibleInt(c, key: .type)
        mealType = Self.decodeFlexibleInt(c, key: .mealType)
        userId = Self.decodeFlexibleString(c, key: .userId)
        schemeId = Self.decodeFlexibleString(c, key: .schemeId)
        doctorId = Self.decodeFlexibleString(c, key: .doctorId)
        sessionId = Self.decodeFlexibleString(c, key: .sessionId)
        hospitalId = Self.decodeFlexibleString(c, key: .hospitalId)
        createTime = try c.decodeIfPresent(String.self, forKey: .createTime)
        timeStamp = Self.decodeFlexibleInt64(c, key: .timeStamp)
        skipUrl = try c.decodeIfPresent(String.self, forKey: .skipUrl)
        completeTaskNumber = Self.decodeFlexibleInt(c, key: .completeTaskNumber)
        taskNumber = Self.decodeFlexibleInt(c, key: .taskNumber)
        remindSwitch = Self.decodeFlexibleInt(c, key: .remindSwitch)
        monitorSpecification = try c.decodeIfPresent(String.self, forKey: .monitorSpecification)
        quantity = Self.decodeFlexibleInt(c, key: .quantity)
        pointsEarned = Self.decodeFlexibleInt(c, key: .pointsEarned)
        pointsTotal = Self.decodeFlexibleInt(c, key: .pointsTotal)
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

    private static func decodeFlexibleInt64<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> Int64? {
        if let i = try? container.decodeIfPresent(Int64.self, forKey: key) { return i }
        if let i = try? container.decodeIfPresent(Int.self, forKey: key) { return Int64(i) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key), let i = Int64(s) { return i }
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
        let category = DictionaryCacheService.shared.monitorTaskDisplayName(type) ?? meta.shortTitle

        let formattedPlanTime = Self.formatPlanTime(monitorTime)
        let planPeriod = Self.planPeriodLabel(
            monitorValue: monitorValue,
            mealType: mealType,
            isComplete: done
        )
        var rows: [DailyHealthTask.Row] = []
        if let period = planPeriod, !period.isEmpty {
            rows.append(.init(label: "计划时段", value: period))
        }
        if !formattedPlanTime.isEmpty {
            rows.append(.init(label: "计划时间", value: formattedPlanTime))
        }
        if let mealLabel = Self.mealTypeLabel(mealType), !mealLabel.isEmpty {
            rows.append(.init(label: "餐次", value: mealLabel))
        }
        if let progress = Self.typeProgressText(complete: completeTaskNumber, total: taskNumber) {
            rows.append(.init(label: "今日进度", value: progress))
        }
        if let points = Self.pointsProgressText(earned: pointsEarned, total: pointsTotal) {
            rows.append(.init(label: "今日积分", value: points))
        }
        if done, let v = monitorValue, !v.isEmpty {
            rows.append(.init(label: "监测值", value: v))
        }

        let instructions = monitorSpecification?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
            ?? meta.instructions

        var extraTags: [String] = []
        if let mealLabel = Self.mealTypeLabel(mealType), !mealLabel.isEmpty {
            extraTags.append(mealLabel)
        }
        if let progress = Self.typeProgressText(complete: completeTaskNumber, total: taskNumber) {
            extraTags.append(progress)
        }
        if let points = Self.pointsProgressText(earned: pointsEarned, total: pointsTotal) {
            extraTags.append("积分 \(points)")
        }

        return DailyHealthTask(
            id: resolvedId,
            iconKey: meta.iconKey,
            title: title,
            shortTitle: shortTitle,
            desc: meta.defaultDesc,
            done: done,
            category: category,
            planTime: formattedPlanTime,
            actionRoute: resolvedActionRoute(),
            monitorType: type,
            detailRows: rows,
            instructions: instructions,
            completedAt: done ? (createTime ?? monitorTime) : nil,
            planPeriod: planPeriod,
            extraTags: extraTags,
            rewardPoints: Self.rewardPointsPerTask(quantity: quantity),
            homeSubtitle: Self.homeListSubtitle(
                planTime: formattedPlanTime,
                taskName: name,
                shortTitle: shortTitle,
                mealType: mealType
            ),
            detailMessage: Self.detailPageMessage(
                shortTitle: shortTitle,
                fallback: meta.defaultDesc
            )
        )
    }

    private static func planPeriodLabel(
        monitorValue: String?,
        mealType: Int?,
        isComplete: Bool
    ) -> String? {
        if let meal = mealTypeLabel(mealType), !meal.isEmpty {
            return meal
        }
        guard !isComplete else { return nil }
        guard let raw = monitorValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            return nil
        }
        if looksLikeNumericMeasurement(raw) { return nil }
        return raw
    }

    private static func looksLikeNumericMeasurement(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let numericCharset = CharacterSet(charactersIn: "0123456789./")
        return trimmed.unicodeScalars.allSatisfy { numericCharset.contains($0) }
    }

    private static func detailPageMessage(shortTitle: String, fallback: String) -> String {
        let metric = shortTitle
            .replacingOccurrences(of: "监测", with: "")
            .replacingOccurrences(of: "记录", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !metric.isEmpty else { return fallback }
        return "您好，已到今日\(metric)监测时间，请静坐休息 5 分钟后测量并上传数据。"
    }

    private static func rewardPointsPerTask(quantity: Int?) -> Int? {
        guard let quantity, quantity > 0 else { return nil }
        return quantity
    }

    private static func homeListSubtitle(
        planTime: String,
        taskName: String,
        shortTitle: String,
        mealType: Int?
    ) -> String {
        let status: String
        if !taskName.isEmpty {
            status = taskName
        } else if let meal = mealTypeLabel(mealType), !meal.isEmpty {
            let metric = shortTitle.replacingOccurrences(of: "监测", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            status = "已到今日\(meal)\(metric)监测"
        } else if !shortTitle.isEmpty {
            status = "已到今日\(shortTitle)"
        } else {
            status = "请按时完成今日健康监测"
        }
        guard !planTime.isEmpty else { return status }
        return "\(planTime)｜\(status)"
    }

    private static func mealTypeLabel(_ mealType: Int?) -> String? {
        guard let mealType else { return nil }
        if let fromDict = DictionaryCacheService.shared.label(parent: .glucosePeriod, intValue: mealType) {
            return fromDict
        }
        if let fromDict = DictionaryCacheService.shared.label(parent: .mealType, intValue: mealType) {
            return fromDict
        }
        return Self.fallbackMealTypeLabels[mealType]
    }

    private static let fallbackMealTypeLabels: [Int: String] = [
        1: "空腹",
        2: "早餐前",
        3: "午餐前",
        4: "午餐后",
        5: "晚餐前",
        6: "晚餐后1小时",
        7: "晚餐后2小时",
        8: "睡前",
    ]

    private static func typeProgressText(complete: Int?, total: Int?) -> String? {
        guard let total, total > 1 else { return nil }
        let done = max(0, complete ?? 0)
        return "\(done)/\(total)"
    }

    private static func pointsProgressText(earned: Int?, total: Int?) -> String? {
        guard let total, total > 0 else { return nil }
        let got = max(0, earned ?? 0)
        return "\(got)/\(total)"
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

    /// 字典 `monitorType` 优先 + 本地路由表兜底；忽略 skipUrl
    private func resolvedActionRoute() -> String {
        let taskRef = id ?? taskId ?? "?"
        let ctx = "map taskId=\(taskRef) skipUrl=\(skipUrl ?? "nil")(ignored)"
        return DictionaryCacheService.shared.resolveMonitorTaskActionRoute(type: type, logContext: ctx)
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
        let dictName = DictionaryCacheService.shared.monitorTaskDisplayName(type)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
        let route = DictionaryCacheService.shared.monitorTaskActionRoute(type) ?? ""
        return DisplayMeta(
            iconKey: base.iconKey,
            shortTitle: dictName ?? base.shortTitle,
            actionRoute: route,
            defaultDesc: base.defaultDesc,
            instructions: base.instructions
        )
    }

    /// 本地兜底：图标 / 默认文案 / 路由模板（按字典 `monitorType.value` 编号，与 Apifox 文档枚举无关）
    private static func legacyDisplayMeta(for type: Int?) -> DisplayMeta {
        switch type {
        case 1:
            return .init(
                iconKey: "sleep",
                shortTitle: "睡眠监测",
                actionRoute: "/health/metrics/sleep",
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

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
