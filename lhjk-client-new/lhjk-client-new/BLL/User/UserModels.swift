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

// MARK: - Onboarding 提交模型 (Encodable)

/// Onboarding 完成后提交的用户数据子集
///
/// 对应 `POST /v1/users/updateCurrentProfile` 请求体
/// 所有字段均为 Optional，按需发送非空值
struct SUsersOnboardingPayload: Encodable {
    /// 手机号（当前登录账号）
    var mobile: String?
    /// 中文姓名（对应 `chineseName`）
    var chineseName: String?
    /// 性别："1"=男, "2"=女
    var sex: String?
    /// 生日，"yyyy-MM-dd" 格式
    var birthday: String?
    /// 用户昵称
    var nickname: String?
    /// 省份（籍贯）
    var province: String?
    /// 城市（籍贯）
    var cities: String?
    /// 年龄（自动计算）
    var age: Int?
    /// 既往病史，逗号分隔
    var medicalHistory: String?
    /// 吸烟情况
    var smokingStatus: String?
    /// 运动频率
    var exerciseFrequency: String?
    /// 头像 URL
    var imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case mobile
        case chineseName
        case sex
        case birthday
        case nickname
        case province
        case cities
        case age
        case medicalHistory
        case smokingStatus
        case exerciseFrequency
        case imageUrl
    }
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
