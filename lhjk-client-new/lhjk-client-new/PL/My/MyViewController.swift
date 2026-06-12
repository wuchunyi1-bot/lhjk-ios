import UIKit
import SnapKit

/// 我的模块入口
final class MyViewController: BaseViewController {
    override func setupUI() {
        title = "我的"
        view.backgroundColor = .systemBackground

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        view.addSubview(stack)

        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        let avatarLabel = UILabel()
        avatarLabel.text = "👤"
        avatarLabel.font = .systemFont(ofSize: 60)
        avatarLabel.textAlignment = .center
        stack.addArrangedSubview(avatarLabel)

        let nameLabel = UILabel()
        nameLabel.text = "用户"
        nameLabel.font = .systemFont(ofSize: 20, weight: .medium)
        nameLabel.textColor = .label
        stack.addArrangedSubview(nameLabel)

        let logoutButton = UIButton(type: .system)
        logoutButton.setTitle("退出登录", for: .normal)
        logoutButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.backgroundColor = .systemRed
        logoutButton.layer.cornerRadius = 8
        logoutButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 40, bottom: 12, right: 40)
        logoutButton.addAction(UIAction { [weak self] _ in
            self?.handleLogout()
        }, for: .touchUpInside)
        stack.addArrangedSubview(logoutButton)
    }

    private func handleLogout() {
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .fullScreen
        present(loginVC, animated: true)
    }
}
