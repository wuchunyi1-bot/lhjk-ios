import Foundation
import Combine

/// 富德优选商城 ViewModel — 对齐 funde-client `HealthMallView.vue`
@MainActor
final class HealthMallViewModel: ObservableObject {

    @Published private(set) var products: [HealthPackageItem] = []
    @Published private(set) var isLoading = false

    private let hospitalPackageService: HospitalPackageService
    private let catalogService: ServiceCatalogService
    private var loadTask: Task<Void, Never>?

    init(
        hospitalPackageService: HospitalPackageService = .shared,
        catalogService: ServiceCatalogService = AppContainer.shared.serviceCatalogService
    ) {
        self.hospitalPackageService = hospitalPackageService
        self.catalogService = catalogService
    }

    deinit { loadTask?.cancel() }

    func load() {
        if let cached = AppContainer.shared.serviceHubCacheService.cachedRetailPreview(), cached.count > 6 {
            products = cached
        }

        loadTask?.cancel()
        isLoading = products.isEmpty
        loadTask = Task { [weak self] in
            await self?.fetchProducts()
        }
    }

    private func fetchProducts() async {
        defer { isLoading = false }
        do {
            products = try await hospitalPackageService.fetchRetailPackageItems(
                hospitalId: catalogService.selectedApiHospitalId(),
                pageSize: 20
            )
        } catch {
            print("[HealthMallVM] fetch retail failed: \(error.localizedDescription)")
            if products.isEmpty { products = [] }
        }
    }
}
