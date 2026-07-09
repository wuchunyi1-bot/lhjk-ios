import Foundation
import Combine

/// 服务首页 ViewModel — 缓存优先，对齐消息模块会话列表加载模式
@MainActor
final class ServiceViewModel: ObservableObject {

    enum Section: Int, CaseIterable {
        case activateBanner
        case bannerCarousel
        case matrix
        case recommend
    }

    @Published private(set) var snapshot: ServiceHubSnapshot?
    @Published private(set) var isLoading = false

    private let cacheService: ServiceHubCacheService
    private let catalogService: ServiceCatalogService
    private let voucherService: VoucherService
    private var selectedCategoryId: String?
    private var cachedCategories: [ServiceRecommendCategory] = []
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?
    private var loadGeneration = 0

    init(
        cacheService: ServiceHubCacheService = AppContainer.shared.serviceHubCacheService,
        catalogService: ServiceCatalogService = AppContainer.shared.serviceCatalogService,
        voucherService: VoucherService = AppContainer.shared.voucherService
    ) {
        self.cacheService = cacheService
        self.catalogService = catalogService
        self.voucherService = voucherService

        NotificationCenter.default.publisher(for: VoucherService.cardActivationDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshActivateBannerOnly() }
            .store(in: &cancellables)
    }

    deinit { loadTask?.cancel() }

    /// 缓存优先：有静态缓存先上屏，再补 packages；会话内不重复全量打网
    func load() {
        // 已有缓存立刻上屏，避免等待网络时整页空白
        if let staticData = cacheService.getStatic() {
            applyFromCache(
                staticData: staticData,
                packages: packagesForSelected(in: staticData.categories)
            )
        }

        // 已有进行中的加载则复用，避免 viewWillAppear 反复 cancel 导致结果被丢弃
        if loadTask != nil, isLoading {
            return
        }

        let generation = beginLoad()
        loadTask = Task { [weak self] in
            await self?.reloadFromCacheOrNetwork(generation: generation)
        }
    }

    /// 下拉刷新等：绕过缓存全量重拉
    func forceReload() {
        let generation = beginLoad()
        loadTask = Task { [weak self] in
            await self?.performForceReload(generation: generation)
        }
    }

    func selectInstitution(id: String) {
        guard snapshot?.institutions.contains(where: { $0.id == id }) == true else { return }
        cacheService.invalidatePackages()
        forceReload()
    }

    func selectCategory(_ title: String) {
        guard let category = cachedCategories.first(where: { $0.title == title }),
              category.id != selectedCategoryId else { return }
        selectedCategoryId = category.id

        if let cached = cacheService.cachedPackages(for: category.id),
           let staticData = cacheService.getStatic() {
            applyFromCache(staticData: staticData, packages: cached)
            return
        }

        let generation = beginLoad()
        loadTask = Task { [weak self] in
            await self?.reloadPackages(category: category, generation: generation)
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

    private func beginLoad() -> Int {
        loadGeneration += 1
        loadTask?.cancel()
        loadTask = nil
        isLoading = true
        return loadGeneration
    }

    private func finishLoad(_ generation: Int) {
        guard generation == loadGeneration else { return }
        isLoading = false
        loadTask = nil
    }

    private func isCurrent(_ generation: Int) -> Bool {
        generation == loadGeneration
    }

    private func reloadFromCacheOrNetwork(generation: Int) async {
        defer { finishLoad(generation) }

        let staticData = await cacheService.preloadStatic()
        guard isCurrent(generation) else { return }

        // 静态层先上屏，避免等 packages 时整页空白
        applyFromCache(
            staticData: staticData,
            packages: packagesForSelected(in: staticData.categories)
        )

        cachedCategories = staticData.categories
        let category = resolveCategory(in: staticData.categories)

        let packages: [HealthPackageItem]
        if let category {
            packages = await cacheService.ensurePackages(
                category: category,
                hospitalId: catalogService.selectedApiHospitalId()
            )
        } else {
            packages = []
        }
        guard isCurrent(generation) else { return }

        applyFromCache(staticData: staticData, packages: packages)
    }

    private func performForceReload(generation: Int) async {
        defer { finishLoad(generation) }

        let categoryHint: ServiceRecommendCategory?
        if let id = selectedCategoryId {
            categoryHint = cachedCategories.first(where: { $0.id == id })
                ?? cacheService.getStatic()?.categories.first(where: { $0.id == id })
        } else {
            categoryHint = cacheService.getStatic()?.categories.first
                ?? cachedCategories.first
        }

        let result = await cacheService.forceReload(
            category: categoryHint,
            hospitalId: catalogService.selectedApiHospitalId()
        )
        guard isCurrent(generation) else { return }

        cachedCategories = result.staticData.categories
        if let categoryHint {
            selectedCategoryId = categoryHint.id
        } else {
            selectedCategoryId = result.staticData.categories.first?.id
        }
        applyFromCache(staticData: result.staticData, packages: result.packages)
    }

    private func reloadPackages(category: ServiceRecommendCategory, generation: Int) async {
        defer { finishLoad(generation) }

        let packages = await cacheService.ensurePackages(
            category: category,
            hospitalId: catalogService.selectedApiHospitalId()
        )
        guard isCurrent(generation) else { return }

        let staticData = cacheService.getStatic() ?? ServiceHubStaticData(
            banners: snapshot?.banners ?? [],
            matrix: snapshot?.matrix ?? [],
            categories: cachedCategories
        )
        applyFromCache(staticData: staticData, packages: packages)
    }

    private func refreshActivateBannerOnly() {
        guard let snapshot else {
            load()
            return
        }
        self.snapshot = catalogService.loadHubSnapshot(
            cardActivated: voucherService.isCardActivated,
            banners: snapshot.banners,
            matrix: snapshot.matrix,
            categories: snapshot.categories,
            selectedCategoryId: snapshot.selectedCategoryId,
            recommendedPackages: snapshot.recommendedPackages
        )
    }

    private func applyFromCache(staticData: ServiceHubStaticData, packages: [HealthPackageItem]) {
        cachedCategories = staticData.categories
        let category = resolveCategory(in: staticData.categories)
        snapshot = catalogService.loadHubSnapshot(
            cardActivated: voucherService.isCardActivated,
            banners: staticData.banners,
            matrix: staticData.matrix,
            categories: staticData.categories,
            selectedCategoryId: category?.id ?? "",
            recommendedPackages: packages
        )
    }

    private func packagesForSelected(in categories: [ServiceRecommendCategory]) -> [HealthPackageItem] {
        let category = resolveCategory(in: categories)
        guard let category else { return [] }
        return cacheService.cachedPackages(for: category.id) ?? []
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
}
