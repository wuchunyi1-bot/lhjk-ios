import Foundation
import UIKit

/// 服务模块路由注册
enum ServiceRoutes {
    static func register() {
        let r = Router.shared

        // Hub
        r.register(path: "/services") { _ in ServiceViewController() }

        // 套餐列表（params: code — 健康管理类目名或德系产品线 code）
        r.register(path: "/services/list") { params in
            let code = params["code"] as? String ?? ""
            return ServiceListViewController(productCode: code)
        }

        // 套餐详情 / 服务套餐详情（params: id, 可选 hospitalId / categoryServiceId）
        r.register(path: "/services/detail") { params in
            let id = ServiceRoutes.stringParam(params["id"])
            let hospitalId = ServiceCatalogService.validApiHospitalId(
                ServiceRoutes.stringParam(params["hospitalId"]).nilIfEmpty
            )
            let categoryServiceId = ServiceCatalogService.validApiHospitalId(
                ServiceRoutes.stringParam(params["categoryServiceId"]).nilIfEmpty
            )
            return ServicePackageDetailViewController(
                packageId: id,
                hospitalId: hospitalId,
                categoryServiceId: categoryServiceId
            )
        }

        // 就医协助
        r.register(path: "/services/medical-assist") { _ in
            PlaceholderViewController(title: "就医协助服务")
        }

        // 健康包详情（params: id）— 与 detail 共用同一页
        r.register(path: "/services/pkg") { params in
            let id = ServiceRoutes.stringParam(params["id"])
            let hospitalId = ServiceCatalogService.validApiHospitalId(
                ServiceRoutes.stringParam(params["hospitalId"]).nilIfEmpty
            )
            let categoryServiceId = ServiceCatalogService.validApiHospitalId(
                ServiceRoutes.stringParam(params["categoryServiceId"]).nilIfEmpty
            )
            return ServicePackageDetailViewController(
                packageId: id,
                hospitalId: hospitalId,
                categoryServiceId: categoryServiceId
            )
        }

        // 搜索 / 购物车 / 切换机构
        r.register(path: "/services/search") { params in
            let raw = params["hospitalId"] as? String ?? params["institution"] as? String
            let hospitalId = ServiceCatalogService.validApiHospitalId(raw)
            return ServicePackageSearchViewController(hospitalId: hospitalId)
        }
        r.register(path: "/services/cart") { _ in
            ServiceCartViewController()
        }
        r.register(path: "/services/institution") { params in
            let selectedId = ServiceRoutes.stringParam(params["selectedId"]).nilIfEmpty
                ?? ServiceRoutes.stringParam(params["id"]).nilIfEmpty
            return InstitutionSelectViewController(selectedId: selectedId)
        }

        // 三好卡激活入口
        r.register(path: "/activate") { _ in
            VoucherListViewController()
        }

        // 富德优选
        r.register(path: "/mall") { _ in HealthMallViewController() }

        // 商品详情（params: id）— 与套餐详情统一
        r.register(path: "/mall/detail") { params in
            let id = Self.stringParam(params["id"])
            let hospitalId = ServiceCatalogService.validApiHospitalId(
                ServiceRoutes.stringParam(params["hospitalId"]).nilIfEmpty
            )
            let categoryServiceId = ServiceCatalogService.validApiHospitalId(
                ServiceRoutes.stringParam(params["categoryServiceId"]).nilIfEmpty
            )
            return ServicePackageDetailViewController(
                packageId: id,
                hospitalId: hospitalId,
                categoryServiceId: categoryServiceId
            )
        }
    }

    /// 兼容 String / Int / NSNumber 路由参数
    static func stringParam(_ value: Any?) -> String {
        if let s = value as? String { return s }
        if let n = value as? NSNumber { return n.stringValue }
        if let i = value as? Int { return String(i) }
        if let i = value as? Int64 { return String(i) }
        return ""
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
