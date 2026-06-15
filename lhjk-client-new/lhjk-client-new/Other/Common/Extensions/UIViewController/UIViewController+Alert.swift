import UIKit

extension UIViewController {
    /// 展示系统 Alert
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息内容
    ///   - actions: 操作按钮，默认包含"确定"
    func showAlert(
        title: String?,
        message: String?,
        actions: [UIAlertAction]? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        if let actions = actions, !actions.isEmpty {
            actions.forEach { alert.addAction($0) }
        } else {
            alert.addAction(UIAlertAction(title: "确定", style: .default))
        }
        present(alert, animated: true)
    }
}
