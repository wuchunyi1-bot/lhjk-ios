import Foundation

// MARK: - 字典父节点

/// App 需要接入的 `getDictionaryByParentId2` parentId 清单
enum DictionaryParent: Int64, CaseIterable {
    /// 商品套餐系列（德系 9 宫格）
    case packageSeries = 2_074_711_686_115_364_864
    /// 商品套餐标识（热销 / 推荐 / 新品）
    case packageBadge = 1_367_317_966_584_156_160
    /// 商品套餐大类（推荐服务 / 健康管理类目）
    case packageCategory = 2_074_711_807_339_139_072
    /// 证件类型
    case idType = 1_352_495_764_366_036_992
    /// 职业类别
    case occupation = 1_352_496_033_388_695_552
    /// 国籍
    case nationality = 1_352_496_236_401_397_760
    /// 文化程度
    case education = 1_352_496_553_893_433_344
    /// 民族类别
    case ethnicity = 1_352_496_472_867_868_672
    /// 糖尿病类型
    case diabetesType = 1_422_846_879_313_563_648
    /// 血糖记录时段
    case glucosePeriod = 1_392_401_386_955_739_136
    /// 监测类型
    case monitorType = 1_677_144_428_066_570_242
    /// 菜谱餐别
    case mealType = 1_386_610_825_011_269_632
    /// 物流名称
    case logistics = 2_081_633_973_934_624_768
    /// 支付方式
    case paymentMethod = 1_372_103_230_904_995_840
    /// 商品套餐单位
    case packageUnit = 1_368_753_516_243_456_000
    /// 风险等级
    case riskLevel = 1_405_690_692_059_140_096

    var rawValueString: String {
        String(rawValue)
    }

    var title: String {
        switch self {
        case .packageSeries: return "商品套餐系列"
        case .packageBadge: return "商品套餐标识字段"
        case .packageCategory: return "商品套餐大类"
        case .idType: return "证件类型"
        case .occupation: return "职业类别"
        case .nationality: return "国籍"
        case .education: return "文化程度"
        case .ethnicity: return "民族类别"
        case .diabetesType: return "糖尿病类型"
        case .glucosePeriod: return "血糖记录时段"
        case .monitorType: return "监测类型"
        case .mealType: return "菜谱餐别"
        case .logistics: return "物流名称"
        case .paymentMethod: return "支付方式"
        case .packageUnit: return "商品套餐单位"
        case .riskLevel: return "风险等级"
        }
    }
}

// MARK: - 字典服务 (BLL)

/// 数据字典 — `POST /v1/dictionary/getDictionaryByParentId2`
///
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/472330853e0
final class DictionaryService {

    static let shared = DictionaryService()

    /// 德系 9 大产品线父级字典 ID
    static let productLineParentId: Int64 = DictionaryParent.packageSeries.rawValue

    /// 服务首页「推荐服务」/ 套餐列表健康管理类目父级字典 ID
    static let serviceRecommendCategoryParentId: Int64 = DictionaryParent.packageCategory.rawValue

    private init() {}

    /// 原始字典节点（含父节点与 children）
    func fetchNodes(
        parentId: Int64,
        allStatus: Bool = true
    ) async throws -> [SDictionary] {
        try await fetchNodes(parentIds: [parentId], allStatus: allStatus)
    }

    func fetchNodes(
        parent: DictionaryParent,
        allStatus: Bool = true
    ) async throws -> [SDictionary] {
        try await fetchNodes(parentId: parent.rawValue, allStatus: allStatus)
    }

    /// 一次拉取多个父节点
    func fetchNodes(
        parentIds: [Int64],
        allStatus: Bool = true
    ) async throws -> [SDictionary] {
        let ids = parentIds.filter { $0 != 0 }
        guard !ids.isEmpty else { return [] }

        let response: APIResponse<[SDictionary]> = try await APIManager.shared.postAsync(
            path: "/v1/dictionary/getDictionaryByParentId2",
            parameters: [
                "parentIds": ids,
                "allStatus": allStatus,
            ],
            responseType: APIResponse<[SDictionary]>.self
        )

        guard response.isSuccess else {
            throw DictionaryServiceError.requestFailed(response.msg ?? "获取字典失败")
        }

        return response.data ?? []
    }

    /// 拉取 App 已登记的全部字典父节点
    func fetchCatalog(allStatus: Bool = true) async throws -> [SDictionary] {
        try await fetchNodes(
            parentIds: DictionaryParent.allCases.map(\.rawValue),
            allStatus: allStatus
        )
    }

    /// 获取服务首页德系产品矩阵
    func fetchProductMatrix(
        parentId: Int64 = DictionaryService.productLineParentId,
        allStatus: Bool = true
    ) async throws -> [ProductMatrixItem] {
        let nodes = try await fetchNodes(parentId: parentId, allStatus: allStatus)
        return ProductMatrixMapper.toMatrixItems(nodes)
    }

    /// 获取服务首页「推荐服务」类目 Tab
    func fetchRecommendCategories(
        parentId: Int64 = DictionaryService.serviceRecommendCategoryParentId,
        allStatus: Bool = true
    ) async throws -> [ServiceRecommendCategory] {
        let nodes = try await fetchNodes(parentId: parentId, allStatus: allStatus)
        return ServiceRecommendCategoryMapper.toCategories(nodes)
    }
}

enum DictionaryServiceError: LocalizedError {
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let message): return message
        }
    }
}
