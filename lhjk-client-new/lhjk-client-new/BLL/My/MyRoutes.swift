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
        r.register(path: "/me/health-assessment") { _ in PlaceholderViewController(title: "健康评估") }

        // 占位页面（后续迭代实现）
        r.register(path: "/me/membership")  { _ in MembershipViewController() }
        r.register(path: "/me/membership/open") { _ in PlaceholderViewController(title: "开通会员") }
        r.register(path: "/me/points")      { _ in PointsViewController() }
        r.register(path: "/me/family")      { _ in FamilyViewController() }

        // 体检报告单 → H5 `#/medical-reports`（宿主接入文档）
        r.register(path: "/me/medical-reports") { _ in
            WebViewController(
                urlString: H5Config.medicalReportsPageURL.absoluteString,
                title: "体检报告单"
            )
        }
        r.register(path: "/me/medical-reports/upload") { _ in
            WebViewController(
                urlString: H5Config.medicalReportsUploadPageURL.absoluteString,
                title: "上传体检报告"
            )
        }
        r.register(path: "/me/medical-reports/detail") { params in
            let reportId = (params["reportId"] as? String)
                ?? (params["id"] as? String)
                ?? ""
            return WebViewController(
                urlString: H5Config.medicalReportsDetailPageURL(reportId: reportId).absoluteString,
                title: "报告详情"
            )
        }

        // 文档路径别名（与 H5 hash 对齐）
        r.register(path: "/medical-reports") { _ in
            WebViewController(
                urlString: H5Config.medicalReportsPageURL.absoluteString,
                title: "体检报告单"
            )
        }
        r.register(path: "/medical-reports/upload") { _ in
            WebViewController(
                urlString: H5Config.medicalReportsUploadPageURL.absoluteString,
                title: "上传体检报告"
            )
        }
        r.register(path: "/medical-reports/detail") { params in
            let reportId = (params["reportId"] as? String)
                ?? (params["id"] as? String)
                ?? ""
            return WebViewController(
                urlString: H5Config.medicalReportsDetailPageURL(reportId: reportId).absoluteString,
                title: "报告详情"
            )
        }

        // Settings 子页面
        r.register(path: "/me/settings/notifications")  { _ in NotificationSettingsViewController() }
        r.register(path: "/me/settings/accessibility")  { _ in AccessibilitySettingsViewController() }
        r.register(path: "/me/settings/privacy")        { _ in PrivacySettingsViewController() }
        r.register(path: "/me/settings/security")       { _ in SecuritySettingsViewController() }
        r.register(path: "/me/settings/about")          { _ in AboutSettingsViewController() }
        r.register(path: "/me/settings/cancel-account") { _ in CancelAccountViewController() }
        r.register(path: "/me/settings/agreement-center") { _ in AgreementCenterViewController() }

        // 安全中心三级页（对齐 Vue `/me/settings/security/*`）
        r.register(path: "/me/settings/security/change-phone") { _ in ChangePhoneViewController() }
        r.register(path: "/me/settings/security/password") { _ in
            let vc = PasswordSetupViewController()
            let phone = UserManager.shared.currentUser?.mobile
                ?? UserDefaults.standard.string(forKey: "current_user_mobile")
                ?? ""
            vc.mode = .loggedIn(phone: phone)
            return vc
        }
        r.register(path: "/me/settings/security/wechat") { _ in WechatAuthorizationViewController() }
        r.register(path: "/me/settings/security/cancel-account") { _ in CancelAccountViewController() }

        // 协议详情（协议与说明 / 登录链路共用）
        r.register(path: "/auth/agreement/user") { _ in AgreementDetailViewController(docType: "user") }
        r.register(path: "/auth/agreement/privacy") { _ in AgreementDetailViewController(docType: "privacy") }
        r.register(path: "/auth/agreement/consent") { _ in AgreementDetailViewController(docType: "consent") }
        r.register(path: "/auth/agreement/personal-info") { _ in AgreementDetailViewController(docType: "personal-info") }
        r.register(path: "/auth/agreement/third-party-sharing") { _ in AgreementDetailViewController(docType: "third-party-sharing") }
        r.register(path: "/auth/agreement/benefit-card") { _ in AgreementDetailViewController(docType: "benefit-card") }

        // 卡券（params: 可选 tab=coupon|benefit）
        r.register(path: "/me/vouchers") { params in
            let raw = (params["tab"] as? String)?.lowercased() ?? ""
            let top: VoucherTopTab = (raw == "coupon") ? .coupon : .benefit
            return VoucherListViewController(topTab: top)
        }

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
        r.register(path: "/me/health-profile") { _ in
            WebViewController(
                urlString: H5Config.healthRecordPageURL.absoluteString,
                title: "健康档案"
            )
        }
        r.register(path: "/orders")          { params in
            let tab = (params["tab"] as? String) ?? "all"
            return OrderListViewController(initialTab: tab)
        }
        r.register(path: "/orders/detail") { params in
            let raw = (params["id"] as? String)
                ?? (params["orderId"] as? String)
                ?? (params["id"] as? NSNumber)?.stringValue
                ?? (params["orderId"] as? NSNumber)?.stringValue
                ?? ""
            guard let orderId = Int64(raw.trimmingCharacters(in: .whitespacesAndNewlines)), orderId > 0 else {
                return PlaceholderViewController(title: "订单信息缺失")
            }
            return OrderDetailViewController(orderId: orderId)
        }
        r.register(path: "/orders/shipment-records") { params in
            let raw = (params["orderId"] as? String)
                ?? (params["orderId"] as? NSNumber)?.stringValue
                ?? ""
            guard let orderId = Int64(raw.trimmingCharacters(in: .whitespacesAndNewlines)), orderId > 0 else {
                return PlaceholderViewController(title: "订单信息缺失")
            }
            let type = (params["type"] as? String)?.lowercased() ?? "express"
            let isPickup = type == "pickup"
            return OrderShipmentRecordsViewController(orderId: orderId, isPickup: isPickup)
        }
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
            let entry = OrderConfirmEntry(routeValue: params["entry"] as? String)
            return OrderConfirmViewController(orderId: orderId, serialNumber: serial, entry: entry)
        }
    }
}
