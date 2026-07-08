import UIKit
import SnapKit
import Kingfisher
import Combine

/// 我的模块 Hub 页
final class MyViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - ViewModel

    private let viewModel = MyViewModel()
    private var cancellables = Set<AnyCancellable>()

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

    private let headerGradient = CAGradientLayer()

    // MARK: - Lifecycle

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
        bindViewModel()
    }

    override func refreshForSeniorMode() {
        super.refreshForSeniorMode()
        tableView.tableHeaderView = buildTableHeader().sizedForTableHeader(in: view)
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    // MARK: - Binding

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
        header.setNeedsLayout()
        header.layoutIfNeeded()
    }

    // MARK: - Table Header

    private func buildTableHeader() -> UIView {
        let header = UIView()
        header.backgroundColor = .clear
        header.clipsToBounds = false

        headerGradient.colors = [UIColor(hexString: "#FFF7F1").cgColor, UIColor(hexString: "#FFE9DC").cgColor]
        headerGradient.startPoint = CGPoint(x: 0, y: 0)
        headerGradient.endPoint = CGPoint(x: 1, y: 1)
        header.layer.insertSublayer(headerGradient, at: 0)

        let contentPadding: CGFloat = 16

        let avatarView: UIImageView = {
            let v = UIImageView()
            v.backgroundColor = UIColor(hexString: "#F4ECE3")
            v.layer.cornerRadius = 32
            v.clipsToBounds = true
            v.contentMode = .scaleAspectFill
            v.tag = 200
            return v
        }()
        let avatarLabel: UILabel = {
            let l = UILabel()
            l.text = viewModel.avatarChar
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
            l.text = viewModel.userName
            l.font = .fdH2
            l.textColor = .fdText
            l.tag = 202
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
            var cfg = UIButton.Configuration.filled()
            cfg.title = "编辑资料"
            cfg.image = UIImage(systemName: "chevron.right")
            cfg.imagePlacement = .trailing
            cfg.imagePadding = 4
            cfg.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12)
            cfg.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 9, weight: .semibold)
            cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming; outgoing.font = .fdMicro; return outgoing
            }
            cfg.baseForegroundColor = .fdText2
            cfg.background.backgroundColor = UIColor.white.withAlphaComponent(0.65)
            cfg.background.cornerRadius = 999
            cfg.background.strokeColor = UIColor.fdBorder
            cfg.background.strokeWidth = 1
            let b = UIButton(configuration: cfg)
            b.addTarget(self, action: #selector(pushProfile), for: .touchUpInside)
            return b
        }()

        let healthBtn: UIButton = {
            var cfg = UIButton.Configuration.filled()
            cfg.title = "健康档案"
            cfg.image = UIImage(systemName: "heart")
            cfg.imagePlacement = .leading
            cfg.imagePadding = 6
            cfg.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 14, bottom: 5, trailing: 14)
            cfg.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
            cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming; outgoing.font = .fdMicroSemibold; return outgoing
            }
            cfg.baseForegroundColor = .white
            cfg.background.backgroundColor = .fdPrimary
            cfg.background.cornerRadius = 999
            let b = UIButton(configuration: cfg)
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

        // Membership Card
        let membershipCard: UIView = {
            let card = UIView()
            card.backgroundColor = UIColor(hexString: "#FFF7F1")
            card.layer.cornerRadius = 18
            card.layer.borderWidth = 1
            card.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.2).cgColor
            card.isUserInteractionEnabled = true
            card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pushMembership)))

            let titleLbl = UILabel()
            titleLbl.text = "会员中心"; titleLbl.font = .fdCaption; titleLbl.textColor = .fdSubtext
            let levelLbl = UILabel()
            levelLbl.text = viewModel.membershipLevel; levelLbl.font = .fdCaptionSemibold; levelLbl.textColor = .fdPrimary
            let moreLbl = UILabel()
            moreLbl.text = "查看更多 ›"; moreLbl.font = .fdCaption; moreLbl.textColor = .fdSubtext

            [titleLbl, levelLbl, moreLbl].forEach(card.addSubview)
            titleLbl.snp.makeConstraints { make in make.top.leading.equalToSuperview().inset(16) }
            levelLbl.snp.makeConstraints { make in
                make.top.equalTo(titleLbl.snp.bottom).offset(4)
                make.leading.equalToSuperview().inset(16)
                make.bottom.equalToSuperview().offset(-16)
            }
            moreLbl.snp.makeConstraints { make in make.centerY.equalToSuperview(); make.trailing.equalToSuperview().offset(-16) }
            return card
        }()
        header.addSubview(membershipCard)
        membershipCard.snp.makeConstraints { make in
            make.top.equalTo(editBtn.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(contentPadding).priority(750)
        }

        // Stats Strip
        let statsContainer: UIView = {
            let container = UIView()
            container.backgroundColor = UIColor.white.withAlphaComponent(0.6)
            container.layer.cornerRadius = 14
            let stack = UIStackView(); stack.distribution = .fillEqually
            container.addSubview(stack)
            stack.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 9, left: 0, bottom: 7, right: 0)).priority(750)
            }

            let stats = viewModel.stats
            for (i, stat) in stats.enumerated() {
                let col = UIView()
                let valLbl = UILabel()
                valLbl.text = stat.value; valLbl.textColor = stat.accent ? .fdPrimary : .fdText
                valLbl.font = .fdH2; valLbl.textAlignment = .center
                let lblLbl = UILabel()
                lblLbl.text = stat.label; lblLbl.font = .fdMicro; lblLbl.textColor = .fdSubtext; lblLbl.textAlignment = .center
                col.addSubview(valLbl); col.addSubview(lblLbl)
                valLbl.snp.makeConstraints { make in make.top.centerX.equalToSuperview() }
                lblLbl.snp.makeConstraints { make in
                    make.top.equalTo(valLbl.snp.bottom).offset(4); make.centerX.bottom.equalToSuperview()
                }
                if i < stats.count - 1 {
                    let divider = UIView()
                    divider.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.12)
                    col.addSubview(divider)
                    divider.snp.makeConstraints { make in
                        make.trailing.centerY.equalToSuperview(); make.width.equalTo(1); make.height.equalTo(36)
                    }
                }
                col.isUserInteractionEnabled = true; col.tag = i
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

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : viewModel.functionGroups[0].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MeServiceFulfillmentCell.reuseIdentifier, for: indexPath) as? MeServiceFulfillmentCell else {
                return UITableViewCell()
            }
            cell.configure(stats: viewModel.fulfillmentStats.map {
                ($0.value, $0.label, $0.accent)
            }, services: viewModel.services.map {
                ($0.icon, $0.iconBg, $0.iconColorHex, $0.name, $0.status, $0.statusType, $0.detail)
            })
            cell.onStatTap = { [weak self] idx in
                let tabs = ["pending_ship", "in_progress", "completed", "pending_payment"]
                guard idx < tabs.count else { return }
                Router.shared.push("/orders", params: ["tab": tabs[idx]])
            }
            cell.onServiceTap = { Router.shared.push("/orders") }
            return cell

        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MeFuncRowCell.reuseIdentifier, for: indexPath) as? MeFuncRowCell else {
                return UITableViewCell()
            }
            let group = viewModel.functionGroups[indexPath.section - 1]
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
        indexPath.section == 1 ? 48 : UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let titles = ["我的订单", "健康管理"]
        guard section < titles.count else { return nil }
        let container = UIView(); container.backgroundColor = .fdBg
        let titleView = SectionTitleView(title: titles[section], more: section == 0 ? "全部订单 ›" : nil)
        titleView.onMoreTapped = { Router.shared.push("/orders") }
        container.addSubview(titleView)
        titleView.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 44 }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.01 }

    // MARK: - Actions

    @objc private func pushSettings() { Router.shared.push("/me/settings") }
    @objc private func pushProfile() { Router.shared.push("/me/profile") }
    @objc private func pushMembership() { Router.shared.push("/me/membership") }
    @objc private func pushHealthRecord() { Router.shared.push("/health/record") }

    @objc private func statTapped(_ gesture: UITapGestureRecognizer) {
        guard let idx = gesture.view?.tag, idx < viewModel.stats.count else { return }
        Router.shared.push(viewModel.stats[idx].route)
    }
}
