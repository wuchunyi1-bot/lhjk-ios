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
        source.showToastAlert(message, duration: 1.5)
    }

    /// 落到：我的 Tab → 我的订单 → 全部
    static func navigateToMyOrdersAll(from source: UIViewController) {
        relocateToMyOrders(from: source, extra: nil, animated: false)
    }

    /// 支付成功/失败：结果页放到「我的 → 订单列表」之上，并清空来源 Tab 下单栈
    static func presentPayResultOnMyOrders(from source: UIViewController, payload: OrderPayResultPayload) {
        let resultVC = OrderPayResultViewController(payload: payload)
        relocateToMyOrders(from: source, extra: resultVC, animated: false)
    }

    /// 支付结果页完成 / 返回：落到「我的」订单列表全部 Tab，不回到确认订单或选择套餐
    static func leavePayResultToOrderList(from source: UIViewController) {
        relocateToMyOrders(from: source, extra: nil, animated: true)
    }

    /// 支付结果页「查看订单」：落到「我的 → 订单列表 → 订单详情」
    static func leavePayResultToOrderDetail(from source: UIViewController, orderId: Int64) {
        guard orderId > 0 else {
            leavePayResultToOrderList(from: source)
            return
        }
        relocateToMyOrders(
            from: source,
            extra: OrderDetailViewController(orderId: orderId),
            animated: true
        )
    }

    /// 服务/来源 Tab 清到根；我的 Tab 变为 `[我的, 订单列表全部, extra?]`
    private static func relocateToMyOrders(
        from source: UIViewController,
        extra: UIViewController?,
        animated: Bool
    ) {
        extra?.hidesBottomBarWhenPushed = true

        guard let tabBar = source.tabBarController else {
            fallbackRelocateWithoutTabBar(from: source, extra: extra, animated: animated)
            return
        }

        let myNav = tabBar.viewControllers?[RootTabBarController.Tab.my] as? UINavigationController
        let serviceNav = tabBar.viewControllers?[RootTabBarController.Tab.service] as? UINavigationController
        let sourceNav = source.navigationController

        guard let myNav, let myRoot = myNav.viewControllers.first else {
            tabBar.selectedIndex = RootTabBarController.Tab.my
            return
        }

        let orders = OrderListViewController(initialTab: "all")
        orders.hidesBottomBarWhenPushed = true
        var stack: [UIViewController] = [myRoot, orders]
        if let extra {
            stack.append(extra)
        }
        // 先搭好「我的」栈再切 Tab，避免先 pop 来源栈时闪服务首页
        myNav.setViewControllers(stack, animated: animated)
        tabBar.selectedIndex = RootTabBarController.Tab.my

        serviceNav?.popToRootViewController(animated: false)
        if let sourceNav, sourceNav !== myNav, sourceNav !== serviceNav {
            sourceNav.popToRootViewController(animated: false)
        }
    }

    private static func fallbackRelocateWithoutTabBar(
        from source: UIViewController,
        extra: UIViewController?,
        animated: Bool
    ) {
        guard let nav = source.navigationController else {
            Router.shared.push("/orders", params: ["tab": "all"], from: source)
            return
        }
        var stack = nav.viewControllers.filter {
            !($0 is OrderConfirmViewController) && !($0 is OrderPayResultViewController)
        }
        let orders = OrderListViewController(initialTab: "all")
        orders.hidesBottomBarWhenPushed = true
        if let index = stack.lastIndex(where: { $0 is OrderListViewController }) {
            stack = Array(stack.prefix(through: index))
            stack[index] = orders
        } else {
            stack.append(orders)
        }
        if let extra {
            stack.append(extra)
        }
        nav.setViewControllers(stack, animated: animated)
    }
}
