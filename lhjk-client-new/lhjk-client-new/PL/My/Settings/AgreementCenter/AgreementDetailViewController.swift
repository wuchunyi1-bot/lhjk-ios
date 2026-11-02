import UIKit

/// 协议页。正文在 H5：`{base}/agreements/user-app/*.html`，不拼登录 token。
enum AgreementDetailViewController {

    static func make(docType: String) -> UIViewController {
        let url = H5Config.agreementPageURL(docType: docType)
        return WebViewController(urlString: url.absoluteString, title: H5Config.agreementTitle(docType: docType))
    }

    /// 登录等无导航栈场景：以独立 Nav present 协议页。
    static func present(from presenter: UIViewController, docType: String) {
        let nav = UINavigationController(rootViewController: make(docType: docType))
        presenter.present(nav, animated: true)
    }
}
