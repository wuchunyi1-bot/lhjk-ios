import Foundation

enum HomeRoutes {
    static func register() {
        Router.shared.register(path: "/home") { _ in HomeViewController() }
        Router.shared.register(path: "/home/tasks") { _ in DailyTasksViewController() }
        Router.shared.register(path: "/companion") { _ in
            WebViewController(
                urlString: H5Config.companionPageURL.absoluteString,
                title: "健康陪伴"
            )
        }
    }
}
