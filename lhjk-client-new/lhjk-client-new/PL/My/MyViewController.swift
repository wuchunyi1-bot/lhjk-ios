import UIKit
import SnapKit

/// 我的模块 Hub 页
/// 参考 funde-client: prototype/src/views/me/MeView.vue
///
/// 布局: UITableView 6 sections
///   tableHeaderView: Hero 区
///   Section 0: MeMembershipCardCell
///   Section 1: MeStatsStripCell
///   Section 2: MeServiceFulfillmentCell
///   Section 3: MeFuncRowCell × 7 (健康管理)
///   Section 4: MeFuncRowCell × 4 (账号与设置)
///   Section 5: MeFuncRowCell × 3 (关于)
///   tableFooterView: 退出登录按钮
final class MyViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Mock Data

    private let userName = "李秀英"
    private let avatarChar = "英"
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
        ("账号与设置", [
            ("bell", UIColor.fdPrimary, "消息通知", "已开启", "/me/settings"),
            ("textformat.size", UIColor(hexString: "#D6602B"), "显示与辅助", "大字 / 简洁操作", "/me/settings/accessibility"),
            ("hand.raised", UIColor(hexString: "#5C8DC9"), "隐私与权限", nil, "/me/settings/privacy"),
            ("lock.shield", UIColor(hexString: "#6B7280"), "账号安全", nil, "/me/settings/security"),
        ]),
        ("关于", [
            ("headphones", UIColor(hexString: "#1F9A6B"), "帮助中心 · 7×24 客服", nil, "/me/settings/about"),
            ("info.circle", UIColor(hexString: "#3D6FB8"), "关于富德健康", nil, "/me/settings/about"),
            ("checkmark.circle", UIColor(hexString: "#9AA0AC"), "当前版本", "v 2.6.1", ""),
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
        tv.register(MeMembershipCardCell.self, forCellReuseIdentifier: MeMembershipCardCell.reuseIdentifier)
        tv.register(MeStatsStripCell.self, forCellReuseIdentifier: MeStatsStripCell.reuseIdentifier)
        tv.register(MeServiceFulfillmentCell.self, forCellReuseIdentifier: MeServiceFulfillmentCell.reuseIdentifier)
        tv.register(MeFuncRowCell.self, forCellReuseIdentifier: MeFuncRowCell.reuseIdentifier)
        tv.tableHeaderView = buildTableHeader()
        tv.tableFooterView = buildTableFooter()
        tv.contentInsetAdjustmentBehavior = .never
        if #available(iOS 15.0, *) { tv.sectionHeaderTopPadding = 0 }
        return tv
    }()

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
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    // MARK: - Table Header (Hero)

    private func buildTableHeader() -> UIView {
        let header = UIView()

        // Warm gradient matching funde-client var(--fd-gradient-hero)
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(hexString: "#FFF7F1").cgColor, UIColor(hexString: "#FFE9DC").cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 200)
        header.layer.insertSublayer(gradient, at: 0)

        let avatarView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hexString: "#F4ECE3")
            v.layer.cornerRadius = 32
            let label = UILabel()
            label.text = avatarChar; label.font = .systemFont(ofSize: 22, weight: .semibold); label.textColor = UIColor(hexString: "#7B5E40")
            v.addSubview(label); label.snp.makeConstraints { $0.center.equalToSuperview() }
            return v
        }()

        let nameLabel = UILabel()
        nameLabel.text = userName; nameLabel.font = .systemFont(ofSize: 20, weight: .bold); nameLabel.textColor = .fdText

        let settingsBtn: UIButton = {
            let b = UIButton(type: .system)
            b.setImage(UIImage(systemName: "gearshape"), for: .normal)
            b.tintColor = .fdText; b.backgroundColor = UIColor.white.withAlphaComponent(0.6)
            b.layer.cornerRadius = 16
            b.addTarget(self, action: #selector(pushSettings), for: .touchUpInside)
            return b
        }()

        let editBtn: UIButton = {
            let b = UIButton(type: .system)
            b.setTitle(" 编辑资料", for: .normal)
            b.setImage(UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate), for: .normal)
            b.tintColor = .fdText2; b.setTitleColor(.fdText2, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 11)
            b.backgroundColor = UIColor.white.withAlphaComponent(0.65); b.layer.cornerRadius = 999
            b.layer.borderWidth = 1; b.layer.borderColor = UIColor.fdBorder.cgColor
            b.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
            b.semanticContentAttribute = .forceRightToLeft
            b.addTarget(self, action: #selector(pushProfile), for: .touchUpInside)
            return b
        }()

        let healthBtn: UIButton = {
            let b = UIButton(type: .system)
            b.setTitle(" 健康档案", for: .normal)
            b.setImage(UIImage(systemName: "heart")?.withRenderingMode(.alwaysTemplate), for: .normal)
            b.tintColor = .white; b.setTitleColor(.white, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
            b.backgroundColor = .fdPrimary; b.layer.cornerRadius = 999
            b.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
            b.addTarget(self, action: #selector(pushHealthRecord), for: .touchUpInside)
            return b
        }()

        [avatarView, nameLabel, settingsBtn, editBtn, healthBtn].forEach(header.addSubview)

        avatarView.snp.makeConstraints { $0.top.equalToSuperview().offset(52); $0.leading.equalToSuperview().offset(18); $0.size.equalTo(64) }
        nameLabel.snp.makeConstraints { $0.top.equalTo(avatarView).offset(4); $0.leading.equalTo(avatarView.snp.trailing).offset(14) }
        settingsBtn.snp.makeConstraints { $0.top.equalTo(avatarView).offset(4); $0.trailing.equalToSuperview().offset(-18); $0.size.equalTo(32) }
        editBtn.snp.makeConstraints { $0.top.equalTo(nameLabel.snp.bottom).offset(8); $0.leading.equalTo(nameLabel) }
        healthBtn.snp.makeConstraints { $0.top.equalTo(nameLabel.snp.bottom).offset(8); $0.leading.equalTo(editBtn.snp.trailing).offset(8) }
        header.snp.makeConstraints { $0.bottom.equalTo(editBtn.snp.bottom).offset(16) }

        // Size header
        let size = header.systemLayoutSizeFitting(CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        header.frame.size = CGSize(width: view.bounds.width, height: size.height)
        return header
    }

    // MARK: - Table Footer (Logout)

    private func buildTableFooter() -> UIView {
        let footer = UIView()
        let btn = UIButton(type: .system)
        btn.setTitle("退出登录", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.setTitleColor(.fdDanger, for: .normal)
        btn.backgroundColor = .fdSurface
        btn.layer.cornerRadius = 18
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 1)
        btn.layer.shadowRadius = 6; btn.layer.shadowOpacity = 0.03
        btn.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
        footer.addSubview(btn)
        btn.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 20, right: 16)); $0.height.equalTo(52) }

        let size = footer.systemLayoutSizeFitting(CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        footer.frame.size = CGSize(width: view.bounds.width, height: size.height)
        return footer
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int { 6 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0, 1, 2: return 1
        case 3: return functionGroups[0].rows.count
        case 4: return functionGroups[1].rows.count
        case 5: return functionGroups[2].rows.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MeMembershipCardCell.reuseIdentifier, for: indexPath) as? MeMembershipCardCell else {
                return UITableViewCell()
            }
            cell.configure(level: membershipLevel)
            cell.onTap = { [weak self] in self?.pushMembership() }
            return cell

        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MeStatsStripCell.reuseIdentifier, for: indexPath) as? MeStatsStripCell else {
                return UITableViewCell()
            }
            cell.configure(items: stats.map { ($0.value, $0.label, $0.accent, $0.route) })
            cell.onStatTap = { [weak self] idx in
                guard let self, idx < self.stats.count else { return }
                Router.shared.push(self.stats[idx].route)
            }
            return cell

        case 2:
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

        case 3, 4, 5:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MeFuncRowCell.reuseIdentifier, for: indexPath) as? MeFuncRowCell else {
                return UITableViewCell()
            }
            let group = functionGroups[indexPath.section - 3]
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
        case 3, 4, 5: return 48
        default: return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let titles = [nil, nil, "服务履约", "健康管理", "账号与设置", "关于"]
        guard let title = titles[section] else { return nil }
        let container = UIView(); container.backgroundColor = .fdBg
        let titleView = SectionTitleView(title: title, more: section == 2 ? "全部订单 ›" : nil)
        titleView.onMoreTapped = { Router.shared.push("/orders") }
        container.addSubview(titleView)
        titleView.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return [nil, nil, "服务履约", "健康管理", "账号与设置", "关于"][section] != nil ? 44 : 0.01
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    // MARK: - Actions

    @objc private func pushSettings() { Router.shared.push("/me/settings") }
    @objc private func pushProfile() { Router.shared.push("/me/profile") }
    @objc private func pushMembership() { Router.shared.push("/me/membership") }
    @objc private func pushHealthRecord() { Router.shared.push("/health/record") }

    @objc private func handleLogout() {
        let alert = UIAlertController(title: nil, message: "确定要退出登录吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "退出", style: .destructive) { _ in
            Router.shared.present("/login")
        })
        present(alert, animated: true)
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { alert.dismiss(animated: true) }
    }
}
