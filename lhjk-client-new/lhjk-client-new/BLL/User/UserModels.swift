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

// MARK: - 默认档案（按用户 ID）

/// `GET /v1/archive/getOArchiveByUserId` 响应 `data`
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/486441727e0.md
///
/// 雪花 ID 字段兼容 String / Number；数值字段兼容 Int / Double。
struct OArchive: Codable {
    let id: String?
    let userId: String?
    let chineseName: String?
    /// 性别："1"=男 / "2"=女（完善资料回填；Apifox 分享站可能尚未同步）
    let sex: String?
    /// 出生日期，优先 `yyyy-MM-dd`
    let birthday: String?
    /// 档案资料是否已完善 — `/onboarding` 唯一门禁字段
    let archiveComplete: Bool?
    /// 状态：1 已分娩 / 0 未分娩 / 2 已转院 / 3 分娩终止 / 4 备孕中
    let status: Int?
    let workplace: String?
    let hospitalId: String?
    let businessManagerId: String?
    let hospitalName: String?
    /// 档案号（JSON key: `no`）
    let archiveNo: String?
    /// 建档来源：1 移动端 / 2 Web 后台
    let source: Int?
    let riskLevel: Int?
    let emergencyContact: String?
    let contactMobile: String?
    /// 与本人关系：1 配偶、2 父女、3 母女、4 子女、5 其他
    let relationship: Int?
    let weight: Double?
    let hipCircum: Double?
    let waistCircum: Double?
    let bustCircum: Double?
    let fatContent: Double?
    let armCircum: Double?
    let basalMetabolicRate: Double?
    let height: Int?
    let bmi: Double?
    let reviewId: String?
    let reviewTime: String?
    let familyChildrenNumber: Int?
    let familyMembers: String?
    /// 是否孕期：0 否 / 1 是
    let whetherPregnancy: Int?
    let pastHistory: String?
    let familyGeneticHistory: String?
    let medicationHistory: String?
    let allergenHistory: String?
    let nutrientHistory: String?
    let bloodType: String?
    let maritalBredHistory: String?
    let tastePreferences: String?
    let tabooList: String?
    let ogtt: String?
    let remarks: String?
    let diabetesType: Int?
    let firstVisit: Int?
    let firstVisitRescheduleTime: String?
    let motionFrequency: Int?
    let motionDuration: Int?
    let motionProject: String?
    let sleepStartTime: String?
    let sleepEndTime: String?
    let sleepDuration: Int?
    let sleepQuality: Int?
    let sleepAbnormal: String?
    let createId: String?
    let createTime: String?
    let modifyId: String?
    let modifyTime: String?
    let operatorUserId: String?
    let businessManagerName: String?

