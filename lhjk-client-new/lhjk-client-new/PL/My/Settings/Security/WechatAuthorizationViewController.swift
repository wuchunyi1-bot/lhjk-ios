import UIKit
import SnapKit

/// 微信授权 — 对齐 Figma「微信授权」与 PRD-205
final class WechatAuthorizationViewController: BaseViewController {

    private enum Layout {
        static let cardCornerRadius: CGFloat = 16
        static let cardInset: CGFloat = 16
        static let cardSpacing: CGFloat = 12
        static let cardMinHeight: CGFloat = 64
        static let cardPadding: CGFloat = 12
        static let iconContainerSize: CGFloat = 38
        static let iconSize: CGFloat = 30
        static let iconTextGap: CGFloat = 11
        static let textStackSpacing: CGFloat = 4
        static let actionButtonSize = CGSize(width: 70, height: 28)
        static let actionButtonCornerRadius: CGFloat = 14
        static let actionButtonBorderWidth: CGFloat = 0.5
    }

    private enum Typography {
        static let cardTitle = SettingsStyle.rowTitleFont
        static let cardSubtitle = SettingsStyle.rowSubtitleFont
        static let actionButton = UIFont.fdFont(ofSize: 16, weight: .medium)
    }

    private var isBound: Bool = false
    private var isLoading: Bool = false

    private let statusTitleLabel = UILabel()
    private let statusDescLabel = UILabel()
    private let actionDescLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        fetchBindStatus()
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

