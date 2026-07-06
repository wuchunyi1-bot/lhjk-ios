import Foundation

// MARK: - 卡券服务 (BLL)

/// 三好卡券管理服务
///
/// 当前使用本地 Mock 数据，后续对接后端 API 时替换 `getVouchers()` 实现即可。
/// 参考 funde-client: prototype/src/views/me/MyVouchersView.vue
final class VoucherService {

    // MARK: - Singleton

    static let shared = VoucherService()

    private init() {}

    // MARK: - Mock State

    /// 模拟激活状态（对应 funde-client stores/demo.ts 的 cardActivated）
    private var cardActivated = false

    // MARK: - 查询卡券列表

    /// 获取当前用户的卡券列表（Mock）
    /// - Returns: 全量卡券数组
    func getVouchers() -> [MVoucher] {
        return [
            MVoucher(
                id: "v001",
                cardNo: "SGHK-2026-0001",
                packageName: cardActivated ? "德好·标准版" : "三好健康服务卡",
                status: cardActivated ? .activated : .unused,
                activationDeadline: "2026/12/31",
                activatedAt: cardActivated ? "2026/06/23" : nil,
                validUntil: cardActivated ? "2027/06/22" : nil,
                advisorName: cardActivated ? "王顾问" : nil,
                daysLeft: cardActivated ? 364 : nil
            ),
            MVoucher(
                id: "v002",
                cardNo: "SGHK-2026-0512",
                packageName: "德康·标准版",
                status: .unused,
                activationDeadline: "2026/09/30",
                activatedAt: nil,
                validUntil: nil,
                advisorName: nil,
                daysLeft: nil
            ),
            MVoucher(
                id: "v003",
                cardNo: "SGHK-2025-1108",
                packageName: "德医·就医协助（标准版）",
                status: .activated,
                activationDeadline: nil,
                activatedAt: "2025/11/08",
                validUntil: "2026/11/07",
                advisorName: "李协调员",
                daysLeft: 137
            ),
            MVoucher(
                id: "v004",
                cardNo: "SGHK-2024-0318",
                packageName: "德康·入门版",
                status: .expired,
                activationDeadline: nil,
                activatedAt: "2024/03/18",
                validUntil: "2025/03/18",
                advisorName: nil,
                daysLeft: nil
            ),
            MVoucher(
                id: "v005",
                cardNo: "SGHK-2023-0921",
                packageName: "体验套餐",
                status: .expired,
                activationDeadline: nil,
                activatedAt: "2023/09/21",
                validUntil: "2023/09/28",
                advisorName: nil,
                daysLeft: nil
            ),
        ]
    }

    // MARK: - 激活卡券（Mock）

    /// 模拟激活卡券（对应 funde-client stores/demo.ts 的 activateCard）
    func activateCard() {
        cardActivated = true
        print("[VoucherService] activateCard ✓ cardActivated = true")
    }
}