    private enum CodingKeys: String, CodingKey {
        case id, userId, chineseName, sex, birthday, archiveComplete
        case status, workplace, hospitalId
        case businessManagerId, hospitalName, source, riskLevel
        case emergencyContact, contactMobile, relationship
        case weight, hipCircum, waistCircum, bustCircum, fatContent
        case armCircum, basalMetabolicRate, height, bmi
        case reviewId, reviewTime, familyChildrenNumber, familyMembers
        case whetherPregnancy, pastHistory, familyGeneticHistory
        case medicationHistory, allergenHistory, nutrientHistory
        case bloodType, maritalBredHistory, tastePreferences, tabooList
        case ogtt, remarks, diabetesType, firstVisit, firstVisitRescheduleTime
        case motionFrequency, motionDuration, motionProject
        case sleepStartTime, sleepEndTime, sleepDuration, sleepQuality, sleepAbnormal
        case createId, createTime, modifyId, modifyTime
        case operatorUserId, businessManagerName
        case archiveNo = "no"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.decodeFlexibleString(c, key: .id)
        userId = Self.decodeFlexibleString(c, key: .userId)
        chineseName = try c.decodeIfPresent(String.self, forKey: .chineseName)
        sex = Self.decodeFlexibleString(c, key: .sex)
        birthday = try c.decodeIfPresent(String.self, forKey: .birthday)
        archiveComplete = Self.decodeFlexibleBool(c, key: .archiveComplete)
        status = Self.decodeFlexibleInt(c, key: .status)
        workplace = try c.decodeIfPresent(String.self, forKey: .workplace)
        hospitalId = Self.decodeFlexibleString(c, key: .hospitalId)
        businessManagerId = Self.decodeFlexibleString(c, key: .businessManagerId)
        hospitalName = try c.decodeIfPresent(String.self, forKey: .hospitalName)
        archiveNo = try c.decodeIfPresent(String.self, forKey: .archiveNo)
        source = Self.decodeFlexibleInt(c, key: .source)
        riskLevel = Self.decodeFlexibleInt(c, key: .riskLevel)
        emergencyContact = try c.decodeIfPresent(String.self, forKey: .emergencyContact)
        contactMobile = try c.decodeIfPresent(String.self, forKey: .contactMobile)
        relationship = Self.decodeFlexibleInt(c, key: .relationship)
        weight = Self.decodeFlexibleDouble(c, key: .weight)
        hipCircum = Self.decodeFlexibleDouble(c, key: .hipCircum)
        waistCircum = Self.decodeFlexibleDouble(c, key: .waistCircum)
        bustCircum = Self.decodeFlexibleDouble(c, key: .bustCircum)
        fatContent = Self.decodeFlexibleDouble(c, key: .fatContent)
        armCircum = Self.decodeFlexibleDouble(c, key: .armCircum)
        basalMetabolicRate = Self.decodeFlexibleDouble(c, key: .basalMetabolicRate)
        height = Self.decodeFlexibleInt(c, key: .height)
        bmi = Self.decodeFlexibleDouble(c, key: .bmi)
        reviewId = Self.decodeFlexibleString(c, key: .reviewId)
        reviewTime = try c.decodeIfPresent(String.self, forKey: .reviewTime)
        familyChildrenNumber = Self.decodeFlexibleInt(c, key: .familyChildrenNumber)
        familyMembers = try c.decodeIfPresent(String.self, forKey: .familyMembers)
        whetherPregnancy = Self.decodeFlexibleInt(c, key: .whetherPregnancy)
        pastHistory = try c.decodeIfPresent(String.self, forKey: .pastHistory)
        familyGeneticHistory = try c.decodeIfPresent(String.self, forKey: .familyGeneticHistory)
        medicationHistory = try c.decodeIfPresent(String.self, forKey: .medicationHistory)
        allergenHistory = try c.decodeIfPresent(String.self, forKey: .allergenHistory)
        nutrientHistory = try c.decodeIfPresent(String.self, forKey: .nutrientHistory)
        bloodType = try c.decodeIfPresent(String.self, forKey: .bloodType)
        maritalBredHistory = try c.decodeIfPresent(String.self, forKey: .maritalBredHistory)
        tastePreferences = try c.decodeIfPresent(String.self, forKey: .tastePreferences)
        tabooList = try c.decodeIfPresent(String.self, forKey: .tabooList)
        ogtt = try c.decodeIfPresent(String.self, forKey: .ogtt)
        remarks = try c.decodeIfPresent(String.self, forKey: .remarks)
        diabetesType = Self.decodeFlexibleInt(c, key: .diabetesType)
        firstVisit = Self.decodeFlexibleInt(c, key: .firstVisit)
        firstVisitRescheduleTime = try c.decodeIfPresent(String.self, forKey: .firstVisitRescheduleTime)
        motionFrequency = Self.decodeFlexibleInt(c, key: .motionFrequency)
        motionDuration = Self.decodeFlexibleInt(c, key: .motionDuration)
        motionProject = try c.decodeIfPresent(String.self, forKey: .motionProject)
        sleepStartTime = try c.decodeIfPresent(String.self, forKey: .sleepStartTime)
        sleepEndTime = try c.decodeIfPresent(String.self, forKey: .sleepEndTime)
        sleepDuration = Self.decodeFlexibleInt(c, key: .sleepDuration)
        sleepQuality = Self.decodeFlexibleInt(c, key: .sleepQuality)
        sleepAbnormal = try c.decodeIfPresent(String.self, forKey: .sleepAbnormal)
        createId = Self.decodeFlexibleString(c, key: .createId)
        createTime = try c.decodeIfPresent(String.self, forKey: .createTime)
        modifyId = Self.decodeFlexibleString(c, key: .modifyId)
        modifyTime = try c.decodeIfPresent(String.self, forKey: .modifyTime)
        operatorUserId = Self.decodeFlexibleString(c, key: .operatorUserId)
        businessManagerName = try c.decodeIfPresent(String.self, forKey: .businessManagerName)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(userId, forKey: .userId)
        try c.encodeIfPresent(chineseName, forKey: .chineseName)
        try c.encodeIfPresent(sex, forKey: .sex)
        try c.encodeIfPresent(birthday, forKey: .birthday)
        try c.encodeIfPresent(archiveComplete, forKey: .archiveComplete)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(workplace, forKey: .workplace)
        try c.encodeIfPresent(hospitalId, forKey: .hospitalId)
        try c.encodeIfPresent(businessManagerId, forKey: .businessManagerId)
        try c.encodeIfPresent(hospitalName, forKey: .hospitalName)
        try c.encodeIfPresent(archiveNo, forKey: .archiveNo)
        try c.encodeIfPresent(source, forKey: .source)
        try c.encodeIfPresent(riskLevel, forKey: .riskLevel)
        try c.encodeIfPresent(emergencyContact, forKey: .emergencyContact)
        try c.encodeIfPresent(contactMobile, forKey: .contactMobile)
        try c.encodeIfPresent(relationship, forKey: .relationship)
        try c.encodeIfPresent(weight, forKey: .weight)
        try c.encodeIfPresent(hipCircum, forKey: .hipCircum)
        try c.encodeIfPresent(waistCircum, forKey: .waistCircum)
        try c.encodeIfPresent(bustCircum, forKey: .bustCircum)
        try c.encodeIfPresent(fatContent, forKey: .fatContent)
        try c.encodeIfPresent(armCircum, forKey: .armCircum)
        try c.encodeIfPresent(basalMetabolicRate, forKey: .basalMetabolicRate)
        try c.encodeIfPresent(height, forKey: .height)
        try c.encodeIfPresent(bmi, forKey: .bmi)
        try c.encodeIfPresent(reviewId, forKey: .reviewId)
        try c.encodeIfPresent(reviewTime, forKey: .reviewTime)
        try c.encodeIfPresent(familyChildrenNumber, forKey: .familyChildrenNumber)
        try c.encodeIfPresent(familyMembers, forKey: .familyMembers)
        try c.encodeIfPresent(whetherPregnancy, forKey: .whetherPregnancy)
        try c.encodeIfPresent(pastHistory, forKey: .pastHistory)
        try c.encodeIfPresent(familyGeneticHistory, forKey: .familyGeneticHistory)
        try c.encodeIfPresent(medicationHistory, forKey: .medicationHistory)
        try c.encodeIfPresent(allergenHistory, forKey: .allergenHistory)
        try c.encodeIfPresent(nutrientHistory, forKey: .nutrientHistory)
        try c.encodeIfPresent(bloodType, forKey: .bloodType)
        try c.encodeIfPresent(maritalBredHistory, forKey: .maritalBredHistory)
        try c.encodeIfPresent(tastePreferences, forKey: .tastePreferences)
        try c.encodeIfPresent(tabooList, forKey: .tabooList)
        try c.encodeIfPresent(ogtt, forKey: .ogtt)
        try c.encodeIfPresent(remarks, forKey: .remarks)
        try c.encodeIfPresent(diabetesType, forKey: .diabetesType)
        try c.encodeIfPresent(firstVisit, forKey: .firstVisit)
        try c.encodeIfPresent(firstVisitRescheduleTime, forKey: .firstVisitRescheduleTime)
        try c.encodeIfPresent(motionFrequency, forKey: .motionFrequency)
        try c.encodeIfPresent(motionDuration, forKey: .motionDuration)
        try c.encodeIfPresent(motionProject, forKey: .motionProject)
        try c.encodeIfPresent(sleepStartTime, forKey: .sleepStartTime)
        try c.encodeIfPresent(sleepEndTime, forKey: .sleepEndTime)
        try c.encodeIfPresent(sleepDuration, forKey: .sleepDuration)
        try c.encodeIfPresent(sleepQuality, forKey: .sleepQuality)
        try c.encodeIfPresent(sleepAbnormal, forKey: .sleepAbnormal)
        try c.encodeIfPresent(createId, forKey: .createId)
        try c.encodeIfPresent(createTime, forKey: .createTime)
        try c.encodeIfPresent(modifyId, forKey: .modifyId)
        try c.encodeIfPresent(modifyTime, forKey: .modifyTime)
        try c.encodeIfPresent(operatorUserId, forKey: .operatorUserId)
        try c.encodeIfPresent(businessManagerName, forKey: .businessManagerName)
    }

