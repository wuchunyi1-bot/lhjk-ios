import Foundation

// MARK: - Notification

extension Notification.Name {
    /// 用户信息更新通知（个人信息保存后触发）
    static let userDidUpdate = Notification.Name("FDUserDidUpdate")
    /// 默认档案更新通知（登录/冷启动拉取或主动刷新后触发）
    static let defaultArchiveDidUpdate = Notification.Name("FDDefaultArchiveDidUpdate")
}

// MARK: - UserManager

/// 用户信息管理器
///
/// 多套用户数据**同时存在、职责分离**：
/// - `loginUserInfo`：登录 token 返回的 `userInfo`，**仅**用于 `checkNeedOnboarding()`
/// - `currentUser`：`GET /v1/users/getCurrentUserBaseInfo`，供首页/我的等业务读取
/// - `defaultArchive`：`GET /v1/archive/getOArchiveByUserId`，默认健康档案本地缓存
///
/// 启动或登录成功后应分别：本地判门禁 + 并行拉详情与默认档案（门禁不依赖后两者）。
final class UserManager {

    // MARK: - Singleton

    static let shared = UserManager()

    // MARK: - Cache Keys

    private static let cacheKey = "cached_user_info"
    private static let loginUserInfoKey = "cached_login_user_info"
    private static let defaultArchiveKey = "cached_default_archive"

    // MARK: - State

    /// 用户详情（`getCurrentUserBaseInfo`）— App 业务统一读此字段
    private(set) var currentUser: SUsers?

    /// 登录返回的 userInfo — **仅** onboarding 门禁使用，禁止当作业务资料源
    private(set) var loginUserInfo: LoginUserInfo?

    /// 默认档案（`getOArchiveByUserId`）— 本地持久化，供健康相关业务读取
    private(set) var defaultArchive: OArchive?

    /// 是否已完成首次详情拉取（同一生命周期内 `fetchUserInfo` 只发一次请求）
    private var hasFetched = false

    /// 是否已完成首次默认档案拉取
    private var hasFetchedArchive = false

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
        if let data = UserDefaults.standard.data(forKey: Self.defaultArchiveKey),
           let archive = try? JSONDecoder().decode(OArchive.self, from: data) {
            self.defaultArchive = archive
            print("[UserManager] loaded defaultArchive — id=\(archive.id ?? "nil") name=\(archive.chineseName ?? "nil")")
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
            // 无登录摘要时不拦截：后端未下发 / 尚未写入时不应强迫完善资料
            print("[UserManager] checkNeedOnboarding → no loginUserInfo, skip gate (false)")
            return false
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

    // MARK: - 默认档案

    /// 解析档案查询用的用户 ID：优先登录摘要，其次业务用户详情
    var resolvedUserId: String? {
        let fromLogin = loginUserInfo?.id?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !fromLogin.isEmpty { return fromLogin }
        let fromUser = currentUser?.id?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return fromUser.isEmpty ? nil : fromUser
    }

    /// 拉取默认档案（首次发网，后续读内存）。与 `fetchUserInfo` 并行调用。
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
        print("[UserManager] refreshDefaultArchive ✓ id=\(archive.id ?? "nil")")
        return archive
    }

    /// 登出：用户详情 / 登录摘要 / 默认档案一并清除
    func clear() {
        currentUser = nil
        loginUserInfo = nil
        defaultArchive = nil
        hasFetched = false
        hasFetchedArchive = false
        UserDefaults.standard.removeObject(forKey: Self.cacheKey)
        UserDefaults.standard.removeObject(forKey: Self.loginUserInfoKey)
        UserDefaults.standard.removeObject(forKey: Self.defaultArchiveKey)
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

    private func persistDefaultArchive(_ archive: OArchive) {
        if let data = try? JSONEncoder().encode(archive) {
            UserDefaults.standard.set(data, forKey: Self.defaultArchiveKey)
        }
    }
}
