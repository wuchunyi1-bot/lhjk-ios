import UIKit

/// 账号安全页
/// 参考 funde-client: prototype/src/views/me/settings/SecuritySettingsView.vue
/// PRD: 02_用户_我的设置_v1.0 §5.2
///
/// 橙色渐变状态卡片 + 4 个链接行：
///   手机号 → /me/change-phone
///   登录密码 → 验证手机号后设置/修改密码
///   微信授权 → 绑定/解绑（确认弹窗）
///   注销账户 → /me/settings/cancel-account
final class SecuritySettingsViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private var phoneValueLabel: UILabel?
    private var passwordValueLabel: UILabel?
    private var wechatValueLabel: UILabel?
    private var statusTitle: UILabel?
    private var statusDesc: UILabel?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        loadUserData()
    }

    private func loadUserData() {
        let mobile = UserDefaults.standard.string(forKey: "current_user_mobile") ?? ""
        guard !mobile.isEmpty else { return }
        Task { [weak self] in
            guard let self else { return }
            if let user = try? await UserService.shared.getUserByParam(mobile: mobile) {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    let hasPhone = user.mobile != nil && user.mobile!.count >= 11
                    self.phoneValueLabel?.text = self.maskPhone(user.mobile)
                    self.statusTitle?.text = hasPhone ? "账号安全状态良好" : "建议绑定手机号"
                    self.statusDesc?.text = hasPhone ? "手机号已绑定，建议定期更新登录密码。" : "绑定手机号后可提升账号安全性。"
                    // WeChat mock state
                    self.wechatValueLabel?.text = UserDefaults.standard.string(forKey: "fd_wechat_nickname") ?? "未绑定"
                }
            }
        }
    }

    private func maskPhone(_ phone: String?) -> String {
        guard let phone = phone, phone.count == 11 else { return phone ?? "未绑定" }
        return "\(phone.prefix(3))****\(phone.suffix(4))"
    }

    override func setupUI() {
        title = "账号安全"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        // MARK: Status Card (orange gradient)

        let statusTitleLabel = UILabel()
        statusTitleLabel.text = "加载中…"
        statusTitleLabel.font = .fdFont(ofSize: 19, weight: .heavy)
        statusTitleLabel.textColor = .white
        self.statusTitle = statusTitleLabel

        let statusDescLabel = UILabel()
        statusDescLabel.text = ""
        statusDescLabel.font = .fdCaption
        statusDescLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        self.statusDesc = statusDescLabel

        let statusCard: UIView = {
            let v = UIView()
            v.layer.cornerRadius = 24
            v.clipsToBounds = true
            let gradient = CAGradientLayer()
            gradient.colors = [UIColor(hexString: "#FF7A50").cgColor, UIColor(hexString: "#FFAA80").cgColor]
            gradient.startPoint = CGPoint(x: 0, y: 0); gradient.endPoint = CGPoint(x: 1, y: 1)
            v.layer.insertSublayer(gradient, at: 0)
            v.layer.setValue(gradient, forKey: "statusGradient")
            v.addSubview(statusTitleLabel); v.addSubview(statusDescLabel)
            statusTitleLabel.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(18) }
            statusDescLabel.snp.makeConstraints { $0.top.equalTo(statusTitleLabel.snp.bottom).offset(8); $0.leading.trailing.bottom.equalToSuperview().inset(18) }
            return v
        }()

        contentView.addSubview(statusCard)
        statusCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        // MARK: Rows Card

        let phoneLabel = UILabel()
        phoneLabel.text = "加载中…"
        phoneLabel.font = .fdCaption
        phoneLabel.textColor = .fdSubtext
        self.phoneValueLabel = phoneLabel

        let pwdLabel = makeStaticValueLabel("去设置")
        self.passwordValueLabel = pwdLabel

        let wechatLabel = UILabel()
        wechatLabel.text = "未绑定"
        wechatLabel.font = .fdCaption
        wechatLabel.textColor = .fdSubtext
        self.wechatValueLabel = wechatLabel

        let items: [(label: String, valueView: UIView, action: Selector)] = [
            ("手机号", phoneLabel, #selector(handlePhoneTap)),
            ("登录密码", pwdLabel, #selector(handlePasswordTap)),
            ("微信授权", wechatLabel, #selector(handleWechatTap)),
            ("注销账户", makeStaticValueLabel("注销后账号无法找回"), #selector(handleCancelAccountTap)),
        ]

        let card = buildCard()
        let stack = UIStackView(); stack.axis = .vertical
        card.addSubview(stack); stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        for (i, item) in items.enumerated() {
            let row = makeLinkRow(label: item.label, valueView: item.valueView, showDivider: i < items.count - 1, action: item.action)
            stack.addArrangedSubview(row)
        }

        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalTo(statusCard.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for sv in contentView.subviews {
            if let gradient = sv.layer.value(forKey: "statusGradient") as? CAGradientLayer {
                gradient.frame = sv.bounds
            }
        }
    }

    // MARK: - Card & Row Builders

    private func buildCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        return card
    }

    private func makeStaticValueLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .fdCaption
        l.textColor = .fdSubtext
        return l
    }

    private func makeLinkRow(label: String, valueView: UIView, showDivider: Bool, action: Selector) -> UIView {
        let row = UIView(); row.isUserInteractionEnabled = true
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))

        let titleLbl = UILabel()
        titleLbl.text = label
        titleLbl.font = .fdBody
        titleLbl.textColor = .fdText

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .fdMuted; arrow.contentMode = .scaleAspectFit

        [titleLbl, valueView, arrow].forEach(row.addSubview)
        arrow.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview(); $0.size.equalTo(16) }
        valueView.snp.makeConstraints { $0.trailing.equalTo(arrow.snp.leading).offset(-4); $0.centerY.equalToSuperview() }
        titleLbl.snp.makeConstraints { $0.leading.equalToSuperview().inset(16); $0.centerY.equalToSuperview(); $0.trailing.lessThanOrEqualTo(valueView.snp.leading).offset(-8) }

        if showDivider {
            let divider = UIView(); divider.backgroundColor = .fdBorder
            row.addSubview(divider)
            divider.snp.makeConstraints { $0.leading.equalTo(titleLbl); $0.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
        }
        row.snp.makeConstraints { $0.height.equalTo(48) }
        return row
    }

    // MARK: - Actions

    @objc private func handlePhoneTap() {
        Router.shared.push("/me/change-phone")
    }

    @objc private func handlePasswordTap() {
        // Navigate to password setup flow (placeholder)
        Router.shared.push("/me/settings/security/password")
    }

    @objc private func handleWechatTap() {
        let isBound = UserDefaults.standard.string(forKey: "fd_wechat_nickname") != nil
        if isBound {
            let alert = UIAlertController(title: "是否解绑微信账号？", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "立即解绑", style: .destructive) { [weak self] _ in
                UserDefaults.standard.removeObject(forKey: "fd_wechat_nickname")
                self?.wechatValueLabel?.text = "未绑定"
                self?.showToast("微信已解绑")
            })
            present(alert, animated: true)
        } else {
            // Mock bind — in production this would invoke WeChat SDK
            UserDefaults.standard.set("微信用户", forKey: "fd_wechat_nickname")
            wechatValueLabel?.text = "微信用户"
            showToast("微信已绑定")
        }
    }

    @objc private func handleCancelAccountTap() {
        Router.shared.push("/me/settings/cancel-account")
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
