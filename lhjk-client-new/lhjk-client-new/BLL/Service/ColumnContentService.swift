import Foundation

// MARK: - 展示位内容服务 (BLL)

/// 栏位展示内容 — `GET /v1/columnContent/getByCode`
///
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/484052032e0.md
final class ColumnContentService {

    static let shared = ColumnContentService()

    /// 服务首页轮播栏位 code
    static let hospitalBannerCode = "mall_advertisement"

    /// 首页（Home Tab）轮播栏位 code
    static let homeBannerCode = "home_banner_code"

    /// 首页金刚区（快捷入口）栏位 code
    static let homeQuickLinkCode = "home_quickLink_code"

    /// 首页推荐健康套餐栏位 code
    static let homeHealthServiceCode = "home_healthService_code"

    /// 首页健康陪伴（资讯）栏位 code
    static let homeNewsCode = "home_news_code"

    private init() {}

    /// 获取服务首页轮播 Banner
    func fetchHospitalBanners(
        code: String = ColumnContentService.hospitalBannerCode
    ) async throws -> [ServiceHubBanner] {
        try await fetchBanners(code: code)
    }

    /// 获取首页运营 Banner
    func fetchHomeBanners(
        code: String = ColumnContentService.homeBannerCode
    ) async throws -> [ServiceHubBanner] {
        try await fetchBanners(code: code)
    }

    /// 获取首页金刚区栏位（与 Banner 同 DTO / 过滤规则）
    func fetchHomeQuickLinks(
        code: String = ColumnContentService.homeQuickLinkCode
    ) async throws -> [ServiceHubBanner] {
        try await fetchBanners(code: code)
    }

    /// 获取首页推荐健康套餐栏位
    func fetchHomeHealthServices(
        code: String = ColumnContentService.homeHealthServiceCode
    ) async throws -> [ServiceHubBanner] {
        try await fetchBanners(code: code)
    }

    /// 获取首页健康陪伴资讯栏位
    func fetchHomeNews(
        code: String = ColumnContentService.homeNewsCode
    ) async throws -> [ServiceHubBanner] {
        try await fetchBanners(code: code)
    }

    /// 按栏位 code 拉取可展示 Banner
    func fetchBanners(code: String) async throws -> [ServiceHubBanner] {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ColumnContentError.requestFailed("栏位 code 为空")
        }

        print("[ColumnContentService] getByCode → code=\(trimmed)")
        let response: APIResponse<[ColumnContentDTO]> = try await APIManager.shared.getAsync(
            path: "/v1/columnContent/getByCode",
            parameters: ["code": trimmed],
            responseType: APIResponse<[ColumnContentDTO]>.self
        )

        guard response.isSuccess else {
            throw ColumnContentError.requestFailed(response.msg ?? "获取轮播失败")
        }

        let items = response.data ?? []
        let banners = items
            .filter { isDisplayable($0) }
            .map(ColumnContentMapper.toHubBanner)
        print("[ColumnContentService] getByCode ✓ code=\(trimmed) count=\(banners.count)")
        return banners
    }

    /// `GET /v1/content/search`：标题 / 正文 / 标签模糊匹配，仅已上架资讯教程。
    func searchContents(
        keyword: String,
        pageNum: Int = 1,
        pageSize: Int = 10
    ) async throws -> PaginatedContentSearchData {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ColumnContentError.requestFailed("请输入搜索关键字")
        }
        let params: [String: Any] = [
            "keyword": trimmed,
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
        ]
        let response: APIResponse<PaginatedContentSearchData> = try await APIManager.shared.getAsync(
            path: "/v1/content/search",
            parameters: params,
            responseType: APIResponse<PaginatedContentSearchData>.self
        )
        guard response.isSuccess else {
            throw ColumnContentError.requestFailed(response.msg ?? "搜索健康知识失败")
        }
        return response.data ?? PaginatedContentSearchData(
            totalRecords: 0,
            pageSize: pageSize,
            totalPages: 0,
            currentPage: pageNum,
            records: []
        )
    }

    /// `POST /v1/content/share`：点击分享时立刻累计分享次数。Query `contentId`。
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529721042e0.md
    func recordShare(contentId: String) async throws {
        let trimmed = contentId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ColumnContentError.requestFailed("内容 ID 为空")
        }
        print("[ColumnContentService] share → contentId=\(trimmed)")
        let response: APIResponse<EmptyResponse> = try await APIManager.shared.postQueryAsync(
            path: "/v1/content/share",
            parameters: ["contentId": trimmed],
            responseType: APIResponse<EmptyResponse>.self
        )
        guard response.isSuccess else {
            throw ColumnContentError.requestFailed(response.msg ?? "记录分享失败")
        }
        print("[ColumnContentService] share ✓ contentId=\(trimmed)")
    }

    private func isDisplayable(_ dto: ColumnContentDTO) -> Bool {
        guard dto.status == nil || dto.status == 1 else { return false }
        let hasImage = !(dto.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasTitle = !(dto.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        return hasImage || hasTitle
    }
}

enum ColumnContentError: LocalizedError {
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let message): return message
        }
    }
}
