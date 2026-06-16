import Foundation

/// 注册/登录模块路由注册
enum RegisterLoginRoutes {
    static func register() {
        // Login page
        Router.shared.register(path: "/login", requiresAuth: false) { params in
            let vc = LoginViewController()
            vc.modalPresentationStyle = .fullScreen

            // Pass redirect/deeplink parameters
            if let redirect = params["redirect"] as? String {
                vc.redirectPath = redirect
            }
            if let deeplink = params["deeplink"] as? String {
                vc.deeplink = deeplink
            }
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
