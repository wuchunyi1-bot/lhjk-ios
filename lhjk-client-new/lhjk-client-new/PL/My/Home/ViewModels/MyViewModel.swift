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
        var value: String
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
    private let userService: UserService
    private var cancellables = Set<AnyCancellable>()

    init(
        userManager: UserManager = AppContainer.shared.userManager,
        userService: UserService = AppContainer.shared.userService
    ) {
        self.userManager = userManager
        self.userService = userService
        self.memberAssets = Self.defaultMemberAssets
        self.fulfillmentStats = Self.defaultFulfillmentStats
        self.healthManagement = Self.defaultHealthManagement

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

    /// 刷新首页概览（`GET /v1/users/getUserCenterOverview`）
    func refreshOverview() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let overview = try await userService.getUserCenterOverview()
                await MainActor.run {
                    self.applyOverview(overview)
                }
            } catch {
                print("[MyViewModel] getUserCenterOverview ✗ \(error.localizedDescription)")
            }
        }
    }

    private func applyOverview(_ overview: UserCenterOverviewVO) {
        memberAssets = memberAssets.map { asset in
            var copy = asset
            switch asset.label {
            case "会员等级":
                copy.value = overview.memberLevelText
            case "健康积分":
                copy.value = overview.healthPointsText
            case "富德币":
                copy.value = overview.fundeCoinText
            case "权益卡券":
                copy.value = overview.benefitsCountText
            default:
                break
            }
            return copy
        }

        fulfillmentStats = fulfillmentStats.map { stat in
            var copy = stat
            switch stat.label {
            case "待支付":
                copy.value = overview.pendingPaymentText
            case "待收货":
                copy.value = overview.pendingReceiptText
            case "使用中":
                copy.value = overview.inUseOrderText
            case "已完成":
                copy.value = overview.completedOrderText
            default:
                break
            }
            return copy
        }
    }
}

// MARK: - Defaults (Figma 3594:8470 / me.json)

extension MyViewModel {

    static var defaultMemberAssets: [MemberAsset] {
        [
            MemberAsset(label: "会员等级", value: "0", route: "/me/member-level", accent: false),
            MemberAsset(label: "健康积分", value: "0", route: "/me/points"),
            MemberAsset(label: "富德币", value: "0", route: "/me/member-level"),
            MemberAsset(label: "权益卡券", value: "0", route: "/me/vouchers"),
        ]
    }

    /// 对齐 Figma 3594:8634 与 me.json `fulfillment.stats`
    static var defaultFulfillmentStats: [FulfillmentStat] {
        [
            FulfillmentStat(label: "待支付", value: "0", accent: false, tabKey: "pending_payment"),
            FulfillmentStat(label: "待收货", value: "0", accent: false, tabKey: "pending_receipt"),
            FulfillmentStat(label: "使用中", value: "0", accent: false, tabKey: "in_progress"),
            FulfillmentStat(label: "已完成", value: "0", accent: false, tabKey: "completed"),
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
