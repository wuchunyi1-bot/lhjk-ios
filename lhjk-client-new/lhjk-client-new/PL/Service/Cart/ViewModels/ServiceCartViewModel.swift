import Foundation
import Combine

/// 购物车 ViewModel — 列表 / 删除走服务端
final class ServiceCartViewModel: ObservableObject {

    @Published private(set) var lines: [CartLineDisplay] = []
    @Published private(set) var selectedCount = 0
    @Published private(set) var selectedTotalText = "¥0"
    @Published private(set) var isLoading = false
    @Published private(set) var isDeleting = false
    @Published private(set) var errorMessage: String?

    private let shoppingCartService: ShoppingCartService
    private var loadTask: Task<Void, Never>?
    private var deleteTask: Task<Void, Never>?
    /// 勾选态（内存）；key = line id
    private var selectedIds: Set<String> = []

    init(
        shoppingCartService: ShoppingCartService = AppContainer.shared.shoppingCartService
    ) {
        self.shoppingCartService = shoppingCartService
    }

    deinit {
        loadTask?.cancel()
        deleteTask?.cancel()
    }

    var isEmpty: Bool { lines.isEmpty && !isLoading }

    var canCheckout: Bool { selectedCount > 0 }

    var firstSelectedTargetId: String? {
        lines.first(where: \.selected)?.targetId
    }

    func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    /// 兼容旧调用名
    func reload() { load() }

    func toggle(id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
        applySelectionToLines()
        refreshTotals()
    }

    /// 删除购物车行（服务端 `serialNumber`）
    func remove(id: String) {
        guard !isDeleting else { return }
        guard let line = lines.first(where: { $0.id == id }) else { return }
        guard let serial = line.serialNumber else {
            errorMessage = ShoppingCartServiceError.missingSerialNumber.localizedDescription
            return
        }

        deleteTask?.cancel()
        deleteTask = Task { [weak self] in
            await self?.performDelete(lineId: id, serialNumber: serial)
        }
    }

    // MARK: - Private

    private func performDelete(lineId: String, serialNumber: Int) async {
        await MainActor.run {
            isDeleting = true
            errorMessage = nil
        }
        do {
            try await shoppingCartService.deleteShoppingCart(serialNumber: serialNumber)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                selectedIds.remove(lineId)
                lines.removeAll { $0.id == lineId }
                isDeleting = false
                refreshTotals()
            }
        } catch {
            guard !Task.isCancelled else { return }
            await MainActor.run {
                isDeleting = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func performLoad() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let page = try await shoppingCartService.getShoppingCartList(
                pageNum: 1,
                pageSize: 50
            )
            guard !Task.isCancelled else { return }
            let records = page.records ?? []
            let mapped = records.map { ShoppingCartListMapper.toLineDisplay($0, selected: true) }
            await MainActor.run {
                let newIds = Set(mapped.map(\.id))
                selectedIds = newIds
                lines = mapped.map { line in
                    var copy = line
                    copy.selected = true
                    return copy
                }
                isLoading = false
                refreshTotals()
            }
        } catch {
            guard !Task.isCancelled else { return }
            await MainActor.run {
                lines = []
                selectedIds = []
                isLoading = false
                errorMessage = error.localizedDescription
                refreshTotals()
            }
        }
    }

    private func applySelectionToLines() {
        lines = lines.map { line in
            var copy = line
            copy.selected = selectedIds.contains(line.id)
            return copy
        }
    }

    private func refreshTotals() {
        let selected = lines.filter(\.selected)
        selectedCount = selected.count
        let total = selected.reduce(0) { $0 + $1.linePrice }
        selectedTotalText = Self.formatPrice(total)
    }

    private static func formatPrice(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        let num = f.string(from: NSNumber(value: value)) ?? "\(value)"
        return "¥\(num)"
    }
}
