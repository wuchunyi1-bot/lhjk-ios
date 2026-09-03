import UIKit
import SnapKit

/// 消息通知设置 — 对齐 Figma「消息通知设置」与 PRD-208
final class NotificationSettingsViewController: BaseViewController {

    private enum Layout {
        static let cardCornerRadius: CGFloat = 16
        static let cardInset: CGFloat = 16
        static let cardSpacing: CGFloat = 12
        static let cardPadding: CGFloat = 12
        static let innerBoxCornerRadius: CGFloat = 12
        static let innerBoxMinHeight: CGFloat = 64
        static let sectionIconSize: CGFloat = 16
        static let sectionHeaderSpacing: CGFloat = 4
        static let headerDividerHeight: CGFloat = 1 / UIScreen.main.scale
        static let statusBadgeHeight: CGFloat = 15
        static let statusBadgeCornerRadius: CGFloat = 4
        static let chevronSize: CGFloat = 12
    }

    private enum Typography {
        static let sectionTitle = SettingsStyle.sectionTitleFont
        static let rowTitle = SettingsStyle.rowTitleFont
        static let rowSubtitle = SettingsStyle.rowSubtitleFont
        static let statusBadge = UIFont.fdFont(ofSize: 12, weight: .bold)
    }

    private enum PrefKey: String, CaseIterable {
        case service, health, appointment, marketing
    }

