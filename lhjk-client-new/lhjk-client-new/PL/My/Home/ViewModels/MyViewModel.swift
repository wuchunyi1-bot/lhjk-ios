import Foundation
import Combine
import UIKit

/// 我的模块 Hub ViewModel — 用户信息、统计数据、服务列表
final class MyViewModel: ObservableObject {

    // MARK: - Published State

    @Published var userName: String = "加载中…"
    @Published var avatarChar: String = "我"
    @Published var avatarURL: String?

    let membershipLevel = "健康大会员"

    struct StatItem {
        let value: String; let label: String; let accent: Bool; let route: String
    }

    struct FulfillmentStat {
        let value: String; let label: String; let accent: Bool
    }

    struct ServiceItem {
        let icon: String; let iconBg: String; let iconColorHex: String
        let name: String; let status: String; let statusType: String; let detail: String
    }

    struct FuncRow {
        let icon: String; let color: UIColor; let label: String
        let detail: String?; let route: String
    }

    struct FuncGroup {
        let title: String; let rows: [FuncRow]
    }

    @Published var stats: [StatItem]
    @Published var fulfillmentStats: [FulfillmentStat]
    @Published var services: [ServiceItem]
    @Published var functionGroups: [FuncGroup]

    // MARK: - Dependencies

    private let userManager: UserManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(userManager: UserManager = AppContainer.shared.userManager) {
        self.userManager = userManager

        self.stats = Self.defaultStats
        self.fulfillmentStats = Self.defaultFulfillmentStats
        self.services = Self.defaultServices
        self.functionGroups = Self.defaultFunctionGroups

        NotificationCenter.default.publisher(for: .userDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.loadUserProfile() }
            .store(in: &cancellables)

        loadUserProfile()
    }

    // MARK: - User Profile

    func loadUserProfile() {
        guard let user = userManager.currentUser else { return }
        let name = user.chineseName ?? user.surname ?? user.nickname ?? "用户"
        userName = name
        avatarChar = String(name.prefix(1))
        avatarURL = user.imageUrl
    }
}

// MARK: - Default Data

extension MyViewModel {

    static var defaultStats: [StatItem] {
        [
            StatItem(value: "892", label: "健康积分", accent: true, route: "/me/points"),
            StatItem(value: "4", label: "家庭成员", accent: false, route: "/me/family"),
            StatItem(value: "2", label: "我的保单", accent: false, route: "/me/policy"),
            StatItem(value: "Lv.3", label: "健康等级", accent: false, route: "/me/membership"),
        ]
    }

    static var defaultFulfillmentStats: [FulfillmentStat] {
        [
            FulfillmentStat(value: "2", label: "待使用", accent: true),
            FulfillmentStat(value: "1", label: "使用中", accent: false),
            FulfillmentStat(value: "3", label: "已完成", accent: false),
            FulfillmentStat(value: "1", label: "待评价", accent: false),
        ]
    }

    static var defaultServices: [ServiceItem] {
        [
            ServiceItem(icon: "德好", iconBg: "#FF7A50", iconColorHex: "#FFFFFF", name: "慢病逆转管理", status: "进行中", statusType: "success", detail: "服务至 2026/06/30 · 剩 45 天"),
            ServiceItem(icon: "体检", iconBg: "#E6F7EF", iconColorHex: "#1F9A6B", name: "慈铭高端体检 · 三甲套餐", status: "待使用", statusType: "warning", detail: "5 月 23 日 · 上海陆家嘴中心"),
        ]
    }

    static var defaultFunctionGroups: [FuncGroup] {
        [
            FuncGroup(title: "健康管理", rows: [
                FuncRow(icon: "doc.text", color: UIColor(hexString: "#7B5E9F"), label: "健康档案", detail: "完整度 72%", route: "/health/record"),
                FuncRow(icon: "heart.text.square", color: UIColor(hexString: "#1F9A6B"), label: "健康报告", detail: "周报 / 阶段小结", route: "/me/health-report"),
                FuncRow(icon: "cross.case", color: UIColor(hexString: "#3D6FB8"), label: "体检报告单", detail: "3 份已上传", route: "/me/medical-reports"),
                FuncRow(icon: "calendar", color: UIColor(hexString: "#B47300"), label: "监测方案", detail: "当前方案生效中", route: "/me/monitoring-plan"),
                FuncRow(icon: "fork.knife", color: UIColor(hexString: "#D6602B"), label: "饮食方案", detail: "可按档案生成", route: "/me/diet-plan"),
                FuncRow(icon: "checklist", color: UIColor(hexString: "#5C8DC9"), label: "健康评估", detail: "2 项待完成", route: "/me/health-evaluations"),
                FuncRow(icon: "clock", color: UIColor(hexString: "#6B9FE4"), label: "我的预约", detail: "1 个待到店", route: "/me/appointments"),
                FuncRow(icon: "creditcard", color: UIColor(hexString: "#FF7A50"), label: "我的卡券", detail: "1 张已激活", route: "/me/vouchers"),
            ]),
        ]
    }
}
