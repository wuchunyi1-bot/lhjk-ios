import Foundation

// MARK: - Notification

extension Notification.Name {
    /// 用户信息更新通知（个人信息保存后触发）
    static let userDidUpdate = Notification.Name("FDUserDidUpdate")
    /// 默认档案更新通知（登录/冷启动拉取或主动刷新后触发）
    static let defaultArchiveDidUpdate = Notification.Name("FDDefaultArchiveDidUpdate")
    /// 档案完善进度更新通知（`calculateArchiveCompletion` 拉取后触发）
    static let archiveCompletionDidUpdate = Notification.Name("FDArchiveCompletionDidUpdate")
    /// 今日健康监测任务需刷新通知（体征录入完成等）
    static let todayMonitorTaskShouldRefresh = Notification.Name("FDTodayMonitorTaskShouldRefresh")
}

// MARK: - UserManager

/// 用户信息管理器
///
/// 两套业务数据并存：
/// - `currentUser`：`GET /v1/users/getCurrentUserBaseInfo`
/// - `defaultArchive`：`GET /v1/archive/getOArchiveByUserId`（含 `archiveComplete`，供 `/onboarding` 门禁）
///
/// 登录 / 冷启动：先拉用户详情拿 `userId`，再拉默认档案，再按 `archiveComplete` 门禁。
final class UserManager {

    // MARK: - Singleton

    static let shared = UserManager()

    // MARK: - Cache Keys

    private static let cacheKey = "cached_user_info"
    private static let defaultArchiveKey = "cached_default_archive"
    private static let archiveCompletionKey = "cached_archive_completion_percentage"
    /// 历史登录摘要缓存（已废弃，启动时清理）
    private static let legacyLoginUserInfoKey = "cached_login_user_info"

    // MARK: - State

    /// 用户详情（`getCurrentUserBaseInfo`）— App 业务统一读此字段
    private(set) var currentUser: SUsers?

    /// 默认档案（`getOArchiveByUserId`）— 本地持久化；`archiveComplete` 为 onboarding 门禁
    private(set) var defaultArchive: OArchive?

    /// 档案完善进度（`calculateArchiveCompletion`）— 0–100，本地持久化
    private(set) var archiveCompletionPercentage: Int?

    /// 是否已完成首次详情拉取（同一生命周期内 `fetchUserInfo` 只发一次请求）
    private var hasFetched = false

    /// 是否已完成首次默认档案拉取
    private var hasFetchedArchive = false

    /// 是否已完成首次档案完善进度拉取
    private var hasFetchedArchiveCompletion = false

    // MARK: - Init

    private init() {
        UserDefaults.standard.removeObject(forKey: Self.legacyLoginUserInfoKey)

        if let data = UserDefaults.standard.data(forKey: Self.cacheKey),
           let user = try? JSONDecoder().decode(SUsers.self, from: data) {
            self.currentUser = user
            print("[UserManager] loaded cached user — id=\(user.id ?? "nil") name=\(user.chineseName ?? "nil")")
        }
        if let data = UserDefaults.standard.data(forKey: Self.defaultArchiveKey),
           let archive = try? JSONDecoder().decode(OArchive.self, from: data) {
            self.defaultArchive = archive
            print("[UserManager] loaded defaultArchive — id=\(archive.id ?? "nil") archiveComplete=\(archive.archiveComplete.map(String.init) ?? "nil")")
        }
        if UserDefaults.standard.object(forKey: Self.archiveCompletionKey) != nil {
            let cached = UserDefaults.standard.integer(forKey: Self.archiveCompletionKey)
            self.archiveCompletionPercentage = cached
            print("[UserManager] loaded archiveCompletionPercentage — \(cached)%")
        }
    }

    // MARK: - Onboarding 门禁

    /// 是否需要 Onboarding — 只读本地 `defaultArchive.archiveComplete`
    ///
    /// - 无缓存：不拦截（拉取失败或尚未写入），避免网络抖动锁死 App
    /// - 有缓存且 `archiveComplete != true`：需要完善
    /// - 调用方须在拉档完成后再调用
    func checkNeedOnboarding() -> Bool {
        guard let archive = defaultArchive else {
            print("[UserManager] checkNeedOnboarding → no defaultArchive, skip gate (false)")
            return false
        }
        let need = archive.archiveComplete != true
        print("[UserManager] checkNeedOnboarding → archiveComplete=\(archive.archiveComplete.map(String.init) ?? "nil") need=\(need)")
        return need
    }

    // MARK: - 用户详情（业务用）

    /// 拉取用户详情（首次发网，后续读内存）。供启动/登录后填充 `currentUser`。
    @discardableResult
    func fetchUserInfo() async -> SUsers? {
        if hasFetched { return currentUser }
        hasFetched = true
        return await refreshUserInfo()
    }

