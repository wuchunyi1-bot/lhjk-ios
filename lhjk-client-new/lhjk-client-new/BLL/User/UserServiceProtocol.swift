import Foundation

/// 用户信息服务协议
protocol UserServiceProtocol {
    /// 修改当前用户资料（Onboarding / 个人信息编辑）
    /// - Returns: 修改后的完整用户信息
    func updateCurrentProfile(_ payload: SUsersOnboardingPayload) async throws -> SUsers?

    /// 保存用户档案机构并修改基本信息（完善资料页）
    func saveArchiveHospital(_ dto: SaveArchiveHospitalDTO) async throws

    /// 获取当前登录用户基础信息（通过 token 识别，无需传参）
    func getCurrentUserBaseInfo() async throws -> SUsers?

    /// 我的 Tab 首页概览（会员资产 + 服务履约统计）
    func getUserCenterOverview() async throws -> UserCenterOverviewVO

    /// 通过用户 ID 获取默认档案（优先未生育状态）
    /// - Parameter userId: 用户雪花 ID（字符串形式）
    func getOArchiveByUserId(_ userId: String) async throws -> OArchive?

    /// 手机端修改档案字段（如 `whetherPregnancy`）
    func saveOrUpdateArchiveByMobile(archive: OArchive, whetherPregnancy: Int?) async throws

    /// 计算档案完善进度（0–100）
    /// `GET /v1/archive/calculateArchiveCompletion?userId=`
    func calculateArchiveCompletion(userId: String) async throws -> ArchiveCompletionVO

    // MARK: - 密码/手机号管理

    /// 手机号验证码重置密码
    func resetPasswordByMobile(mobile: String, newPwd: String, checkCode: String) async throws

    /// 修改用户手机号
    func changeMobile(oldMobile: String?, newMobile: String, checkCode: String?) async throws

    /// 修改当前登录用户密码
    func changeCurrentPassword(oldPwd: String, newPwd: String) async throws
}
