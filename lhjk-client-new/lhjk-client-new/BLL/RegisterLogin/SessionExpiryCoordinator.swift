import Foundation

/// 登录态失效统一协调：去重 → **优先 refresh_token** → 失败再清本地态并弹窗
///
/// 由 `APIManager.onSessionInvalidated` 触发（已认证请求业务码 A0230 / HTTP 401）。
/// UI 展示通过 `presentExpiredUI` 由启动层注入，避免 BLL 依赖 PL。
final class SessionExpiryCoordinator {

    static let shared = SessionExpiryCoordinator()

    static let defaultMessage = "为保护您的健康数据安全，登录状态已过期，请重新登录"
    static let sessionExpiredHintKey = "fd_session_expired_hint"

    /// - Parameters:
    ///   - message: 弹窗说明文案
    ///   - onRelogin: 用户点击「重新登录」后调用（设置 hint + 进登录页）
    var presentExpiredUI: ((_ message: String, _ onRelogin: @escaping () -> Void) -> Void)?

    private let lock = NSLock()
    private var isHandling = false

    private init() {}

    /// App 启动时注册到 `APIManager.shared.onSessionInvalidated`
    func install() {
        APIManager.shared.onSessionInvalidated = { [weak self] message in
            self?.handle(message: message)
        }
    }

    func handle(message: String?) {
        lock.lock()
        let already = isHandling
        let hasSession = UserDefaults.standard.string(forKey: "auth_access_token") != nil
            || LoginService.shared.getToken() != nil
        if already || !hasSession {
            lock.unlock()
            return
        }
        isHandling = true
        lock.unlock()

        let displayMessage: String = {
            let raw = message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if raw.isEmpty { return Self.defaultMessage }
            if raw == "登录已失效!" || raw == "登录已失效" { return Self.defaultMessage }
            return raw
        }()

        Task { [weak self] in
            // 先静默刷新；成功则用户无感，后续请求带新 Token
            let refreshed = await APIManager.shared.refreshCredentialIfPossible()
            await MainActor.run {
                guard let self else { return }
                if refreshed {
                    if let access = UserDefaults.standard.string(forKey: "auth_access_token"),
                       let refresh = UserDefaults.standard.string(forKey: "auth_refresh_token") {
                        LoginService.shared.saveToken(access, refreshToken: refresh)
                    }
                    self.lock.lock()
                    self.isHandling = false
                    self.lock.unlock()
                    print("[SessionExpiry] A0230 → refresh_token success, keep session")
                    return
                }
                self.presentForceRelogin(message: displayMessage)
            }
        }
    }

    private func presentForceRelogin(message: String) {
        clearLocalState()
        let finishToLogin = { [weak self] in
            UserDefaults.standard.set(true, forKey: Self.sessionExpiredHintKey)
            Router.shared.setRoot("/login")
            self?.lock.lock()
            self?.isHandling = false
            self?.lock.unlock()
        }
        if let present = presentExpiredUI {
            present(message, finishToLogin)
        } else {
            finishToLogin()
        }
    }

    private func clearLocalState() {
        LoginService.shared.clearSession()
        IMService.shared.clear()
        Task {
            await ServiceHubCacheService.shared.clear()
            await ColumnContentCacheService.shared.clear()
            await HealthPageCacheService.shared.clear()
        }
        InstitutionSelectionStore.shared.clear()
        RongCloudManager.shared.disconnect()
        UserManager.shared.clear()
    }
}
