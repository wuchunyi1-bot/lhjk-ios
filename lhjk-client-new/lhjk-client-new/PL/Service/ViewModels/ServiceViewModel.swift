import Foundation
import Combine

/// 服务首页 ViewModel — 缓存优先，对齐 funde-client `ServicesView.vue`
@MainActor
final class ServiceViewModel: ObservableObject {

    enum Section: Int, CaseIterable {
        case activateBanner
        case bannerCarousel
        case matrix
        case mallPreview
    }

    @Published private(set) var snapshot: ServiceHubSnapshot?
    @Published private(set) var isLoading = false

    private let cacheService: ServiceHubCacheService
    private let catalogService: ServiceCatalogService
    private let voucherService: VoucherService
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

    func load() {
        if let staticData = cacheService.getStatic() {
            applyFromCache(
                staticData: staticData,
                mallPreview: cacheService.cachedRetailPreview() ?? []
            )
        }

        if loadTask != nil, isLoading { return }

        let generation = beginLoad()
        loadTask = Task { [weak self] in
            await self?.reloadFromCacheOrNetwork(generation: generation)
        }
    }

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

    func rowCount(for section: Section) -> Int {
        guard let snapshot else { return 0 }
        switch section {
        case .activateBanner:
            return snapshot.showActivateBanner ? 1 : 0
        case .bannerCarousel:
            return snapshot.banners.isEmpty ? 0 : 1
        case .matrix:
            return snapshot.matrix.isEmpty ? 0 : 1
        case .mallPreview:
            return snapshot.mallPreviewPackages.count
        }
    }

    func sectionTitle(for section: Section) -> String? {
        switch section {
        case .matrix: return "德系9大产品线"
        case .mallPreview: return "富德优选"
        default: return nil
        }
    }

    func sectionMore(for section: Section) -> String? {
        switch section {
        case .mallPreview: return "查看全部 ›"
        default: return nil
        }
    }

    func package(at indexPath: IndexPath) -> HealthPackageItem? {
        guard let snapshot, snapshot.mallPreviewPackages.indices.contains(indexPath.row) else { return nil }
        return snapshot.mallPreviewPackages[indexPath.row]
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

        applyFromCache(
            staticData: staticData,
            mallPreview: cacheService.cachedRetailPreview() ?? []
        )

        let mallPreview = await cacheService.ensureRetailPreview(
            hospitalId: catalogService.selectedApiHospitalId(),
            pageSize: 6
        )
        guard isCurrent(generation) else { return }

        applyFromCache(staticData: staticData, mallPreview: mallPreview)
    }

    private func performForceReload(generation: Int) async {
        defer { finishLoad(generation) }

        cacheService.invalidatePackages()
        let staticData = await cacheService.preloadStatic()
        guard isCurrent(generation) else { return }

        let mallPreview = await cacheService.ensureRetailPreview(
            hospitalId: catalogService.selectedApiHospitalId(),
            pageSize: 6
        )
        guard isCurrent(generation) else { return }

        applyFromCache(staticData: staticData, mallPreview: mallPreview)
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
            mallPreviewPackages: snapshot.mallPreviewPackages
        )
    }

    private func applyFromCache(staticData: ServiceHubStaticData, mallPreview: [HealthPackageItem]) {
        snapshot = catalogService.loadHubSnapshot(
            cardActivated: voucherService.isCardActivated,
            banners: staticData.banners,
            matrix: staticData.matrix,
            mallPreviewPackages: mallPreview
        )
    }
}
