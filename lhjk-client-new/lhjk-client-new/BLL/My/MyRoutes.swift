import Foundation

/// 「我的」模块路由注册
enum MyRoutes {

    static func register() {
        let r = Router.shared

        // Hub
        r.register(path: "/me") { _ in MyViewController() }

        // 已实现的子页面
        r.register(path: "/me/settings")   { _ in SettingsViewController() }
        r.register(path: "/me/profile")    { _ in ProfileViewController() }
        r.register(path: "/me/policy")     { _ in PolicyViewController() }
        r.register(path: "/me/health-report")    { _ in HealthReportViewController() }
        r.register(path: "/me/appointments")     { _ in AppointmentsViewController() }
        r.register(path: "/me/devices")          { _ in DevicesViewController() }
        r.register(path: "/me/diet-plan")        { _ in DietPlanViewController() }
        r.register(path: "/me/monitoring-plan")  { _ in MonitoringPlanViewController() }
        r.register(path: "/me/health-evaluations") { _ in HealthEvaluationsViewController() }

        // 占位页面（后续迭代实现）
        r.register(path: "/me/membership")  { _ in MembershipViewController() }
        r.register(path: "/me/points")      { _ in PointsViewController() }
        r.register(path: "/me/family")      { _ in FamilyViewController() }
        r.register(path: "/me/medical-reports") { _ in PlaceholderViewController(title: "体检报告单") }

        // Settings 子页面
        r.register(path: "/me/settings/notifications")  { _ in PlaceholderViewController(title: "消息通知设置") }
        r.register(path: "/me/settings/accessibility")  { _ in PlaceholderViewController(title: "大字显示与简洁操作") }
        r.register(path: "/me/settings/privacy")        { _ in PlaceholderViewController(title: "隐私设置") }
        r.register(path: "/me/settings/security")       { _ in PlaceholderViewController(title: "账号安全") }
        r.register(path: "/me/settings/about")          { _ in PlaceholderViewController(title: "关于富德健康") }

        // 跨模块路由
        r.register(path: "/orders")          { params in
            let tab = params["tab"] as? String
            return OrderListViewController(initialTab: tab)
        }
        r.register(path: "/orders/detail")  { params in PlaceholderViewController(title: "订单详情: \(params["id"] as? String ?? "")") }
    }
}
