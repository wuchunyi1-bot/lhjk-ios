import Foundation

// MARK: - 医院搜索 DTO
// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/488248475e0

/// `GET /v1/hospital/searchPage` → `data` 分页
struct PaginatedHospitalSearchData: Decodable {
    let totalRecords: Int?
    let pageSize: Int?
    let totalPages: Int?
    let currentPage: Int?
    let records: [HospitalSearchVO]?

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
        records: [HospitalSearchVO]? = nil
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
        records = (try? c.decodeIfPresent([HospitalSearchVO].self, forKey: .records))
            ?? (try? c.decodeIfPresent([HospitalSearchVO].self, forKey: .recordsCN))
    }
}

/// App 端医院搜索信息
struct HospitalSearchVO: Decodable {
    let id: String
    let name: String?
    /// 1 医院 / 2 社康 / 3 平台
    let hospitalType: Int?
    let fullAddress: String?
    /// 文档写高德，实际腾讯坐标系
    let longitude: String?
    let latitude: String?
    let distanceMeters: Int64?

    private enum CodingKeys: String, CodingKey {
        case id, name, hospitalType, fullAddress, longitude, latitude, distanceMeters
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = HospitalPackageID.decode(c, key: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        hospitalType = Self.decodeFlexibleInt(c, key: .hospitalType)
        fullAddress = try c.decodeIfPresent(String.self, forKey: .fullAddress)
        longitude = try c.decodeIfPresent(String.self, forKey: .longitude)
        latitude = try c.decodeIfPresent(String.self, forKey: .latitude)
        if let v = try? c.decodeIfPresent(Int64.self, forKey: .distanceMeters) {
            distanceMeters = v
        } else if let i = try? c.decodeIfPresent(Int.self, forKey: .distanceMeters) {
            distanceMeters = Int64(i)
        } else if let s = try? c.decodeIfPresent(String.self, forKey: .distanceMeters) {
            distanceMeters = Int64(s)
        } else {
            distanceMeters = nil
        }
    }

    private static func decodeFlexibleInt<K: CodingKey>(
        _ container: KeyedDecodingContainer<K>,
        key: K
    ) -> Int? {
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) { return value }
        if let value = try? container.decodeIfPresent(Int64.self, forKey: key) { return Int(value) }
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            return Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

enum HospitalTypeLabel {
    static func display(for type: Int?) -> String {
        switch type {
        case 1: return "医院"
        case 2: return "社康"
        case 3: return "平台"
        default: return "机构"
        }
    }
}

// MARK: - 选中机构（服务模块持久化）

struct SelectedServiceInstitution: Codable, Equatable {
    let id: String
    let name: String
    let typeLabel: String
    let fullAddress: String

    init(id: String, name: String, typeLabel: String, fullAddress: String) {
        self.id = id
        self.name = name
        self.typeLabel = typeLabel
        self.fullAddress = fullAddress
    }

    init(vo: HospitalSearchVO) {
        id = vo.id
        name = vo.name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "服务机构"
        typeLabel = HospitalTypeLabel.display(for: vo.hospitalType)
        fullAddress = vo.fullAddress?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? ""
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
