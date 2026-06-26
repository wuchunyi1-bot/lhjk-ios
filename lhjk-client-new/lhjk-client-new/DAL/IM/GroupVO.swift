import Foundation

/// `GET /mobile/v1/session/getGroup` 返回的群组模型
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
    let status: Int?             // 后端返回 Int
    let pregnantId: String?      // 后端返回 String
    let labelType: Int?          // 后端返回 Int (nullable)
}

/// `GET /mobile/v1/session/getGroup` 响应
typealias GroupListResponse = APIResponse<[GroupVO]>
