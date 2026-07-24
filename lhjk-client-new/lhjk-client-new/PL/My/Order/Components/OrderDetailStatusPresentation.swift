import UIKit

/// 订单详情状态头展示 — 对齐 funde `orderStatusPresentation`
struct OrderDetailStatusPresentation {

    enum Tone {
        case primary
        case pending
        case warning
        case danger
        case info
        case success
        case neutral
    }

    let tone: Tone
    let title: String
    let systemImageName: String

    var iconBackgroundColor: UIColor {
        switch tone {
        case .primary: return .fdPrimarySoft
        case .pending: return .fdWarningSoft
        case .warning: return .fdWarningSoft
        case .danger: return .fdDangerSoft
        case .info: return .fdInfoSoft
        case .success: return .fdSuccessSoft
        case .neutral: return .fdBg2
        }
    }

    var iconTintColor: UIColor {
        switch tone {
        case .primary: return .fdPrimary
        case .pending: return .fdDanger
        case .warning: return UIColor(hexString: "#B47300")
        case .danger: return .fdDanger
        case .info: return .fdInfo
        case .success: return .fdSuccess
        case .neutral: return .fdMuted
        }
    }

    static func make(status: AppOrderStatus?, title: String? = nil, preferPrimaryForPending: Bool = false) -> OrderDetailStatusPresentation {
        let resolvedTitle = title ?? status?.label ?? "订单详情"
        switch status {
        case .pendingPayment:
            return OrderDetailStatusPresentation(
                tone: preferPrimaryForPending ? .primary : .pending,
                title: resolvedTitle,
                systemImageName: "clock"
            )
        case .pendingShip:
            return OrderDetailStatusPresentation(tone: .warning, title: resolvedTitle, systemImageName: "shippingbox")
        case .pendingReceive:
            return OrderDetailStatusPresentation(tone: .info, title: resolvedTitle, systemImageName: "tray")
        case .inProgress:
            return OrderDetailStatusPresentation(tone: .info, title: resolvedTitle, systemImageName: "heart")
        case .completed:
            return OrderDetailStatusPresentation(tone: .success, title: resolvedTitle, systemImageName: "checkmark.circle")
        case .cancelled:
            return OrderDetailStatusPresentation(tone: .neutral, title: resolvedTitle, systemImageName: "xmark.circle")
        case .overdue:
            return OrderDetailStatusPresentation(tone: .danger, title: resolvedTitle, systemImageName: "exclamationmark.triangle")
        case .refund, .refundReview:
            return OrderDetailStatusPresentation(tone: .warning, title: resolvedTitle, systemImageName: "arrow.uturn.left.circle")
        case .none:
            return OrderDetailStatusPresentation(tone: .neutral, title: resolvedTitle, systemImageName: "info.circle")
        }
    }
}
