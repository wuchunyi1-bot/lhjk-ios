import UIKit
import SnapKit
import Kingfisher
import Combine

/// 我的模块 Hub 页 — 对齐 Figma 3594:8470
final class MyViewController: BaseViewController {

    private let viewModel = MyViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Elements

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = UIColor(hexString: "#FDF6F3")
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()

    private let contentView = UIView()

    // Header Area
    private let headerView = UIView()
    private let headerInfoStack = UIStackView()
    private let headerWatermarkView = UIImageView()
    private let avatarContainerView = UIView()
    private let avatarButton = UIButton(type: .custom)
    private let avatarImageView = UIImageView()
    private let avatarCharLabel = UILabel()
    private let nameButton = UIButton(type: .custom)
    private let nameLabel = UILabel()
    private let healthArchiveContainer = UIView()
    private let healthArchiveImageView = UIImageView()
    private let healthArchiveTapButton = UIButton(type: .custom)
    private let settingsButton = UIButton(type: .custom)

    // Cards
    private let membershipCardView = MeMembershipCardView()
    private let fulfillmentCardView = MeServiceFulfillmentCardView()
    private let healthManagementCardView = MeHealthManagementCardView()

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.loadUserProfile()
        viewModel.refreshOverview()
        refreshHeader()
        refreshCards()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = UIColor(hexString: "#FDF6F3")

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        setupHeader()
        setupCards()
        bindViewModel()
    }

    // MARK: - Setup Subviews

    private func setupHeader() {
        contentView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(64)
        }

        // Settings Button (top right)
        settingsButton.setImage(UIImage(named: "me_settings_icon"), for: .normal)
        settingsButton.addTarget(self, action: #selector(pushSettings), for: .touchUpInside)
        headerView.addSubview(settingsButton)
        settingsButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-13)
            make.size.equalTo(24)
        }

        // 头像 + 昵称 + 健康档案：横向排列，垂直居中对齐
        headerInfoStack.axis = .horizontal
        headerInfoStack.alignment = .center
        headerInfoStack.spacing = 8
        headerView.addSubview(headerInfoStack)
        headerInfoStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(settingsButton.snp.leading).offset(-8)
        }

        // Avatar — Figma 3773:12953：46×46，0.958pt 白描边
        avatarContainerView.backgroundColor = UIColor(hexString: "#FFEDD9")
        avatarContainerView.layer.cornerRadius = 23
        avatarContainerView.layer.borderWidth = 0.958
        avatarContainerView.layer.borderColor = UIColor.white.cgColor
        avatarContainerView.clipsToBounds = true
        avatarContainerView.snp.makeConstraints { make in
            make.size.equalTo(46)
        }
        headerInfoStack.addArrangedSubview(avatarContainerView)

        avatarButton.backgroundColor = .clear
        avatarButton.addTarget(self, action: #selector(pushProfile), for: .touchUpInside)
        avatarContainerView.addSubview(avatarButton)
        avatarButton.snp.makeConstraints { $0.edges.equalToSuperview() }

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarButton.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        avatarCharLabel.font = .fdFont(ofSize: 22, weight: .semibold)
        avatarCharLabel.textColor = UIColor(hexString: "#754200")
        avatarCharLabel.textAlignment = .center
        avatarButton.addSubview(avatarCharLabel)
        avatarCharLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        // Name — 18pt Medium（登录态昵称需比 16pt 更醒目）
        nameLabel.font = .fdFont(ofSize: 20, weight: .medium)
        nameLabel.textColor = UIColor(hexString: "#1F2942")
        nameButton.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { $0.edges.equalToSuperview() }
        nameButton.addTarget(self, action: #selector(pushProfile), for: .touchUpInside)
        nameButton.snp.makeConstraints { make in
            make.height.equalTo(28)
        }
        headerInfoStack.addArrangedSubview(nameButton)

        // Health Archive Tag — Figma 3773:13147：100×33；相对昵称视觉中心下移 3pt
        healthArchiveContainer.addSubview(healthArchiveImageView)
        healthArchiveImageView.image = UIImage(named: "me_health_archive_tag")
        healthArchiveImageView.contentMode = .scaleAspectFit
        healthArchiveImageView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(3)
            make.width.equalTo(100)
            make.height.equalTo(33)
        }
        healthArchiveContainer.snp.makeConstraints { make in
            make.height.equalTo(36)
        }
        headerInfoStack.addArrangedSubview(healthArchiveContainer)

        healthArchiveTapButton.backgroundColor = .clear
        healthArchiveTapButton.addTarget(self, action: #selector(pushHealthProfile), for: .touchUpInside)
        headerView.addSubview(healthArchiveTapButton)
        healthArchiveTapButton.snp.makeConstraints { $0.edges.equalTo(healthArchiveImageView) }
    }

    private func setupCards() {
        // Membership Card
        membershipCardView.onTitleTap = { [weak self] in
            self?.openMemberLevel()
        }
        membershipCardView.onRedemptionTap = { [weak self] in
            self?.openRedemptions()
        }
        membershipCardView.onAssetTap = { [weak self] index in
            guard let asset = self?.viewModel.memberAssets[safe: index] else { return }
            Router.shared.push(asset.route)
        }
        contentView.addSubview(membershipCardView)
        membershipCardView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(132)
        }

        // Watermark V — 置于 header 下层，仅露出会员卡上方装饰，不遮挡健康档案
        headerWatermarkView.image = UIImage(named: "me_header_v_watermark")
        headerWatermarkView.contentMode = .scaleAspectFit
        contentView.insertSubview(headerWatermarkView, belowSubview: headerView)
        headerWatermarkView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-44)
            make.bottom.equalTo(membershipCardView.snp.top)
            make.width.equalTo(104)
            make.height.equalTo(76)
        }

        // Service Fulfillment Card
        fulfillmentCardView.onAllOrdersTap = { [weak self] in
            self?.openAllOrders()
        }
        fulfillmentCardView.onStatTap = { [weak self] index in
            guard let stat = self?.viewModel.fulfillmentStats[safe: index] else { return }
            Router.shared.push("/orders", params: ["tab": stat.tabKey])
        }
        contentView.addSubview(fulfillmentCardView)
        fulfillmentCardView.snp.makeConstraints { make in
            make.top.equalTo(membershipCardView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(110)
        }

        // Health Management Card
        healthManagementCardView.onRowTap = { route in
            Router.shared.push(route)
        }
        contentView.addSubview(healthManagementCardView)
        healthManagementCardView.snp.makeConstraints { make in
            make.top.equalTo(fulfillmentCardView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
        }
    }

    // MARK: - Bindings & Refresh

    override func bindViewModel() {
        viewModel.$userName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshHeader() }
            .store(in: &cancellables)

        viewModel.$memberAssets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshCards() }
            .store(in: &cancellables)

        viewModel.$fulfillmentStats
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshCards() }
            .store(in: &cancellables)

        viewModel.$healthManagement
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshCards() }
            .store(in: &cancellables)
    }

    private func refreshHeader() {
        if let urlStr = viewModel.avatarURL, let url = URL(string: urlStr) {
            avatarCharLabel.isHidden = true
            avatarImageView.isHidden = false
            let placeholder = UIImage(named: "chat_im_avatar")
            avatarImageView.kf.setImage(with: url, placeholder: placeholder)
        } else {
            avatarCharLabel.isHidden = true
            avatarImageView.isHidden = false
            avatarImageView.image = UIImage(named: "chat_im_avatar")
        }
        nameLabel.text = viewModel.userName
    }

    private func refreshCards() {
        let assets = viewModel.memberAssets.map {
            MeMembershipCardView.AssetItem(label: $0.label, value: $0.value, route: $0.route)
        }
        membershipCardView.configure(assets: assets)

        let stats = viewModel.fulfillmentStats.map {
            MeServiceFulfillmentCardView.StatItem(label: $0.label, value: $0.value, tabKey: $0.tabKey)
        }
        fulfillmentCardView.configure(stats: stats)

        let rows = viewModel.healthManagement.rows.map {
            MeHealthManagementCardView.RowItem(
                iconName: $0.icon,
                title: $0.label,
                detail: $0.detail,
                route: $0.route
            )
        }
        healthManagementCardView.configure(rows: rows)
    }

    override func refreshForSeniorMode() {
        super.refreshForSeniorMode()
        refreshHeader()
        refreshCards()
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    // MARK: - Navigation Actions

    @objc private func pushSettings() {
        Router.shared.push("/me/settings")
    }

    @objc private func pushProfile() {
        Router.shared.push("/me/profile")
    }

    @objc private func pushHealthProfile() {
        Router.shared.push("/me/health-profile")
    }

    @objc private func openMemberLevel() {
        Router.shared.push("/me/member-level")
    }

    @objc private func openRedemptions() {
        Router.shared.push("/me/redemptions")
    }

    private func openAllOrders() {
        Router.shared.push("/orders")
    }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
