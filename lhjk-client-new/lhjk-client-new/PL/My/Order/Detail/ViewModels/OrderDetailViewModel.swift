import Foundation
import Combine

final class OrderDetailViewModel: ObservableObject {

    @Published private(set) var detail: AppOrderDetailBO?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasAttemptedLoad = false
    @Published var contentExpanded = false

    private let orderId: Int64
    private let orderService: OrderService

    init(orderId: Int64, orderService: OrderService = AppContainer.shared.orderService) {
        self.orderId = orderId
        self.orderService = orderService
    }

    var bottomActions: [OrderListCardAction] {
        OrderListCardAction.actions(for: detail?.orderStatus, packageType: detail?.packageType)
    }

    var visibleContentLines: [OrderDetailPackageLineBO] {
        let lines = detail?.detailLines ?? []
        if contentExpanded || lines.count <= 3 { return lines }
        return Array(lines.prefix(3))
    }

    var canExpandContent: Bool {
        (detail?.detailLines.count ?? 0) > 3
    }

    func load() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let data = try await orderService.getAppOrderDetail(orderId: orderId)
                await MainActor.run {
                    self.detail = data
                    self.isLoading = false
                    self.hasAttemptedLoad = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    self.hasAttemptedLoad = true
                }
            }
        }
    }

    func handleAction(_ action: OrderListCardAction) -> String {
        switch action {
        case .cancel: return ""
        case .pay: return "请返回订单列表进入支付"
        case .confirmShip: return ""
        case .confirmReceipt: return ""
        case .afterSale: return ""
        case .renew: return ""
        case .settle: return ""
        }
    }
}