    /// 强制刷新用户详情（个人中心保存后等）
    @discardableResult
    func refreshUserInfo() async -> SUsers? {
        print("[UserManager] refreshUserInfo → GET getCurrentUserBaseInfo")
        guard let user = try? await UserService.shared.getCurrentUserBaseInfo() else {
            print("[UserManager] refreshUserInfo → request failed, keeping cached data")
            return currentUser
        }
        currentUser = user
        persist(user)
        await MainActor.run {
            NotificationCenter.default.post(name: .userDidUpdate, object: user)
        }
        print("[UserManager] refreshUserInfo ✓ id=\(user.id ?? "nil")")
        return user
    }

    // MARK: - 默认档案

    /// 档案查询用的用户 ID（仅 `currentUser.id`）
    var resolvedUserId: String? {
        let fromUser = currentUser?.id?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return fromUser.isEmpty ? nil : fromUser
    }

    /// 拉取默认档案（首次发网，后续读内存）。须先有 `currentUser.id`。
    @discardableResult
    func fetchDefaultArchive() async -> OArchive? {
        if hasFetchedArchive { return defaultArchive }
        hasFetchedArchive = true
        return await refreshDefaultArchive()
    }

    /// 强制刷新默认档案（建档/改档后等）
    @discardableResult
    func refreshDefaultArchive(userId: String? = nil) async -> OArchive? {
        let id = (userId ?? resolvedUserId)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !id.isEmpty else {
            print("[UserManager] refreshDefaultArchive → no userId, skip")
            return defaultArchive
        }

        print("[UserManager] refreshDefaultArchive → GET getOArchiveByUserId userId=\(id)")
        guard let archive = try? await UserService.shared.getOArchiveByUserId(id) else {
            print("[UserManager] refreshDefaultArchive → request failed, keeping cached data")
            return defaultArchive
        }
        defaultArchive = archive
        persistDefaultArchive(archive)
        await MainActor.run {
            NotificationCenter.default.post(name: .defaultArchiveDidUpdate, object: archive)
        }
        print("[UserManager] refreshDefaultArchive ✓ id=\(archive.id ?? "nil") archiveComplete=\(archive.archiveComplete.map(String.init) ?? "nil")")
        return archive
    }

    // MARK: - 档案完善进度

    /// 拉取档案完善进度（首次发网，后续读内存）。须先有 `currentUser.id`。
    @discardableResult
    func fetchArchiveCompletion() async -> Int? {
        if hasFetchedArchiveCompletion { return archiveCompletionPercentage }
        hasFetchedArchiveCompletion = true
        return await refreshArchiveCompletion()
    }

    /// 强制刷新档案完善进度
    @discardableResult
    func refreshArchiveCompletion(userId: String? = nil) async -> Int? {
        let id = (userId ?? resolvedUserId)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !id.isEmpty else {
            print("[UserManager] refreshArchiveCompletion → no userId, skip")
            return archiveCompletionPercentage
        }

        print("[UserManager] refreshArchiveCompletion → GET calculateArchiveCompletion userId=\(id)")
        guard let vo = try? await UserService.shared.calculateArchiveCompletion(userId: id) else {
            print("[UserManager] refreshArchiveCompletion → request failed, keeping cached data")
            return archiveCompletionPercentage
        }

        let raw = vo.completionPercentage ?? 0
        let clamped = min(100, max(0, raw))
        archiveCompletionPercentage = clamped
        UserDefaults.standard.set(clamped, forKey: Self.archiveCompletionKey)
        await MainActor.run {
            NotificationCenter.default.post(name: .archiveCompletionDidUpdate, object: clamped)
        }
        print("[UserManager] refreshArchiveCompletion ✓ \(clamped)%")
        return clamped
    }

    /// 登出：用户详情 / 默认档案一并清除
    func clear() {
        currentUser = nil
        defaultArchive = nil
        archiveCompletionPercentage = nil
        hasFetched = false
        hasFetchedArchive = false
        hasFetchedArchiveCompletion = false
        UserDefaults.standard.removeObject(forKey: Self.cacheKey)
        UserDefaults.standard.removeObject(forKey: Self.defaultArchiveKey)
        UserDefaults.standard.removeObject(forKey: Self.archiveCompletionKey)
        UserDefaults.standard.removeObject(forKey: Self.legacyLoginUserInfoKey)
        HomeService.shared.invalidateTodayTasksCache()
        print("[UserManager] cleared")
    }

    // MARK: - Private

    private func persist(_ user: SUsers) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: Self.cacheKey)
        }
    }

    private func persistDefaultArchive(_ archive: OArchive) {
        if let data = try? JSONEncoder().encode(archive) {
            UserDefaults.standard.set(data, forKey: Self.defaultArchiveKey)
        }
    }
}