    private let prefsStorageKey = "fd_notification_settings"

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var systemStatusBadgeLabel: UILabel?
    private var systemStatusBadgeContainer: UIView?
    private var foregroundObserver: NSObjectProtocol?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        refreshSystemStatus()
        installForegroundObserverIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeForegroundObserver()
    }

    override func setupUI() {
        title = "消息通知设置"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        let systemCard = buildSystemCard()
        contentView.addSubview(systemCard)
        systemCard.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(Layout.cardInset)
        }

        let prefs = loadPrefs()
        let rows: [(title: String, subtitle: String, key: PrefKey)] = [
            ("服务进度提醒", "订单履约、健管师跟进、服务到期提醒", .service),
            ("健康任务提醒", "测量、评估、饮食记录等健康任务", .health),
            ("预约提醒", "体检、复诊、线上咨询开始前提醒", .appointment),
            ("活动与优惠", "权益兑换、商城优惠和服务活动", .marketing),
        ]

        let prefsCard = buildPrefsCard(rows: rows, prefs: prefs)
        contentView.addSubview(prefsCard)
        prefsCard.snp.makeConstraints {
            $0.top.equalTo(systemCard.snp.bottom).offset(Layout.cardSpacing)
            $0.leading.trailing.equalToSuperview().inset(Layout.cardInset)
            $0.bottom.equalToSuperview().offset(-24)
        }

        refreshSystemStatus()
    }

    // MARK: - System card

    private func buildSystemCard() -> UIView {
        let card = makeCard()

        let header = makeSectionHeader(iconName: "settings_section_message", title: "手机系统通知")
        card.addSubview(header)
        header.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(Layout.cardPadding)
        }

        let innerBox = UIView()
        innerBox.backgroundColor = .fdBg
        innerBox.layer.cornerRadius = Layout.innerBoxCornerRadius
        innerBox.clipsToBounds = true

        let row = UIControl()
        row.addAction(UIAction { [weak self] _ in self?.handleSystemTap() }, for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.text = "手机系统通知"
        titleLabel.font = Typography.rowTitle
        titleLabel.textColor = SettingsStyle.titleColor
        titleLabel.isUserInteractionEnabled = false

        let badge = UIView()
        badge.backgroundColor = .fdPrimary
        badge.layer.cornerRadius = Layout.statusBadgeCornerRadius
        badge.isUserInteractionEnabled = false

        let badgeLabel = UILabel()
        badgeLabel.font = Typography.statusBadge
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.isUserInteractionEnabled = false
        systemStatusBadgeLabel = badgeLabel
        systemStatusBadgeContainer = badge
        badge.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(3)
        }

        let titleRow = UIStackView(arrangedSubviews: [titleLabel, badge])
        titleRow.axis = .horizontal
        titleRow.spacing = 4
        titleRow.alignment = .center
        titleRow.isUserInteractionEnabled = false
        badge.snp.makeConstraints {
            $0.height.equalTo(Layout.statusBadgeHeight)
            $0.width.greaterThanOrEqualTo(37)
        }

        let descLabel = UILabel()
        descLabel.text = "关闭后，App无法向您推送服务与健康提醒"
        descLabel.font = Typography.rowSubtitle
        descLabel.textColor = SettingsStyle.subtitleColor
        descLabel.numberOfLines = 0
        descLabel.isUserInteractionEnabled = false

        let chevron = UIImageView(image: UIImage(named: "order_confirm_arrow_right"))
        chevron.contentMode = .scaleAspectFit
        chevron.isUserInteractionEnabled = false

        row.addSubview(titleRow)
        row.addSubview(descLabel)
        row.addSubview(chevron)

        chevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-Layout.cardPadding)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(Layout.chevronSize)
        }
        titleRow.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Layout.cardPadding)
            $0.top.equalToSuperview().offset(Layout.cardPadding)
            $0.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-8)
        }
        descLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Layout.cardPadding)
            $0.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-8)
            $0.top.equalTo(titleRow.snp.bottom).offset(4)
            $0.bottom.equalToSuperview().offset(-Layout.cardPadding)
        }

        innerBox.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview() }

        card.addSubview(innerBox)
        innerBox.snp.makeConstraints {
            $0.top.equalTo(header.snp.bottom).offset(9)
            $0.leading.trailing.equalToSuperview().inset(Layout.cardPadding)
            $0.height.greaterThanOrEqualTo(Layout.innerBoxMinHeight)
            $0.bottom.equalToSuperview().offset(-Layout.cardPadding)
        }

        return card
    }

    // MARK: - Prefs card

    private func buildPrefsCard(
        rows: [(title: String, subtitle: String, key: PrefKey)],
        prefs: [PrefKey: Bool]
    ) -> UIView {
        let card = makeCard()

        let header = makeSectionHeader(iconName: "settings_section_general", title: "通知进度提醒")
        card.addSubview(header)
        header.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(Layout.cardPadding)
        }

        let headerDivider = UIView()
        headerDivider.backgroundColor = .fdBorder
        card.addSubview(headerDivider)
        headerDivider.snp.makeConstraints {
            $0.top.equalTo(header.snp.bottom).offset(9)
            $0.leading.trailing.equalToSuperview().inset(Layout.cardPadding)
            $0.height.equalTo(Layout.headerDividerHeight)
        }

        let stack = UIStackView()
        stack.axis = .vertical
        card.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalTo(headerDivider.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        for (idx, item) in rows.enumerated() {
            let cell = SettingsToggleCell(
                model: .init(
                    title: item.title,
                    subtitle: item.subtitle,
                    isOn: prefs[item.key] ?? defaultOn(item.key)
                ),
                showDivider: idx < rows.count - 1,
                style: .notification
            )
            cell.onToggle = { [weak self] isOn in
                self?.updatePref(item.key, isOn: isOn)
            }
            stack.addArrangedSubview(cell)
        }

        return card
    }

    private func makeSectionHeader(iconName: String, title: String) -> UIView {
        let iconView = UIImageView(image: UIImage(named: iconName))
        iconView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = title
        label.font = Typography.sectionTitle
        label.textColor = SettingsStyle.titleColor

        let stack = UIStackView(arrangedSubviews: [iconView, label])
        stack.axis = .horizontal
        stack.spacing = Layout.sectionHeaderSpacing
        stack.alignment = .center

        iconView.snp.makeConstraints { $0.size.equalTo(Layout.sectionIconSize) }
        return stack
    }

    private func makeCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = Layout.cardCornerRadius
        card.clipsToBounds = true
        return card
    }

    // MARK: - System notification

    private func refreshSystemStatus() {
        Task {
            let authorized = await NotificationPromptService.shared.refreshSystemNotificationStatus()
            await MainActor.run {
                updateSystemStatusBadge(authorized: authorized)
            }
        }
    }

    private func updateSystemStatusBadge(authorized: Bool) {
        systemStatusBadgeLabel?.text = authorized ? "已开启" : "未开启"
        systemStatusBadgeContainer?.backgroundColor = authorized ? .fdPrimary : .fdTabInactive
    }

    private func installForegroundObserverIfNeeded() {
        guard foregroundObserver == nil else { return }
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshSystemStatus()
        }
    }

    private func removeForegroundObserver() {
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
            foregroundObserver = nil
        }
    }

    private func handleSystemTap() {
        Task {
            var status = await NotificationPromptService.shared.authorizationStatus()
            if status == .notDetermined {
                let authorized = await NotificationPromptService.shared.requestSystemAuthorization()
                await MainActor.run { refreshSystemStatus() }
                if authorized { return }
                status = await NotificationPromptService.shared.authorizationStatus()
            }
            await MainActor.run {
                NotificationPromptService.shared.openSystemSettings()
            }
        }
    }

    // MARK: - Prefs storage

    private func defaultOn(_ key: PrefKey) -> Bool {
        key != .marketing
    }

    private func loadPrefs() -> [PrefKey: Bool] {
        var result: [PrefKey: Bool] = [:]
        for key in PrefKey.allCases {
            result[key] = defaultOn(key)
        }
        guard let data = UserDefaults.standard.data(forKey: prefsStorageKey),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Bool] else {
            return result
        }
        for key in PrefKey.allCases {
            if let v = json[key.rawValue] { result[key] = v }
        }
        return result
    }

    private func updatePref(_ key: PrefKey, isOn: Bool) {
        var prefs = loadPrefs()
        prefs[key] = isOn
        let dict = Dictionary(uniqueKeysWithValues: prefs.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONSerialization.data(withJSONObject: dict) {
            UserDefaults.standard.set(data, forKey: prefsStorageKey)
        }
    }
}
