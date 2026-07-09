import Foundation
import UIKit

/// 服务模块路由注册
enum ServiceRoutes {
    static func register() {
        let r = Router.shared

        // Hub
        r.register(path: "/services") { _ in ServiceViewController() }

        // 套餐列表（params: code）
        r.register(path: "/services/list") { params in
            let code = params["code"] as? String ?? "德好"
            return ServiceListViewController(productCode: code)
        }

        // 套餐详情（params: id）
        r.register(path: "/services/detail") { params in
            let id = params["id"] as? String ?? ""
            return PlaceholderViewController(title: "服务详情: \(id)")
        }

        // 就医协助
        r.register(path: "/services/medical-assist") { _ in
            PlaceholderViewController(title: "就医协助服务")
        }

        // 健康包详情（params: id）
        r.register(path: "/services/pkg") { params in
            let id = params["id"] as? String ?? ""
            return PlaceholderViewController(title: "健康包详情: \(id)")
        }

        // 搜索 / 购物车
        r.register(path: "/services/search") { params in
            let raw = params["hospitalId"] as? String ?? params["institution"] as? String
            let hospitalId = ServiceCatalogService.validApiHospitalId(raw)
            return ServicePackageSearchViewController(hospitalId: hospitalId)
        }
        r.register(path: "/services/cart") { _ in
            PlaceholderViewController(title: "购物车")
        }

        // 三好卡激活入口
        r.register(path: "/activate") { _ in
            VoucherListViewController()
        }

        // 富德优选
        r.register(path: "/mall") { _ in HealthMallViewController() }

        // 商品详情（params: id）
        r.register(path: "/mall/detail") { params in
            let id = params["id"] as? String ?? ""
            return PlaceholderViewController(title: "商品详情: \(id)")
        }
    }
}
