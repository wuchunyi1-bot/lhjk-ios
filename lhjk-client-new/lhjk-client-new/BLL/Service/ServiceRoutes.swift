import Foundation

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

        // 富德优选
        r.register(path: "/mall") { _ in HealthMallViewController() }

        // 商品详情（params: id）
        r.register(path: "/mall/detail") { params in
            let id = params["id"] as? String ?? ""
            return PlaceholderViewController(title: "商品详情: \(id)")
        }
    }
}
