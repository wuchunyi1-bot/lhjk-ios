import UIKit
import SnapKit

/// 我的模块 Hub 页
/// 参考 funde-client: prototype/src/views/me/MeView.vue
final class MyViewController: BaseViewController {

    // MARK: - Mock Data

    private struct Mock {
        let name = "李秀英"
        let avatarChar = "英"
        let membershipLevel = "健康大会员"
        let stats = [
            ("892", "健康积分", true),
            ("4", "家庭成员", false),
            ("2", "我的保单", false),
            ("Lv.3", "健康等级", false),
        ]
        let fulfillmentStats = [
            ("2", "待使用", true),
            ("1", "使用中", false),
            ("3", "已完成", false),
            ("1", "待评价", false),
        ]
        let services = [
            (icon: "德好", iconBg: "#FF7A50", iconColorHex: "#FFFFFF", name: "慢病逆转管理", status: "进行中", statusType: "success", detail: "服务至 2026/06/30 · 剩 45 天"),
            (icon: "体检", iconBg: "#E6F7EF", iconColorHex: "#1F9A6B", name: "慈铭高端体检 · 三甲套餐", status: "待使用", statusType: "warning", detail: "5 月 23 日 · 上海陆家嘴中心"),
        ]
    }

    private let mock = Mock()

    // MARK: - Constants

    private let sectionPadding: CGFloat = 16

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentView = UIView()

