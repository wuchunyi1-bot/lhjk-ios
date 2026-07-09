import Foundation
import Combine

/// 服务首页 ViewModel
final class ServiceViewModel: ObservableObject {

    enum Section: Int, CaseIterable {
        case activateBanner
        case bannerCarousel
        case matrix
        case recommend
    }

    @Published private(set) var snapshot: ServiceHubSnapshot?
    @Published private(set) var isLoading = false

    private let catalogService: ServiceCatalogService
    private let columnContentService: ColumnContentService
    private let dictionaryService: DictionaryService
    private let hospitalPackageService: HospitalPackageService
    private let voucherService: VoucherService
    private var selectedCategoryId: String?
    private var cachedCategories: [ServiceRecommendCategory] = []
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?

    init(
        catalogService: ServiceCatalogService = AppContainer.shared.serviceCatalogService,
        columnContentService: ColumnContentService = AppContainer.shared.columnContentService,
        dictionaryService: DictionaryService = AppContainer.shared.dictionaryService,
        hospitalPackageService: HospitalPackageService = AppContainer.shared.hospitalPackageService,
        voucherService: VoucherService = AppContainer.shared.voucherService
    ) {
        self.catalogService = catalogService
        self.columnContentService = columnContentService
        self.dictionaryService = dictionaryService
        self.hospitalPackageService = hospitalPackageService
        self.voucherService = voucherService

        NotificationCenter.default.publisher(for: VoucherService.cardActivationDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.load() }
            .store(in: &cancellables)
    }

    deinit { loadTask?.cancel() }

    func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.reload()
        }
    }

    func selectInstitution(id: String) {
        guard snapshot?.institutions.contains(where: { $0.id == id }) == true else { return }
        load()
    }

    func selectCategory(_ title: String) {
        guard let category = cachedCategories.first(where: { $0.title == title }),
              category.id != selectedCategoryId else { return }
        selectedCategoryId = category.id
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.reloadPackages(categoryId: category.id)
        }
    }

    func rowCount(for section: Section) -> Int {
        guard let snapshot else { return 0 }
        switch section {
        case .activateBanner:
            return snapshot.showActivateBanner ? 1 : 0
        case .bannerCarousel:
            return snapshot.banners.isEmpty ? 0 : 1
        case .matrix:
            return snapshot.matrix.isEmpty ? 0 : 1
        case .recommend:
            guard !snapshot.categories.isEmpty else { return 0 }
            return 1 + snapshot.recommendedPackages.count
        }
    }

    func sectionTitle(for section: Section) -> String? {
        switch section {
        case .matrix: return "德系9大产品线"
        case .recommend: return "推荐服务"
        default: return nil
        }
    }

    func sectionMore(for section: Section) -> String? {
        switch section {
        case .recommend: return "查看全部 ›"
        default: return nil
        }
    }

    func isCategoryRow(at indexPath: IndexPath) -> Bool {
        indexPath.row == 0
    }

    func package(at indexPath: IndexPath) -> HealthPackageItem? {
        guard let snapshot, indexPath.row > 0 else { return nil }
        let index = indexPath.row - 1
        guard snapshot.recommendedPackages.indices.contains(index) else { return nil }
        return snapshot.recommendedPackages[index]
    }

    // MARK: - Private

    @MainActor
    private func reload() async {
        isLoading = true
        defer { isLoading = false }

        async let banners = fetchBanners()
        async let matrix = fetchMatrix()
        async let categories = fetchCategories()
        let resolvedBanners = await banners
        let resolvedMatrix = await matrix
        let resolvedCategories = await categories
        guard !Task.isCancelled else { return }

        cachedCategories = resolvedCategories
        let category = resolveCategory(in: resolvedCategories)
        let packages: [HealthPackageItem]
        if let category {
            packages = await fetchPackages(for: category)
        } else {
            packages = []
        }

        applySnapshot(
            banners: resolvedBanners,
            matrix: resolvedMatrix,
            categories: resolvedCategories,
            selectedCategoryId: category?.id ?? "",
            packages: packages
        )
    }

    @MainActor
    private func reloadPackages(categoryId: String) async {
        isLoading = true
        defer { isLoading = false }

        guard let category = cachedCategories.first(where: { $0.id == categoryId }) else { return }
        let packages = await fetchPackages(for: category)
        guard !Task.isCancelled else { return }

        applySnapshot(
            banners: snapshot?.banners ?? [],
            matrix: snapshot?.matrix ?? [],
            categories: cachedCategories,
            selectedCategoryId: categoryId,
            packages: packages
        )
    }

    @MainActor
    private func applySnapshot(
        banners: [ServiceHubBanner],
        matrix: [ProductMatrixItem],
        categories: [ServiceRecommendCategory],
        selectedCategoryId: String,
        packages: [HealthPackageItem]
    ) {
        snapshot = catalogService.loadHubSnapshot(
            cardActivated: voucherService.isCardActivated,
            banners: banners,
            matrix: matrix,
            categories: categories,
            selectedCategoryId: selectedCategoryId,
            recommendedPackages: packages
        )
    }

    private func resolveCategory(in categories: [ServiceRecommendCategory]) -> ServiceRecommendCategory? {
        if let selectedCategoryId,
           let selected = categories.first(where: { $0.id == selectedCategoryId }) {
            return selected
        }
        let first = categories.first
        selectedCategoryId = first?.id
        return first
    }

    private func fetchBanners() async -> [ServiceHubBanner] {
        do {
            return try await columnContentService.fetchHospitalBanners()
        } catch {
            print("[ServiceViewModel] fetchHospitalBanners failed: \(error.localizedDescription)")
            return []
        }
    }

    private func fetchMatrix() async -> [ProductMatrixItem] {
        do {
            return try await dictionaryService.fetchProductMatrix()
        } catch {
            print("[ServiceViewModel] fetchProductMatrix failed: \(error.localizedDescription)")
            return []
        }
    }

    private func fetchCategories() async -> [ServiceRecommendCategory] {
        do {
            return try await dictionaryService.fetchRecommendCategories()
        } catch {
            print("[ServiceViewModel] fetchRecommendCategories failed: \(error.localizedDescription)")
            return []
        }
    }

    private func fetchPackages(for category: ServiceRecommendCategory) async -> [HealthPackageItem] {
        do {
            return try await hospitalPackageService.fetchPackageItems(
                category: category,
                hospitalId: catalogService.selectedApiHospitalId()
            )
        } catch {
            print("[ServiceViewModel] fetchPackageItems failed: \(error.localizedDescription)")
            return []
        }
    }
}
