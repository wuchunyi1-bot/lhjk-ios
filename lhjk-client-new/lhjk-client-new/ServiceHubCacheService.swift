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
/// - **无 TTL**：不做时间过期；冷启动 / `clear()` 后重新拉取
/// - **静态层**：冷启动延迟预拉；会话内 `hasLoadedStatic` 为 true 时复用
/// - **packages**：不预拉；按类目 id 缓存，同 key 会话内复用
final class ServiceHubCacheService {

    static let shared = ServiceHubCacheService()

    private(set) var hasLoadedStatic = false

    private var staticData: ServiceHubStaticData?
    private var packagesByCategoryId: [String: [HealthPackageItem]] = [:]

    private var staticTask: Task<ServiceHubStaticData, Never>?
    private var packageTasks: [String: Task<[HealthPackageItem], Never>] = [:]
    /// 递增以丢弃 clear / forceReload 之后迟到的 in-flight 结果
    private var generation = 0

    private let columnContentService: ColumnContentService
    private let dictionaryService: DictionaryService
    private let hospitalPackageService: HospitalPackageService

    init(
        columnContentService: ColumnContentService = .shared,
        dictionaryService: DictionaryService = .shared,
        hospitalPackageService: HospitalPackageService = .shared
    ) {
        self.columnContentService = columnContentService
        self.dictionaryService = dictionaryService
        self.hospitalPackageService = hospitalPackageService
    }

    // MARK: - Read

    func getStatic() -> ServiceHubStaticData? {
        staticData
    }

    func cachedPackages(for categoryId: String) -> [HealthPackageItem]? {
        packagesByCategoryId[categoryId]
    }

    // MARK: - Preload / Ensure

    /// 预拉静态层（banners / matrix / categories）。已加载则直接返回缓存；in-flight 去重。
    @discardableResult
    func preloadStatic() async -> ServiceHubStaticData {
        if let staticData, hasLoadedStatic {
            return staticData
        }
        if let staticTask {
            return await staticTask.value
        }

        let gen = generation
        let task = Task { [weak self] in
            await self?.fetchStatic() ?? ServiceHubStaticData(banners: [], matrix: [], categories: [])
        }
        staticTask = task
        let result = await task.value
        if staticTask != nil { staticTask = nil }

        guard gen == generation else {
            return staticData ?? result
        }
        staticData = result
        hasLoadedStatic = true
        return result
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
        let task = Task { [weak self] in
            guard let self else { return [] as [HealthPackageItem] }
            do {
                return try await self.hospitalPackageService.fetchPackageItems(
                    category: category,
                    hospitalId: hospitalId
                )
            } catch {
                print("[ServiceHubCache] ensurePackages failed category=\(key): \(error.localizedDescription)")
                return []
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
        clear()
        let staticResult = await preloadStatic()
        guard let category else {
            return (staticResult, [])
        }
        let packages = await ensurePackages(category: category, hospitalId: hospitalId)
        return (staticResult, packages)
    }

    /// 登出 / 强制刷新前清空。进程重启本身内存已空；显式 clear 用于同进程登出再登录。
    func clear() {
        generation += 1
        staticData = nil
        hasLoadedStatic = false
        packagesByCategoryId.removeAll()
        staticTask?.cancel()
        staticTask = nil
        packageTasks.values.forEach { $0.cancel() }
        packageTasks.removeAll()
        print("[ServiceHubCache] cleared")
    }

    /// 仅清空 packages（未来换机构时用）
    func invalidatePackages() {
        packagesByCategoryId.removeAll()
        packageTasks.values.forEach { $0.cancel() }
        packageTasks.removeAll()
    }

    // MARK: - Private

    private func fetchStatic() async -> ServiceHubStaticData {
        async let banners = fetchBanners()
        async let matrix = fetchMatrix()
        async let categories = fetchCategories()
        return await ServiceHubStaticData(
            banners: banners,
            matrix: matrix,
            categories: categories
        )
    }

    private func fetchBanners() async -> [ServiceHubBanner] {
        do {
            return try await columnContentService.fetchHospitalBanners()
        } catch {
            print("[ServiceHubCache] fetchBanners failed: \(error.localizedDescription)")
            return []
        }
    }

    private func fetchMatrix() async -> [ProductMatrixItem] {
        do {
            return try await dictionaryService.fetchProductMatrix()
        } catch {
            print("[ServiceHubCache] fetchMatrix failed: \(error.localizedDescription)")
            return []
        }
    }

    private func fetchCategories() async -> [ServiceRecommendCategory] {
        do {
            return try await dictionaryService.fetchRecommendCategories()
        } catch {
            print("[ServiceHubCache] fetchCategories failed: \(error.localizedDescription)")
            return []
        }
    }
}
