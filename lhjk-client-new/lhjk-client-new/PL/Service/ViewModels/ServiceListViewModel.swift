import Foundation
import Combine

/// 套餐列表页 ViewModel — 对齐 funde-client `ServiceListView.vue`
@MainActor
final class ServiceListViewModel: ObservableObject {

    @Published private(set) var categories: [ServiceListCategory] = []
    @Published private(set) var packageSections: [ServiceListPackageSection] = []
    @Published private(set) var activeCategoryId: String?
    @Published private(set) var institution = ServiceListInstitutionDisplay.default
    @Published private(set) var isLoading = false

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
    private let selectionStore: InstitutionSelectionStore
    private var loadTask: Task<Void, Never>?
    private var loadGeneration = 0
    private var institutionObserver: NSObjectProtocol?

    init(
        routeCode: String,
        hospitalPackageService: HospitalPackageService = .shared,
        catalogService: ServiceCatalogService = AppContainer.shared.serviceCatalogService,
        selectionStore: InstitutionSelectionStore = AppContainer.shared.institutionSelectionStore
    ) {
        self.initialRouteCode = routeCode.trimmingCharacters(in: .whitespacesAndNewlines)
        self.hospitalPackageService = hospitalPackageService
        self.catalogService = catalogService
        self.selectionStore = selectionStore
        refreshInstitutionDisplay()

        institutionObserver = NotificationCenter.default.addObserver(
            forName: InstitutionSelectionStore.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshInstitutionDisplay()
                self?.load()
            }
        }
    }

    deinit {
        loadTask?.cancel()
        if let institutionObserver {
            NotificationCenter.default.removeObserver(institutionObserver)
        }
    }

    func load() {
        loadTask?.cancel()
        loadGeneration += 1
        let generation = loadGeneration
        isLoading = true
        refreshInstitutionDisplay()
        loadTask = Task { [weak self] in
            await self?.performLoad(generation: generation)
        }
    }

    /// 左栏点击：仅切换高亮，由 VC 滚动右栏
    func selectCategory(id: String) {
        guard categories.contains(where: { $0.id == id }) else { return }
        activeCategoryId = id
    }

    /// 右栏滚动联动：更新左栏高亮
    func syncActiveCategory(fromRightIndexPath indexPath: IndexPath) {
        guard packageSections.indices.contains(indexPath.section) else { return }
        let categoryId = packageSections[indexPath.section].category.id
        guard activeCategoryId != categoryId else { return }
        activeCategoryId = categoryId
    }

    func indexPath(forCategoryId id: String) -> IndexPath? {
        guard let section = packageSections.firstIndex(where: { $0.category.id == id }) else { return nil }
        return IndexPath(row: 0, section: section)
    }

    // MARK: - Private

    private var resolvedHospitalId: String {
        if let selected = selectionStore.selectedHospitalId {
            return selected
        }
        if let archiveHospitalId = AppContainer.shared.userManager.defaultArchive?.hospitalId,
           let valid = HospitalPackageService.apiHospitalId(archiveHospitalId) {
            return valid
        }
        return catalogService.selectedApiHospitalId()
            ?? HospitalPackageService.temporaryHospitalId
    }

    private func refreshInstitutionDisplay() {
        if let selected = selectionStore.selected {
            institution = ServiceListInstitutionDisplay(
                name: selected.name,
                typeLabel: selected.typeLabel,
                address: selected.fullAddress.isEmpty ? "地址待补充" : selected.fullAddress,
                distance: "已选择"
            )
        } else {
            institution = .default
        }
    }

    private func performLoad(generation: Int) async {
        defer {
            if generation == loadGeneration { isLoading = false }
        }

        let hospitalId = resolvedHospitalId
        do {
            let groups = try await hospitalPackageService.fetchEnabledHospitalPackageListByCategory(
                hospitalId: hospitalId
            )
            guard generation == loadGeneration else { return }

            let loaded = HospitalPackageCategoryListMapper.map(groups)
            categories = loaded.categories
            packageSections = loaded.packageSections
            activeCategoryId = resolveInitialCategoryId(in: categories)
        } catch {
            print("[ServiceListVM] load failed: \(error.localizedDescription)")
            guard generation == loadGeneration else { return }
            categories = []
            packageSections = []
            activeCategoryId = nil
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
