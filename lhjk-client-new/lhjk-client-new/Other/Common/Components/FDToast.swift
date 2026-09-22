import UIKit
import SnapKit

/// 短时浮层提示。挂在当前 key window 上，不占用系统 Alert。
enum FDToast {
    private static let viewTag = 9_014_022
    private static var generation = 0

    static func show(_ message: String, duration: TimeInterval = 1.5) {
        let text = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let present = {
            guard let window = keyWindow() else { return }
            generation += 1
            let token = generation
            window.viewWithTag(viewTag)?.removeFromSuperview()

            let container = UIView()
            container.tag = viewTag
            container.isUserInteractionEnabled = false
            container.backgroundColor = UIColor.black.withAlphaComponent(0.75)
            container.layer.cornerRadius = 8
            container.alpha = 0

            let label = UILabel()
            label.text = text
            label.font = .fdFont(ofSize: 14, weight: .regular)
            label.textColor = .white
            label.textAlignment = .center
            label.numberOfLines = 0
            container.addSubview(label)
            label.snp.makeConstraints {
                $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16))
            }

            window.addSubview(container)
            container.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.centerY.equalToSuperview()
                $0.leading.greaterThanOrEqualToSuperview().offset(48)
                $0.trailing.lessThanOrEqualToSuperview().offset(-48)
            }

            UIView.animate(withDuration: 0.2) {
                container.alpha = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                guard token == generation, container.superview != nil else { return }
                UIView.animate(withDuration: 0.25, animations: {
                    container.alpha = 0
                }, completion: { _ in
                    guard token == generation else { return }
                    container.removeFromSuperview()
                })
            }
        }
        if Thread.isMainThread {
            present()
        } else {
            DispatchQueue.main.async(execute: present)
        }
    }

    private static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}
