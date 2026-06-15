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
        HomeRoutes.register()
        MyRoutes.register()
        HealthRoutes.register()
        MessageRoutes.register()

        // WebView 页面
        Router.shared.register(path: "/web/appointments") { _ in
            WebViewController(urlString: "https://www.funde-life.com/appointments/exams", title: "预约体检")
        }
        Router.shared.register(path: "/web/membership") { _ in
            WebViewController(urlString: "https://www.funde-life.com/me/membership", title: "查看权益")
        }
    }
}
