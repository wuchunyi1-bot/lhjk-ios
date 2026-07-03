import Foundation

/// 登录业务接口协议
/// 参考 funde-client PRD 2.7 接口契约（接口名称以真实后端为准，PRD 中为自动生成仅作参考）
protocol LoginServiceProtocol {

    // MARK: - Privacy

    /// 获取最新隐私协议版本
    func getPrivacyVersion() async throws -> PrivacyVersionInfo

    /// 记录用户同意隐私协议
    func agreePrivacy(version: Int) async throws

    // MARK: - SMS

    /// 发送短信验证码
    /// - Parameters:
    ///   - phone: 手机号
    ///   - type: 验证码类型（`.login` / `.changePhone` / `.setPassword` / `.resetPassword`）
    func sendVerificationCode(to phone: String, type: SMSVerificationType) async throws -> SMSResponse

    // MARK: - Login

    /// 验证码登录（新用户自动注册）
    func loginByPhone(_ phone: String, code: String) async throws -> LoginResult

    /// 密码登录
    func loginByPassword(_ phone: String, password: String) async throws -> LoginResult

    // MARK: - WeChat

    /// 微信授权
    func wechatAuth(authCode: String) async throws -> WechatAuthResult

    /// 微信绑定手机号
    func wechatBindPhone(wechatToken: String, phone: String, code: String, confirmRebind: Bool) async throws -> LoginResult

    // MARK: - Password Reset

    /// 重置密码
    func resetPassword(phone: String, code: String, newPassword: String) async throws

    // MARK: - Session

    /// 查询登录态和账号状态
    func getSessionStatus() async throws -> SessionStatus

    /// 记录通知授权结果
    func reportNotificationPermission(status: NotificationPermissionStatus) async throws

    // MARK: - Token Storage

    /// 保存 token 到 Keychain
    func saveToken(_ token: String, refreshToken: String)

    /// 从 Keychain 读取 token
    func getToken() -> String?

    /// 调用服务端退出登录接口（fire-and-forget，不处理结果）
    func logout() async

    /// 清除本地登录态
    func clearSession()
}
