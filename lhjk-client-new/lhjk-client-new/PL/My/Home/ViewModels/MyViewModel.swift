import Foundation
import Combine
import UIKit

/// 我的模块 Hub ViewModel — 对齐 Figma 3594:8470 + funde-client `MeView.vue`
final class MyViewModel: ObservableObject {

    struct MemberAsset: Identifiable {
        let id = UUID()
        let label: String
        var value: String
        let route: String
        var accent: Bool = false
    }

    struct FulfillmentStat: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        let accent: Bool
        /// 订单列表 Tab routeKey（见 `OrderListViewController`）
        let tabKey: String
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

    @Published var memberAssets: [MemberAsset]
    @Published var fulfillmentStats: [FulfillmentStat]
    @Published var healthManagement: FuncGroup

    private let userManager: UserManager
    private var cancellables = Set<AnyCancellable>()

    init(userManager: UserManager = AppContainer.shared.userManager) {
        self.userManager = userManager
        self.memberAssets = Self.defaultMemberAssets
        self.fulfillmentStats = Self.defaultFulfillmentStats
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

    /// 刷新「权益卡券」数量（权益卡 + 优惠券）
    func refreshVoucherBadge() {
        applyVoucherCount(AppContainer.shared.voucherService.meBadgeText)
        Task { [weak self] in
            await AppContainer.shared.voucherService.refreshVoucherBadges()
            await MainActor.run {
                self?.applyVoucherCount(AppContainer.shared.voucherService.meBadgeText)
            }
        }
    }

    private func applyVoucherCount(_ badge: String?) {
        let count = badge ?? "0"
        memberAssets = memberAssets.map { asset in
            guard asset.label == "权益卡券" else { return asset }
            var copy = asset
            copy.value = count
            return copy
        }
    }
}

// MARK: - Defaults (Figma 3594:8470 / me.json)

extension MyViewModel {

    static var defaultMemberAssets: [MemberAsset] {
        [
            MemberAsset(label: "会员等级", value: "V1", route: "/me/member-level", accent: false),
            MemberAsset(label: "健康积分", value: "892", route: "/me/points"),
            MemberAsset(label: "富德币", value: "200", route: "/me/member-level"),
            MemberAsset(label: "权益卡券", value: "119", route: "/me/vouchers"),
        ]
    }

    /// 对齐 Figma 3594:8634 与 me.json `fulfillment.stats`
    static var defaultFulfillmentStats: [FulfillmentStat] {
        [
            FulfillmentStat(label: "待支付", value: "3", accent: false, tabKey: "pending_payment"),
            FulfillmentStat(label: "待收货", value: "1", accent: false, tabKey: "pending_receipt"),
            FulfillmentStat(label: "使用中", value: "3", accent: false, tabKey: "in_progress"),
            FulfillmentStat(label: "已完成", value: "3", accent: false, tabKey: "completed"),
        ]
    }

    /// 对齐 Figma 3594:8653 与 me.json `healthManagementActions`
    static var defaultHealthManagement: FuncGroup {
        FuncGroup(title: "健康管理", rows: [
            FuncRow(icon: "me_health_report_icon", color: UIColor(hexString: "#1F2942"), label: "健康报告", detail: "周报/月报", route: "/me/health-report"),
            FuncRow(icon: "me_medical_report_icon", color: UIColor(hexString: "#1F2942"), label: "体检报告单", detail: "3份已上传", route: "/me/medical-reports"),
            FuncRow(icon: "me_monitoring_plan_icon", color: UIColor(hexString: "#1F2942"), label: "监测方案", detail: "当前方案生效中", route: "/me/monitoring-plan"),
            FuncRow(icon: "me_diet_plan_icon", color: UIColor(hexString: "#1F2942"), label: "饮食方案", detail: "可按档案生成", route: "/me/diet-plan"),
            FuncRow(icon: "me_health_assessment_icon", color: UIColor(hexString: "#1F2942"), label: "健康评估", detail: "含健康方案", route: "/me/health-assessment"),
            FuncRow(icon: "me_health_evaluation_icon", color: UIColor(hexString: "#1F2942"), label: "健康测评", detail: "2项待完成", route: "/me/health-evaluations"),
        ])
    }
}
