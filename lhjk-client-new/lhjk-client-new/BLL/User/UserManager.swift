import Foundation

// MARK: - Notification

extension Notification.Name {
    /// 用户信息更新通知（个人信息保存后触发）
    static let userDidUpdate = Notification.Name("FDUserDidUpdate")
}

// MARK: - UserManager

/// 用户信息管理器
///
/// 两套用户数据**同时存在、职责分离**：
/// - `loginUserInfo`：登录 token 返回的 `userInfo`，**仅**用于 `checkNeedOnboarding()`
/// - `currentUser`：`GET /v1/users/getCurrentUserBaseInfo`，供首页/我的/档案等业务读取
///
/// 启动或登录成功后应分别：本地判门禁 + 网络拉详情（二者互不调用对方接口）。
final class UserManager {

    // MARK: - Singleton

    static let shared = UserManager()

    // MARK: - Cache Keys

    private static let cacheKey = "cached_user_info"
    private static let loginUserInfoKey = "cached_login_user_info"

    // MARK: - State

    /// 用户详情（`getCurrentUserBaseInfo`）— App 业务统一读此字段
    private(set) var currentUser: SUsers?

    /// 登录返回的 userInfo — **仅** onboarding 门禁使用，禁止当作业务资料源
    private(set) var loginUserInfo: LoginUserInfo?

    /// 是否已完成首次详情拉取（同一生命周期内 `fetchUserInfo` 只发一次请求）
    private var hasFetched = false

    // MARK: - Init

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.cacheKey),
           let user = try? JSONDecoder().decode(SUsers.self, from: data) {
            self.currentUser = user
            print("[UserManager] loaded cached user — id=\(user.id ?? "nil") name=\(user.chineseName ?? "nil")")
        }
        if let data = UserDefaults.standard.data(forKey: Self.loginUserInfoKey),
           let info = try? JSONDecoder().decode(LoginUserInfo.self, from: data) {
            self.loginUserInfo = info
            print("[UserManager] loaded loginUserInfo — name=\(info.chineseName ?? "nil") hospitalId=\(info.hospitalId ?? "nil")")
        }
    }

    // MARK: - Login userInfo（Onboarding 专用）

    /// 登录成功后写入 token 内的 userInfo（仅门禁）
    func applyLoginUserInfo(_ info: LoginUserInfo?) {
        guard let info else {
            print("[UserManager] applyLoginUserInfo → nil, keep existing")
            return
        }
        loginUserInfo = info
        persistLoginUserInfo(info)
        print("[UserManager] applyLoginUserInfo ✓ name=\(info.chineseName ?? "nil") hospitalId=\(info.hospitalId ?? "nil")")
    }

    /// 完善资料后更新门禁缓存（仍不替代 `currentUser`）
    func patchLoginUserInfo(
        chineseName: String? = nil,
        sex: String? = nil,
        birthday: String? = nil,
        hospitalId: String? = nil
    ) {
        var info = loginUserInfo ?? LoginUserInfo()
        if let chineseName { info.chineseName = chineseName }
        if let sex { info.sex = sex }
        if let birthday { info.birthday = birthday }
        if let hospitalId { info.hospitalId = hospitalId }
        loginUserInfo = info
        persistLoginUserInfo(info)
    }

    /// 是否需要 Onboarding — **纯本地**，只读 `loginUserInfo`，绝不请求详情接口
    func checkNeedOnboarding() -> Bool {
        guard let info = loginUserInfo else {
            print("[UserManager] checkNeedOnboarding → no loginUserInfo, skip gate (false)")
            return true
        }
        let need = info.needsOnboarding
        print("[UserManager] checkNeedOnboarding → name=\(!Self.isBlank(info.chineseName)) sex=\(!Self.isBlank(info.sex)) birthday=\(!Self.isBlank(info.birthday)) hospitalId=\(!Self.isBlank(info.hospitalId)) need=\(need)")
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

    /// 登出：两套缓存一并清除
    func clear() {
        currentUser = nil
        loginUserInfo = nil
        hasFetched = false
        UserDefaults.standard.removeObject(forKey: Self.cacheKey)
        UserDefaults.standard.removeObject(forKey: Self.loginUserInfoKey)
        print("[UserManager] cleared")
    }

    // MARK: - Private

    private static func isBlank(_ value: String?) -> Bool {
        (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func persist(_ user: SUsers) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: Self.cacheKey)
        }
    }

    private func persistLoginUserInfo(_ info: LoginUserInfo) {
        if let data = try? JSONEncoder().encode(info) {
            UserDefaults.standard.set(data, forKey: Self.loginUserInfoKey)
        }
    }
}
