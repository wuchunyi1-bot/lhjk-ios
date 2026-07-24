import Foundation

// MARK: - 医院套包服务 (BLL / 服务·商城模块)

/// 商城套包 — `GET /v1/hospitalPackage/getEnabledHospitalPackagePage`
///
/// 同一接口，两种入参场景：
/// - **推荐服务**：`packageMainCategory` 必传
/// - **搜索套餐**：`name` 必传（关键字）
/// - 两种场景若有 `hospitalId` 则一并传递
///
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/484150836e0
final class HospitalPackageService {

    static let shared = HospitalPackageService()

    /// 临时医院 id；机构列表 API 接入后改为服务端下发
    /// Apifox 详情接口要求必传 `hospitalId`
    static let temporaryHospitalId = "1372444113118564352"

    private init() {}

    // MARK: - 推荐服务（按类目）

    func fetchRecommendPackages(
        packageMainCategory: Int,
        hospitalId: String? = nil,
        pageNum: Int = 1,
        pageSize: Int = 10
    ) async throws -> PaginatedHospitalPackageData {
        var params: [String: Any] = [
            "packageMainCategory": packageMainCategory,
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
        ]
        if let hospitalId = Self.apiHospitalId(hospitalId) {
            params["hospitalId"] = hospitalId
        } else {
            params["hospitalId"] = Self.temporaryHospitalId
        }

        return try await requestPackages(params: params)
    }

    /// 推荐服务类目 → UI 模型（服务首页首屏第一页）
    func fetchPackageItems(
        category: ServiceRecommendCategory,
        hospitalId: String? = nil,
        pageNum: Int = 1,
        pageSize: Int = 10
    ) async throws -> [HealthPackageItem] {
        guard let packageMainCategory = category.packageMainCategoryInt else {
            throw HospitalPackageServiceError.missingPackageMainCategory
        }

        let page = try await fetchRecommendPackages(
            packageMainCategory: packageMainCategory,
            hospitalId: hospitalId,
            pageNum: pageNum,
            pageSize: pageSize
        )
        return mapPackageItems(page.records)
    }

    // MARK: - 富德优选（零售套包）
    // 零售分页 Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/487882770e0
    // 业务分类 Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/487882771e0

    /// 零售类业务分类 Tab（`type = 2`）
    func fetchRetailCategoryList() async throws -> [CategoryServiceListVO] {
        try await fetchCategoryServiceListByType(type: HospitalPackageCategoryType.retail)
    }

    /// `GET /v1/hospitalPackage/getCategoryServiceListByType`
    func fetchCategoryServiceListByType(
        type: Int,
        hospitalId: String? = nil
    ) async throws -> [CategoryServiceListVO] {
        var params: [String: Any] = ["type": type]
        if type == HospitalPackageCategoryType.hospitalService {
            params["hospitalId"] = Self.resolvedHospitalId(hospitalId)
        } else if let hospitalId = Self.apiHospitalId(hospitalId) {
            params["hospitalId"] = hospitalId
        }

        let response: APIResponse<[CategoryServiceListVO]> = try await APIManager.shared.getAsync(
            path: "/v1/hospitalPackage/getCategoryServiceListByType",
            parameters: params,
            responseType: APIResponse<[CategoryServiceListVO]>.self
        )

        guard response.isSuccess else {
            throw HospitalPackageServiceError.requestFailed(response.msg ?? "获取业务分类失败")
        }

        return response.data ?? []
    }

    // MARK: - 医院服务（选择套餐）

    /// 医院服务业务分类（`type = 1`，须传 `hospitalId`）
    func fetchHospitalServiceCategoryList(hospitalId: String? = nil) async throws -> [CategoryServiceListVO] {
        try await fetchCategoryServiceListByType(
            type: HospitalPackageCategoryType.hospitalService,
            hospitalId: hospitalId
        )
    }

    func fetchHospitalServicePackages(
        categoryServiceId: String,
        hospitalId: String? = nil,
        pageNum: Int = 1,
        pageSize: Int = 10
    ) async throws -> PaginatedHospitalPackageData {
        let hid = Self.resolvedHospitalId(hospitalId)
        let params: [String: Any] = [
            "categoryServiceId": categoryServiceId,
            "hospitalId": hid,
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
        ]
        return try await requestPackages(params: params)
    }

    func fetchHospitalServicePackageItems(
        categoryServiceId: String,
        hospitalId: String? = nil,
        pageNum: Int = 1,
        pageSize: Int = 10
    ) async throws -> [HealthPackageItem] {
        let page = try await fetchHospitalServicePackages(
            categoryServiceId: categoryServiceId,
            hospitalId: hospitalId,
            pageNum: pageNum,
            pageSize: pageSize
        )
        return mapPackageItems(page.records)
    }

    // MARK: - 富德优选（零售套包）

    func fetchRetailPackages(
        categoryServiceId: String = "",
        pageNum: Int = 1,
        pageSize: Int = 10
    ) async throws -> PaginatedHospitalPackageData {
        let params: [String: Any] = [
            "categoryServiceId": categoryServiceId,
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
        ]

        let response: APIResponse<PaginatedHospitalPackageData> = try await APIManager.shared.getAsync(
            path: "/v1/hospitalPackage/getEnabledRetailHospitalPackagePage",
            parameters: params,
            responseType: APIResponse<PaginatedHospitalPackageData>.self
        )

        guard response.isSuccess else {
            throw HospitalPackageServiceError.requestFailed(response.msg ?? "获取零售套包列表失败")
        }

        return response.data ?? PaginatedHospitalPackageData(
            totalRecords: 0,
            pageSize: pageSize,
            totalPages: 0,
            currentPage: pageNum,
            records: []
        )
    }

