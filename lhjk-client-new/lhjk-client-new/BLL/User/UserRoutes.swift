import Foundation

/// 用户模块路由注册
enum UserRoutes {

    /// 注册用户相关路由（目前无新增独立页面，Profile 使用已有 MyRoutes 的 `/me/profile`）
    static func register() {
        // 用户相关页面路由如需要可在此扩展：
        // Router.shared.register("/user/profile/edit") { _, _ in UserProfileEditViewController() }
    }
}
