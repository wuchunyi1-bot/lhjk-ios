import UIKit
import SnapKit

/// 微信授权 — 对齐 PRD-205 / WechatAuthorizationView.vue
final class WechatAuthorizationViewController: BaseViewController {

    private let wechatNicknameKey = "fd_wechat_nickname"

    private let statusTitleLabel = UILabel()
    private let statusDescLabel = UILabel()
    private let actionDescLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        refresh()
    }

    override func setupUI() {
        title = "微信授权"
        view.backgroundColor = .fdBg

        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)
        scroll.snp.makeConstraints { $0.edges.equalToSuperview() }

        let content = UIView()
        scroll.addSubview(content)
        content.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        // Status card
        let statusCard = UIView()
        statusCard.backgroundColor = .fdSurface
        statusCard.layer.cornerRadius = 12
        statusCard.layer.shadowColor = UIColor.black.cgColor
        statusCard.layer.shadowOffset = CGSize(width: 0, height: 1)
        statusCard.layer.shadowRadius = 6
        statusCard.layer.shadowOpacity = 0.03
        content.addSubview(statusCard)
        statusCard.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        let iconBg = UIView()
        iconBg.backgroundColor = .fdPrimarySoft
        iconBg.layer.cornerRadius = 14
        let icon = UIImageView(image: UIImage(systemName: "message.fill"))
        icon.tintColor = .fdPrimary
        icon.contentMode = .scaleAspectFit
        iconBg.addSubview(icon)
        icon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(22)
        }

        statusTitleLabel.font = .fdMyBodySemibold
        statusTitleLabel.textColor = .fdText
        statusDescLabel.font = .fdMyCaption
        statusDescLabel.textColor = .fdSubtext
        statusDescLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [statusTitleLabel, statusDescLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        statusCard.addSubview(iconBg)
        statusCard.addSubview(textStack)
        iconBg.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(48)
            $0.top.greaterThanOrEqualToSuperview().offset(18)
            $0.bottom.lessThanOrEqualToSuperview().offset(-18)
        }
        textStack.snp.makeConstraints {
            $0.leading.equalTo(iconBg.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(18)
            $0.bottom.equalToSuperview().offset(-18)
        }

        // Action card
        let actionCard = UIView()
        actionCard.backgroundColor = .fdSurface
        actionCard.layer.cornerRadius = 12
        content.addSubview(actionCard)
        actionCard.snp.makeConstraints {
            $0.top.equalTo(statusCard.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-24)
        }

        let actionTitle = UILabel()
        actionTitle.text = "微信快捷登录"
        actionTitle.font = .fdMyBodySemibold
        actionTitle.textColor = .fdText

        actionDescLabel.font = .fdMyBody
        actionDescLabel.textColor = .fdSubtext
        actionDescLabel.numberOfLines = 0

        actionButton.titleLabel?.font = .fdMyBodySemibold
        actionButton.layer.cornerRadius = 22
        actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)

        actionCard.addSubview(actionTitle)
        actionCard.addSubview(actionDescLabel)
        actionCard.addSubview(actionButton)
        actionTitle.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(16)
        }
        actionDescLabel.snp.makeConstraints {
            $0.top.equalTo(actionTitle.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        actionButton.snp.makeConstraints {
            $0.top.equalTo(actionDescLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
            $0.bottom.equalToSuperview().offset(-16)
        }

        refresh()
    }

    private var nickname: String {
        UserDefaults.standard.string(forKey: wechatNicknameKey) ?? ""
    }

    private func refresh() {
        let bound = !nickname.isEmpty
        statusTitleLabel.text = bound ? "微信已绑定" : "尚未绑定微信"
        statusDescLabel.text = bound
            ? "当前微信：\(nickname)"
            : "绑定后可使用微信快捷登录富德健康。"
        actionDescLabel.text = bound
            ? "如不再使用当前微信快捷登录，可解除绑定。"
            : "绑定微信后，下次可直接使用微信登录，无需重复输入手机号。"

        if bound {
            actionButton.setTitle("解绑微信", for: .normal)
            actionButton.setTitleColor(.fdPrimary, for: .normal)
            actionButton.backgroundColor = .fdSurface
            actionButton.layer.borderWidth = 1
            actionButton.layer.borderColor = UIColor.fdPrimary.cgColor
        } else {
            actionButton.setTitle("绑定微信", for: .normal)
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.backgroundColor = .fdPrimary
            actionButton.layer.borderWidth = 0
        }
    }

    @objc private func handleAction() {
        if nickname.isEmpty {
            UserDefaults.standard.set("富德健康用户", forKey: wechatNicknameKey)
            refresh()
            showToast("微信已绑定")
        } else {
            let alert = UIAlertController(
                title: "确认解绑微信？",
                message: "解绑后，将不能使用当前微信快捷登录富德健康。",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "暂不解绑", style: .cancel))
            alert.addAction(UIAlertAction(title: "确认解绑", style: .destructive) { [weak self] _ in
                UserDefaults.standard.removeObject(forKey: self?.wechatNicknameKey ?? "")
                self?.refresh()
                self?.showToast("微信已解绑")
            })
            present(alert, animated: true)
        }
    }

    private func showToast(_ message: String) {
        showToastAlert(message, duration: 1.5)
    }
}
