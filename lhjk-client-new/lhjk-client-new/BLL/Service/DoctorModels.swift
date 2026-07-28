import Foundation

// MARK: - 医生分页（业务经理列表）
// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330896e0.md
// operationId: getDoctorPage

/// `GET /v1/doctor/getDoctorPage` → `data` 分页
struct PaginatedDoctorData: Decodable {
    let totalRecords: Int?
    let pageSize: Int?
    let totalPages: Int?
    let currentPage: Int?
    let records: [DoctorVo]?

    enum CodingKeys: String, CodingKey {
        case totalRecords = "totalCount"
        case pageSize
        case totalPages = "totalPage"
        case currentPage = "currPage"
        case records = "list"
        case totalRecordsCN = "总记录数"
        case pageSizeCN = "每页记录数"
        case totalPagesCN = "总页数"
        case currentPageCN = "当前页数"
        case recordsCN = "数据集合"
    }

    init(
        totalRecords: Int? = nil,
        pageSize: Int? = nil,
        totalPages: Int? = nil,
        currentPage: Int? = nil,
        records: [DoctorVo]? = nil
    ) {
        self.totalRecords = totalRecords
        self.pageSize = pageSize
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.records = records
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalRecords = (try? c.decodeIfPresent(Int.self, forKey: .totalRecords))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .totalRecordsCN))
        pageSize = (try? c.decodeIfPresent(Int.self, forKey: .pageSize))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .pageSizeCN))
        totalPages = (try? c.decodeIfPresent(Int.self, forKey: .totalPages))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .totalPagesCN))
        currentPage = (try? c.decodeIfPresent(Int.self, forKey: .currentPage))
            ?? (try? c.decodeIfPresent(Int.self, forKey: .currentPageCN))
        records = (try? c.decodeIfPresent([DoctorVo].self, forKey: .records))
            ?? (try? c.decodeIfPresent([DoctorVo].self, forKey: .recordsCN))
    }
}

/// 分页查询医生信息 — 完善资料「业务经理」候选
struct DoctorVo: Decodable {
    let id: String
    let userId: String?
    let chineseName: String?
    let sex: String?
    /// 账户 / 经理号
    let account: String?
    let mobile: String?
    let imageUrl: String?
    let signing: Int?
    let position: String?
    let roleName: String?
    let hospitalId: String?
    let nickName: String?
    let departmentName: String?
    let hospitalName: String?
    let status: Int?
    let userStatus: Int?

    private enum CodingKeys: String, CodingKey {
        case id, userId, chineseName, sex, account, mobile, imageUrl
        case signing, position, roleName, hospitalId, nickName
        case departmentName, hospitalName, status, userStatus
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = HospitalPackageID.decode(c, key: .id)
        userId = HospitalPackageID.decodeOptional(c, key: .userId)
        chineseName = try c.decodeIfPresent(String.self, forKey: .chineseName)
        sex = try c.decodeIfPresent(String.self, forKey: .sex)
        account = try c.decodeIfPresent(String.self, forKey: .account)
        mobile = try c.decodeIfPresent(String.self, forKey: .mobile)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        signing = HospitalPackageInt.decodeIfPresent(c, key: .signing)
        position = try c.decodeIfPresent(String.self, forKey: .position)
        roleName = try c.decodeIfPresent(String.self, forKey: .roleName)
        hospitalId = HospitalPackageID.decodeOptional(c, key: .hospitalId)
        nickName = try c.decodeIfPresent(String.self, forKey: .nickName)
        departmentName = try c.decodeIfPresent(String.self, forKey: .departmentName)
        hospitalName = try c.decodeIfPresent(String.self, forKey: .hospitalName)
        status = HospitalPackageInt.decodeIfPresent(c, key: .status)
        userStatus = HospitalPackageInt.decodeIfPresent(c, key: .userStatus)
    }

    /// 列表主标题
    var displayName: String {
        let name = chineseName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "业务经理" : name
    }

    /// 经理号（账户）
    var displayCode: String {
        account?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// 职位文案
    var displayTitle: String {
        let p = position?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !p.isEmpty { return p }
        return roleName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// 脱敏手机号
    var maskedMobile: String {
        let raw = mobile?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard raw.count >= 7 else { return raw }
        let prefix = raw.prefix(3)
        let suffix = raw.suffix(4)
        return "\(prefix)****\(suffix)"
    }

    /// 回显「姓名（经理号）」
    var pickerDisplay: String {
        let code = displayCode
        if code.isEmpty { return displayName }
        return "\(displayName)（\(code)）"
    }
}
