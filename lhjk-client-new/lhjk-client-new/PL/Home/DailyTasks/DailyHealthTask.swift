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
    let detailRows: [Row]
    let instructions: String?
    let completedAt: String?

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
        "temperature": .init(systemName: "thermometer", background: UIColor(hexString: "#E6F7EF"), tint: UIColor(hexString: "#2DB983")),
        "heart-rate": .init(systemName: "waveform.path.ecg", background: UIColor(hexString: "#FCE9E6"), tint: UIColor(hexString: "#E5564B")),
    ]
}
