import Foundation

// MARK: - 系统用户模型 (Codable)

/// 系统用户完整信息，对应后端 `SUsers` / `SUsersVO` schema
///
/// 所有字段均为 Optional，支持部分保存和部分查询
/// snake_case JSON key 由 `APIManager.jsonDecoder` 自动转换（keyDecodingStrategy = .convertFromSnakeCase）
struct SUsers: Codable {
    // MARK: 核心标识
    let id: String?
    let account: String?
    let mobile: String?

    // MARK: 姓名
    let surname: String?
    let chineseName: String?
    let nickname: String?

    // MARK: 联系方式
    let email: String?
    let qqNumber: String?
    let wechat: String?
    let weibo: String?

    // MARK: 个人基础信息
    let sex: String?
    let birthday: String?
    let age: Int?
    let nationality: String?
    let ethnic: String?
    let blood: String?
    let education: String?
    let career: String?

    // MARK: 证件
    let idType: Int?
    let idNumber: String?
    let identityCardsImage: String?

    // MARK: 地址
    let province: String?
    let cities: String?
    let address: String?
    let addressProvince: String?
    let addressCity: String?
    let addressArea: String?
    let addressStreet: String?

    // MARK: 户籍
    let householdProvince: String?
    let householdCity: String?

    // MARK: 车辆
    let carNo: String?

    // MARK: 头像
    let imageUrl: String?

    // MARK: 登录与注册
    let pwd: String?
    let lastDate: String?
    let registerTime: String?
    let registerType: Int?
    let registerCode: String?
    let loginType: String?

    // MARK: 账号状态
    let status: Int?
    let gradeName: Int?

    // MARK: 用户类型与角色
    let userType: Int?
    let userTypes: String?
    let userTypeAndDictionary: String?
    let roleId: String?
    let roleIds: [String]?
    let roleNames: String?
    let organName: String?

    // MARK: UI 偏好
    let layout: Int?
    let autoMenu: Bool?
    let oneLevelMenu: Bool?
    let skin: String?

    // MARK: 第三方平台 OpenID
    let openIdQq: String?
    let openIdWechat: String?
    let openIdWeibo: String?
    let miniappOpenid: String?
    let unionId: String?
    let enterpriseUserId: String?

    // MARK: 虚拟币与积分
    let angelCoin: Int?
    let angelCoinEarned: Int?
    let accountPoint: Int?
    let accountPointEarned: Int?

    // MARK: 推送设置
    let openPush: Bool?

    // MARK: 渠道
    let channelUtm: String?

    // MARK: 修改审计
    let modifyTime: String?
    let modifyId: String?
}

// MARK: - Onboarding / 资料提交模型 (Encodable)

/// 提交用户资料子集 — `POST /v1/users/updateCurrentProfile`
///
/// 所有字段均为 Optional（默认 nil），按需发送非空值
struct SUsersOnboardingPayload: Encodable {
    var mobile: String? = nil
    var chineseName: String? = nil
    /// 性别："1"=男, "2"=女
    var sex: String? = nil
    var birthday: String? = nil
    var nickname: String? = nil
    var email: String? = nil
    /// 职业（对应 `career`）
    var career: String? = nil
    var education: String? = nil
    var idType: Int? = nil
    var idNumber: String? = nil
    var nationality: String? = nil
    var ethnic: String? = nil
    /// 籍贯省
    var province: String? = nil
    /// 籍贯市
    var cities: String? = nil
    var addressProvince: String? = nil
    var addressCity: String? = nil
    var addressArea: String? = nil
    var address: String? = nil
    var age: Int? = nil
    var medicalHistory: String? = nil
    var smokingStatus: String? = nil
    var exerciseFrequency: String? = nil
    var imageUrl: String? = nil
}

// MARK: - 密码重置 & 修改 DTO

/// 手机号验证码重置密码请求体
/// `POST /v1/users/resetPasswordByMobile`
struct ResetPasswordByMobileDTO: Encodable {
    let mobile: String
    let newPwd: String
    let checkCode: String
}

/// 修改当前用户密码请求体
/// `POST /v1/users/changeCurrentPassword`
struct ChangeCurrentPasswordDTO: Encodable {
    let oldPwd: String
    let newPwd: String
}