    // MARK: - Lifecycle

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }

        var previousBottom: ConstraintItem = contentView.snp.top

        // 1. Hero
        let heroView = buildHero()
        contentView.addSubview(heroView)
        heroView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        previousBottom = heroView.snp.bottom

        // 2. Membership card
        let memberCard = buildMembershipCard()
        contentView.addSubview(memberCard)
        memberCard.snp.makeConstraints { make in
            make.top.equalTo(previousBottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(sectionPadding)
        }
        previousBottom = memberCard.snp.bottom

        // 3. Stats strip
        let statsView = buildStatsStrip(mock.stats)
        contentView.addSubview(statsView)
        statsView.snp.makeConstraints { make in
            make.top.equalTo(previousBottom)
            make.leading.trailing.equalToSuperview().inset(sectionPadding)
        }
        previousBottom = statsView.snp.bottom

        // 4. Service fulfillment
        let svcView = buildServiceSection()
        contentView.addSubview(svcView)
        svcView.snp.makeConstraints { make in
            make.top.equalTo(previousBottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(sectionPadding)
        }
        previousBottom = svcView.snp.bottom

        // 5. Function groups
        let funcGroupView = buildFunctionGroups()
        contentView.addSubview(funcGroupView)
        funcGroupView.snp.makeConstraints { make in
            make.top.equalTo(previousBottom)
            make.leading.trailing.equalToSuperview()
        }
        previousBottom = funcGroupView.snp.bottom

        // 6. Logout
        let logoutBtn = buildLogoutButton()
        contentView.addSubview(logoutBtn)
        logoutBtn.snp.makeConstraints { make in
            make.top.equalTo(previousBottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(sectionPadding)
            make.height.equalTo(52)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    // MARK: - Hero Section

    private func buildHero() -> UIView {
        let container = UIView()
        container.backgroundColor = .fdBg

        // Profile row
        let avatarView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hexString: "#F4ECE3")
            v.layer.cornerRadius = 32
            let label = UILabel()
            label.text = mock.avatarChar
            label.font = .systemFont(ofSize: 22, weight: .semibold)
            label.textColor = UIColor(hexString: "#7B5E40")
            v.addSubview(label)
            label.snp.makeConstraints { $0.center.equalToSuperview() }
            return v
        }()

        let nameLabel: UILabel = {
            let l = UILabel()
            l.text = mock.name
            l.font = .systemFont(ofSize: 20, weight: .bold)
            l.textColor = .fdText
            return l
        }()

        let settingsBtn: UIButton = {
            let b = UIButton(type: .system)
            b.setImage(UIImage(systemName: "gearshape"), for: .normal)
            b.tintColor = .fdText
            b.backgroundColor = UIColor.white.withAlphaComponent(0.6)
            b.layer.cornerRadius = 16
            b.addTarget(self, action: #selector(pushSettings), for: .touchUpInside)
            return b
        }()

        // Action buttons row
        let editBtn: UIButton = {
            let b = UIButton(type: .system)
            b.setTitle(" 编辑资料", for: .normal)
            b.setImage(UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate), for: .normal)
            b.tintColor = .fdText2
            b.setTitleColor(.fdText2, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 11)
            b.backgroundColor = UIColor.white.withAlphaComponent(0.65)
            b.layer.cornerRadius = 999
            b.layer.borderWidth = 1
            b.layer.borderColor = UIColor.fdBorder.cgColor
            b.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
            b.semanticContentAttribute = .forceRightToLeft
            b.addTarget(self, action: #selector(pushProfile), for: .touchUpInside)
            return b
        }()

        let healthBtn: UIButton = {
            let b = UIButton(type: .system)
            b.setTitle(" 健康档案", for: .normal)
            b.setImage(UIImage(systemName: "heart")?.withRenderingMode(.alwaysTemplate), for: .normal)
            b.tintColor = .white
            b.setTitleColor(.white, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
            b.backgroundColor = .fdPrimary
            b.layer.cornerRadius = 999
            b.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
            return b
        }()

        container.addSubview(avatarView)
        container.addSubview(nameLabel)
        container.addSubview(settingsBtn)
        container.addSubview(editBtn)
        container.addSubview(healthBtn)

        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(52)
            make.leading.equalToSuperview().offset(18)
            make.size.equalTo(64)
        }

        let nameRow = UIStackView(arrangedSubviews: [nameLabel, UIView(), settingsBtn])
        nameRow.axis = .horizontal
        nameRow.alignment = .center
        nameRow.spacing = 12
        container.addSubview(nameRow)
        nameRow.snp.makeConstraints { make in
            make.top.equalTo(avatarView).offset(4)
            make.leading.equalTo(avatarView.snp.trailing).offset(14)
            make.trailing.equalToSuperview().offset(-18)
        }
        settingsBtn.snp.makeConstraints { make in
            make.size.equalTo(32)
        }

        let btnRow = UIStackView(arrangedSubviews: [editBtn, healthBtn, UIView()])
        btnRow.axis = .horizontal
        btnRow.spacing = 8
        container.addSubview(btnRow)
        btnRow.snp.makeConstraints { make in
            make.top.equalTo(nameRow.snp.bottom).offset(8)
            make.leading.equalTo(nameLabel)
            make.bottom.equalTo(avatarView)
        }

        let bottomPad = UIView()
        container.addSubview(bottomPad)
        bottomPad.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(4)
        }

        return container
    }

    // MARK: - Membership Card

    private func buildMembershipCard() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(hexString: "#FFF7F1")
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.2).cgColor

        let titleLabel = UILabel()
        titleLabel.text = "会员中心"
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .fdSubtext

        let levelLabel = UILabel()
        levelLabel.text = mock.membershipLevel
        levelLabel.font = .systemFont(ofSize: 13, weight: .bold)
        levelLabel.textColor = .fdPrimary

        let moreLabel = UILabel()
        moreLabel.text = "查看更多 ›"
        moreLabel.font = .systemFont(ofSize: 12)
        moreLabel.textColor = .fdSubtext

        card.addSubview(titleLabel)
        card.addSubview(levelLabel)
        card.addSubview(moreLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        levelLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
        moreLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(pushMembership))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true

        return card
    }

    // MARK: - Stats Strip

    private func buildStatsStrip(_ stats: [(String, String, Bool)]) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        container.layer.cornerRadius = 14

        let stack = UIStackView()
        stack.distribution = .fillEqually
        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 9, left: 0, bottom: 7, right: 0))
        }

        for (i, (value, label, accent)) in stats.enumerated() {
            let col = UIView()
            let valLabel = UILabel()
            valLabel.text = value
            valLabel.textColor = accent ? .fdPrimary : .fdText
            valLabel.font = .systemFont(ofSize: 22, weight: .bold)
            valLabel.textAlignment = .center

            let lblLabel = UILabel()
            lblLabel.text = label
            lblLabel.font = .systemFont(ofSize: 11)
            lblLabel.textColor = .fdSubtext
            lblLabel.textAlignment = .center

            col.addSubview(valLabel)
            col.addSubview(lblLabel)
            valLabel.snp.makeConstraints { make in
                make.top.centerX.equalToSuperview()
            }
            lblLabel.snp.makeConstraints { make in
                make.top.equalTo(valLabel.snp.bottom).offset(4)
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview()
            }

            // Divider (except last)
            if i < stats.count - 1 {
                let divider = UIView()
                divider.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.12)
                col.addSubview(divider)
                divider.snp.makeConstraints { make in
                    make.trailing.centerY.equalToSuperview()
                    make.width.equalTo(1)
                    make.height.equalTo(36)
                }
            }

            col.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(statTapped(_:)))
            col.addGestureRecognizer(tap)
            col.tag = i

            stack.addArrangedSubview(col)
        }

        return container
    }

    // MARK: - Service Section

    private func buildServiceSection() -> UIView {
        let container = UIView()

        let titleView = SectionTitleView(title: "服务履约", more: "全部订单 ›")
        titleView.onMoreTapped = { [weak self] in self?.showToast("全部订单") }
        container.addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        container.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }

        // Stats
        let statsStack = UIStackView()
        statsStack.distribution = .fillEqually
        card.addSubview(statsStack)
        statsStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(14)
        }

        for (value, label, accent) in mock.fulfillmentStats {
            let col = UIView()
            let valLbl = UILabel()
            valLbl.text = value
            valLbl.textColor = accent ? .fdPrimary : .fdText
            valLbl.font = .systemFont(ofSize: 22, weight: .bold)
            valLbl.textAlignment = .center
            let lblLbl = UILabel()
            lblLbl.text = label
            lblLbl.font = .systemFont(ofSize: 11)
            lblLbl.textColor = .fdSubtext
            lblLbl.textAlignment = .center
            col.addSubview(valLbl)
            col.addSubview(lblLbl)
            valLbl.snp.makeConstraints { $0.top.centerX.equalToSuperview() }
            lblLbl.snp.makeConstraints { make in
                make.top.equalTo(valLbl.snp.bottom).offset(2)
                make.centerX.bottom.equalToSuperview()
            }
            statsStack.addArrangedSubview(col)
        }

        let divider = UIView()
        divider.backgroundColor = .fdBorder
        card.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.top.equalTo(statsStack.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(14)
            make.height.equalTo(1)
        }

        // Service rows
        var prevDivider: UIView = divider
        let lastIndex = mock.services.count - 1
        for (i, svc) in mock.services.enumerated() {
            let row = buildServiceRow(svc)
            card.addSubview(row)
            row.snp.makeConstraints { make in
                make.top.equalTo(prevDivider.snp.bottom)
                make.leading.trailing.equalToSuperview().inset(14)
                if i == lastIndex {
                    make.bottom.equalToSuperview()
                }
            }
            prevDivider = row
        }

        return container
    }

    private func buildServiceRow(_ svc: (icon: String, iconBg: String, iconColorHex: String, name: String, status: String, statusType: String, detail: String)) -> UIView {
        let row = UIView()

        let iconView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hexString: svc.iconBg)
            v.layer.cornerRadius = 11
            let l = UILabel()
            l.text = svc.icon
            l.font = .systemFont(ofSize: 13, weight: .bold)
            l.textColor = UIColor(hexString: svc.iconColorHex)
            v.addSubview(l)
            l.snp.makeConstraints { $0.center.equalToSuperview() }
            return v
        }()

        let nameLabel = UILabel()
        nameLabel.text = svc.name
        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.textColor = .fdText

        let statusBadge = buildBadge(svc.status, type: svc.statusType)

        let detailLabel = UILabel()
        detailLabel.text = svc.detail
        detailLabel.font = .systemFont(ofSize: 11)
        detailLabel.textColor = .fdSubtext

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .fdMuted

        let topDivider = UIView()
        topDivider.backgroundColor = .fdBorder

        row.addSubview(topDivider)
        row.addSubview(iconView)
        row.addSubview(nameLabel)
        row.addSubview(statusBadge)
        row.addSubview(detailLabel)
        row.addSubview(arrow)

        topDivider.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        iconView.snp.makeConstraints { make in
            make.top.equalTo(topDivider.snp.bottom).offset(10)
            make.leading.equalToSuperview()
            make.size.equalTo(40)
            make.bottom.equalToSuperview().offset(-10)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView)
            make.leading.equalTo(iconView.snp.trailing).offset(10)
        }
        statusBadge.snp.makeConstraints { make in
            make.centerY.equalTo(nameLabel)
            make.leading.equalTo(nameLabel.snp.trailing).offset(6)
        }
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.leading.equalTo(nameLabel)
        }
        arrow.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
            make.size.equalTo(16)
        }

        row.isUserInteractionEnabled = true
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(serviceTapped)))

        return row
    }

    private func buildBadge(_ text: String, type: String) -> UIView {
        let badge = UIView()
        badge.layer.cornerRadius = 999
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        if type == "success" {
            badge.backgroundColor = .fdSuccessSoft
            label.textColor = .fdSuccess
        } else {
            badge.backgroundColor = .fdWarningSoft
            label.textColor = UIColor(hexString: "#B47300")
        }
        badge.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6))
        }
        return badge
    }

    // MARK: - Function Groups

    private func buildFunctionGroups() -> UIView {
        let container = UIView()

        let groups: [(title: String, rows: [(icon: String, color: UIColor, label: String, detail: String?)])] = [
            ("健康管理", [
                ("doc.text", UIColor(hexString: "#7B5E9F"), "健康档案", "完整度 72%"),
                ("heart.text.square", UIColor(hexString: "#1F9A6B"), "健康报告", "周报 / 阶段小结"),
                ("cross.case", UIColor(hexString: "#3D6FB8"), "体检报告单", "3 份已上传"),
                ("calendar", UIColor(hexString: "#B47300"), "监测方案", "当前方案生效中"),
                ("fork.knife", UIColor(hexString: "#D6602B"), "饮食方案", "可按档案生成"),
                ("checklist", UIColor(hexString: "#5C8DC9"), "健康评估", "2 项待完成"),
                ("clock", UIColor(hexString: "#6B9FE4"), "我的预约", "1 个待到店"),
            ]),
            ("账号与设置", [
                ("bell", UIColor.fdPrimary, "消息通知", "已开启"),
                ("textformat.size", UIColor(hexString: "#D6602B"), "显示与辅助", "大字 / 简洁操作"),
                ("hand.raised", UIColor(hexString: "#5C8DC9"), "隐私与权限", nil),
                ("lock.shield", UIColor(hexString: "#6B7280"), "账号安全", nil),
            ]),
            ("关于", [
                ("headphones", UIColor(hexString: "#1F9A6B"), "帮助中心 · 7×24 客服", nil),
                ("info.circle", UIColor(hexString: "#3D6FB8"), "关于富德健康", nil),
                ("checkmark.circle", UIColor(hexString: "#9AA0AC"), "当前版本", "v 2.6.1"),
            ]),
        ]

        var prevSection: UIView?
        for group in groups {
            let section = buildFunctionSection(title: group.title, rows: group.rows)
            container.addSubview(section)
            section.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                if let prev = prevSection {
                    make.top.equalTo(prev.snp.bottom)
                } else {
                    make.top.equalToSuperview()
                }
            }
            prevSection = section
        }
        prevSection?.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
        }

        return container
    }

    private func buildFunctionSection(title: String, rows: [(icon: String, color: UIColor, label: String, detail: String?)]) -> UIView {
        let container = UIView()

        let titleView = SectionTitleView(title: title)
        container.addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(sectionPadding)
        }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        container.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(sectionPadding)
            make.bottom.equalToSuperview()
        }

        var prevRow: FuncRowView?
        for (i, rowData) in rows.enumerated() {
            let row = FuncRowView(
                icon: rowData.icon,
                iconColor: rowData.color,
                title: rowData.label,
                detail: rowData.detail,
                showDivider: i < rows.count - 1
            )
            card.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                if let prev = prevRow {
                    make.top.equalTo(prev.snp.bottom)
                } else {
                    make.top.equalToSuperview().offset(4)
                }
            }

            let tap = UITapGestureRecognizer(target: self, action: #selector(funcRowTapped(_:)))
            row.addGestureRecognizer(tap)

            prevRow = row
        }
        prevRow?.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-4)
        }

        return container
    }

    // MARK: - Logout

    private func buildLogoutButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("退出登录", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.setTitleColor(.fdDanger, for: .normal)
        btn.backgroundColor = .fdSurface
        btn.layer.cornerRadius = 18
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 1)
        btn.layer.shadowRadius = 6
        btn.layer.shadowOpacity = 0.03
        btn.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
        return btn
    }

    // MARK: - Actions

    @objc private func pushSettings() {
        Router.shared.push("/me/settings")
    }

    @objc private func pushProfile() {
        Router.shared.push("/me/profile")
    }

    @objc private func pushMembership() {
        Router.shared.push("/me/membership")
    }

    @objc private func statTapped(_ gesture: UITapGestureRecognizer) {
        guard let idx = gesture.view?.tag else { return }
        let routes = ["/me/points", "/me/family", "/me/policy", "/me/membership"]
        guard idx < routes.count else { return }
        Router.shared.push(routes[idx])
    }

    @objc private func serviceTapped() {
        Router.shared.push("/orders")
    }

    @objc private func funcRowTapped(_ gesture: UITapGestureRecognizer) {
        guard let row = gesture.view as? FuncRowView else { return }
        let title = row.routeTitle
        routeFromFunction(title: title)
    }

    private func routeFromFunction(title: String) {
        let mapping: [String: String] = [
            "健康档案":  "/health/record",
            "健康报告":  "/me/health-report",
            "体检报告单": "/me/medical-reports",
            "监测方案":  "/me/monitoring-plan",
            "饮食方案":  "/me/diet-plan",
            "健康评估":  "/me/health-evaluations",
            "我的预约":  "/me/appointments",
            "消息通知":  "/me/settings",
            "显示与辅助": "/me/settings/accessibility",
            "隐私与权限": "/me/settings/privacy",
            "账号安全":  "/me/settings/security",
            "帮助中心 · 7×24 客服": "/me/settings/about",
            "关于富德健康": "/me/settings/about",
        ]
        if let route = mapping[title] {
            Router.shared.push(route)
        }
    }

    @objc private func handleLogout() {
        let alert = UIAlertController(title: nil, message: "确定要退出登录吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "退出", style: .destructive) { _ in
            Router.shared.present("/login")
        })
        present(alert, animated: true)
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
        }
    }
}
