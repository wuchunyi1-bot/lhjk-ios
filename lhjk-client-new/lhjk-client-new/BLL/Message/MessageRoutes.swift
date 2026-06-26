import Foundation

/// 消息模块路由注册
enum MessageRoutes {

    static func register() {
        let r = Router.shared

        // 消息根页（分段 Tab：团队对话 + 通知中心）
        r.register(path: "/messages") { _ in MessagesViewController() }

        // 会话详情
        r.register(path: "/conversations/:id") { params in
            let id = params["id"] as? String ?? ""
            return ChatViewController(conversationId: id)
        }

        // 通知中心
        r.register(path: "/notifications") { _ in NotificationsViewController() }
    }
}
