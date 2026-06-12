import Foundation

enum HomeRoutes {
    static func register() {
        Router.shared.register(path: "/home") { _ in HomeViewController() }
    }
}
