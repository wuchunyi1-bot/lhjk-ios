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