    private static func decodeFlexibleString<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> String? {
        if let s = try? container.decodeIfPresent(String.self, forKey: key) { return s }
        if let i = try? container.decodeIfPresent(Int64.self, forKey: key) { return String(i) }
        if let i = try? container.decodeIfPresent(Int.self, forKey: key) { return String(i) }
        return nil
    }

    private static func decodeFlexibleInt<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> Int? {
        if let i = try? container.decodeIfPresent(Int.self, forKey: key) { return i }
        if let i = try? container.decodeIfPresent(Int64.self, forKey: key) { return Int(i) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key), let i = Int(s) { return i }
        if let d = try? container.decodeIfPresent(Double.self, forKey: key) { return Int(d) }
        return nil
    }

    private static func decodeFlexibleBool<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> Bool? {
        if let b = try? container.decodeIfPresent(Bool.self, forKey: key) { return b }
        if let i = try? container.decodeIfPresent(Int.self, forKey: key) { return i != 0 }
        if let i = try? container.decodeIfPresent(Int64.self, forKey: key) { return i != 0 }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) {
            switch s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "1", "yes": return true
            case "false", "0", "no": return false
            default: return nil
            }
        }
        return nil
    }

    private static func decodeFlexibleDouble<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> Double? {
        if let d = try? container.decodeIfPresent(Double.self, forKey: key) { return d }
        if let i = try? container.decodeIfPresent(Int.self, forKey: key) { return Double(i) }
        if let i = try? container.decodeIfPresent(Int64.self, forKey: key) { return Double(i) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key), let d = Double(s) { return d }
        return nil
    }
}

