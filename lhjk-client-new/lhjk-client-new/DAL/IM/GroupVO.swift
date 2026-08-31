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
    let status: Int?             // 会话状态；仅 `1` 允许用户发送消息
    let pregnantId: String?      // 后端返回 String
    let labelType: Int?          // 后端返回 Int (nullable)

    /// 仅 `status == 1` 可发送；缺失或其它值均只读
    var isMessagingReadOnly: Bool {
        status != GroupSessionStatus.messagingEnabled
    }
}

/// `GET /v1/session/getGroup` 响应 `status` 约定
enum GroupSessionStatus {
    /// 进行中，用户可发送消息
    static let messagingEnabled = 1
    /// 已结束（历史值，仍用于列表文案）
    static let ended = 2

    /// 群组 API 已给出 status 时：只有 `1` 可聊；`nil` 表示尚未拿到群组状态（不据此锁发送）
    static func isMessagingReadOnly(_ status: Int?) -> Bool {
        guard let status else { return false }
        return status != messagingEnabled
    }

    static func listStatusText(status: Int?, memberCount: Int?) -> String {
        if status == messagingEnabled {
            if let n = memberCount, n > 0 { return "\(n) 人在线" }
            return "在线"
        }
        if status == ended {
            return "会话已结束"
        }
        return "暂不可聊天"
    }
}

/// `GET /v1/session/getGroup` 响应
typealias GroupListResponse = APIResponse<[GroupVO]>
