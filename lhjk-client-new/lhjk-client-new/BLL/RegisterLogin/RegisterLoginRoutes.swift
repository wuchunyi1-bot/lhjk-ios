import Foundation
import UIKit

/// 注册/登录模块路由注册
enum RegisterLoginRoutes {
    static func register() {
        // Login page
        Router.shared.register(path: "/login", requiresAuth: false) { _ in
            let vc = LoginViewController()
            vc.modalPresentationStyle = .fullScreen
            return vc
        }

        // Onboarding (new user guide) — 包一层 Nav，便于机构/业务经理 push 后有系统返回
        Router.shared.register(path: "/onboarding", requiresAuth: false) { _ in
            let vc = OnboardingViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            nav.setNavigationBarHidden(true, animated: false)
            return nav
        }
    }
}
