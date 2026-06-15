import Foundation

/// 消息模块路由注册
enum MessageRoutes {

    static func register() {
        let r = Router.shared

        // 会话列表
        r.register(path: "/messages") { _ in ConversationListViewController() }
    }
}
