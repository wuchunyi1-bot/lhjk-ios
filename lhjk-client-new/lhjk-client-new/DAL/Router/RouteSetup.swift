import Foundation

/// 全局路由注册入口
/// 在 AppDelegate 中调用 RouteSetup.registerAll()
enum RouteSetup {

    static var isRegistered = false

    /// 注册所有模块路由
    /// 应在 AppDelegate.application(_:didFinishLaunchingWithOptions:) 中调用
    static func registerAll() {
        guard !isRegistered else { return }
        isRegistered = true

        RegisterLoginRoutes.register()
        MyRoutes.register()
    }
}
