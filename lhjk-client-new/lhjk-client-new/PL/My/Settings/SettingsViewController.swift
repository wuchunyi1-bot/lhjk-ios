import UIKit
import SnapKit

/// 设置主列表页
/// 参考 funde-client: prototype/src/views/me/SettingsView.vue
///
/// 卡片式布局（UIScrollView）：
///   Card 1: 账号安全 / 隐私设置
///   Card 2: 消息通知 / 长辈版（toggle）/ 清理缓存
///   Card 3: 个人信息收集清单 / 第三方信息共享清单
///   Card 4: 关于我们
///   Bottom: 退出登录按钮
final class SettingsViewController: BaseViewController {

    // MARK: - Associated Object Key

    private static var rowActionKey: UInt8 = 0

    // MARK: - Storage Keys

    private let seniorModeKey = "fd_senior_mode"
    private let cacheSizeKey = "fd_cache_size"

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var cacheSizeLabel: UILabel?

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        updateCacheSizeLabel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if navigationController?.viewControllers.last is MyViewController {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }

    override func setupUI() {
        title = "设置"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        var lastBottom: ConstraintItem = contentView.snp.top

        // MARK: Card 1 — 账号安全 + 隐私设置

        let card1Items: [(label: String, route: String)] = [
            ("账号安全", "/me/settings/security"),
            ("隐私设置", "/me/settings/privacy"),
        ]
        let card1 = buildCard(rows: card1Items.map { item in
            makeLinkRow(label: item.label, showDivider: item.label != card1Items.last?.label, action: { [weak self] in
                Router.shared.push(item.route)
            })
        })
        contentView.addSubview(card1)
        card1.snp.makeConstraints { make in
            make.top.equalTo(lastBottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        lastBottom = card1.snp.bottom

        // MARK: Card 2 — 消息通知 + 长辈版 + 清理缓存

        let card2 = buildCardContainer()
        let card2Stack = UIStackView(); card2Stack.axis = .vertical
        card2.addSubview(card2Stack)
        card2Stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        // 消息通知 row
        let notiRow = makeLinkRow(label: "消息通知", showDivider: true, action: { [weak self] in
            Router.shared.push("/me/settings/notifications")
        })
        card2Stack.addArrangedSubview(notiRow)

        // 长辈版 toggle
        let seniorOn = UserDefaults.standard.object(forKey: seniorModeKey) as? Bool ?? false
        let seniorToggle = SettingsToggleCell(
            model: SettingsToggleCell.Model(
                title: "长辈版",
                subtitle: "开启后使用大字号、大按钮和高对比显示",
                isOn: seniorOn
            ),
            showDivider: true
        )
        seniorToggle.onToggle = { [weak self] val in
            self?.toggleSeniorMode(val)
        }
        card2Stack.addArrangedSubview(seniorToggle)

        // 清理缓存 row
        let cacheLabel = UILabel()
        cacheLabel.font = .fdCaption
        cacheLabel.textColor = .fdSubtext
        cacheLabel.text = cacheSizeText()
        self.cacheSizeLabel = cacheLabel

        let cacheRow = makeLinkRow(label: "清理缓存", valueView: cacheLabel, showDivider: false, action: { [weak self] in
            self?.handleClearCache()
        })
        card2Stack.addArrangedSubview(cacheRow)

        contentView.addSubview(card2)
        card2.snp.makeConstraints { make in
            make.top.equalTo(lastBottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        lastBottom = card2.snp.bottom

        // MARK: Card 3 — 个人信息收集清单 + 第三方信息共享清单

        let card3Items: [(label: String, dialogTitle: String, dialogMessage: String)] = [
            ("个人信息收集清单", "个人信息收集清单",
             "这里是《个人信息收集清单》的完整内容。\n\n在原型阶段，此处展示清单摘要。\n\n一、账号信息\n- 手机号\n- 微信授权信息\n- 头像/昵称\n\n二、健康信息\n- 健康档案数据\n- 健康指标测量记录\n- 体检报告\n\n三、服务信息\n- 订单与交易记录\n- 服务履约记录\n- 咨询交流记录"),
            ("第三方信息共享清单", "第三方信息共享清单",
             "这里是《第三方信息共享清单》的完整内容。\n\n在原型阶段，此处展示清单摘要。\n\n一、第三方 SDK 列表\n1. 微信 SDK - 用于微信登录和微信支付\n2. 个推 SDK - 用于消息推送\n3. 支付宝 SDK - 用于支付宝支付\n\n二、数据共享场景\n仅在必要情况下与上述第三方共享脱敏或最小化信息。"),
        ]
        let card3 = buildCard(rows: card3Items.map { item in
            makeLinkRow(label: item.label, showDivider: item.label != card3Items.last?.label, action: { [weak self] in
                self?.showDialog(title: item.dialogTitle, message: item.dialogMessage)
            })
        })
        contentView.addSubview(card3)
        card3.snp.makeConstraints { make in
            make.top.equalTo(lastBottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        lastBottom = card3.snp.bottom

        // MARK: Card 4 — 关于我们

        let card4 = buildCard(rows: [
            makeLinkRow(label: "关于我们", showDivider: false, action: { [weak self] in
                Router.shared.push("/me/settings/about")
            })
        ])
        contentView.addSubview(card4)
        card4.snp.makeConstraints { make in
            make.top.equalTo(lastBottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        lastBottom = card4.snp.bottom

        // MARK: 退出登录 Button

        let logoutBtn: UIButton = {
            let b = UIButton(type: .system)
            b.setTitle("退出登录", for: .normal)
            b.titleLabel?.font = .fdFont(ofSize: 16, weight: .heavy)
            b.setTitleColor(.fdDanger, for: .normal)
            b.backgroundColor = .fdSurface
            b.layer.cornerRadius = 25
            b.layer.borderWidth = 1
            b.layer.borderColor = UIColor.fdDanger.withAlphaComponent(0.24).cgColor
            b.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
            return b
        }()
        contentView.addSubview(logoutBtn)
        logoutBtn.snp.makeConstraints { make in
            make.top.equalTo(lastBottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-32)
        }
    }

    // MARK: - Card Helpers

    private func buildCardContainer() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        return card
    }

    /// Build a card with pre-made rows
    private func buildCard(rows: [UIView]) -> UIView {
        let card = buildCardContainer()
        let stack = UIStackView(); stack.axis = .vertical
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        rows.forEach { stack.addArrangedSubview($0) }
        return card
    }

    // MARK: - Row Helpers

    private func makeLinkRow(label: String, showDivider: Bool, action: @escaping () -> Void) -> UIView {
        let row = UIView(); row.isUserInteractionEnabled = true
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rowTapped(_:))))
        objc_setAssociatedObject(row, &SettingsViewController.rowActionKey, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let titleLbl = UILabel()
        titleLbl.text = label
        titleLbl.font = .fdBody
        titleLbl.textColor = .fdText

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .fdMuted; arrow.contentMode = .scaleAspectFit

        [titleLbl, arrow].forEach(row.addSubview)
        arrow.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview(); $0.size.equalTo(16) }
        titleLbl.snp.makeConstraints { $0.leading.equalToSuperview().inset(16); $0.centerY.equalToSuperview(); $0.trailing.lessThanOrEqualTo(arrow.snp.leading).offset(-8) }

        if showDivider {
            let divider = UIView(); divider.backgroundColor = .fdBorder
            row.addSubview(divider)
            divider.snp.makeConstraints { $0.leading.equalTo(titleLbl); $0.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
        }
        row.snp.makeConstraints { $0.height.equalTo(48) }
        return row
    }

    private func makeLinkRow(label: String, valueView: UIView, showDivider: Bool, action: @escaping () -> Void) -> UIView {
        let row = UIView(); row.isUserInteractionEnabled = true
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rowTapped(_:))))
        objc_setAssociatedObject(row, &SettingsViewController.rowActionKey, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let titleLbl = UILabel()
        titleLbl.text = label
        titleLbl.font = .fdBody
        titleLbl.textColor = .fdText

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .fdMuted; arrow.contentMode = .scaleAspectFit

        [titleLbl, valueView, arrow].forEach(row.addSubview)
        arrow.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview(); $0.size.equalTo(16) }
        valueView.snp.makeConstraints { $0.trailing.equalTo(arrow.snp.leading).offset(-4); $0.centerY.equalToSuperview() }
        titleLbl.snp.makeConstraints { $0.leading.equalToSuperview().inset(16); $0.centerY.equalToSuperview(); $0.trailing.lessThanOrEqualTo(valueView.snp.leading).offset(-8) }

        if showDivider {
            let divider = UIView(); divider.backgroundColor = .fdBorder
            row.addSubview(divider)
            divider.snp.makeConstraints { $0.leading.equalTo(titleLbl); $0.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
        }
        row.snp.makeConstraints { $0.height.equalTo(48) }
        return row
    }

    @objc private func rowTapped(_ gesture: UITapGestureRecognizer) {
        guard let row = gesture.view,
              let action = objc_getAssociatedObject(row, &SettingsViewController.rowActionKey) as? () -> Void else { return }
        action()
    }

    // MARK: - Actions

    private func toggleSeniorMode(_ isOn: Bool) {
        UserDefaults.standard.set(isOn, forKey: seniorModeKey)
        UIFont.isSeniorMode = isOn
        showToast(isOn ? "已切换至长辈版" : "已切换至标准版")
    }

    private func handleClearCache() {
        UserDefaults.standard.set("0 B", forKey: cacheSizeKey)
        updateCacheSizeLabel()
        showToast("清理成功")
    }

    private func updateCacheSizeLabel() {
        cacheSizeLabel?.text = cacheSizeText()
    }

    private func cacheSizeText() -> String {
        return UserDefaults.standard.string(forKey: cacheSizeKey) ?? "0 B"
    }

    private func showDialog(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "关闭", style: .default))
        present(alert, animated: true)
    }

    @objc private func handleLogout() {
        let alert = UIAlertController(
            title: "确认退出登录",
            message: "退出后需要重新登录才能使用富德健康。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "退出登录", style: .destructive) { [weak self] _ in
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

    // MARK: - Toast

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