// MARK: - 档案机构 + 基本信息（完善资料提交）

/// `POST /v1/archive/saveArchiveHospital`
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/491046480e0.md
struct SaveArchiveHospitalDTO {
    let chineseName: String
    /// 性别："1"=男, "2"=女
    let sex: String
    /// 出生日期，优先 `yyyy-MM-dd`
    let birthday: String
    let hospitalId: Int64
    /// 业务经理（医生 id），选填
    let businessManagerId: Int64?
}

// MARK: - 个人中心概览

/// `GET /v1/users/getUserCenterOverview` 响应 `data`
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/503199941e0.md
struct UserCenterOverviewVO: Decodable, Equatable {
    /// 会员等级（字典值）
    let gradeName: Int?
    /// 健康积分
    let accountPoint: Int?
    /// 富德币
    let fundeCoin: Int?
    /// 使用中权益卡数量
    let availableBenefitsCount: Int64?
    /// 待支付订单数量
    let pendingPaymentOrderCount: Int?
    /// 待收货订单数量
    let pendingReceiptOrderCount: Int?
    /// 使用中订单数量
    let inUseOrderCount: Int?
    /// 已完成订单数量
    let completedOrderCount: Int?

    var memberLevelText: String {
        guard let gradeName else { return "0" }
        return "V\(gradeName)"
    }

    var healthPointsText: String { Self.countText(accountPoint) }
    var fundeCoinText: String { Self.countText(fundeCoin) }
    var benefitsCountText: String { Self.countText(availableBenefitsCount) }

    var pendingPaymentText: String { Self.countText(pendingPaymentOrderCount) }
    var pendingReceiptText: String { Self.countText(pendingReceiptOrderCount) }
    var inUseOrderText: String { Self.countText(inUseOrderCount) }
    var completedOrderText: String { Self.countText(completedOrderCount) }

    private static func countText(_ value: Int?) -> String {
        countText(value.map(Int64.init))
    }

    private static func countText(_ value: Int64?) -> String {
        let n = max(0, Int(value ?? 0))
        if n >= 10_000 {
            return compactWanText(n)
        }
        if n > 99 { return "99+" }
        return "\(n)"
    }

    /// ≥ 10000 时按「万」缩写，如 10000 → `1w`、15000 → `1.5w`
    private static func compactWanText(_ value: Int) -> String {
        let wan = Double(value) / 10_000.0
        let roundedTenth = (wan * 10).rounded() / 10
        if abs(roundedTenth - roundedTenth.rounded()) < 0.001 {
            return "\(Int(roundedTenth))w"
        }
        return String(format: "%.1fw", roundedTenth)
    }

    private enum CodingKeys: String, CodingKey {
        case gradeName, accountPoint, fundeCoin, availableBenefitsCount
        case pendingPaymentOrderCount, pendingReceiptOrderCount
        case inUseOrderCount, completedOrderCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        gradeName = Self.decodeInt(c, .gradeName)
        accountPoint = Self.decodeInt(c, .accountPoint)
        fundeCoin = Self.decodeInt(c, .fundeCoin)
        availableBenefitsCount = Self.decodeInt64(c, .availableBenefitsCount)
        pendingPaymentOrderCount = Self.decodeInt(c, .pendingPaymentOrderCount)
        pendingReceiptOrderCount = Self.decodeInt(c, .pendingReceiptOrderCount)
        inUseOrderCount = Self.decodeInt(c, .inUseOrderCount)
        completedOrderCount = Self.decodeInt(c, .completedOrderCount)
    }

    private static func decodeInt(
        _ c: KeyedDecodingContainer<CodingKeys>,
        _ key: CodingKeys
    ) -> Int? {
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return v }
        if let v = try? c.decodeIfPresent(Int64.self, forKey: key) { return Int(v) }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            return Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private static func decodeInt64(
        _ c: KeyedDecodingContainer<CodingKeys>,
        _ key: CodingKeys
    ) -> Int64? {
        if let v = try? c.decodeIfPresent(Int64.self, forKey: key) { return v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return Int64(v) }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            return Int64(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

// MARK: - 档案完善进度

/// `GET /v1/archive/calculateArchiveCompletion` 响应 data
struct ArchiveCompletionVO: Decodable {
    /// 完成度百分比（0–100）
    let completionPercentage: Int?
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

// MARK: - 微信绑定状态

/// 微信账号绑定状态
/// `GET /v1/users/getWechatBindStatus` 响应 `data`
struct WechatBindStatusVO: Codable, Equatable {
    let bound: Bool?
}
