import UIKit

/// 关于我们页
/// 参考 funde-client: prototype/src/views/me/settings/AboutSettingsView.vue
/// PRD: 02_用户_我的设置_v1.0 §5.13
///
/// 居中 Logo + 品牌名 + slogan + 版本号
/// + 功能卡片（版本检查 / 应用市场评分 / 客服电话）
/// + 法律链接（用户协议 / 隐私政策 / 知情同意书）
/// + 版权 + 备案信息
final class AboutSettingsViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "关于我们"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        // MARK: Logo + Brand

        let logoView: UIView = {
            let v = UIView()
            let gradient = CAGradientLayer()
            gradient.colors = [UIColor(hexString: "#FF7A50").cgColor, UIColor(hexString: "#FFAA80").cgColor]
            gradient.startPoint = CGPoint(x: 0, y: 0); gradient.endPoint = CGPoint(x: 1, y: 1)
            gradient.cornerRadius = 18
            v.layer.insertSublayer(gradient, at: 0)
            v.layer.cornerRadius = 18
            v.clipsToBounds = true
            let charLabel = UILabel()
            charLabel.text = "富"
            charLabel.font = .fdFont(ofSize: 30, weight: .heavy)
            charLabel.textColor = .white
            v.addSubview(charLabel)
            charLabel.snp.makeConstraints { $0.center.equalToSuperview() }
            v.layer.setValue(gradient, forKey: "logoGradient")
            return v
        }()

        let nameLabel: UILabel = {
            let l = UILabel()
            l.text = "富德健康"
            l.font = .fdH2
            l.textColor = .fdText
            l.textAlignment = .center
            return l
        }()

        let sloganLabel: UILabel = {
            let l = UILabel()
            l.text = "健康生命 · 美好生活"
            l.font = .fdCaption
            l.textColor = .fdSubtext
            l.textAlignment = .center
            return l
        }()

        let versionLabel: UILabel = {
            let l = UILabel()
            l.text = "当前版本 v 2.6.1"
            l.font = .fdCaption
            l.textColor = .fdSubtext
            l.textAlignment = .center
            l.isUserInteractionEnabled = true
            l.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleVersionTap)))
            return l
        }()

        [logoView, nameLabel, sloganLabel, versionLabel].forEach(contentView.addSubview)
        logoView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.centerX.equalToSuperview()
            make.size.equalTo(68)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(logoView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
        sloganLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
        versionLabel.snp.makeConstraints { make in
            make.top.equalTo(sloganLabel.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
        }

        // MARK: Card 1 — Features

        let card1 = buildCard()
        let stack1 = UIStackView(); stack1.axis = .vertical
        card1.addSubview(stack1); stack1.snp.makeConstraints { $0.edges.equalToSuperview() }

        let featureItems: [(label: String, value: String?, showArrow: Bool, action: Selector)] = [
            ("当前版本", "v 2.6.1", true, #selector(handleVersionTap)),
            ("去应用市场评分", nil, true, #selector(handleRatingTap)),
            ("联系我们", "400-888-6520", false, #selector(noop)),
        ]
        for (i, item) in featureItems.enumerated() {
            stack1.addArrangedSubview(makeLinkRow(
                label: item.label, value: item.value, showArrow: item.showArrow,
                showDivider: i < featureItems.count - 1, action: item.action
            ))
        }

        contentView.addSubview(card1)
        card1.snp.makeConstraints { make in
            make.top.equalTo(versionLabel.snp.bottom).offset(22)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        // MARK: Card 2 — Legal Links

        let card2 = buildCard()
        let stack2 = UIStackView(); stack2.axis = .vertical
        card2.addSubview(stack2); stack2.snp.makeConstraints { $0.edges.equalToSuperview() }

        let legalItems: [(label: String, action: Selector)] = [
            ("用户服务协议", #selector(handleUserAgreementTap)),
            ("隐私政策", #selector(handlePrivacyPolicyTap)),
            ("健康管理服务知情同意书", #selector(handleConsentTap)),
        ]
        for (i, item) in legalItems.enumerated() {
            stack2.addArrangedSubview(makeLinkRow(
                label: item.label, value: nil, showArrow: true,
                showDivider: i < legalItems.count - 1, action: item.action
            ))
        }

        contentView.addSubview(card2)
        card2.snp.makeConstraints { make in
            make.top.equalTo(card1.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        // MARK: Card 3 — ICP + Copyright

        let card3 = buildCard()
        let stack3 = UIStackView(); stack3.axis = .vertical
        card3.addSubview(stack3); stack3.snp.makeConstraints { $0.edges.equalToSuperview() }

        let icpRow = makeLinkRow(label: "备案信息", value: "粤ICP备示例号", showArrow: false, showDivider: true, action: #selector(noop))
        stack3.addArrangedSubview(icpRow)

        let copyrightRow = makeLinkRow(label: "版权信息", value: "Copyright © 2026 富德健康", showArrow: false, showDivider: false, action: #selector(noop))
        stack3.addArrangedSubview(copyrightRow)

        contentView.addSubview(card3)
        card3.snp.makeConstraints { make in
            make.top.equalTo(card2.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-32)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for sv in contentView.subviews {
            if let gradient = sv.layer.value(forKey: "logoGradient") as? CAGradientLayer {
                gradient.frame = sv.bounds
            }
        }
    }

    // MARK: - Builders

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

    private func makeLinkRow(label: String, value: String?, showArrow: Bool, showDivider: Bool, action: Selector) -> UIView {
        let row = UIView(); row.isUserInteractionEnabled = true
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))

        let titleLbl = UILabel()
        titleLbl.text = label
        titleLbl.font = .fdBody
        titleLbl.textColor = .fdText

        row.addSubview(titleLbl)
        titleLbl.snp.makeConstraints { $0.leading.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }

        if let value = value {
            let valueLbl = UILabel()
            valueLbl.text = value
            valueLbl.font = .fdCaption
            valueLbl.textColor = .fdSubtext
            row.addSubview(valueLbl)
            valueLbl.snp.makeConstraints { $0.trailing.equalToSuperview().offset(showArrow ? -40 : -16); $0.centerY.equalToSuperview() }
            titleLbl.snp.makeConstraints { $0.trailing.lessThanOrEqualTo(valueLbl.snp.leading).offset(-8) }
        }

        if showArrow {
            let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
            arrow.tintColor = .fdMuted; arrow.contentMode = .scaleAspectFit
            row.addSubview(arrow)
            arrow.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview(); $0.size.equalTo(16) }
        }

        if showDivider {
            let divider = UIView(); divider.backgroundColor = .fdBorder
            row.addSubview(divider)
            divider.snp.makeConstraints { $0.leading.equalTo(titleLbl); $0.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
        }
        row.snp.makeConstraints { $0.height.equalTo(48) }
        return row
    }

    // MARK: - Actions

    @objc private func noop() {}

    @objc private func handleVersionTap() {
        showToast("当前已经是最新版本")
    }

    @objc private func handleRatingTap() {
        showToast("功能开发中")
    }

    @objc private func handleUserAgreementTap() {
        showDialog(title: "用户服务协议", message: "这里是《用户服务协议》的完整内容。\n\n在原型阶段，此处展示协议摘要。\n\n正式上线前需替换为法务/合规审核后的完整文本。")
    }

    @objc private func handlePrivacyPolicyTap() {
        showDialog(title: "隐私政策", message: "这里是《隐私政策》的完整内容。\n\n在原型阶段，此处展示协议摘要。\n\n正式上线前需替换为法务/合规审核后的完整文本。")
    }

    @objc private func handleConsentTap() {
        showDialog(title: "健康管理服务知情同意书", message: "这里是《健康管理服务知情同意书》的完整内容。\n\n在原型阶段，此处展示协议摘要。\n\n正式上线前需替换为法务/合规审核后的完整文本。")
    }

    private func showDialog(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "关闭", style: .default))
        present(alert, animated: true)
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
