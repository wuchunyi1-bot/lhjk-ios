import Foundation

// MARK: - Notification

extension Notification.Name {
    /// 用户信息更新通知（个人信息保存后触发）
    static let userDidUpdate = Notification.Name("FDUserDidUpdate")
}

// MARK: - UserManager

/// 用户信息管理器
///
/// 统一管理用户信息的**内存缓存 + 本地持久化**：
/// - App 启动时从 UserDefaults 恢复缓存
/// - 登录成功后调用 `fetchUserInfo()` 拉取一次
/// - 各页面通过 `currentUser` 读取，不再重复请求
/// - 个人信息更新后调用 `refreshUserInfo()` 强制刷新
/// - 登出时调用 `clear()` 清除
final class UserManager {

    // MARK: - Singleton

    static let shared = UserManager()

    // MARK: - Cache Key

    private static let cacheKey = "cached_user_info"

    // MARK: - State

    /// 当前用户信息（内存缓存）
    private(set) var currentUser: SUsers?

    /// 是否已完成首次网络拉取（同一生命周期内 fetchUserInfo 只发一次请求）
    private var hasFetched = false

    // MARK: - Init

    private init() {
        // 启动时从 UserDefaults 恢复缓存
        if let data = UserDefaults.standard.data(forKey: Self.cacheKey),
           let user = try? JSONDecoder().decode(SUsers.self, from: data) {
            self.currentUser = user
            print("[UserManager] loaded cached user — id=\(user.id ?? "nil") name=\(user.chineseName ?? "nil")")
        }
    }

    // MARK: - Public API

    /// 从 API 拉取用户信息（首次调用才发请求，后续直接返回内存缓存）
    ///
    /// 适用场景：App 启动、登录成功后
    @discardableResult
    func fetchUserInfo() async -> SUsers? {
        if hasFetched { return currentUser }
        hasFetched = true
        return await refreshUserInfo()
    }

    /// 强制刷新用户信息（总是发请求，更新内存 + 本地持久化 + 发通知）
    ///
    /// 适用场景：个人信息保存后
    @discardableResult
    func refreshUserInfo() async -> SUsers? {
        print("[UserManager] refreshUserInfo → fetching current user")
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

    /// 检查是否需要展示引导页（onboarding）
    ///
    /// 调用 `getCurrentUserBaseInfo` 获取最新用户数据，检查 `chineseName`、`sex`、`birthday`
    /// 三个字段是否都存在非空值。任意一个为空即返回 `true`（需要展示）。
    ///
    /// - Returns: `true` 表示需要展示 onboarding
    func checkNeedOnboarding() async -> Bool {
        let user = await refreshUserInfo()
        if let user = user {
            hasFetched = true
            let nameEmpty = (user.chineseName ?? "").isEmpty
            let sexEmpty = (user.sex ?? "").isEmpty
            let birthdayEmpty = (user.birthday ?? "").isEmpty
            let need = nameEmpty || sexEmpty || birthdayEmpty
            print("[UserManager] checkNeedOnboarding → name=\(!nameEmpty) sex=\(!sexEmpty) birthday=\(!birthdayEmpty) need=\(need)")
            return need
        }
        // 网络请求失败，fallback 到缓存
        if let cached = currentUser {
            let nameEmpty = (cached.chineseName ?? "").isEmpty
            let sexEmpty = (cached.sex ?? "").isEmpty
            let birthdayEmpty = (cached.birthday ?? "").isEmpty
            let need = nameEmpty || sexEmpty || birthdayEmpty
            print("[UserManager] checkNeedOnboarding → using cache, need=\(need)")
            return need
        }
        // 无缓存且请求失败：不阻塞用户
        print("[UserManager] checkNeedOnboarding → no data, default false")
        return false
    }

    /// 登出时清除内存 + 本地缓存
    func clear() {
        currentUser = nil
        hasFetched = false
        UserDefaults.standard.removeObject(forKey: Self.cacheKey)
        print("[UserManager] cleared")
    }

    // MARK: - Private

    private func persist(_ user: SUsers) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: Self.cacheKey)
        }
    }
}
