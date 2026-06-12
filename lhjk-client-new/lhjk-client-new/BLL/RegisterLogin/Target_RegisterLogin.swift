import UIKit

/// 「注册登录」模块路由 Target
final class Target_RegisterLogin: NSObject {

    @objc func Action_login(_ params: NSDictionary) -> UIViewController? {
        let dict = params as? [String: Any]
        let transition = dict?["transition"] as? RouteTransition
        let vc = LoginViewController()
        if transition == .some(.present) || transition == nil {
            vc.modalPresentationStyle = .fullScreen
        }
        return vc
    }
}
