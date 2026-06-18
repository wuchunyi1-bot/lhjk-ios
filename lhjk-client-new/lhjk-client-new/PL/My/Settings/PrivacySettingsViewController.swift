import UIKit

/// 隐私设置页
/// 参考 funde-client: prototype/src/views/me/settings/PrivacySettingsView.vue
///
/// 第一张卡：3 个开关行（家人查看 / 健管师授权 / 匿名数据）
/// 第二张卡：3 个链接行（信息清单 / 共享清单 / 撤回授权）
final class PrivacySettingsViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let storageKeys = (
        family: "priv_family",
        advisor: "priv_advisor",
        research: "priv_research"
    )

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "隐私设置"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        // Card 1: Toggle rows
        let toggleItems: [(title: String, subtitle: String, key: String, isOn: Bool)] = [
            ("家人查看健康数据", "允许已授权家庭成员查看健康档案和指标",
             storageKeys.family, UserDefaults.standard.object(forKey: storageKeys.family) as? Bool ?? true),
            ("健管师服务授权", "允许服务团队查看履约所需的健康信息",
             storageKeys.advisor, UserDefaults.standard.object(forKey: storageKeys.advisor) as? Bool ?? true),
            ("匿名数据改进服务", "不包含姓名、手机号等个人身份信息",
             storageKeys.research, UserDefaults.standard.object(forKey: storageKeys.research) as? Bool ?? false),
        ]

        let card1 = buildCard()
        let stack1 = UIStackView(); stack1.axis = .vertical
        card1.addSubview(stack1); stack1.snp.makeConstraints { $0.edges.equalToSuperview() }
        for (i, item) in toggleItems.enumerated() {
            let toggle = SettingsToggleCell(
                model: SettingsToggleCell.Model(title: item.title, subtitle: item.subtitle, isOn: item.isOn),
                showDivider: i < toggleItems.count - 1
            )
            toggle.onToggle = { val in UserDefaults.standard.set(val, forKey: item.key) }
            stack1.addArrangedSubview(toggle)
        }

        // Card 2: Link rows
        let linkItems: [(label: String, value: String)] = [
            ("个人信息收集清单", "查看"),
            ("第三方共享清单", "查看"),
            ("撤回全部授权", "谨慎操作"),
        ]
        let card2 = buildCard()
        let stack2 = UIStackView(); stack2.axis = .vertical
        card2.addSubview(stack2); stack2.snp.makeConstraints { $0.edges.equalToSuperview() }
        for (i, item) in linkItems.enumerated() {
            let row = makeLinkRow(label: item.label, value: item.value, showDivider: i < linkItems.count - 1)
            stack2.addArrangedSubview(row)
        }

        contentView.addSubview(card1)
        contentView.addSubview(card2)
        card1.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        card2.snp.makeConstraints { make in
            make.top.equalTo(card1.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
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
        row.isUserInteractionEnabled = true

        let titleLbl = UILabel()
        titleLbl.text = label
        titleLbl.font = .fdBody
        titleLbl.textColor = .fdText

        let valueLbl = UILabel()
        valueLbl.text = value
        valueLbl.font = .fdCaption
        valueLbl.textColor = .fdSubtext

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .fdMuted
        arrow.contentMode = .scaleAspectFit

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
