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

    /// 短时提示（带「确定」按钮，避免系统默认英文 OK）
    func showToastAlert(_ message: String, duration: TimeInterval = 1.2, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        var didFinish = false
        let finish: () -> Void = {
            guard !didFinish else { return }
            didFinish = true
            completion?()
        }
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            alert.dismiss(animated: true, completion: finish)
        })
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            alert.dismiss(animated: true, completion: finish)
        }
    }
}
