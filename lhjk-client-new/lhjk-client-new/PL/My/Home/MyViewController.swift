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
    private let headerWatermarkView = UIImageView()
    private let avatarButton = UIButton(type: .custom)
    private let avatarImageView = UIImageView()
    private let avatarCharLabel = UILabel()
    private let nameButton = UIButton(type: .custom)
    private let nameLabel = UILabel()
    private let healthArchiveButton = UIButton(type: .custom)
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
            make.height.equalTo(72)
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

        // Avatar (top left)
        avatarButton.layer.cornerRadius = 23
        avatarButton.layer.borderWidth = 1
        avatarButton.layer.borderColor = UIColor.white.cgColor
        avatarButton.backgroundColor = UIColor(hexString: "#FFEDD9")
        avatarButton.clipsToBounds = true
        avatarButton.addTarget(self, action: #selector(pushProfile), for: .touchUpInside)
        headerView.addSubview(avatarButton)
        avatarButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(46)
        }

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarButton.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        avatarCharLabel.font = .fdFont(ofSize: 20, weight: .semibold)
        avatarCharLabel.textColor = UIColor(hexString: "#754200")
        avatarCharLabel.textAlignment = .center
        avatarButton.addSubview(avatarCharLabel)
        avatarCharLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        // Name
        nameLabel.font = .fdFont(ofSize: 18, weight: .medium)
        nameLabel.textColor = UIColor(hexString: "#1F2942")
        nameButton.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { $0.edges.equalToSuperview() }
        nameButton.addTarget(self, action: #selector(pushProfile), for: .touchUpInside)
        headerView.addSubview(nameButton)
        nameButton.snp.makeConstraints { make in
            make.leading.equalTo(avatarButton.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(6)
            make.height.equalTo(26)
            make.trailing.lessThanOrEqualTo(settingsButton.snp.leading).offset(-8)
        }

        // Health Archive Tag Button (自然宽高 79x28，居左对齐)
        healthArchiveButton.setImage(UIImage(named: "me_health_archive_tag"), for: .normal)
        healthArchiveButton.imageView?.contentMode = .scaleAspectFit
        healthArchiveButton.contentHorizontalAlignment = .leading
        healthArchiveButton.contentVerticalAlignment = .center
        healthArchiveButton.addTarget(self, action: #selector(pushHealthProfile), for: .touchUpInside)
        headerView.addSubview(healthArchiveButton)
        healthArchiveButton.snp.makeConstraints { make in
            make.leading.equalTo(nameButton)
            make.top.equalTo(nameButton.snp.bottom).offset(4)
            make.width.equalTo(79)
            make.height.equalTo(28)
        }
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

        // Watermark V in top right (底部严格贴紧会员卡顶部)
        headerWatermarkView.image = UIImage(named: "me_header_v_watermark")
        headerWatermarkView.contentMode = .scaleAspectFit
        contentView.insertSubview(headerWatermarkView, belowSubview: membershipCardView)
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
            avatarImageView.kf.setImage(with: url)
        } else {
            avatarCharLabel.isHidden = false
            avatarImageView.isHidden = true
            avatarCharLabel.text = viewModel.avatarChar
            avatarImageView.image = nil
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
