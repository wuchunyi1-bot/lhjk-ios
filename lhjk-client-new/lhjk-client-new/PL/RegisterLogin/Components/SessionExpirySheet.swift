import UIKit
import SnapKit

/// 登录状态已过期全局弹窗 — 对齐 funde `MobileApp.vue` session-sheet / PRD AUTH-11
final class SessionExpirySheet: UIViewController {

    var onRelogin: (() -> Void)?

    private let message: String
    private let dimView = UIView()
    private let panel = UIView()

    init(message: String = SessionExpiryCoordinator.defaultMessage) {
        self.message = message
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    private func buildUI() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }
        // 遮罩不可关闭（PRD EXPIRED-F001）

        panel.backgroundColor = .fdSurface
        panel.layer.cornerRadius = 20
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(panel)
        panel.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }

        let badge = UIView()
        badge.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.12)
        badge.layer.cornerRadius = 20

        let badgeIcon = UIImageView(image: UIImage(systemName: "exclamationmark.shield.fill"))
        badgeIcon.tintColor = .fdPrimary
        badgeIcon.contentMode = .scaleAspectFit
        badge.addSubview(badgeIcon)
        badgeIcon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(26)
        }
        badge.snp.makeConstraints { $0.width.height.equalTo(56) }

        let title = UILabel()
        title.text = "登录状态已过期"
        title.font = .fdMyH3
        title.textColor = .fdText
        title.textAlignment = .center

        let desc = UILabel()
        desc.text = message
        desc.font = .fdLoginMeta
        desc.textColor = .fdSubtext
        desc.textAlignment = .center
        desc.numberOfLines = 0

        let button = UIButton(type: .system)
        button.setTitle("重新登录", for: .normal)
        button.titleLabel?.font = .fdLoginInput
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .fdPrimary
        button.layer.cornerRadius = 14
        button.addTarget(self, action: #selector(tapRelogin), for: .touchUpInside)
        button.snp.makeConstraints { $0.height.equalTo(48) }

        let stack = UIStackView(arrangedSubviews: [badge, title, desc, button])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10
        stack.setCustomSpacing(14, after: badge)
        stack.setCustomSpacing(18, after: desc)

        panel.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(panel.safeAreaLayoutGuide).offset(-16)
        }
        button.snp.makeConstraints { $0.leading.trailing.equalToSuperview() }
    }

    @objc private func tapRelogin() {
        let action = onRelogin
        dismiss(animated: true) {
            action?()
        }
    }
}
