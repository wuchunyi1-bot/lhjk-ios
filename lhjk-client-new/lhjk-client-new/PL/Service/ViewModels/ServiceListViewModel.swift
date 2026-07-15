import Foundation
import Combine

/// 套餐列表页 ViewModel — 对齐 funde-client `ServiceListView.vue`
@MainActor
final class ServiceListViewModel: ObservableObject {

    @Published private(set) var categories: [ServiceRecommendCategory] = []
    @Published private(set) var packages: [HealthPackageItem] = []
    @Published private(set) var activeCategoryId: String?
    @Published private(set) var isLoading = false

    var activeCategory: ServiceRecommendCategory? {
        guard let activeCategoryId else { return categories.first }
        return categories.first { $0.id == activeCategoryId } ?? categories.first
    }

    private let initialRouteCode: String
    private let dictionaryService: DictionaryService
    private let catalogService: ServiceCatalogService
    private let cacheService: ServiceHubCacheService
    private var loadTask: Task<Void, Never>?

    init(
        routeCode: String,
        dictionaryService: DictionaryService = .shared,
        catalogService: ServiceCatalogService = AppContainer.shared.serviceCatalogService,
        cacheService: ServiceHubCacheService = AppContainer.shared.serviceHubCacheService
    ) {
        self.initialRouteCode = routeCode.trimmingCharacters(in: .whitespacesAndNewlines)
        self.dictionaryService = dictionaryService
        self.catalogService = catalogService
        self.cacheService = cacheService
    }

    deinit { loadTask?.cancel() }

    func load() {
        loadTask?.cancel()
        isLoading = true
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    func selectCategory(id: String) {
        guard activeCategoryId != id,
              let category = categories.first(where: { $0.id == id }) else { return }
        activeCategoryId = id
        loadPackages(for: category)
    }

    // MARK: - Private

    private func performLoad() async {
        defer { isLoading = false }

        let loadedCategories: [ServiceRecommendCategory]
        if let cached = cacheService.getStatic()?.categories, !cached.isEmpty {
            loadedCategories = cached
        } else {
            do {
                loadedCategories = try await dictionaryService.fetchRecommendCategories()
            } catch {
                print("[ServiceListVM] fetch categories failed: \(error.localizedDescription)")
                categories = []
                packages = []
                return
            }
        }

        categories = loadedCategories.filter(\.isEnabled)
        activeCategoryId = resolveInitialCategoryId(in: categories)
        guard let category = activeCategory else {
            packages = []
            return
        }
        await reloadPackages(for: category)
    }

    private func loadPackages(for category: ServiceRecommendCategory) {
        loadTask?.cancel()
        isLoading = true
        loadTask = Task { [weak self] in
            await self?.reloadPackages(for: category)
            await MainActor.run { self?.isLoading = false }
        }
    }

    private func reloadPackages(for category: ServiceRecommendCategory) async {
        let items = await cacheService.ensurePackages(
            category: category,
            hospitalId: catalogService.selectedApiHospitalId()
        )
        packages = items
    }

    private func resolveInitialCategoryId(in categories: [ServiceRecommendCategory]) -> String? {
        guard !categories.isEmpty else { return nil }
        let code = initialRouteCode
        if !code.isEmpty {
            if let match = categories.first(where: {
                $0.title == code || $0.packageMainCategory == code || $0.name == code
            }) {
                return match.id
            }
        }
        return categories.first?.id
    }
}
