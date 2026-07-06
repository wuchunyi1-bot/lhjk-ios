import Foundation

// MARK: - 卡券状态

/// 三好卡兑换状态
enum VoucherStatus: String, Codable {
    /// 未使用
    case unused
    /// 已激活
    case activated
    /// 已过期
    case expired

    /// 状态显示文本
    var label: String {
        switch self {
        case .unused:    return "未使用"
        case .activated: return "已激活"
        case .expired:   return "已过期"
        }
    }

    /// 状态角标背景色 hex
    var tagBgHex: String {
        switch self {
        case .unused:    return "#FFF3DC"
        case .activated: return "#E6F7EF"
        case .expired:   return "#F0F0F0"
        }
    }

    /// 状态角标文字色 hex
    var tagTextHex: String {
        switch self {
        case .unused:    return "#B47300"
        case .activated: return "#1F9A6B"
        case .expired:   return "#999999"
        }
    }
}

// MARK: - 卡券模型

/// 三好卡券模型，对应 funde-client `Voucher` interface
struct MVoucher {
    /// 卡券唯一标识
    let id: String
    /// 卡号，如 "SGHK-2026-0001"
    let cardNo: String
    /// 套餐名称
    let packageName: String
    /// 兑换状态
    let status: VoucherStatus
    /// 激活截止日期（未使用时显示）
    let activationDeadline: String?
    /// 激活时间（已激活/已过期时显示）
    let activatedAt: String?
    /// 有效期至（已激活/已过期时显示）
    let validUntil: String?
    /// 专属健管师（已激活时显示）
    let advisorName: String?
    /// 剩余天数（已激活时显示）
    let daysLeft: Int?
}
