import UIKit

/// 关于页
/// 参考 funde-client: prototype/src/views/me/settings/AboutSettingsView.vue
///
/// 居中 logo（橙色渐变方块 68×68） + 品牌名 + 版本号
/// + 4 个链接行包裹在一张 fd-card 内：
///   用户服务协议 / 隐私政策 / 客服电话 / 备案信息
final class AboutSettingsViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "关于"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        // Logo area
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

        let versionLabel: UILabel = {
            let l = UILabel()
            l.text = "当前版本 v 2.6.1"
            l.font = .fdCaption
            l.textColor = .fdSubtext
            l.textAlignment = .center
            return l
        }()

        [logoView, nameLabel, versionLabel].forEach(contentView.addSubview)
        logoView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.centerX.equalToSuperview()
            make.size.equalTo(68)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(logoView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
        versionLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
        }

        // Link rows
        let items: [(label: String, value: String?, showArrow: Bool)] = [
            ("用户服务协议", nil, true),
            ("隐私政策", nil, true),
            ("客服电话", "400-888-6520", false),
            ("备案信息", "粤ICP备示例号", false),
        ]

        let card = buildCard()
        let stack = UIStackView(); stack.axis = .vertical
        card.addSubview(stack); stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        for (i, item) in items.enumerated() {
            let row = makeLinkRow(label: item.label, value: item.value, showArrow: item.showArrow, showDivider: i < items.count - 1)
            stack.addArrangedSubview(row)
        }

        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalTo(versionLabel.snp.bottom).offset(22)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
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

    private func makeLinkRow(label: String, value: String?, showArrow: Bool, showDivider: Bool) -> UIView {
        let row = UIView()

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
}
