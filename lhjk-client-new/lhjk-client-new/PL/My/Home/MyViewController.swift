import UIKit
import SnapKit
import Kingfisher
import Combine

/// 我的模块 Hub 页 — 对齐 funde-client MeView.vue
final class MyViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    private enum Section: Int, CaseIterable {
        case common
        case health
        case settings
    }

    private let viewModel = MyViewModel()
    private var cancellables = Set<AnyCancellable>()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.dataSource = self
        tv.delegate = self
        tv.register(MeCommonActionsCell.self, forCellReuseIdentifier: MeCommonActionsCell.reuseIdentifier)
        tv.register(MeFuncRowCell.self, forCellReuseIdentifier: MeFuncRowCell.reuseIdentifier)
        tv.contentInsetAdjustmentBehavior = .never
        if #available(iOS 15.0, *) { tv.sectionHeaderTopPadding = 0 }
        return tv
    }()

    private let headerGradient = CAGradientLayer()

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let header = tableView.tableHeaderView {
            headerGradient.frame = header.bounds
            let size = header.systemLayoutSizeFitting(
                CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel
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
        viewModel.loadUserProfile()
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
        tableView.tableFooterView = buildLogoutFooter()
        bindViewModel()
    }

    override func refreshForSeniorMode() {
        super.refreshForSeniorMode()
        tableView.tableHeaderView = buildTableHeader().sizedForTableHeader(in: view)
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    override func bindViewModel() {
        viewModel.$userName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshHeader() }
            .store(in: &cancellables)
    }

    private func refreshHeader() {
        guard let header = tableView.tableHeaderView else { return }
        if let avatar = header.viewWithTag(200) as? UIImageView {
            let label = header.viewWithTag(201) as? UILabel
            if let urlStr = viewModel.avatarURL, let url = URL(string: urlStr) {
                label?.isHidden = true
                avatar.kf.setImage(with: url)
            } else {
                label?.isHidden = false
                label?.text = viewModel.avatarChar
            }
        }
        (header.viewWithTag(202) as? UILabel)?.text = viewModel.userName
        if let card = header.viewWithTag(300) as? MeMembershipCardView {
            card.configure(with: viewModel)
        }
        header.setNeedsLayout()
        header.layoutIfNeeded()
    }

    // MARK: - Header

    private func buildTableHeader() -> UIView {
        let header = UIView()
        header.backgroundColor = .clear
        header.clipsToBounds = false

        headerGradient.colors = [UIColor(hexString: "#FFF7F1").cgColor, UIColor(hexString: "#FFE9DC").cgColor]
        headerGradient.startPoint = CGPoint(x: 0, y: 0)
        headerGradient.endPoint = CGPoint(x: 1, y: 1)
        header.layer.insertSublayer(headerGradient, at: 0)

        let contentPadding: CGFloat = 16

        let avatarView = UIImageView()
        avatarView.backgroundColor = UIColor(hexString: "#F4ECE3")
        avatarView.layer.cornerRadius = 32
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.tag = 200

        let avatarLabel = UILabel()
        avatarLabel.text = viewModel.avatarChar
        avatarLabel.font = .fdH2
        avatarLabel.textColor = UIColor(hexString: "#7B5E40")
        avatarLabel.textAlignment = .center
        avatarLabel.tag = 201
        avatarView.addSubview(avatarLabel)
        avatarLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        let nameLabel = UILabel()
        nameLabel.text = viewModel.userName
        nameLabel.font = .fdH2
        nameLabel.textColor = .fdText
        nameLabel.tag = 202

        let settingsBtn = UIButton(type: .system)
        settingsBtn.setImage(UIImage(systemName: "gearshape")?.applyingSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)), for: .normal)
        settingsBtn.tintColor = .fdText
        settingsBtn.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        settingsBtn.layer.cornerRadius = 16
        settingsBtn.clipsToBounds = true
        settingsBtn.addTarget(self, action: #selector(pushSettings), for: .touchUpInside)

        let profileBtn = makePillButton(
            title: "个人信息",
            systemImage: "chevron.right",
            imageTrailing: true,
            filled: false
        )
        profileBtn.addTarget(self, action: #selector(pushProfile), for: .touchUpInside)

        let healthBtn = makePillButton(
            title: "健康档案",
            systemImage: "heart",
            imageTrailing: false,
            filled: true
        )
        healthBtn.addTarget(self, action: #selector(pushHealthProfile), for: .touchUpInside)

        let membershipCard = MeMembershipCardView()
        membershipCard.tag = 300
        membershipCard.configure(with: viewModel)
        membershipCard.onCardTap = { [weak self] in self?.openMembershipCard() }
        membershipCard.onPrimaryTap = { [weak self] in self?.openMembershipAction() }
        membershipCard.onUpgradeTap = { [weak self] in self?.openMembershipAction() }
        membershipCard.onBenefitsTap = { Router.shared.push("/me/membership") }

        [avatarView, nameLabel, settingsBtn, profileBtn, healthBtn, membershipCard].forEach(header.addSubview)

        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(52)
            make.leading.equalToSuperview().offset(contentPadding + 2)
            make.size.equalTo(64)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView).offset(4)
            make.leading.equalTo(avatarView.snp.trailing).offset(14)
            make.trailing.lessThanOrEqualTo(settingsBtn.snp.leading).offset(-8)
        }
        settingsBtn.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(56)
            make.trailing.equalToSuperview().offset(-contentPadding)
            make.size.equalTo(32)
        }
        profileBtn.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(10)
            make.leading.equalTo(nameLabel)
            make.height.greaterThanOrEqualTo(28)
        }
        healthBtn.snp.makeConstraints { make in
            make.centerY.equalTo(profileBtn)
            make.leading.equalTo(profileBtn.snp.trailing).offset(8)
            make.height.greaterThanOrEqualTo(28)
        }
        membershipCard.snp.makeConstraints { make in
            make.top.equalTo(profileBtn.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(contentPadding)
            make.bottom.equalToSuperview().offset(-8)
        }

        return header
    }

    private func makePillButton(title: String, systemImage: String, imageTrailing: Bool, filled: Bool) -> UIButton {
        var cfg = UIButton.Configuration.filled()
        cfg.title = title
        cfg.image = UIImage(systemName: systemImage)
        cfg.imagePlacement = imageTrailing ? .trailing : .leading
        cfg.imagePadding = imageTrailing ? 4 : 6
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: imageTrailing ? 10 : 12, bottom: 4, trailing: imageTrailing ? 10 : 12)
        cfg.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: imageTrailing ? 9 : 11, weight: .semibold)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = filled ? .fdMicroSemibold : .fdMicro
            return outgoing
        }
        if filled {
            cfg.baseForegroundColor = .white
            cfg.background.backgroundColor = .fdPrimary
        } else {
            cfg.baseForegroundColor = .fdText2
            cfg.background.backgroundColor = UIColor.white.withAlphaComponent(0.65)
            cfg.background.strokeColor = .fdBorder
            cfg.background.strokeWidth = 1
        }
        cfg.background.cornerRadius = 999
        return UIButton(configuration: cfg)
    }

    private func buildLogoutFooter() -> UIView {
        let wrap = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 72))
        let btn = UIButton(type: .system)
        btn.setTitle("退出登录", for: .normal)
        btn.setTitleColor(.fdDanger, for: .normal)
        btn.titleLabel?.font = .fdBody
        btn.backgroundColor = .fdSurface
        btn.layer.cornerRadius = 14
        btn.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
        wrap.addSubview(btn)
        btn.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        return wrap
    }

    // MARK: - Table

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let s = Section(rawValue: section) else { return 0 }
        switch s {
        case .common: return 1
        case .health: return viewModel.healthManagement.rows.count
        case .settings: return viewModel.settingsSupport.rows.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let s = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        switch s {
        case .common:
            let cell = tableView.dequeueReusableCell(withIdentifier: MeCommonActionsCell.reuseIdentifier, for: indexPath) as! MeCommonActionsCell
            cell.configure(actions: viewModel.commonActions)
            cell.onActionTap = { route in Router.shared.push(route) }
            return cell

        case .health, .settings:
            let cell = tableView.dequeueReusableCell(withIdentifier: MeFuncRowCell.reuseIdentifier, for: indexPath) as! MeFuncRowCell
            let group = s == .health ? viewModel.healthManagement : viewModel.settingsSupport
            let row = group.rows[indexPath.row]
            cell.configure(data: MeFuncRowCell.RowData(
                icon: row.icon,
                color: row.color,
                title: row.label,
                detail: row.detail,
                showDivider: indexPath.row < group.rows.count - 1,
                showChevron: row.route != nil
            ))
            cell.onTap = {
                guard let route = row.route, !route.isEmpty else { return }
                Router.shared.push(route)
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let s = Section(rawValue: indexPath.section) else { return 48 }
        switch s {
        case .common:
            let rows = Int(ceil(Double(viewModel.commonActions.count) / 4.0))
            return CGFloat(10 + 12 + rows * 72 + max(0, rows - 1) * 10)
        case .health, .settings:
            return 48
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let s = Section(rawValue: section) else { return nil }
        let title: String
        switch s {
        case .common: title = "常用功能"
        case .health: title = viewModel.healthManagement.title
        case .settings: title = viewModel.settingsSupport.title
        }
        let container = UIView()
        container.backgroundColor = .fdBg
        let titleView = SectionTitleView(title: title, more: nil)
        container.addSubview(titleView)
        titleView.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 44 }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 8 }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let v = UIView(); v.backgroundColor = .fdBg; return v
    }

    // MARK: - Actions

    @objc private func pushSettings() { Router.shared.push("/me/settings") }
    @objc private func pushProfile() { Router.shared.push("/me/profile") }
    @objc private func pushHealthProfile() { Router.shared.push("/me/health-profile") }

    private func openMembershipCard() {
        switch viewModel.membership.status {
        case .active, .expiring:
            Router.shared.push("/me/membership")
        case .notOpened, .expired:
            openMembershipAction()
        }
    }

    private func openMembershipAction() {
        Router.shared.push("/me/membership/open")
    }

    @objc private func handleLogout() {
        let alert = UIAlertController(
            title: "确认退出登录",
            message: "退出后需要重新登录才能使用富德健康。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "退出登录", style: .destructive) { _ in
            Task {
                await LoginService.shared.logout()
                LoginService.shared.clearSession()
            }
            IMService.shared.clear()
            ServiceHubCacheService.shared.clear()
            InstitutionSelectionStore.shared.clear()
            RongCloudManager.shared.disconnect()
            UserManager.shared.clear()
            Router.shared.setRoot("/login")
        })
        present(alert, animated: true)
    }
}