        let statusCard = makeStatusCard()
        content.addSubview(statusCard)
        statusCard.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(Layout.cardInset)
            $0.height.greaterThanOrEqualTo(Layout.cardMinHeight)
        }

        let actionCard = makeActionCard()
        content.addSubview(actionCard)
        actionCard.snp.makeConstraints {
            $0.top.equalTo(statusCard.snp.bottom).offset(Layout.cardSpacing)
            $0.leading.trailing.equalToSuperview().inset(Layout.cardInset)
            $0.height.greaterThanOrEqualTo(Layout.cardMinHeight)
            $0.bottom.equalToSuperview().offset(-24)
        }

        refresh()
    }

    private func makeStatusCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = Layout.cardCornerRadius
        card.clipsToBounds = true

        let iconBg = UIView()
        iconBg.backgroundColor = .fdBg
        iconBg.layer.cornerRadius = Layout.iconContainerSize / 2

        let icon = UIImageView(image: UIImage(named: "login_wechat"))
        icon.contentMode = .scaleAspectFit
        iconBg.addSubview(icon)
        icon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(Layout.iconSize)
        }

        statusTitleLabel.font = Typography.cardTitle
        statusTitleLabel.textColor = SettingsStyle.titleColor
        statusDescLabel.font = Typography.cardSubtitle
        statusDescLabel.textColor = SettingsStyle.subtitleColor
        statusDescLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [statusTitleLabel, statusDescLabel])
        textStack.axis = .vertical
        textStack.spacing = Layout.textStackSpacing
        textStack.alignment = .leading

        card.addSubview(iconBg)
        card.addSubview(textStack)

        iconBg.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Layout.cardPadding)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(Layout.iconContainerSize)
            $0.top.greaterThanOrEqualToSuperview().offset(Layout.cardPadding)
            $0.bottom.lessThanOrEqualToSuperview().offset(-Layout.cardPadding)
        }
        textStack.snp.makeConstraints {
            $0.leading.equalTo(iconBg.snp.trailing).offset(Layout.iconTextGap)
            $0.trailing.equalToSuperview().offset(-Layout.cardPadding)
            $0.centerY.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview().offset(Layout.cardPadding)
            $0.bottom.lessThanOrEqualToSuperview().offset(-Layout.cardPadding)
        }

        return card
    }

    private func makeActionCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = Layout.cardCornerRadius
        card.clipsToBounds = true

        let actionTitleLabel = UILabel()
        actionTitleLabel.text = "微信快捷登录"
        actionTitleLabel.font = Typography.cardTitle
        actionTitleLabel.textColor = SettingsStyle.titleColor

        actionDescLabel.font = Typography.cardSubtitle
        actionDescLabel.textColor = SettingsStyle.subtitleColor
        actionDescLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [actionTitleLabel, actionDescLabel])
        textStack.axis = .vertical
        textStack.spacing = Layout.textStackSpacing
        textStack.alignment = .leading

        actionButton.titleLabel?.font = Typography.actionButton
        actionButton.layer.cornerRadius = Layout.actionButtonCornerRadius
        actionButton.clipsToBounds = true
        actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)

        card.addSubview(textStack)
        card.addSubview(actionButton)

        actionButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-Layout.cardPadding)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(Layout.actionButtonSize)
        }
        textStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Layout.cardPadding)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(actionButton.snp.leading).offset(-8)
            $0.top.greaterThanOrEqualToSuperview().offset(Layout.cardPadding)
            $0.bottom.lessThanOrEqualToSuperview().offset(-Layout.cardPadding)
        }

        return card
    }

    /// 查询微信绑定状态：`GET /v1/users/getWechatBindStatus`
    private func fetchBindStatus() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let status = try await UserService.shared.getWechatBindStatus()
                let bound = status.bound ?? false
                await MainActor.run {
                    self.isBound = bound
                    self.refresh()
                }
            } catch {
                print("[WechatAuth] fetchBindStatus ✗ \(error.localizedDescription)")
            }
        }
    }

    private func refresh() {
        statusTitleLabel.text = isBound ? "微信已绑定" : "尚未绑定微信"
        statusDescLabel.text = "绑定后可使用微信快捷登录富德健康"
        actionDescLabel.text = isBound
            ? "如不再使用当前微信快捷登录，可解除绑定"
            : "绑定微信后，下次可直接使用微信登录，无需重复输入手机号"

        if isBound {
            actionButton.setTitle("解绑", for: .normal)
            actionButton.setTitleColor(.fdPrimary, for: .normal)
            actionButton.backgroundColor = .fdSurface
            actionButton.layer.borderWidth = Layout.actionButtonBorderWidth
            actionButton.layer.borderColor = UIColor.fdPrimary.cgColor
        } else {
            actionButton.setTitle("绑定", for: .normal)
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.backgroundColor = .fdPrimary
            actionButton.layer.borderWidth = 0
            actionButton.layer.borderColor = nil
        }
    }

    @objc private func handleAction() {
        if isBound {
            showUnbindConfirmAlert()
        } else {
            performBind()
        }
    }

    /// 绑定微信：调用微信 SDK 获取 Auth Code，再调用 `POST /v1/users/bindWechat`
    private func performBind() {
        guard !isLoading else { return }

        if !WeChatSDKManager.shared.isWeChatInstalled {
            showToast("当前设备未安装微信")
            return
        }

        isLoading = true
        actionButton.isEnabled = false

        Task { [weak self] in
            guard let self else { return }
            defer {
                Task { @MainActor in
                    self.isLoading = false
                    self.actionButton.isEnabled = true
                }
            }
            do {
                let authResult = try await WeChatSDKManager.shared.sendAuth()
                let code = authResult.code
                try await UserService.shared.bindWechat(code: code)
                await MainActor.run {
                    self.isBound = true
                    self.refresh()
                    self.showToast("微信绑定成功")
                }
                _ = await UserManager.shared.refreshUserInfo()
            } catch let sdkErr as WeChatSDKError {
                await MainActor.run {
                    if sdkErr != .userCancelled {
                        self.showToast(sdkErr.localizedDescription)
                    }
                }
            } catch {
                await MainActor.run {
                    self.showToast(error.localizedDescription)
                }
            }
        }
    }

    private func showUnbindConfirmAlert() {
        let alert = UIAlertController(
            title: "确认解绑微信？",
            message: "解绑后，将不能使用当前微信快捷登录富德健康。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "暂不解绑", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认解绑", style: .destructive) { [weak self] _ in
            self?.performUnbind()
        })
        present(alert, animated: true)
    }

    /// 解除绑定微信：调用 `POST /v1/users/unbindWechat`
    private func performUnbind() {
        guard !isLoading else { return }

        isLoading = true
        actionButton.isEnabled = false

        Task { [weak self] in
            guard let self else { return }
            defer {
                Task { @MainActor in
                    self.isLoading = false
                    self.actionButton.isEnabled = true
                }
            }
            do {
                try await UserService.shared.unbindWechat()
                await MainActor.run {
                    self.isBound = false
                    self.refresh()
                    self.showToast("微信已解绑")
                }
                _ = await UserManager.shared.refreshUserInfo()
            } catch {
                await MainActor.run {
                    self.showToast(error.localizedDescription)
                }
            }
        }
    }

    private func showToast(_ message: String) {
        showToastAlert(message, duration: 1.5)
    }
}
