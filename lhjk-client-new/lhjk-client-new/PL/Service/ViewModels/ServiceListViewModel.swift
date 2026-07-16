import Foundation
import Combine

/// 套餐列表页 ViewModel — 对齐 funde-client `ServiceListView.vue`
@MainActor
final class ServiceListViewModel: ObservableObject {

    @Published private(set) var categories: [ServiceListCategory] = []
    @Published private(set) var packages: [HealthPackageItem] = []
    @Published private(set) var activeCategoryId: String?
    @Published private(set) var institution = ServiceListInstitutionDisplay.default
    @Published private(set) var isLoadingCategories = false
    @Published private(set) var isLoadingPackages = false

    var activeCategory: ServiceListCategory? {
        guard let activeCategoryId else { return categories.first }
        return categories.first { $0.id == activeCategoryId } ?? categories.first
    }

    /// 搜索页 `hospitalId` 参数
    var searchHospitalId: String {
        resolvedHospitalId
    }

    private let initialRouteCode: String
    private let hospitalPackageService: HospitalPackageService
    private let catalogService: ServiceCatalogService
    private var loadTask: Task<Void, Never>?
    private var packagesTask: Task<Void, Never>?
    private var loadGeneration = 0

    private let packagePageSize = 50

    init(
        routeCode: String,
        hospitalPackageService: HospitalPackageService = .shared,
        catalogService: ServiceCatalogService = AppContainer.shared.serviceCatalogService
    ) {
        self.initialRouteCode = routeCode.trimmingCharacters(in: .whitespacesAndNewlines)
        self.hospitalPackageService = hospitalPackageService
        self.catalogService = catalogService
    }

    deinit {
        loadTask?.cancel()
        packagesTask?.cancel()
    }

    func load() {
        loadTask?.cancel()
        loadGeneration += 1
        let generation = loadGeneration
        isLoadingCategories = true
        loadTask = Task { [weak self] in
            await self?.performLoad(generation: generation)
        }
    }

    func selectCategory(id: String) {
        guard activeCategoryId != id,
              let category = categories.first(where: { $0.id == id }) else { return }
        activeCategoryId = id
        packagesTask?.cancel()
        let generation = loadGeneration
        packagesTask = Task { [weak self] in
            await self?.reloadPackages(for: category, generation: generation)
        }
    }

    // MARK: - Private

    private var resolvedHospitalId: String {
        if let userHospitalId = AppContainer.shared.userManager.loginUserInfo?.hospitalId,
           let valid = HospitalPackageService.apiHospitalId(userHospitalId) {
            return valid
        }
        return catalogService.selectedApiHospitalId()
            ?? HospitalPackageService.temporaryHospitalId
    }

    private func performLoad(generation: Int) async {
        defer {
            if generation == loadGeneration { isLoadingCategories = false }
        }

        let hospitalId = resolvedHospitalId
        do {
            let vos = try await hospitalPackageService.fetchHospitalServiceCategoryList(
                hospitalId: hospitalId
            )
            guard generation == loadGeneration else { return }

            categories = CategoryServiceListMapper.toServiceListCategories(vos)
            activeCategoryId = resolveInitialCategoryId(in: categories)
            guard let category = activeCategory else {
                packages = []
                return
            }
            await reloadPackages(for: category, generation: generation)
        } catch {
            print("[ServiceListVM] load categories failed: \(error.localizedDescription)")
            guard generation == loadGeneration else { return }
            categories = []
            packages = []
            activeCategoryId = nil
        }
    }

    private func reloadPackages(for category: ServiceListCategory, generation: Int) async {
        isLoadingPackages = true
        defer {
            if generation == loadGeneration { isLoadingPackages = false }
        }

        let hospitalId = resolvedHospitalId
        do {
            let items = try await hospitalPackageService.fetchHospitalServicePackageItems(
                categoryServiceId: category.id,
                hospitalId: hospitalId,
                pageNum: 1,
                pageSize: packagePageSize
            )
            guard generation == loadGeneration else { return }
            packages = items
        } catch {
            print("[ServiceListVM] load packages failed: \(error.localizedDescription)")
            guard generation == loadGeneration else { return }
            packages = []
        }
    }

    private func resolveInitialCategoryId(in categories: [ServiceListCategory]) -> String? {
        guard !categories.isEmpty else { return nil }
        let code = initialRouteCode
        if !code.isEmpty,
           let match = categories.first(where: { $0.title == code }) {
            return match.id
        }
        return categories.first?.id
    }
}
