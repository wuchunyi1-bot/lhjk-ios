import Foundation

/// 用户信息服务协议
protocol UserServiceProtocol {
    /// 修改当前用户资料（Onboarding / 个人信息编辑）
    /// - Returns: 修改后的完整用户信息
    func updateCurrentProfile(_ payload: SUsersOnboardingPayload) async throws -> SUsers?

    /// 获取当前登录用户基础信息（通过 token 识别，无需传参）
    func getCurrentUserBaseInfo() async throws -> SUsers?

    // MARK: - 密码/手机号管理

    /// 手机号验证码重置密码
    func resetPasswordByMobile(mobile: String, newPwd: String, checkCode: String) async throws

    /// 修改密码（旧密码 + 新密码，可选验证码）
    func changePassword(mobile: String, oldPwd: String?, newPwd: String, checkCode: String?) async throws

    /// 修改用户手机号
    func changeMobile(oldMobile: String?, newMobile: String, checkCode: String?) async throws

    /// 修改当前登录用户密码
    func changeCurrentPassword(oldPwd: String, newPwd: String) async throws
}
