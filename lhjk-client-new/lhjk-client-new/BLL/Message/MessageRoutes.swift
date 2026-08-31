import Foundation
import RongIMLibCore

/// 消息模块路由注册
enum MessageRoutes {

    static func register() {
        let r = Router.shared

        // 消息根页 = Tab Bar「消息」，切 Tab 不 push（push 会 hidesBottomBarWhenPushed）
        r.register(path: "/messages") { _ in
            RootTabBarController.selectMessageTab()
            return nil
        }

        // 会话详情
        r.register(path: "/conversations/:id") { params in
            let id = params["id"] as? String ?? ""
            let typeRaw = (params["conversationType"] as? String)?.lowercased()
                ?? (params["type"] as? String)?.lowercased()
            let isPrivate = typeRaw == "private" || typeRaw == "1"
            return ChatViewController(
                conversationId: id,
                conversationType: isPrivate ? .ConversationType_PRIVATE : .ConversationType_GROUP
            )
        }

        r.register(path: "/conversations/:id/members") { params in
            let id = params["id"] as? String ?? ""
            return GroupMembersViewController(groupId: id)
        }

        // 通知中心
        r.register(path: "/notifications") { _ in NotificationsViewController() }
    }
}
