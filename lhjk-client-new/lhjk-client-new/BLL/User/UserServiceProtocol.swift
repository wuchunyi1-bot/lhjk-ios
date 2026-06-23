import Foundation

/// 用户信息服务协议
protocol UserServiceProtocol {
    /// 保存/修改用户信息
    func saveUser(_ payload: SUsersOnboardingPayload) async throws

    /// 根据手机号查询用户详细信息
    func getUserByParam(mobile: String) async throws -> SUsers?

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
