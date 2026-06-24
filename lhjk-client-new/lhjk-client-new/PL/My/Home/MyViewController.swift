import UIKit
import SnapKit
import Kingfisher

/// 我的模块 Hub 页
/// 参考 funde-client: prototype/src/views/me/MeView.vue
///
/// 布局: UITableView 2 sections
///   tableHeaderView: Hero 区 + 会员卡 + 统计条（合并 MeMembershipCardCell + MeStatsStripCell）
///   Section 0: MeServiceFulfillmentCell
///   Section 1: MeFuncRowCell × 7 (健康管理)
/// 注: "账号与设置"、"关于" 分组和退出登录已移至 SettingsViewController（/me/settings）
final class MyViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Mock Data

    private var userName = "加载中…"
    private var avatarChar = "我"
    private var avatarURL: String?
    private let membershipLevel = "健康大会员"

    private let stats: [(value: String, label: String, accent: Bool, route: String)] = [
        ("892", "健康积分", true, "/me/points"),
        ("4", "家庭成员", false, "/me/family"),
        ("2", "我的保单", false, "/me/policy"),
        ("Lv.3", "健康等级", false, "/me/membership"),
    ]

    private let fulfillmentStats: [(value: String, label: String, accent: Bool)] = [
        ("2", "待使用", true), ("1", "使用中", false), ("3", "已完成", false), ("1", "待评价", false),
    ]

    private let services: [(icon: String, iconBg: String, iconColorHex: String, name: String, status: String, statusType: String, detail: String)] = [
        ("德好", "#FF7A50", "#FFFFFF", "慢病逆转管理", "进行中", "success", "服务至 2026/06/30 · 剩 45 天"),
        ("体检", "#E6F7EF", "#1F9A6B", "慈铭高端体检 · 三甲套餐", "待使用", "warning", "5 月 23 日 · 上海陆家嘴中心"),
    ]

    private let functionGroups: [(title: String, rows: [(icon: String, color: UIColor, label: String, detail: String?, route: String)])] = [
        ("健康管理", [
            ("doc.text", UIColor(hexString: "#7B5E9F"), "健康档案", "完整度 72%", "/health/record"),
            ("heart.text.square", UIColor(hexString: "#1F9A6B"), "健康报告", "周报 / 阶段小结", "/me/health-report"),
            ("cross.case", UIColor(hexString: "#3D6FB8"), "体检报告单", "3 份已上传", "/me/medical-reports"),
            ("calendar", UIColor(hexString: "#B47300"), "监测方案", "当前方案生效中", "/me/monitoring-plan"),
            ("fork.knife", UIColor(hexString: "#D6602B"), "饮食方案", "可按档案生成", "/me/diet-plan"),
            ("checklist", UIColor(hexString: "#5C8DC9"), "健康评估", "2 项待完成", "/me/health-evaluations"),
            ("clock", UIColor(hexString: "#6B9FE4"), "我的预约", "1 个待到店", "/me/appointments"),
        ]),
    ]

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.dataSource = self
        tv.delegate = self
        tv.register(MeServiceFulfillmentCell.self, forCellReuseIdentifier: MeServiceFulfillmentCell.reuseIdentifier)
        tv.register(MeFuncRowCell.self, forCellReuseIdentifier: MeFuncRowCell.reuseIdentifier)
        tv.contentInsetAdjustmentBehavior = .never
        if #available(iOS 15.0, *) { tv.sectionHeaderTopPadding = 0 }
        return tv
    }()

    /// 渐变背景 layer（需要在 viewDidLayoutSubviews 中更新 frame）
    private let headerGradient = CAGradientLayer()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(onUserUpdated),
                                               name: .userDidUpdate, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update gradient frame when bounds are known
        if let header = tableView.tableHeaderView {
            headerGradient.frame = header.bounds
            // Recalculate header size with actual width
            let size = header.systemLayoutSizeFitting(
                CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            if header.frame.size.height != size.height {
                header.frame.size = CGSize(width: view.bounds.width, height: size.height)
                tableView.tableHeaderView = header
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        if tableView.tableHeaderView == nil {
            tableView.tableHeaderView = buildTableHeader().sizedForTableHeader(in: view)
        }
        loadUserProfile()
    }

    // MARK: - User Profile

    private func loadUserProfile() {
        guard let user = UserManager.shared.currentUser else { return }
        let name = user.chineseName ?? user.surname ?? user.nickname ?? "用户"
        self.userName = name
        self.avatarChar = String(name.prefix(1))
        self.avatarURL = user.imageUrl
        self.refreshHeader()
    }

    @objc private func onUserUpdated() {
        loadUserProfile()
    }

    private func refreshHeader() {
        guard let header = tableView.tableHeaderView else { return }
        if let avatar = header.viewWithTag(200) as? UIImageView {
            let label = header.viewWithTag(201) as? UILabel
            if let urlStr = avatarURL, let url = URL(string: urlStr) {
                label?.isHidden = true
                avatar.kf.setImage(with: url)
            } else {
                label?.isHidden = false
                label?.text = avatarChar
            }
        }
        header.setNeedsLayout()
        header.layoutIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    // MARK: - Table Header (Hero + Membership Card + Stats Strip)

    private func buildTableHeader() -> UIView {
        let header = UIView()
        header.backgroundColor = .clear
        header.clipsToBounds = false

        // Warm gradient matching funde-client var(--fd-gradient-hero)
        headerGradient.colors = [UIColor(hexString: "#FFF7F1").cgColor, UIColor(hexString: "#FFE9DC").cgColor]
        headerGradient.startPoint = CGPoint(x: 0, y: 0)
        headerGradient.endPoint = CGPoint(x: 1, y: 1)
        header.layer.insertSublayer(headerGradient, at: 0)

        let contentPadding: CGFloat = 16
        let cardRadius: CGFloat = 18

        // MARK: User Info Area

        let avatarView: UIImageView = {
            let v = UIImageView()
            v.backgroundColor = UIColor(hexString: "#F4ECE3")
            v.layer.cornerRadius = 32
            v.clipsToBounds = true
            v.contentMode = .scaleAspectFill
            v.tag = 200  // for later reference
            return v
        }()
        let avatarLabel: UILabel = {
            let l = UILabel()
            l.text = avatarChar
            l.font = .fdH2
            l.textColor = UIColor(hexString: "#7B5E40")
            l.textAlignment = .center
            l.tag = 201
            return l
        }()
        avatarView.addSubview(avatarLabel)
        avatarLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        let nameLabel: UILabel = {
            let l = UILabel()
            l.text = userName
            l.font = .fdH2
            l.textColor = .fdText
            return l
        }()

        let settingsBtn: UIButton = {
            let b = UIButton(type: .system)
            b.setImage(UIImage(systemName: "gearshape")?.applyingSymbolConfiguration(
                UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)), for: .normal)
            b.tintColor = .fdText
            b.backgroundColor = UIColor.white.withAlphaComponent(0.6)
            b.layer.cornerRadius = 16
            b.clipsToBounds = true
            b.addTarget(self, action: #selector(pushSettings), for: .touchUpInside)
            return b
        }()

        let editBtn: UIButton = {
            let b = UIButton(type: .system)
            b.setTitle(" 编辑资料", for: .normal)
            b.setImage(UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate), for: .normal)
            b.tintColor = .fdText2
            b.setTitleColor(.fdText2, for: .normal)
            b.titleLabel?.font = .fdMicro
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
            b.titleLabel?.font = .fdMicroSemibold
            b.backgroundColor = .fdPrimary
            b.layer.cornerRadius = 999
            b.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
            b.addTarget(self, action: #selector(pushHealthRecord), for: .touchUpInside)
            return b
        }()

        [avatarView, nameLabel, settingsBtn, editBtn, healthBtn].forEach(header.addSubview)

        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(52)
            make.leading.equalToSuperview().offset(contentPadding + 2)
            make.size.equalTo(64)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView).offset(4)
            make.leading.equalTo(avatarView.snp.trailing).offset(14)
        }
        settingsBtn.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(56)
            make.trailing.equalToSuperview().offset(-contentPadding)
            make.size.equalTo(32)
        }
        editBtn.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.leading.equalTo(nameLabel)
        }
        healthBtn.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.leading.equalTo(editBtn.snp.trailing).offset(8)
        }

        // MARK: Membership Card (from MeMembershipCardCell)

        let membershipCard: UIView = {
            let card = UIView()
            card.backgroundColor = UIColor(hexString: "#FFF7F1")
            card.layer.cornerRadius = cardRadius
            card.layer.borderWidth = 1
            card.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.2).cgColor
            card.isUserInteractionEnabled = true
            card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pushMembership)))

            let titleLbl = UILabel()
            titleLbl.text = "会员中心"
            titleLbl.font = .fdCaption
            titleLbl.textColor = .fdSubtext

            let levelLbl = UILabel()
            levelLbl.text = membershipLevel
            levelLbl.font = .fdCaptionSemibold
            levelLbl.textColor = .fdPrimary

            let moreLbl = UILabel()
            moreLbl.text = "查看更多 ›"
            moreLbl.font = .fdCaption
            moreLbl.textColor = .fdSubtext

            [titleLbl, levelLbl, moreLbl].forEach(card.addSubview)
            titleLbl.snp.makeConstraints { make in
                make.top.leading.equalToSuperview().inset(16)
            }
            levelLbl.snp.makeConstraints { make in
                make.top.equalTo(titleLbl.snp.bottom).offset(4)
                make.leading.equalToSuperview().inset(16)
                make.bottom.equalToSuperview().offset(-16)
            }
            moreLbl.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().offset(-16)
            }
            return card
        }()

        header.addSubview(membershipCard)
        membershipCard.snp.makeConstraints { make in
            make.top.equalTo(editBtn.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(contentPadding).priority(750)
        }

        // MARK: Stats Strip (from MeStatsStripCell)

        let statsContainer: UIView = {
            let container = UIView()
            container.backgroundColor = UIColor.white.withAlphaComponent(0.6)
            container.layer.cornerRadius = 14

            let stack = UIStackView()
            stack.distribution = .fillEqually
            container.addSubview(stack)
            stack.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 9, left: 0, bottom: 7, right: 0)).priority(750)
            }

            for (i, (value, label, accent, route)) in stats.enumerated() {
                let col = UIView()
                let valLbl = UILabel()
                valLbl.text = value
                valLbl.textColor = accent ? .fdPrimary : .fdText
                valLbl.font = .fdH2
                valLbl.textAlignment = .center

                let lblLbl = UILabel()
                lblLbl.text = label
                lblLbl.font = .fdMicro
                lblLbl.textColor = .fdSubtext
                lblLbl.textAlignment = .center

                col.addSubview(valLbl)
                col.addSubview(lblLbl)
                valLbl.snp.makeConstraints { make in
                    make.top.centerX.equalToSuperview()
                }
                lblLbl.snp.makeConstraints { make in
                    make.top.equalTo(valLbl.snp.bottom).offset(4)
                    make.centerX.bottom.equalToSuperview()
                }

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
                col.tag = i
                col.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(statTapped(_:))))
                stack.addArrangedSubview(col)
            }
            return container
        }()

        header.addSubview(statsContainer)
        statsContainer.snp.makeConstraints { make in
            make.top.equalTo(membershipCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(contentPadding).priority(750)
            make.bottom.equalToSuperview().offset(-16)
        }

        return header
    }

    // MARK: - UITableViewDataSource

    /// 2 sections: 0=ServiceFulfillment, 1=HealthMgt
    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return functionGroups[0].rows.count   // 7
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MeServiceFulfillmentCell.reuseIdentifier, for: indexPath) as? MeServiceFulfillmentCell else {
                return UITableViewCell()
            }
            cell.configure(stats: fulfillmentStats, services: services)
            cell.onStatTap = { [weak self] idx in
                let tabs = ["pending_use", "in_progress", "completed", "pending_review"]
                guard idx < tabs.count else { return }
                Router.shared.push("/orders", params: ["tab": tabs[idx]])
            }
            cell.onServiceTap = { Router.shared.push("/orders") }
            return cell

        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MeFuncRowCell.reuseIdentifier, for: indexPath) as? MeFuncRowCell else {
                return UITableViewCell()
            }
            let group = functionGroups[indexPath.section - 1]
            let row = group.rows[indexPath.row]
            cell.configure(data: MeFuncRowCell.RowData(
                icon: row.icon, color: row.color, title: row.label, detail: row.detail,
                showDivider: indexPath.row < group.rows.count - 1
            ))
            cell.onTap = { [weak self] in
                if !row.route.isEmpty { Router.shared.push(row.route) }
            }
            return cell

        default: return UITableViewCell()
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 1: return 48
        default: return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let titles = ["我的订单", "健康管理"]
        guard section < titles.count else { return nil }
        let title = titles[section]
        let container = UIView(); container.backgroundColor = .fdBg
        let titleView = SectionTitleView(title: title, more: section == 0 ? "全部订单 ›" : nil)
        titleView.onMoreTapped = { Router.shared.push("/orders") }
        container.addSubview(titleView)
        titleView.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    // MARK: - Actions

    @objc private func pushSettings() { Router.shared.push("/me/settings") }
    @objc private func pushProfile() { Router.shared.push("/me/profile") }
    @objc private func pushMembership() { Router.shared.push("/me/membership") }
    @objc private func pushHealthRecord() { Router.shared.push("/health/record") }

    @objc private func statTapped(_ gesture: UITapGestureRecognizer) {
        guard let idx = gesture.view?.tag, idx < stats.count else { return }
        Router.shared.push(stats[idx].route)
    }

}
