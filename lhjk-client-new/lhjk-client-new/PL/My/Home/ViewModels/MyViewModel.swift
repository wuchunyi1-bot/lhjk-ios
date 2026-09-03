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
    private let medicalReportService: MedicalReportService
    private let questionnaireService: QuestionnaireService
    private var cancellables = Set<AnyCancellable>()

    init(
        userManager: UserManager = AppContainer.shared.userManager,
        userService: UserService = AppContainer.shared.userService,
        medicalReportService: MedicalReportService = AppContainer.shared.medicalReportService,
        questionnaireService: QuestionnaireService = AppContainer.shared.questionnaireService
    ) {
        self.userManager = userManager
        self.userService = userService
        self.medicalReportService = medicalReportService
        self.questionnaireService = questionnaireService
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

    /// 刷新 Hub 概览（个人中心 + 健康管理统计）
    func refreshOverview() {
        Task { [weak self] in
            guard let self else { return }

            async let overviewResult: UserCenterOverviewVO? = {
                do {
                    return try await self.userService.getUserCenterOverview()
                } catch {
                    print("[MyViewModel] getUserCenterOverview ✗ \(error.localizedDescription)")
                    return nil
                }
            }()

            async let medicalReportStatsResult: MedicalReportStatisticsVO? = {
                do {
                    return try await self.medicalReportService.getMedicalReportStatistics(
                        userId: self.userManager.currentUser?.id
                    )
                } catch {
                    print("[MyViewModel] getMedicalReportStatistics ✗ \(error.localizedDescription)")
                    return nil
                }
            }()

            async let schoolExamCountResult: [ExamUserListCountVO]? = {
                do {
                    return try await self.questionnaireService.getSchoolExamUserListCount()
                } catch {
                    print("[MyViewModel] getSchoolExamUserListCount ✗ \(error.localizedDescription)")
                    return nil
                }
            }()

            let overview = await overviewResult
            let medicalReportStats = await medicalReportStatsResult
            let schoolExamCounts = await schoolExamCountResult

            await MainActor.run {
                if let overview {
                    self.applyOverview(overview)
                }
                if let medicalReportStats {
                    self.updateHealthManagementDetail(
                        label: "体检报告单",
                        detail: medicalReportStats.hubDetailText
                    )
                }
                if let schoolExamCounts {
                    self.updateHealthManagementDetail(
                        label: "健康测评",
                        detail: schoolExamCounts.hubHealthEvaluationDetail
                    )
                }
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

    private func updateHealthManagementDetail(label: String, detail: String?) {
        healthManagement = FuncGroup(
            title: healthManagement.title,
            rows: healthManagement.rows.map { row in
                guard row.label == label else { return row }
                return FuncRow(
                    icon: row.icon,
                    color: row.color,
                    label: row.label,
                    detail: detail,
                    route: row.route
                )
            }
        )
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
            FuncRow(icon: "me_health_report_icon", color: UIColor(hexString: "#1F2942"), label: "健康报告", detail: nil, route: "/me/health-report"),
            FuncRow(icon: "me_medical_report_icon", color: UIColor(hexString: "#1F2942"), label: "体检报告单", detail: nil, route: "/me/medical-reports"),
            FuncRow(icon: "me_monitoring_plan_icon", color: UIColor(hexString: "#1F2942"), label: "监测方案", detail: nil, route: "/me/monitoring-plan"),
            FuncRow(icon: "me_diet_plan_icon", color: UIColor(hexString: "#1F2942"), label: "饮食方案", detail: nil, route: "/me/diet-plan"),
            FuncRow(icon: "me_health_assessment_icon", color: UIColor(hexString: "#1F2942"), label: "健康评估", detail: nil, route: "/me/health-assessment"),
            FuncRow(icon: "me_health_evaluation_icon", color: UIColor(hexString: "#1F2942"), label: "健康测评", detail: nil, route: "/me/health-evaluations"),
        ])
    }
}
