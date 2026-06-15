import UIKit

/// 「注册登录」模块路由 Target
/// CTMediator 风格，支持 redirect/deeplink 参数传递
final class Target_RegisterLogin: NSObject {

    @objc func Action_login(_ params: NSDictionary) -> UIViewController? {
        let dict = params as? [String: Any]
        let transition = dict?["transition"] as? RouteTransition

        let vc = LoginViewController()

        // Pass redirect/deeplink
        if let redirect = dict?["redirect"] as? String {
            vc.redirectPath = redirect
        }
        if let deeplink = dict?["deeplink"] as? String {
            vc.deeplink = deeplink
        }

        if transition == .some(.present) || transition == nil {
            vc.modalPresentationStyle = .fullScreen
        }
        return vc
    }
}
