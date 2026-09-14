import Foundation

/// `GET /v1/session/getGroup` 返回的群组模型
struct GroupVO: Decodable {
    let sessionId: String?       // 后端返回 String
    let groupId: String?         // 后端返回 String
    let groupName: String?
    let groupImg: String?
    let lastTime: String?
    let lastContent: String?
    let serviceName: String?
    let serviceId: String?
    let userId: String?
    let createTime: String?
    let repurchaseTime: String?
    let numbers: Int?            // 后端返回 Int
    let principalName: String?
    let hospitalId: String?
    let status: Int?             // 会话状态；仅 `0` 已过期、`2` 已结束不可发送
    let pregnantId: String?      // 后端返回 String
    let labelType: Int?          // 后端返回 Int (nullable)

    /// 仅 `status == 0`（已过期）或 `2`（已结束）只读
    var isMessagingReadOnly: Bool {
        GroupSessionStatus.isMessagingReadOnly(status)
    }
}

/// `GET /v1/session/getGroup` 响应 `status` 约定
enum GroupSessionStatus {
    /// 已过期，用户不可发送
    static let expired = 0
    /// 进行中，用户可发送消息
    static let messagingEnabled = 1
    /// 已结束，用户不可发送
    static let ended = 2

    /// 仅 `0` / `2` 只读；`nil` 表示尚未拿到群组状态（不据此锁发送）
    static func isMessagingReadOnly(_ status: Int?) -> Bool {
        guard let status else { return false }
        return status == expired || status == ended
    }

    static func listStatusText(status: Int?, memberCount: Int?) -> String {
        if status == ended {
            return "会话已结束"
        }
        if status == expired {
            return "已过期"
        }
        if let n = memberCount, n > 0 { return "\(n) 人在线" }
        return "在线"
    }

    /// 聊天页底部不可发送横幅文案（`0` / `2` 同一句）
    static func readOnlyBannerCopy(status _: Int?) -> String {
        "您的服务已过期，可前往商城重新购买健康管理服务！"
    }

    static func readOnlyToast(status _: Int?) -> String {
        "服务已过期，仅可查看历史消息"
    }

    /// `0` / `2` 横幅均可点进商城续购
    static func readOnlyBannerOpensMall(status: Int?) -> Bool {
        isMessagingReadOnly(status)
    }
}

/// `GET /v1/session/getGroup` 响应
typealias GroupListResponse = APIResponse<[GroupVO]>
