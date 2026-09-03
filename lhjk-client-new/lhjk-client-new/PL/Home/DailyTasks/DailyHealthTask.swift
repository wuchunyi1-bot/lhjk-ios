import UIKit

/// 今日健康任务展示模型 — 首页卡片 / 详情页共用
struct DailyHealthTask: Equatable {
    struct Row: Equatable {
        let label: String
        let value: String
    }

    let id: String
    let iconKey: String
    let title: String
    let shortTitle: String
    let desc: String
    let done: Bool
    let category: String
    let planTime: String
    let actionRoute: String
    /// 字典 `monitorType.value`，用于「去完成」路由匹配与日志
    let monitorType: Int?
    let detailRows: [Row]
    let instructions: String?
    let completedAt: String?
    /// 计划时段（详情页「计划时段」行，如「晨起」）
    let planPeriod: String?
    /// 首页任务行额外标签（餐次、进度、积分等）
    let extraTags: [String]
    /// 完成单次任务可获得积分（首页 `home_task_goal` 角标）
    let rewardPoints: Int?
    /// 首页列表副标题，如 `07:00｜已到今日血压监测`
    let homeSubtitle: String
    /// 详情页卡片主文案（白色信息区内）
    let detailMessage: String

    init(
        id: String,
        iconKey: String,
        title: String,
        shortTitle: String,
        desc: String,
        done: Bool,
        category: String,
        planTime: String,
        actionRoute: String,
        monitorType: Int? = nil,
        detailRows: [Row],
        instructions: String?,
        completedAt: String?,
        planPeriod: String? = nil,
        extraTags: [String] = [],
        rewardPoints: Int? = nil,
        homeSubtitle: String = "",
        detailMessage: String = ""
    ) {
        self.id = id
        self.iconKey = iconKey
        self.title = title
        self.shortTitle = shortTitle
        self.desc = desc
        self.done = done
        self.category = category
        self.planTime = planTime
        self.actionRoute = actionRoute
        self.monitorType = monitorType
        self.detailRows = detailRows
        self.instructions = instructions
        self.completedAt = completedAt
        self.planPeriod = planPeriod
        self.extraTags = extraTags
        self.rewardPoints = rewardPoints
        self.homeSubtitle = homeSubtitle
        self.detailMessage = detailMessage
    }

    /// 是否存在可跳转的路由（与 `done` / isComplete 无关；无路由时「去完成」仍展示，点击不跳转）
    var hasNavigableRoute: Bool {
        !actionRoute.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    struct IconStyle {
        let systemName: String
        let background: UIColor
        let tint: UIColor
    }

    var iconStyle: IconStyle {
        Self.iconStyles[iconKey] ?? IconStyle(
            systemName: "checklist",
            background: UIColor(hexString: "#FFF3EE"),
            tint: .fdPrimary
        )
    }

    private static let iconStyles: [String: IconStyle] = [
        "pressure": .init(systemName: "heart", background: UIColor(hexString: "#FFF3DC"), tint: UIColor(hexString: "#B47300")),
        "glucose": .init(systemName: "drop", background: UIColor(hexString: "#FCE9E6"), tint: UIColor(hexString: "#E5564B")),
        "weight": .init(systemName: "scalemass", background: UIColor(hexString: "#E6F7EF"), tint: UIColor(hexString: "#1F9A6B")),
        "diet": .init(systemName: "fork.knife", background: UIColor(hexString: "#EBF1FA"), tint: UIColor(hexString: "#3D6FB8")),
        "exercise": .init(systemName: "figure.walk", background: UIColor(hexString: "#FFF3EE"), tint: .fdPrimary),
        "medicine": .init(systemName: "pills", background: UIColor(hexString: "#F3EEFF"), tint: UIColor(hexString: "#7C5CC4")),
        "supplement": .init(systemName: "cross.vial", background: UIColor(hexString: "#FFF3EE"), tint: UIColor(hexString: "#E55A2E")),
        "oxygen": .init(systemName: "lungs", background: UIColor(hexString: "#EAF3FF"), tint: UIColor(hexString: "#3D6FB8")),
        "sleep": .init(systemName: "moon.zzz.fill", background: UIColor(hexString: "#EEF0FF"), tint: UIColor(hexString: "#5B6FD8")),
        "temperature": .init(systemName: "thermometer", background: UIColor(hexString: "#E6F7EF"), tint: UIColor(hexString: "#2DB983")),
        "heart-rate": .init(systemName: "waveform.path.ecg", background: UIColor(hexString: "#FCE9E6"), tint: UIColor(hexString: "#E5564B")),
    ]
}

// MARK: - 「去完成」跳转（字典 monitorType 优先，本地路由表兜底）

extension DailyHealthTask {

    /// 点击「去完成」：打 log 区分「按钮无响应」与「路由匹配失败」
    func pushMonitorTaskRoute(source: String) {
        let tag = "[TodayMonitorTask][\(source)]"
        print("\(tag) tap taskId=\(id) type=\(monitorType.map(String.init) ?? "nil") done=\(done) actionRoute=\"\(actionRoute)\"")
        guard !done else {
            print("\(tag) skip: task already done")
            return
        }
        let route = actionRoute.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !route.isEmpty else {
            print("\(tag) skip: empty actionRoute — check dict monitorType match for type=\(monitorType.map(String.init) ?? "nil")")
            return
        }
        print("\(tag) Router.push \(route)")
        Router.shared.push(route)
    }
}
