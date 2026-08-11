import UIKit

/// 登录失效弹窗展示（PL）：由 `SceneDelegate` 注入 `SessionExpiryCoordinator.presentExpiredUI`
enum SessionExpiryPresenter {

    static func present(message: String, onRelogin: @escaping () -> Void) {
        guard let host = topViewController() else {
            onRelogin()
            return
        }

        if host is LoginViewController {
            onRelogin()
            return
        }

        if host is SessionExpirySheet || host.presentedViewController is SessionExpirySheet {
            return
        }

        let sheet = SessionExpirySheet(message: message)
        sheet.onRelogin = onRelogin
        host.present(sheet, animated: true)
    }

    private static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let base = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
