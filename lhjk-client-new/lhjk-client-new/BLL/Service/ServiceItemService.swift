import Foundation

/// 服务项目详情。权益列表改走新接口，不再请求 `medicalConfigList`。
///
/// - 详情：`GET /v1/serviceItem/detail`
///
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/530062591e0
final class ServiceItemService {

    static let shared = ServiceItemService()

    /// 预约体检
    static let examBusinessType = 2
    /// 就医协助
    static let assistBusinessType = 3

    private init() {}

    func detail(configId: String) async throws -> ServiceItemDetailVO {
        let response: APIResponse<ServiceItemDetailVO> = try await APIManager.shared.getAsync(
            path: "/v1/serviceItem/detail",
            parameters: ["configId": configId],
            responseType: APIResponse<ServiceItemDetailVO>.self
        )
        guard response.isSuccess, let detail = response.data, detail.hasContent else {
            throw ServiceItemServiceError.requestFailed(response.msg ?? "未找到该项目")
        }
        return detail
    }
}

enum ServiceItemServiceError: LocalizedError {
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let message): return message
        }
    }
}

struct PaginatedServiceItemData: Decodable {
    let totalRecords: Int?
    let pageSize: Int?
    let totalPages: Int?
    let currentPage: Int?
    let records: [ServiceItemVO]?

    static func empty(pageNum: Int, pageSize: Int) -> PaginatedServiceItemData {
        PaginatedServiceItemData(
            totalRecords: 0,
            pageSize: pageSize,
            totalPages: 0,
            currentPage: pageNum,
            records: []
        )
    }

    init(
        totalRecords: Int?,
        pageSize: Int?,
        totalPages: Int?,
        currentPage: Int?,
        records: [ServiceItemVO]?
    ) {
        self.totalRecords = totalRecords
        self.pageSize = pageSize
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.records = records
    }

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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalRecords = Self.int(c, .totalRecords) ?? Self.int(c, .totalRecordsCN)
        pageSize = Self.int(c, .pageSize) ?? Self.int(c, .pageSizeCN)
        totalPages = Self.int(c, .totalPages) ?? Self.int(c, .totalPagesCN)
        currentPage = Self.int(c, .currentPage) ?? Self.int(c, .currentPageCN)
        records = (try? c.decodeIfPresent([ServiceItemVO].self, forKey: .records))
            ?? (try? c.decodeIfPresent([ServiceItemVO].self, forKey: .recordsCN))
    }

    private static func int(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Int? {
        CabinJSON.int(c, key)
    }
}

struct ServiceItemVO: Decodable, Equatable {
    /// 项目配置 id，详情和预约入口用
    let id: String
    let hospitalId: String
    let name: String
    let price: Double?
    let projectId: String
    let navigateUrl: String?
    let descriptionHTML: String?
    let imgUrls: String?
    let payType: Int?
    let packageId: String?
    let duration: Int?
    let notice: String?
    let unitName: String?
    let categoryName: String?

    var priceText: String? {
        guard let plainPrice else { return nil }
        return "¥\(plainPrice)"
    }

    var plainPrice: String? {
        guard let price else { return nil }
        return Self.formatPrice(price)
    }

    /// 列表封面优先导航图，没有再用介绍图第一张。
    var coverURL: URL? {
        if let navigateUrl, let url = URL(string: navigateUrl) { return url }
        return CabinMedia.urls(from: imgUrls).first
    }

    /// 列表简介。去掉 HTML 标签后的纯文本。
    var introText: String? {
        Self.plainText(descriptionHTML)
    }

    var needsPurchase: Bool { payType == 2 }

    private enum CodingKeys: String, CodingKey {
        case id, hospitalId, name, price, projectId, navigateUrl
        case description, imgUrls, payType, packageId, duration, notice, unitName, categoryName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = CabinJSON.string(c, .id) ?? ""
        hospitalId = CabinJSON.string(c, .hospitalId) ?? ""
        name = CabinJSON.string(c, .name) ?? ""
        price = CabinJSON.double(c, .price)
        projectId = CabinJSON.string(c, .projectId) ?? ""
        navigateUrl = CabinJSON.string(c, .navigateUrl)
        descriptionHTML = CabinJSON.string(c, .description)
        imgUrls = CabinJSON.string(c, .imgUrls)
        payType = CabinJSON.int(c, .payType)
        packageId = CabinJSON.string(c, .packageId)
        duration = CabinJSON.int(c, .duration)
        notice = CabinJSON.string(c, .notice)
        unitName = CabinJSON.string(c, .unitName)
        categoryName = CabinJSON.string(c, .categoryName)
    }

    private static func plainText(_ html: String?) -> String? {
        guard var text = html else { return nil }
        text = text.replacingOccurrences(
            of: "<br\\s*/?>",
            with: " ",
            options: .regularExpression
        )
        text = text.replacingOccurrences(of: "</p>", with: " ", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}

struct ServiceItemDetailVO: Decodable, Equatable {
    let id: String
    let projectId: String
    let name: String
    /// 1 免费直接预约，2 需购买后预约
    let payType: Int?
    let applicablePeople: String?
    let restrictedPeople: String?
    let descriptionText: String?
    let notice: String?
    let duration: Int?
    let packageId: String?
    let hospitalId: String
    let confirmMode: Int?
    private let imgUrls: String?

    var hasContent: Bool { !id.isEmpty || !name.isEmpty }
    var galleryURLs: [URL] { CabinMedia.urls(from: imgUrls) }
    var needsPurchase: Bool { payType == 2 }

    var durationText: String? {
        guard let duration, duration > 0 else { return nil }
        return "\(duration) 分钟"
    }

    var noticeLines: [String] {
        guard let notice else { return [] }
        let lines = notice
            .components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return lines.isEmpty ? [notice] : lines
    }

    private enum CodingKeys: String, CodingKey {
        case id, projectId, name, payType, applicablePeople, restrictedPeople
        case description, notice, duration, packageId, hospitalId, confirmMode, imgUrls
        case bookDaysAhead, cancelLimitHours
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = CabinJSON.string(c, .id) ?? ""
        projectId = CabinJSON.string(c, .projectId) ?? ""
        name = CabinJSON.string(c, .name) ?? ""
        payType = CabinJSON.int(c, .payType)
        applicablePeople = CabinJSON.string(c, .applicablePeople)
        restrictedPeople = CabinJSON.string(c, .restrictedPeople)
        descriptionText = CabinJSON.string(c, .description)
        notice = CabinJSON.string(c, .notice)
        duration = CabinJSON.int(c, .duration)
        packageId = CabinJSON.string(c, .packageId)
        hospitalId = CabinJSON.string(c, .hospitalId) ?? ""
        confirmMode = CabinJSON.int(c, .confirmMode)
        imgUrls = CabinJSON.string(c, .imgUrls)
        _ = CabinJSON.int(c, .bookDaysAhead)
        _ = CabinJSON.int(c, .cancelLimitHours)
    }
}
