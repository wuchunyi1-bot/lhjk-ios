import Foundation

enum RegisterLoginRoutes {
    static func register() {
        Router.shared.register(path: "/login", requiresAuth: false) { _ in
            let vc = LoginViewController()
            vc.modalPresentationStyle = .fullScreen
            return vc
        }
    }
}
