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
        guard let mobile = UserDefaults.standard.string(forKey: "current_user_mobile"), !mobile.isEmpty else {
            print("[UserManager] refreshUserInfo → no mobile stored, skip")
            return nil
        }
        print("[UserManager] refreshUserInfo → fetching for mobile=\(mobile)")
        guard let user = try? await UserService.shared.getUserByParam(mobile: mobile) else {
            print("[UserManager] refreshUserInfo → request failed, keeping cached data")
            return currentUser
        }
        currentUser = user
        persist(user)
        NotificationCenter.default.post(name: .userDidUpdate, object: user)
        print("[UserManager] refreshUserInfo ✓ id=\(user.id ?? "nil")")
        return user
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
