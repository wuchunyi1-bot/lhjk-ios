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
        r.register(path: "/me/membership/open") { _ in PlaceholderViewController(title: "开通会员") }
        r.register(path: "/me/points")      { _ in PointsViewController() }
        r.register(path: "/me/family")      { _ in FamilyViewController() }
        r.register(path: "/me/medical-reports") { _ in PlaceholderViewController(title: "体检报告单") }

        // Settings 子页面
        r.register(path: "/me/settings/notifications")  { _ in NotificationSettingsViewController() }
        r.register(path: "/me/settings/accessibility")  { _ in AccessibilitySettingsViewController() }
        r.register(path: "/me/settings/privacy")        { _ in PrivacySettingsViewController() }
        r.register(path: "/me/settings/security")       { _ in SecuritySettingsViewController() }
        r.register(path: "/me/settings/about")          { _ in AboutSettingsViewController() }
        r.register(path: "/me/settings/cancel-account") { _ in CancelAccountViewController() }

        // 卡券
        r.register(path: "/me/vouchers")         { _ in VoucherListViewController() }

        // 新增子页面（占位）
        r.register(path: "/me/change-phone")     { _ in ChangePhoneViewController() }
        r.register(path: "/me/address")          { params in
            let selectMode = (params["selectMode"] as? Bool) ?? false
            let onSelect = params["onSelect"] as? (MAddress) -> Void
            return AddressListViewController(selectMode: selectMode, onSelect: onSelect)
        }
        r.register(path: "/me/address/edit")     { params in
            let address = params["address"] as? MAddress
            let count = params["existingAddressCount"] as? Int ?? 0
            return AddressEditViewController(address: address, existingAddressCount: count)
        }
        r.register(path: "/me/health-profile")   { _ in PlaceholderViewController(title: "健康档案") }
        r.register(path: "/orders")          { params in
            let tab = params["tab"] as? String
            return OrderListViewController(initialTab: tab)
        }
        r.register(path: "/orders/detail")  { params in PlaceholderViewController(title: "订单详情: \(params["id"] as? String ?? "")") }
        r.register(path: "/orders/confirm") { params in
            let orderIdRaw = (params["orderId"] as? String)
                ?? (params["orderId"] as? NSNumber)?.stringValue
                ?? ""
            guard let orderId = Int64(orderIdRaw.trimmingCharacters(in: .whitespacesAndNewlines)),
                  orderId > 0 else {
                return PlaceholderViewController(title: "订单信息缺失")
            }
            let serial: Int? = {
                if let s = params["serialNumber"] as? String { return Int(s) }
                if let n = params["serialNumber"] as? NSNumber { return n.intValue }
                if let i = params["serialNumber"] as? Int { return i }
                return nil
            }()
            return OrderConfirmViewController(orderId: orderId, serialNumber: serial)
        }
    }
}
