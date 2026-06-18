import UIKit

/// 消息通知设置页
/// 参考 funde-client: prototype/src/views/me/settings/NotificationSettingsView.vue
///
/// 4 个开关行包裹在一张 fd-card 内：
///   服务进度提醒 / 健康任务提醒 / 预约提醒 / 活动与优惠
final class NotificationSettingsViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let storageKeys = (
        service: "noti_service",
        health: "noti_health",
        appointment: "noti_appointment",
        marketing: "noti_marketing"
    )

    private var toggles: [(String, String, String, SettingsToggleCell)] = []

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "消息通知设置"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        let items: [(title: String, subtitle: String, key: String)] = [
            ("服务进度提醒", "订单履约、健管师跟进、服务到期提醒", storageKeys.service),
            ("健康任务提醒", "测量、评估、饮食记录等健康任务", storageKeys.health),
            ("预约提醒", "体检、复诊、线上咨询开始前提醒", storageKeys.appointment),
            ("活动与优惠", "权益兑换、商城优惠和服务活动", storageKeys.marketing),
        ]

        let card = buildCard()
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
        }

        let stack = UIStackView()
        stack.axis = .vertical
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        for (i, item) in items.enumerated() {
            let isOn = UserDefaults.standard.object(forKey: item.key) as? Bool ?? true
            let toggle = SettingsToggleCell(
                model: SettingsToggleCell.Model(title: item.title, subtitle: item.subtitle, isOn: isOn),
                showDivider: i < items.count - 1
            )
            toggle.onToggle = { val in
                UserDefaults.standard.set(val, forKey: item.key)
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
