import Foundation

/// 注册/登录模块路由注册
enum RegisterLoginRoutes {
    static func register() {
        // Login page
        Router.shared.register(path: "/login", requiresAuth: false) { _ in
            let vc = LoginViewController()
            vc.modalPresentationStyle = .fullScreen
            return vc
        }

        // Onboarding (new user guide)
        Router.shared.register(path: "/onboarding", requiresAuth: false) { _ in
            let vc = OnboardingViewController()
            vc.modalPresentationStyle = .fullScreen
            return vc
        }
    }
}