    func fetchRetailPackageItems(
        categoryServiceId: String = "",
        hospitalId: String? = nil,
        pageNum: Int = 1,
        pageSize: Int = 10
    ) async throws -> [HealthPackageItem] {
        let page = try await fetchRetailPackages(
            categoryServiceId: categoryServiceId,
            pageNum: pageNum,
            pageSize: pageSize
        )
        return mapPackageItems(page.records)
    }

    // MARK: - 搜索套餐（按关键字）

    func searchPackages(
        keyword: String,
        hospitalId: String? = nil,
        pageNum: Int = 1,
        pageSize: Int = 10
    ) async throws -> PaginatedHospitalPackageData {
        guard let name = Self.nonEmpty(keyword) else {
            throw HospitalPackageServiceError.missingSearchKeyword
        }

        var params: [String: Any] = [
            "name": name,
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
        ]
        if let hospitalId = Self.apiHospitalId(hospitalId) {
            params["hospitalId"] = hospitalId
        } else {
            params["hospitalId"] = Self.temporaryHospitalId
        }

        return try await requestPackages(params: params)
    }

    /// 搜索关键字 → UI 模型
    func searchPackageItems(
        keyword: String,
        hospitalId: String? = nil,
        pageNum: Int = 1,
        pageSize: Int = 10
    ) async throws -> [HealthPackageItem] {
        let page = try await searchPackages(
            keyword: keyword,
            hospitalId: hospitalId,
            pageNum: pageNum,
            pageSize: pageSize
        )
        return mapPackageItems(page.records)
    }

    // MARK: - 套餐详情

    /// `GET /v1/hospitalPackage/getHospitalPackageDetail`
    /// - Parameters:
    ///   - packageId: 列表接口返回的商品 id
    ///   - hospitalId: 默认临时常量；机构 API 接入后传入真实值
    func fetchPackageDetail(
        packageId: String,
        hospitalId: String? = nil,
        renewalMode: Bool = false
    ) async throws -> ServicePackageDetail {
        guard let pkgId = Self.apiHospitalId(packageId) else {
            throw HospitalPackageServiceError.invalidPackageId
        }
        let hid = Self.apiHospitalId(hospitalId) ?? Self.temporaryHospitalId
        let response: APIResponse<HospitalPackageDetailBO> = try await APIManager.shared.getAsync(
            path: "/v1/hospitalPackage/getHospitalPackageDetail",
            parameters: [
                "hospitalId": hid,
                "packageId": pkgId,
            ],
            responseType: APIResponse<HospitalPackageDetailBO>.self
        )
        guard response.isSuccess else {
            throw HospitalPackageServiceError.requestFailed(response.msg ?? "获取套餐详情失败")
        }
        guard let data = response.data else {
            throw HospitalPackageServiceError.requestFailed("套餐详情为空")
        }
        return HospitalPackageDetailMapper.toServicePackageDetail(
            data,
            packageId: pkgId,
            renewalMode: renewalMode
        )
    }

    // MARK: - Private

    private func requestPackages(params: [String: Any]) async throws -> PaginatedHospitalPackageData {
        let response: APIResponse<PaginatedHospitalPackageData> = try await APIManager.shared.getAsync(
            path: "/v1/hospitalPackage/getEnabledHospitalPackagePage",
            parameters: params,
            responseType: APIResponse<PaginatedHospitalPackageData>.self
        )

        guard response.isSuccess else {
            throw HospitalPackageServiceError.requestFailed(response.msg ?? "获取套包列表失败")
        }

        return response.data ?? PaginatedHospitalPackageData(
            totalRecords: 0,
            pageSize: (params["pageSize"] as? String).flatMap(Int.init) ?? 10,
            totalPages: 0,
            currentPage: (params["pageNum"] as? String).flatMap(Int.init) ?? 1,
            records: []
        )
    }

    private func mapPackageItems(_ records: [HospitalPackagePageVO]?) -> [HealthPackageItem] {
        (records ?? []).enumerated().map { index, vo in
            HospitalPackageMapper.toPackageItem(vo, index: index)
        }
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    /// 套包 API `hospitalId`：须为后端 `Long` 的纯数字字符串；mock 机构 id 等不传
    static func apiHospitalId(_ value: String?) -> String? {
        ServiceCatalogService.validApiHospitalId(value)
    }

    /// 列表无机构 id 时使用临时 hospitalId，与详情接口保持一致
    static func resolvedHospitalId(_ value: String?) -> String {
        apiHospitalId(value) ?? temporaryHospitalId
    }
}

enum HospitalPackageServiceError: LocalizedError {
    case missingPackageMainCategory
    case missingSearchKeyword
    case invalidPackageId
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingPackageMainCategory: return "缺少 packageMainCategory"
        case .missingSearchKeyword: return "请输入搜索关键字"
        case .invalidPackageId: return "套餐 id 无效"
        case .requestFailed(let message): return message
        }
    }
}
