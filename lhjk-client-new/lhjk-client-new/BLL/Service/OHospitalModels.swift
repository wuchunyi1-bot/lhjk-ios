import Foundation

// MARK: - 医院详情 DTO
// Apifox: GET /v1/hospital/getById
// https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330908e0.md

/// 医院实体 `OHospital`（确认订单自提地址用）
struct OHospital: Decodable {
    let id: String?
    let name: String?
    let province: String?
    let city: String?
    let area: String?
    let address: String?
    let mobile: String?
    let dutyPhone: String?
    let hospitalType: Int?
    let status: Int?

    private enum CodingKeys: String, CodingKey {
        case id, name, province, city, area, address
        case mobile, dutyPhone, hospitalType, status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = HospitalPackageID.decodeOptional(c, key: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        province = try c.decodeIfPresent(String.self, forKey: .province)
        city = try c.decodeIfPresent(String.self, forKey: .city)
        area = try c.decodeIfPresent(String.self, forKey: .area)
        address = try c.decodeIfPresent(String.self, forKey: .address)
        mobile = try c.decodeIfPresent(String.self, forKey: .mobile)
        dutyPhone = try c.decodeIfPresent(String.self, forKey: .dutyPhone)
        hospitalType = HospitalPackageInt.decodeIfPresent(c, key: .hospitalType)
        status = HospitalPackageInt.decodeIfPresent(c, key: .status)
    }

    /// 省市区 + 详细地址
    var fullAddress: String {
        [province, city, area, address]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined()
    }

    /// 联系电话：优先公开电话，其次值班电话
    var contactPhone: String? {
        let primary = mobile?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !primary.isEmpty { return primary }
        let duty = dutyPhone?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return duty.isEmpty ? nil : duty
    }
}
