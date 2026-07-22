import Foundation
import Combine

/// 购物车 ViewModel — 列表 / 删除走服务端；仅单卡结算（无多选）
final class ServiceCartViewModel: ObservableObject {

    @Published private(set) var lines: [CartLineDisplay] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isDeleting = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var toastMessage: String?

    private let shoppingCartService: ShoppingCartService
    private var loadTask: Task<Void, Never>?
    private var deleteTask: Task<Void, Never>?

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

    func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    func reload() { load() }

    func consumeToast() {
        toastMessage = nil
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
                lines.removeAll { $0.id == lineId }
                isDeleting = false
                toastMessage = "已删除"
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
            let mapped = records.map { ShoppingCartListMapper.toLineDisplay($0) }
            await MainActor.run {
                lines = mapped
                isLoading = false
            }
        } catch {
            guard !Task.isCancelled else { return }
            await MainActor.run {
                lines = []
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
