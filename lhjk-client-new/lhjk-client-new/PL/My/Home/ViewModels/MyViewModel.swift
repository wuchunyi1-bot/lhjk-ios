import Foundation
import Combine
import UIKit

/// 我的模块 Hub ViewModel — 对齐 funde-client MeView.vue + me.json
final class MyViewModel: ObservableObject {

    enum MembershipStatus: String {
        case notOpened = "not_opened"
        case active
        case expiring
        case expired
    }

    struct MembershipState {
        var status: MembershipStatus
        var planId: String
        var planName: String
        var includedCount: Int
        var expireDate: String
        var expiringDays: Int
    }

    struct CommonAction {
        let icon: String
        let color: UIColor
        let label: String
        let route: String
    }

    struct FuncRow {
        let icon: String
        let color: UIColor
        let label: String
        let detail: String?
        let route: String?
    }

    struct FuncGroup {
        let title: String
        let rows: [FuncRow]
    }

    @Published var userName: String = "加载中…"
    @Published var avatarChar: String = "我"
    @Published var avatarURL: String?

    @Published var membership: MembershipState
    @Published var commonActions: [CommonAction]
    @Published var healthManagement: FuncGroup
    @Published var settingsSupport: FuncGroup

    private let userManager: UserManager
    private var cancellables = Set<AnyCancellable>()

    init(userManager: UserManager = AppContainer.shared.userManager) {
        self.userManager = userManager
        self.membership = Self.defaultMembership
        self.commonActions = Self.defaultCommonActions
        self.healthManagement = Self.defaultHealthManagement
        self.settingsSupport = Self.defaultSettingsSupport

        NotificationCenter.default.publisher(for: .userDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.loadUserProfile() }
            .store(in: &cancellables)

        loadUserProfile()
    }

    func loadUserProfile() {
        guard let user = userManager.currentUser else { return }
        let name = user.chineseName ?? user.surname ?? user.nickname ?? "用户"
        userName = name
        avatarChar = String(name.prefix(1))
        avatarURL = user.imageUrl
    }

    // MARK: - Membership display

    var membershipTypeText: String {
        switch membership.status {
        case .expired: return "会员已过期"
        case .notOpened: return ""
        case .active, .expiring: return membership.planName
        }
    }

    var membershipBenefitText: String {
        switch membership.status {
        case .notOpened: return "仅需 ¥19.9，体验 5 天会员服务"
        case .expired: return "已于 \(membership.expireDate) 到期"
        case .active, .expiring: return "已开通 \(membership.includedCount) 项会员权益"
        }
    }

    var membershipDateText: String {
        switch membership.status {
        case .notOpened, .expired: return ""
        case .expiring:
            return "有效期至 \(membership.expireDate) · 剩余 \(membership.expiringDays) 天"
        case .active:
            return "有效期至 \(membership.expireDate)"
        }
    }

    var membershipPrimaryActionTitle: String? {
        switch membership.status {
        case .notOpened: return "立即开通"
        case .expired: return "立即续费"
        case .active, .expiring: return nil
        }
    }

    var membershipUpgradeTitle: String? {
        switch membership.status {
        case .active:
            return membership.planId == "advanced" ? "续费会员" : "升级会员"
        case .expiring: return "续费升级"
        default: return nil
        }
    }

    var showsMembershipBenefitsButton: Bool {
        membership.status == .active || membership.status == .expiring
    }
}

// MARK: - Defaults (me.json)

extension MyViewModel {

    static var defaultMembership: MembershipState {
        MembershipState(
            status: .notOpened,
            planId: "trial-5d",
            planName: "5天体验会员",
            includedCount: 0,
            expireDate: "",
            expiringDays: 15
        )
    }

    static var defaultCommonActions: [CommonAction] {
        [
            CommonAction(icon: "doc.text", color: UIColor(hexString: "#FF7A50"), label: "我的订单", route: "/orders"),
            CommonAction(icon: "calendar", color: UIColor(hexString: "#B47300"), label: "我的预约", route: "/me/appointments"),
            CommonAction(icon: "ticket", color: UIColor(hexString: "#7B5E9F"), label: "我的卡券", route: "/me/vouchers"),
            CommonAction(icon: "cart", color: UIColor(hexString: "#3D6FB8"), label: "购物车", route: "/services/cart"),
            CommonAction(icon: "applewatch", color: UIColor(hexString: "#1F9A6B"), label: "智能设备", route: "/me/devices"),
            CommonAction(icon: "mappin.and.ellipse", color: UIColor(hexString: "#D6602B"), label: "我的地址", route: "/me/address"),
            CommonAction(icon: "person.3", color: UIColor(hexString: "#5C8DC9"), label: "家庭成员", route: "/me/family"),
            CommonAction(icon: "doc.badge.gearshape", color: UIColor(hexString: "#6B7280"), label: "我的保单", route: "/me/policy"),
        ]
    }

    static var defaultHealthManagement: FuncGroup {
        FuncGroup(title: "健康管理", rows: [
            FuncRow(icon: "doc.text", color: UIColor(hexString: "#7B5E9F"), label: "健康档案", detail: "完整度 72%", route: "/health/record"),
            FuncRow(icon: "heart.text.square", color: UIColor(hexString: "#1F9A6B"), label: "健康报告", detail: "周报 / 阶段小结", route: "/me/health-report"),
            FuncRow(icon: "cross.case", color: UIColor(hexString: "#3D6FB8"), label: "体检报告单", detail: "3 份已上传", route: "/me/medical-reports"),
            FuncRow(icon: "calendar", color: UIColor(hexString: "#B47300"), label: "监测方案", detail: "当前方案生效中", route: "/me/monitoring-plan"),
            FuncRow(icon: "fork.knife", color: UIColor(hexString: "#D6602B"), label: "饮食方案", detail: "可按档案生成", route: "/me/diet-plan"),
            FuncRow(icon: "checklist", color: UIColor(hexString: "#5C8DC9"), label: "健康评估", detail: "2 项待完成", route: "/me/health-evaluations"),
        ])
    }

    static var defaultSettingsSupport: FuncGroup {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        return FuncGroup(title: "设置与支持", rows: [
            FuncRow(icon: "gearshape", color: UIColor(hexString: "#6B7280"), label: "设置", detail: "通知、隐私、安全中心", route: "/me/settings"),
            FuncRow(icon: "info.circle", color: UIColor(hexString: "#3D6FB8"), label: "关于富德健康", detail: nil, route: "/me/settings/about"),
            FuncRow(icon: "checkmark.circle", color: UIColor(hexString: "#9AA0AC"), label: "当前版本", detail: "v \(version)", route: nil),
        ])
    }
}
