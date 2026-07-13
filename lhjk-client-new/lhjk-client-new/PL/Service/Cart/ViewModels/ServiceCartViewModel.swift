import Foundation
import Combine

/// 购物车 ViewModel — 对齐 `CartView.vue`
final class ServiceCartViewModel: ObservableObject {

    @Published private(set) var lines: [CartLineDisplay] = []
    @Published private(set) var selectedCount = 0
    @Published private(set) var selectedTotalText = "¥0"

    private let cartService: CartService

    init(cartService: CartService = AppContainer.shared.cartService) {
        self.cartService = cartService
        reload()
    }

    var isEmpty: Bool { lines.isEmpty }

    var canCheckout: Bool { selectedCount > 0 }

    var firstSelectedTargetId: String? {
        lines.first(where: \.selected)?.targetId
    }

    func reload() {
        lines = cartService.displayLines()
        selectedCount = cartService.selectedCount
        selectedTotalText = Self.formatPrice(cartService.selectedTotal)
    }

    func toggle(id: String) {
        cartService.toggleSelected(id: id)
        reload()
    }

    func remove(id: String) {
        cartService.removeItem(id: id)
        reload()
    }

    private static func formatPrice(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        let num = f.string(from: NSNumber(value: value)) ?? "\(value)"
        return "¥\(num)"
    }
}
