import Foundation

// MARK: - 栏位内容缓存 (BLL)

/// `GET /v1/columnContent/getByCode` 按 code 的会话内内存缓存。
///
/// - **actor 隔离**：禁止并行 Task 直接互踩 `cache` / `inflight`（否则会 EXC_BAD_ACCESS）
/// - **无 TTL**：不做时间过期；冷启动 / `clear()` 后重新拉取
/// - **冷启动**：`preloadColdStart()` 强制请求已知 code 并写入
/// - **界面**：`banners(for:)` 有成功缓存则复用，否则拉网并写入；同 code in-flight 去重
actor ColumnContentCacheService {

    static let shared = ColumnContentCacheService()

    /// 冷启动预拉的已知栏位
    static let knownPreloadCodes: [String] = [
        ColumnContentService.homeBannerCode,
        ColumnContentService.homeQuickLinkCode,
        ColumnContentService.homeHealthServiceCode,
        ColumnContentService.homeNewsCode,
        ColumnContentService.hospitalBannerCode,
    ]

    private var cache: [String: [ServiceHubBanner]] = [:]
    /// 已成功写入的 code（含空列表）；失败不入此集合
    private var loadedCodes: Set<String> = []
    private var inflight: [String: Task<FetchOutcome, Never>] = [:]
    private var generation = 0

    private let columnContentService: ColumnContentService

    init(columnContentService: ColumnContentService = .shared) {
        self.columnContentService = columnContentService
    }

    // MARK: - Read

    /// 若该 code 已成功缓存则返回；否则 nil
    func cachedBanners(for code: String) -> [ServiceHubBanner]? {
        let key = Self.normalized(code)
        guard !key.isEmpty, loadedCodes.contains(key) else { return nil }
        return cache[key] ?? []
    }

    /// 优先缓存；未命中则请求并写入。同 code 并发合并为一次网络。
    func banners(for code: String) async -> [ServiceHubBanner] {
        let key = Self.normalized(code)
        guard !key.isEmpty else { return [] }

        if loadedCodes.contains(key) {
            return cache[key] ?? []
        }
        return await fetchAndStore(code: key, force: false)
    }

    // MARK: - Cold start

    /// 冷启动：对已知 code **强制**拉网并覆盖缓存。
    /// 网络请求可并行；对 actor 状态的读写串行，避免 Dictionary 数据竞争。
    func preloadColdStart(codes: [String] = ColumnContentCacheService.knownPreloadCodes) async {
        let keys = codes.map(Self.normalized).filter { !$0.isEmpty }
        guard !keys.isEmpty else { return }

        print("[ColumnContentCache] preloadColdStart → codes=\(keys.joined(separator: ","))")
        await withTaskGroup(of: Void.self) { group in
            for key in keys {
                group.addTask {
                    // 通过 actor 方法入口串行化状态；网络 await 时会释放 actor 允许其它 code 推进
                    _ = await self.fetchAndStore(code: key, force: true)
                }
            }
        }
        print("[ColumnContentCache] preloadColdStart → done loaded=\(loadedCodes.sorted().joined(separator: ","))")
    }

    // MARK: - Clear

    func clear() {
        generation += 1
        cache.removeAll()
        loadedCodes.removeAll()
        for (_, task) in inflight {
            task.cancel()
        }
        inflight.removeAll()
        print("[ColumnContentCache] cleared")
    }

    // MARK: - Private

    private struct FetchOutcome: Sendable {
        let banners: [ServiceHubBanner]
        let succeeded: Bool
    }

    private func fetchAndStore(code: String, force: Bool) async -> [ServiceHubBanner] {
        if !force, loadedCodes.contains(code) {
            return cache[code] ?? []
        }

        if let existing = inflight[code] {
            let outcome = await existing.value
            if outcome.succeeded {
                return outcome.banners
            }
            return cachedBanners(for: code) ?? outcome.banners
        }

        let gen = generation
        let service = columnContentService
        let task = Task {
            do {
                let items = try await service.fetchBanners(code: code)
                return FetchOutcome(banners: items, succeeded: true)
            } catch {
                print("[ColumnContentCache] fetch ✗ code=\(code) \(error.localizedDescription)")
                return FetchOutcome(banners: [], succeeded: false)
            }
        }
        inflight[code] = task
        let outcome = await task.value
        inflight[code] = nil

        guard gen == generation else {
            return cachedBanners(for: code) ?? outcome.banners
        }

        if outcome.succeeded {
            cache[code] = outcome.banners
            loadedCodes.insert(code)
            print("[ColumnContentCache] cached ✓ code=\(code) count=\(outcome.banners.count)")
        }
        return outcome.banners
    }

    private static func normalized(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
