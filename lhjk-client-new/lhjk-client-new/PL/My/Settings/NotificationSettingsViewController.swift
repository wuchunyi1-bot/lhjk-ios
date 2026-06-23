import UIKit

/// 消息通知设置页
/// 参考 funde-client: prototype/src/views/me/settings/NotificationSettingsView.vue
/// PRD: 02_用户_我的设置_v1.0 §5.8 — 本期仅管理手机系统通知
///
/// 单一设置行：手机系统通知（已开启 / 去开启）
/// 后续版本可扩展：服务通知、指标预警、随访提醒、免打扰时段
final class NotificationSettingsViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let storageKey = "fd_system_notification"
    private var notifyEnabled = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        notifyEnabled = UserDefaults.standard.object(forKey: storageKey) as? Bool ?? true
    }

    override func setupUI() {
        title = "消息通知"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        // Hint card
        let hintCard: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hexString: "#FFF3EE")
            v.layer.cornerRadius = 24

            let title = UILabel()
            title.text = "及时收到健康提醒"
            title.font = .fdFont(ofSize: 19, weight: .heavy)
            title.textColor = .fdText

            let desc = UILabel()
            desc.text = "开启通知后，您将收到服务进度、健康任务、预约提醒等重要消息。"
            desc.font = .fdBody
            desc.textColor = .fdSubtext
            desc.numberOfLines = 0

            v.addSubview(title); v.addSubview(desc)
            title.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(18) }
            desc.snp.makeConstraints { $0.top.equalTo(title.snp.bottom).offset(8); $0.leading.trailing.bottom.equalToSuperview().inset(18) }
            return v
        }()

        contentView.addSubview(hintCard)
        hintCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        // Card with notification row
        let card = buildCard()
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalTo(hintCard.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
        }

        let stack = UIStackView(); stack.axis = .vertical
        card.addSubview(stack); stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Row: 手机系统通知
        let row = makeLinkRow(label: "手机系统通知", value: notifyEnabled ? "已开启" : "去开启", showDivider: false)
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSystemNotifyTap)))
        stack.addArrangedSubview(row)
    }

    // MARK: - Builders

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

    private func makeLinkRow(label: String, value: String, showDivider: Bool) -> UIView {
        let row = UIView(); row.isUserInteractionEnabled = true

        let titleLbl = UILabel()
        titleLbl.text = label
        titleLbl.font = .fdBody
        titleLbl.textColor = .fdText

        let valueLbl = UILabel()
        valueLbl.text = value
        valueLbl.font = .fdCaption
        valueLbl.textColor = .fdSubtext

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .fdMuted; arrow.contentMode = .scaleAspectFit

        [titleLbl, valueLbl, arrow].forEach(row.addSubview)
        arrow.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview(); $0.size.equalTo(16) }
        valueLbl.snp.makeConstraints { $0.trailing.equalTo(arrow.snp.leading).offset(-4); $0.centerY.equalToSuperview() }
        titleLbl.snp.makeConstraints { $0.leading.equalToSuperview().inset(16); $0.centerY.equalToSuperview(); $0.trailing.lessThanOrEqualTo(valueLbl.snp.leading).offset(-8) }

        if showDivider {
            let divider = UIView(); divider.backgroundColor = .fdBorder
            row.addSubview(divider)
            divider.snp.makeConstraints { $0.leading.equalTo(titleLbl); $0.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
        }
        row.snp.makeConstraints { $0.height.equalTo(48) }
        return row
    }

    // MARK: - Actions

    @objc private func handleSystemNotifyTap() {
        // In production, this would open system Settings app
        // For prototype: toggle the mock state
        notifyEnabled.toggle()
        UserDefaults.standard.set(notifyEnabled, forKey: storageKey)
        let msg = notifyEnabled
            ? "请在系统设置中管理「富德健康」的通知权限"
            : "请在系统设置中开启「富德健康」的通知权限"
        showToast(msg)
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
