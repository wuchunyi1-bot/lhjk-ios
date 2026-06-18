import UIKit

/// 大字显示与简洁操作页
/// 参考 funde-client: prototype/src/views/me/settings/AccessibilitySettingsView.vue
///
/// Hero 卡片（浅橙） + 4 个开关行包裹在一张 fd-card 内：
///   大字显示 / 简洁操作 / 高对比显示 / 语音提示
/// 大字显示开关联动 UIFont.isSeniorMode，切换后整个页面字号即时生效
final class AccessibilitySettingsViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let storageKeys = (
        largeText: "access_large_text",
        simpleMode: "access_simple_mode",
        strongContrast: "access_strong_contrast",
        voicePrompt: "access_voice_prompt"
    )

    // Observe senior mode changes to refresh UI
    private var seniorObserver: NSObjectProtocol?

    deinit {
        if let obs = seniorObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "大字显示与简洁操作"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        buildContent()

        // When senior mode changes elsewhere, rebuild this page's fonts
        seniorObserver = NotificationCenter.default.addObserver(
            forName: UIFont.seniorModeDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildContent()
        }
    }

    /// Clear and rebuild all font-dependent subviews
    private func rebuildContent() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        buildContent()
    }

    private func buildContent() {
        // Hero card
        let heroCard: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hexString: "#FFF3EE")
            v.layer.cornerRadius = 24

            let title = UILabel()
            title.text = "看得清，点得准"
            title.font = .fdFont(ofSize: 19, weight: .heavy)
            title.textColor = .fdText

            let desc = UILabel()
            desc.text = "放大文字和关键按钮，减少复杂入口，适合需要更轻松操作的用户。"
            desc.font = .fdBody
            desc.textColor = .fdSubtext
            desc.numberOfLines = 0

            v.addSubview(title)
            v.addSubview(desc)
            title.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview().inset(18)
            }
            desc.snp.makeConstraints { make in
                make.top.equalTo(title.snp.bottom).offset(8)
                make.leading.trailing.bottom.equalToSuperview().inset(18)
            }
            return v
        }()

        contentView.addSubview(heroCard)
        heroCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        // Toggle items — read current state from UserDefaults
        let items: [(title: String, subtitle: String, key: String, isOn: Bool)] = [
            ("大字显示", "列表、按钮和关键数字使用更大字号",
             storageKeys.largeText, UserDefaults.standard.object(forKey: storageKeys.largeText) as? Bool ?? true),
            ("简洁操作", "减少弱相关入口，突出常用功能",
             storageKeys.simpleMode, UserDefaults.standard.object(forKey: storageKeys.simpleMode) as? Bool ?? true),
            ("高对比显示", "提高文字和按钮的对比度",
             storageKeys.strongContrast, UserDefaults.standard.object(forKey: storageKeys.strongContrast) as? Bool ?? false),
            ("语音提示", "关键操作增加语音确认提示",
             storageKeys.voicePrompt, UserDefaults.standard.object(forKey: storageKeys.voicePrompt) as? Bool ?? false),
        ]

        let card = buildCard()
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalTo(heroCard.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
        }

        let stack = UIStackView()
        stack.axis = .vertical
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        for (i, item) in items.enumerated() {
            let toggle = SettingsToggleCell(
                model: SettingsToggleCell.Model(title: item.title, subtitle: item.subtitle, isOn: item.isOn),
                showDivider: i < items.count - 1
            )
            toggle.onToggle = { [weak self] val in
                UserDefaults.standard.set(val, forKey: item.key)
                // 大字显示联动全局字体 — 触发通知后 rebuildContent 自动调用
                if item.key == self?.storageKeys.largeText {
                    UIFont.isSeniorMode = val
                }
            }
            stack.addArrangedSubview(toggle)
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
}
