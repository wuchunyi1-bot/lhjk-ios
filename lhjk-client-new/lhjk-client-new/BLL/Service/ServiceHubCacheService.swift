import Foundation

// MARK: - 静态层快照

/// 服务 Hub 静态层（banners / matrix / categories）— 无 TTL，会话内内存缓存
struct ServiceHubStaticData {
    let banners: [ServiceHubBanner]
    let matrix: [ProductMatrixItem]
    let categories: [ServiceRecommendCategory]
}

// MARK: - 服务 Hub 缓存 (BLL)

/// 服务首页预加载与会话内缓存 — 对标 `IMService` 会话列表缓存模式。
///
/// - **actor 隔离**：禁止并行 Task 互踩 `packageTasks` / `packagesByCategoryId` 等（否则会 EXC_BAD_ACCESS）
/// - **无 TTL**：不做时间过期；冷启动 / `clear()` 后重新拉取
/// - **静态层**：冷启动延迟预拉；会话内 `hasLoadedStatic` 为 true 时复用
/// - **packages**：不预拉；按类目 id 缓存，同 key 会话内复用
actor ServiceHubCacheService {

    static let shared = ServiceHubCacheService()

    private struct StaticFetchOutcome {
        let data: ServiceHubStaticData
        /// 至少有一路接口成功，或任一模块非空 → 视为本会话可复用
        let succeeded: Bool
    }

    private(set) var hasLoadedStatic = false

    private var staticData: ServiceHubStaticData?
    private var packagesByCategoryId: [String: [HealthPackageItem]] = [:]
    private var retailPreviewPackages: [HealthPackageItem]?
    private var retailTotalPages: Int = 1
    private var retailTask: Task<(packages: [HealthPackageItem], totalPages: Int), Never>?

    private var staticTask: Task<StaticFetchOutcome, Never>?
    private var packageTasks: [String: Task<[HealthPackageItem], Never>] = [:]
    /// 递增以丢弃 clear / forceReload 之后迟到的 in-flight 结果
    private var generation = 0

    private let columnContentCache: ColumnContentCacheService
    private let hospitalPackageService: HospitalPackageService
    private let retailCategoryService: RetailCategoryService

    init(
        columnContentCache: ColumnContentCacheService = .shared,
        hospitalPackageService: HospitalPackageService = .shared,
        retailCategoryService: RetailCategoryService = .shared
    ) {
        self.columnContentCache = columnContentCache
        self.hospitalPackageService = hospitalPackageService
        self.retailCategoryService = retailCategoryService
    }

    // MARK: - Read

    func getStatic() -> ServiceHubStaticData? {
        staticData
    }

    func cachedPackages(for categoryId: String) -> [HealthPackageItem]? {
        packagesByCategoryId[categoryId]
    }

    /// 在已缓存的推荐套餐中按 id 查找
    func findCachedPackage(id: String) -> HealthPackageItem? {
        if let match = retailPreviewPackages?.first(where: { $0.id == id }) {
            return match
        }
        return packagesByCategoryId.values
            .flatMap { $0 }
            .first { $0.id == id }
    }

    func cachedRetailPreview() -> [HealthPackageItem]? {
        retailPreviewPackages
    }

    /// `loadMore` 成功后同步会话缓存，避免 Tab 切回或 `/mall` 只读到首屏
    func updateRetailPreview(packages: [HealthPackageItem], totalPages: Int) {
        retailPreviewPackages = packages
        retailTotalPages = max(1, totalPages)
    }

    /// Hub 富德优选预览（前 10 条零售套包）
    func ensureRetailPreview(hospitalId: String?, pageSize: Int = 10) async -> (packages: [HealthPackageItem], totalPages: Int) {
        if let retailPreviewPackages, !retailPreviewPackages.isEmpty {
            return (retailPreviewPackages, retailTotalPages)
        }
        if let retailTask {
            return await retailTask.value
        }

        let gen = generation
        let packageService = hospitalPackageService
        let task = Task { () -> (packages: [HealthPackageItem], totalPages: Int) in
            do {
                let pageData = try await packageService.fetchRetailPackages(
                    pageNum: 1,
                    pageSize: pageSize
                )
                let items = (pageData.records ?? []).enumerated().map { index, vo in
                    HospitalPackageMapper.toPackageItem(vo, index: index)
                }
                return (packages: items, totalPages: pageData.totalPages ?? 1)
            } catch {
                print("[ServiceHubCache] ensureRetailPreview failed: \(error.localizedDescription)")
                return (packages: [], totalPages: 1)
            }
        }
        retailTask = task
        let result = await task.value
        retailTask = nil

        guard gen == generation else {
            return (packages: retailPreviewPackages ?? result.packages, totalPages: retailTotalPages)
        }
        retailPreviewPackages = result.packages
        retailTotalPages = result.totalPages
        return result
    }

    // MARK: - Preload / Ensure

    /// 预拉静态层（banners / matrix / categories）。已成功加载则直接返回缓存；in-flight 去重。
    /// 全失败 / 全空时 **不** 置 `hasLoadedStatic`，以便进入服务 Tab 时再次拉取（对齐 service-hub-preload）。
    @discardableResult
    func preloadStatic() async -> ServiceHubStaticData {
        if let staticData, hasLoadedStatic {
            return staticData
        }
        if let staticTask {
            return await staticTask.value.data
        }

        let gen = generation
        let task = Task {
            await self.fetchStatic()
        }
        staticTask = task
        let fetched = await task.value
        staticTask = nil

        guard gen == generation else { return fetched.data }
        if fetched.succeeded {
            staticData = fetched.data
            hasLoadedStatic = true
        } else {
            print("[ServiceHubCache] preloadStatic not ready — retry later")
        }
        return fetched.data
    }

    /// 确保某类目 packages 已缓存；有缓存则返回，否则请求并写入。
    func ensurePackages(
        category: ServiceRecommendCategory,
        hospitalId: String?
    ) async -> [HealthPackageItem] {
        let key = category.id
        if let cached = packagesByCategoryId[key] {
            return cached
        }
        if let existing = packageTasks[key] {
            return await existing.value
        }

        let gen = generation
        let packageService = hospitalPackageService
        let task = Task {
            do {
                return try await packageService.fetchPackageItems(
                    category: category,
                    hospitalId: hospitalId
                )
            } catch {
                print("[ServiceHubCache] ensurePackages failed category=\(key): \(error.localizedDescription)")
                return [] as [HealthPackageItem]
            }
        }
        packageTasks[key] = task
        let result = await task.value
        packageTasks[key] = nil

        guard gen == generation else {
            return packagesByCategoryId[key] ?? result
        }
        packagesByCategoryId[key] = result
        return result
    }

    /// 绕过缓存全量重拉静态层 + 指定类目 packages
    func forceReload(
        category: ServiceRecommendCategory?,
        hospitalId: String?
    ) async -> (staticData: ServiceHubStaticData, packages: [HealthPackageItem]) {
        await clear()
        let staticResult = await preloadStatic()
        guard let category else {
            return (staticResult, [])
        }
        let packages = await ensurePackages(category: category, hospitalId: hospitalId)
        return (staticResult, packages)
    }

    /// 登出 / 强制刷新前清空。进程重启本身内存已空；显式 clear 用于同进程登出再登录。
    func clear() async {
        generation += 1
        staticData = nil
        hasLoadedStatic = false
        packagesByCategoryId.removeAll()
        retailPreviewPackages = nil
        retailTotalPages = 1
        await retailCategoryService.invalidate()
        staticTask?.cancel()
        staticTask = nil
        retailTask?.cancel()
        retailTask = nil
        packageTasks.values.forEach { $0.cancel() }
        packageTasks.removeAll()
        print("[ServiceHubCache] cleared")
    }

    /// 仅清空 packages（未来换机构时用）
    func invalidatePackages() async {
        packagesByCategoryId.removeAll()
        retailPreviewPackages = nil
        retailTotalPages = 1
        await retailCategoryService.invalidate()
        retailTask?.cancel()
        retailTask = nil
        packageTasks.values.forEach { $0.cancel() }
        packageTasks.removeAll()
    }

    // MARK: - Private

    private func fetchStatic() async -> StaticFetchOutcome {
        async let banners = fetchBanners()
        async let matrix = fetchMatrix()
        async let categories = fetchCategories()
        let (b, m, c) = await (banners, matrix, categories)
        let data = ServiceHubStaticData(banners: b.items, matrix: m.items, categories: c.items)
        let hasContent = !b.items.isEmpty || !m.items.isEmpty || !c.items.isEmpty
        let anyOK = b.ok || m.ok || c.ok
        return StaticFetchOutcome(data: data, succeeded: hasContent || anyOK)
    }

    private struct FetchList<T> {
        let items: [T]
        let ok: Bool
    }

    private func fetchBanners() async -> FetchList<ServiceHubBanner> {
        let code = ColumnContentService.hospitalBannerCode
        let items = await columnContentCache.banners(for: code)
        // 缓存层失败不标记 loaded → 返回空且 ok=false 以便 Hub 可重试静态层
        if await columnContentCache.cachedBanners(for: code) != nil {
            return FetchList(items: items, ok: true)
        }
        return FetchList(items: items, ok: false)
    }

    private func fetchMatrix() async -> FetchList<ProductMatrixItem> {
        var items = DictionaryCacheService.shared.productMatrix()
        if items.isEmpty {
            await DictionaryCacheService.shared.sync()
            items = DictionaryCacheService.shared.productMatrix()
        }
        return FetchList(items: items, ok: !items.isEmpty)
    }

    private func fetchCategories() async -> FetchList<ServiceRecommendCategory> {
        var items = DictionaryCacheService.shared.recommendCategories()
        if items.isEmpty {
            await DictionaryCacheService.shared.sync()
            items = DictionaryCacheService.shared.recommendCategories()
        }
        return FetchList(items: items, ok: !items.isEmpty)
    }
}
