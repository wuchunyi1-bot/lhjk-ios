import Foundation
import Combine

/// 服务首页 ViewModel — 缓存优先，对齐 funde-client `ServicesView.vue`
@MainActor
final class ServiceViewModel: ObservableObject {

    enum Section: Int, CaseIterable {
        case bannerCarousel
        case matrix
        case mallPreview
    }

    @Published private(set) var snapshot: ServiceHubSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var currentPage = 1
    @Published private(set) var totalPages = 1
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = true

    private let cacheService: ServiceHubCacheService
    private let catalogService: ServiceCatalogService
    private let hospitalPackageService: HospitalPackageService
    private var loadTask: Task<Void, Never>?
    private var loadGeneration = 0

    init(
        cacheService: ServiceHubCacheService = AppContainer.shared.serviceHubCacheService,
        catalogService: ServiceCatalogService = AppContainer.shared.serviceCatalogService,
        hospitalPackageService: HospitalPackageService = AppContainer.shared.hospitalPackageService
    ) {
        self.cacheService = cacheService
        self.catalogService = catalogService
        self.hospitalPackageService = hospitalPackageService
    }

    deinit { loadTask?.cancel() }

    func load() {
        if let staticData = cacheService.getStatic() {
            let preview = snapshot?.mallPreviewPackages
                ?? cacheService.cachedRetailPreview()
                ?? []
            applyFromCache(staticData: staticData, mallPreview: preview)
        }

        // 已加载富德优选数据时，Tab 切回不重置分页
        if snapshot?.mallPreviewPackages.isEmpty == false {
            return
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
        case .matrix: return "德系产品"
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

        let result = await cacheService.ensureRetailPreview(
            hospitalId: catalogService.selectedApiHospitalId(),
            pageSize: 10
        )
        guard isCurrent(generation) else { return }

        applyFromCache(staticData: staticData, mallPreview: result.packages)
        currentPage = 1
        totalPages = result.totalPages
        hasMore = currentPage < totalPages
    }

    private func performForceReload(generation: Int) async {
        defer { finishLoad(generation) }

        cacheService.invalidatePackages()
        let staticData = await cacheService.preloadStatic()
        guard isCurrent(generation) else { return }

        let result = await cacheService.ensureRetailPreview(
            hospitalId: catalogService.selectedApiHospitalId(),
            pageSize: 10
        )
        guard isCurrent(generation) else { return }

        applyFromCache(staticData: staticData, mallPreview: result.packages)
        currentPage = 1
        totalPages = result.totalPages
        hasMore = currentPage < totalPages
    }

    func loadMore() {
        guard !isLoadingMore, !isLoading, hasMore, let currentSnapshot = snapshot else { return }
        isLoadingMore = true

        let generation = loadGeneration
        Task { [weak self] in
            guard let self else { return }
            do {
                let nextPage = self.currentPage + 1

                let pageData = try await self.hospitalPackageService.fetchRetailPackages(
                    pageNum: nextPage,
                    pageSize: 10
                )

                guard self.isCurrent(generation) else { return }

                let newItems = (pageData.records ?? []).enumerated().map { index, vo in
                    HospitalPackageMapper.toPackageItem(vo, index: (nextPage - 1) * 10 + index)
                }

                let updatedPackages = currentSnapshot.mallPreviewPackages + newItems
                let resolvedTotalPages = pageData.totalPages ?? self.totalPages
                let resolvedCurrentPage = pageData.currentPage ?? nextPage
                let stillHasMore = !newItems.isEmpty && resolvedCurrentPage < resolvedTotalPages

                self.currentPage = resolvedCurrentPage
                self.totalPages = resolvedTotalPages
                self.hasMore = stillHasMore
                self.isLoadingMore = false

                self.cacheService.updateRetailPreview(
                    packages: updatedPackages,
                    totalPages: resolvedTotalPages
                )
                self.snapshot = ServiceHubSnapshot(
                    institution: currentSnapshot.institution,
                    institutions: currentSnapshot.institutions,
                    banners: currentSnapshot.banners,
                    matrix: currentSnapshot.matrix,
                    mallPreviewPackages: updatedPackages
                )
            } catch {
                print("[ServiceVM] loadMore failed: \(error.localizedDescription)")
                self.isLoadingMore = false
            }
        }
    }

    private func applyFromCache(staticData: ServiceHubStaticData, mallPreview: [HealthPackageItem]) {
        snapshot = catalogService.loadHubSnapshot(
            banners: staticData.banners,
            matrix: staticData.matrix,
            mallPreviewPackages: mallPreview
        )
    }
}
