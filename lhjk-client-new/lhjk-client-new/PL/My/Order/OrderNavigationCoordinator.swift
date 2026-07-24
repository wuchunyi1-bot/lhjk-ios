import UIKit

/// 确认订单页入口来源（路由 `entry` 参数）
enum OrderConfirmEntry: Equatable {
    case `default`
    case cartCheckout
    /// 我的订单 → 待支付去支付
    case orderListPay

    init(routeValue: String?) {
        switch routeValue {
        case "cart":
            self = .cartCheckout
        case "order_pay":
            self = .orderListPay
        default:
            self = .default
        }
    }
}

/// 订单相关跨 Tab / 栈导航
enum OrderNavigationCoordinator {

    /// 续费：进入套餐详情续费态
    static func openPackageRenewal(
        from source: UIViewController,
        orderId: Int64,
        packageId: String,
        hospitalId: String? = nil,
        categoryServiceId: String? = nil
    ) {
        let trimmedPackageId = packageId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPackageId.isEmpty else {
            showToast("无法获取套餐信息", on: source)
            return
        }
        var params: [String: Any] = [
            "id": trimmedPackageId,
            "orderId": String(orderId),
        ]
        if let hospitalId = hospitalId?.trimmingCharacters(in: .whitespacesAndNewlines), !hospitalId.isEmpty {
            params["hospitalId"] = hospitalId
        }
        if let categoryServiceId = categoryServiceId?.trimmingCharacters(in: .whitespacesAndNewlines),
           !categoryServiceId.isEmpty {
            params["categoryServiceId"] = categoryServiceId
        }
        Router.shared.push("/services/pkg", params: params, from: source)
    }

    /// 列表订单续费：无 packageId 时先拉详情
    static func openPackageRenewal(
        from source: UIViewController,
        order: MOrder,
        orderService: OrderService = AppContainer.shared.orderService
    ) {
        guard let orderId = order.id, orderId > 0 else {
            showToast("订单信息缺失", on: source)
            return
        }
        if let packageId = order.resolvedPackageId {
            openPackageRenewal(
                from: source,
                orderId: orderId,
                packageId: packageId,
                hospitalId: order.hospitalId,
                categoryServiceId: order.categoryServiceId
            )
            return
        }
        Task {
            do {
                let detail = try await orderService.getAppOrderDetail(orderId: orderId)
                await MainActor.run {
                    guard let packageId = detail.resolvedPackageId else {
                        showToast("无法获取套餐信息", on: source)
                        return
                    }
                    openPackageRenewal(
                        from: source,
                        orderId: orderId,
                        packageId: packageId,
                        hospitalId: detail.hospitalId,
                        categoryServiceId: detail.categoryServiceId
                    )
                }
            } catch {
                await MainActor.run {
                    showToast(error.localizedDescription, on: source)
                }
            }
        }
    }

    /// 详情页续费
    static func openPackageRenewal(from source: UIViewController, detail: AppOrderDetailBO) {
        guard let orderId = detail.id, orderId > 0 else {
            showToast("订单信息缺失", on: source)
            return
        }
        guard let packageId = detail.resolvedPackageId else {
            showToast("无法获取套餐信息", on: source)
            return
        }
        openPackageRenewal(
            from: source,
            orderId: orderId,
            packageId: packageId,
            hospitalId: detail.hospitalId,
            categoryServiceId: detail.categoryServiceId
        )
    }

    private static func showToast(_ message: String, on source: UIViewController) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        source.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }

    /// 落到：我的 Tab → 我的订单 → 全部
    static func navigateToMyOrdersAll(from source: UIViewController) {
        guard let tabBar = source.tabBarController else {
            Router.shared.push("/orders", params: ["tab": "all"], from: source)
            return
        }

        if let serviceNav = tabBar.viewControllers?[RootTabBarController.Tab.service] as? UINavigationController {
            serviceNav.popToRootViewController(animated: false)
        }

        if let myNav = tabBar.viewControllers?[RootTabBarController.Tab.my] as? UINavigationController {
            myNav.popToRootViewController(animated: false)
            tabBar.selectedIndex = RootTabBarController.Tab.my
            myNav.pushViewController(OrderListViewController(initialTab: "all"), animated: false)
        } else {
            tabBar.selectedIndex = RootTabBarController.Tab.my
        }
    }
}
