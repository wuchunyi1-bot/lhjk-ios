import UIKit
import SnapKit

/// 订单底部弹层：键盘顶起面板；点击遮罩仅收起键盘（不关闭弹层）
final class OrderBottomSheetKeyboardSupport {

    private weak var hostView: UIView?
    private var panelBottomConstraint: Constraint?

    func attach(hostView: UIView, panelBottomConstraint: Constraint) {
        self.hostView = hostView
        self.panelBottomConstraint = panelBottomConstraint
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    func dimTapDismissesKeyboardOnly(dimView: UIView) {
        dimView.gestureRecognizers?.forEach { dimView.removeGestureRecognizer($0) }
        dimView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        )
    }

    @objc private func dismissKeyboard() {
        hostView?.endEditing(true)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let hostView,
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curveRaw = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let keyboardInView = hostView.convert(frame, from: nil)
        let overlap = max(0, hostView.bounds.maxY - keyboardInView.minY)
        panelBottomConstraint?.update(offset: -overlap)

        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            hostView.layoutIfNeeded()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
