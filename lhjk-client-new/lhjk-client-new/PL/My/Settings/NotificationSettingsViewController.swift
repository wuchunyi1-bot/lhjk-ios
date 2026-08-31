import UIKit
import SnapKit

/// 消息通知设置 — 对齐 PRD-208 / 设置 PRD §5.8.6
final class NotificationSettingsViewController: BaseViewController {

    private enum PrefKey: String, CaseIterable {
        case service, health, appointment, marketing
    }

    private let prefsStorageKey = "fd_notification_settings"

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var systemStatusLabel: UILabel?
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

        let systemSection = buildSystemSection()
        contentView.addSubview(systemSection)
        systemSection.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview()
        }

        let prefs = loadPrefs()
        let rows: [(title: String, subtitle: String, key: PrefKey)] = [
            ("服务进度提醒", "订单履约、健管师跟进、服务到期提醒", .service),
            ("健康任务提醒", "测量、评估、饮食记录等健康任务", .health),
            ("预约提醒", "体检、复诊、线上咨询开始前提醒", .appointment),
            ("活动与优惠", "权益兑换、商城优惠和服务活动", .marketing),
        ]

        let prefsSection = buildPrefsSection(rows: rows, prefs: prefs)
        contentView.addSubview(prefsSection)
        prefsSection.snp.makeConstraints {
            $0.top.equalTo(systemSection.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-24)
        }

        refreshSystemStatus()
    }

    // MARK: - System section

    private func buildSystemSection() -> UIView {
        let wrap = UIView()

        let title = UILabel()
        title.text = "手机系统通知"
        title.font = .fdMyCaptionSemibold
        title.textColor = .fdSubtext
        wrap.addSubview(title)
        title.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        let card = makeCard()
        wrap.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalTo(title.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }

        let row = UIControl()
        row.addAction(UIAction { [weak self] _ in self?.handleSystemTap() }, for: .touchUpInside)

        let label = UILabel()
        label.text = "手机系统通知"
        label.font = .fdMyBodySemibold
        label.textColor = .fdText
        label.isUserInteractionEnabled = false

        let desc = UILabel()
        desc.text = "关闭后，App 无法向您推送服务与健康提醒"
        desc.font = .fdFont(ofSize: 13, weight: .regular)
        desc.textColor = .fdSubtext
        desc.numberOfLines = 2
        desc.isUserInteractionEnabled = false

        let textStack = UIStackView(arrangedSubviews: [label, desc])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.isUserInteractionEnabled = false

        let value = UILabel()
        value.font = .fdMyCaption
        value.textColor = .fdPrimary
        value.setContentCompressionResistancePriority(.required, for: .horizontal)
        value.isUserInteractionEnabled = false
        systemStatusLabel = value

        row.addSubview(textStack)
        row.addSubview(value)
        textStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalTo(value.snp.leading).offset(-12)
            $0.top.equalToSuperview().offset(14)
            $0.bottom.equalToSuperview().offset(-14)
        }
        value.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }

        card.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview() }

        return wrap
    }

    // MARK: - Prefs section

    private func buildPrefsSection(
        rows: [(title: String, subtitle: String, key: PrefKey)],
        prefs: [PrefKey: Bool]
    ) -> UIView {
        let wrap = UIView()

        let title = UILabel()
        title.text = "通知提醒"
        title.font = .fdMyCaptionSemibold
        title.textColor = .fdSubtext
        wrap.addSubview(title)
        title.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        let card = makeCard()
        wrap.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalTo(title.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }

        let stack = UIStackView()
        stack.axis = .vertical
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        for (idx, item) in rows.enumerated() {
            let cell = SettingsToggleCell(
                model: .init(
                    title: item.title,
                    subtitle: item.subtitle,
                    isOn: prefs[item.key] ?? defaultOn(item.key)
                ),
                showDivider: idx < rows.count - 1
            )
            cell.onToggle = { [weak self] isOn in
                self?.updatePref(item.key, isOn: isOn)
            }
            stack.addArrangedSubview(cell)
        }

        return wrap
    }

    private func makeCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        return card
    }

    // MARK: - System notification

    private func refreshSystemStatus() {
        Task {
            let authorized = await NotificationPromptService.shared.refreshSystemNotificationStatus()
            await MainActor.run {
                systemStatusLabel?.text = authorized ? "已开启" : "未开启"
            }
        }
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
