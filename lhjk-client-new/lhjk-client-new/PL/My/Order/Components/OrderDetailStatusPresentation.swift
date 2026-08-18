import UIKit

/// 订单详情状态头 — 对齐 Figma 3546:4382（插画 + 棕色渐变标题）
struct OrderDetailStatusPresentation {

    let title: String
    let illustrationName: String

    static func make(status: AppOrderStatus?, title: String? = nil, preferPrimaryForPending: Bool = false) -> OrderDetailStatusPresentation {
        _ = preferPrimaryForPending
        let resolvedTitle = title ?? status?.label ?? "订单详情"
        return OrderDetailStatusPresentation(
            title: resolvedTitle,
            illustrationName: illustrationAsset(for: status)
        )
    }

    private static func illustrationAsset(for status: AppOrderStatus?) -> String {
        switch status {
        case .pendingPayment:
            return "order_detail_status_pending_pay"
        case .pendingShip:
            return "order_detail_status_pending_ship"
        case .pendingReceive:
            return "order_detail_status_pending_receive"
        case .inProgress:
            return "order_detail_status_in_use"
        case .completed:
            return "order_detail_status_completed"
        case .refund, .refundReview:
            return "order_detail_status_refund"
        case .overdue, .cancelled, .none:
            return "order_detail_status_overdue"
        }
    }
}
