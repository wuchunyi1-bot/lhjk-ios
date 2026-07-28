import Foundation
import Combine
import UIKit

/// 我的模块 Hub ViewModel — 对齐 MeView.vue + me.json（无健康大会员）
final class MyViewModel: ObservableObject {

    struct CommonAction {
        let icon: String
        let color: UIColor
        let label: String
        let route: String
        /// 角标文案（如卡券可用数）；nil 不展示
        var badge: String? = nil
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

    @Published var commonActions: [CommonAction]
    @Published var healthManagement: FuncGroup

    private let userManager: UserManager
    private var cancellables = Set<AnyCancellable>()

    init(userManager: UserManager = AppContainer.shared.userManager) {
        self.userManager = userManager
        self.commonActions = Self.defaultCommonActions
        self.healthManagement = Self.defaultHealthManagement

        NotificationCenter.default.publisher(for: .userDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.loadUserProfile() }
            .store(in: &cancellables)

        loadUserProfile()
        refreshVoucherBadge()
    }

    func loadUserProfile() {
        guard let user = userManager.currentUser else { return }
        let name = user.chineseName ?? user.surname ?? user.nickname ?? "用户"
        userName = name
        avatarChar = String(name.prefix(1))
        avatarURL = user.imageUrl
    }

    /// 刷新「我的卡券」角标
    func refreshVoucherBadge() {
        let badge = AppContainer.shared.voucherService.meBadgeText
        commonActions = commonActions.map { action in
            guard action.route == "/me/vouchers" else { return action }
            return CommonAction(
                icon: action.icon,
                color: action.color,
                label: action.label,
                route: action.route,
                badge: badge
            )
        }
    }
}

// MARK: - Defaults (me.json)

extension MyViewModel {

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

    /// 对齐 me.json `healthManagementActions`
    static var defaultHealthManagement: FuncGroup {
        FuncGroup(title: "健康管理", rows: [
            FuncRow(icon: "doc.text", color: UIColor(hexString: "#7B5E9F"), label: "健康档案", detail: "完整度 72%", route: "/health/record"),
            FuncRow(icon: "heart.text.square", color: UIColor(hexString: "#1F9A6B"), label: "健康报告", detail: "周报 / 阶段小结", route: "/me/health-report"),
            FuncRow(icon: "cross.case", color: UIColor(hexString: "#3D6FB8"), label: "体检报告单", detail: "3 份已上传", route: "/me/medical-reports"),
            FuncRow(icon: "calendar", color: UIColor(hexString: "#B47300"), label: "监测方案", detail: "当前方案生效中", route: "/me/monitoring-plan"),
            FuncRow(icon: "fork.knife", color: UIColor(hexString: "#D6602B"), label: "饮食方案", detail: "可按档案生成", route: "/me/diet-plan"),
            FuncRow(icon: "list.clipboard", color: UIColor(hexString: "#E55A2E"), label: "健康评估", detail: "备孕管理版 · 含方案目标", route: "/me/health-assessment"),
            FuncRow(icon: "checklist", color: UIColor(hexString: "#5C8DC9"), label: "健康测评", detail: "2 项待完成", route: "/me/health-evaluations"),
        ])
    }
}
