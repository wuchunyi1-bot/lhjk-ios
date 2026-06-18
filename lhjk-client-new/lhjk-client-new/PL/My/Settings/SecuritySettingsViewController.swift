import UIKit

/// 账号安全页
/// 参考 funde-client: prototype/src/views/me/settings/SecuritySettingsView.vue
///
/// 橙色渐变状态卡片 + 4 个链接行包裹在一张 fd-card 内：
///   绑定手机号 / 修改登录密码 / 实名认证 / 登录设备管理
final class SecuritySettingsViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "账号安全"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        // Status card (orange gradient)
        let statusCard: UIView = {
            let v = UIView()
            v.layer.cornerRadius = 24
            v.clipsToBounds = true

            let gradient = CAGradientLayer()
            gradient.colors = [UIColor(hexString: "#FF7A50").cgColor, UIColor(hexString: "#FFAA80").cgColor]
            gradient.startPoint = CGPoint(x: 0, y: 0); gradient.endPoint = CGPoint(x: 1, y: 1)
            v.layer.insertSublayer(gradient, at: 0)

            let title = UILabel()
            title.text = "账号安全状态良好"
            title.font = .fdFont(ofSize: 19, weight: .heavy)
            title.textColor = .white

            let desc = UILabel()
            desc.text = "手机号已绑定，建议定期更新登录密码。"
            desc.font = .fdCaption
            desc.textColor = UIColor.white.withAlphaComponent(0.9)

            v.addSubview(title); v.addSubview(desc)
            title.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(18) }
            desc.snp.makeConstraints { $0.top.equalTo(title.snp.bottom).offset(8); $0.leading.trailing.bottom.equalToSuperview().inset(18) }

            // Store gradient for layout update
            v.layer.setValue(gradient, forKey: "statusGradient")
            return v
        }()

        contentView.addSubview(statusCard)
        statusCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        // Link rows card
        let items: [(label: String, value: String)] = [
            ("绑定手机号", "188****6520"),
            ("修改登录密码", "去设置"),
            ("实名认证", "已认证"),
            ("登录设备管理", "2 台设备"),
        ]

        let card = buildCard()
        let stack = UIStackView(); stack.axis = .vertical
        card.addSubview(stack); stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        for (i, item) in items.enumerated() {
            let row = makeLinkRow(label: item.label, value: item.value, showDivider: i < items.count - 1)
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
        // Update gradient frame
        for sv in contentView.subviews {
            if let gradient = sv.layer.value(forKey: "statusGradient") as? CAGradientLayer {
                gradient.frame = sv.bounds
            }
        }
    }

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

    private func makeLinkRow(label: String, value: String, showDivider: Bool) -> UIView {
        let row = UIView()

        let titleLbl = UILabel()
        titleLbl.text = label
        titleLbl.font = .fdBody
        titleLbl.textColor = .fdText

        let valueLbl = UILabel()
        valueLbl.text = value
        valueLbl.font = .fdCaption
        valueLbl.textColor = .fdSubtext

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .fdMuted; arrow.contentMode = .scaleAspectFit

        [titleLbl, valueLbl, arrow].forEach(row.addSubview)
        arrow.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview(); $0.size.equalTo(16) }
        valueLbl.snp.makeConstraints { $0.trailing.equalTo(arrow.snp.leading).offset(-4); $0.centerY.equalToSuperview() }
        titleLbl.snp.makeConstraints { $0.leading.equalToSuperview().inset(16); $0.centerY.equalToSuperview(); $0.trailing.lessThanOrEqualTo(valueLbl.snp.leading).offset(-8) }

        if showDivider {
            let divider = UIView(); divider.backgroundColor = .fdBorder
            row.addSubview(divider)
            divider.snp.makeConstraints { $0.leading.equalTo(titleLbl); $0.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
        }
        row.snp.makeConstraints { $0.height.equalTo(48) }
        return row
    }
}
