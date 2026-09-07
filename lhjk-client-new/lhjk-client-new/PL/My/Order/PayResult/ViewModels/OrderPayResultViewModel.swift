import Foundation
import Combine

/// 确认订单支付结束后的结果页入参
struct OrderPayResultPayload: Equatable {
    enum Outcome: String, Equatable {
        case success
        case failure
    }

    let outcome: Outcome
    let orderId: Int64
    let amountYuan: Double
    let payMethodTitle: String
    let failureMessage: String?
    let entry: OrderConfirmEntry

    var titleText: String {
        switch outcome {
        case .success: return "支付成功"
        case .failure: return "支付失败"
        }
    }

    var descriptionText: String {
        switch outcome {
        case .success:
            return "订单已提交，我们将尽快为您处理"
        case .failure:
            let trimmed = failureMessage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? "支付失败，请稍后重试" : trimmed
        }
    }

    var routeOutcome: String { outcome.rawValue }

    var routeEntry: String {
        switch entry {
        case .cartCheckout: return "cart"
        case .orderListPay: return "order_pay"
        case .default: return "default"
        }
    }
}

/// 支付结果信息卡一行
struct OrderPayResultInfoRow: Equatable {
    let title: String
    let value: String
    let isOrderNumber: Bool
}

/// 支付结果页 ViewModel — 终态来自确认页，订单信息拉 `getAppOrderDetail`
final class OrderPayResultViewModel: ObservableObject {
    let payload: OrderPayResultPayload

    @Published private(set) var detail: AppOrderDetailBO?
    @Published private(set) var isLoading = false
    @Published var toastMessage: String?

    private let orderService: OrderService

    init(
        payload: OrderPayResultPayload,
        orderService: OrderService = AppContainer.shared.orderService
    ) {
        self.payload = payload
        self.orderService = orderService
    }

    convenience init(params: [String: Any]) {
        let outcomeRaw = (params["outcome"] as? String)?.lowercased() ?? "success"
        let outcome: OrderPayResultPayload.Outcome = outcomeRaw == "failure" ? .failure : .success
        let orderId: Int64 = {
            if let raw = params["orderId"] as? String { return Int64(raw) ?? 0 }
            if let n = params["orderId"] as? NSNumber { return n.int64Value }
            if let i = params["orderId"] as? Int64 { return i }
            return 0
        }()
        let amount: Double = {
            if let n = params["amountYuan"] as? NSNumber { return n.doubleValue }
            if let d = params["amountYuan"] as? Double { return d }
            if let s = params["amountYuan"] as? String { return Double(s) ?? 0 }
            return 0
        }()
        let payMethod = (params["payMethodTitle"] as? String) ?? ""
        let message = params["message"] as? String
        let entry = OrderConfirmEntry(routeValue: params["entry"] as? String)
        self.init(
            payload: OrderPayResultPayload(
                outcome: outcome,
                orderId: orderId,
                amountYuan: amount,
                payMethodTitle: payMethod,
                failureMessage: message,
                entry: entry
            )
        )
    }

    /// 成功态金额：详情应付优先，缺省用确认页提交值
    var displayAmountYuan: Double {
        if let amount = detail?.payExpectedPayableAmount { return amount }
        if let payable = detail?.payable { return max(0, payable) }
        return payload.amountYuan
    }

    /// 信息区行：订单号 / 下单时间 / 支付方式 / 订单状态。不展示支付时间。
    var infoRows: [OrderPayResultInfoRow] {
        guard let detail else { return [] }
        var rows: [OrderPayResultInfoRow] = []
        let orderNo = detail.id.map(String.init) ?? (payload.orderId > 0 ? String(payload.orderId) : "")
        if !orderNo.isEmpty {
            rows.append(OrderPayResultInfoRow(title: "订单号", value: orderNo, isOrderNumber: true))
        }
        if let created = detail.createTime?.trimmingCharacters(in: .whitespacesAndNewlines), !created.isEmpty {
            rows.append(OrderPayResultInfoRow(title: "下单时间", value: created, isOrderNumber: false))
        }
        let payMethod = resolvedPayMethodTitle(from: detail)
        if !payMethod.isEmpty {
            rows.append(OrderPayResultInfoRow(title: "支付方式", value: payMethod, isOrderNumber: false))
        }
        if let status = detail.orderStatus?.label, !status.isEmpty {
            rows.append(OrderPayResultInfoRow(title: "订单状态", value: status, isOrderNumber: false))
        }
        return rows
    }

    func load() {
        guard payload.orderId > 0, !isLoading else { return }
        isLoading = true
        Task { [weak self] in
            guard let self else { return }
            do {
                let data = try await orderService.getAppOrderDetail(orderId: payload.orderId)
                await MainActor.run {
                    self.detail = data
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    func consumeToast() {
        toastMessage = nil
    }

    func copyOrderNumberSucceeded() {
        toastMessage = "订单号已复制"
    }

    private func resolvedPayMethodTitle(from detail: AppOrderDetailBO) -> String {
        let fromDetail = detail.paymentTypeLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fromDetail.isEmpty, fromDetail != "—" {
            return fromDetail
        }
        return payload.payMethodTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
