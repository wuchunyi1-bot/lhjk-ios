import UIKit

/// 长辈模式 — 即原来的老年模式（`UIFont.isSeniorMode`）
///
/// 开启后 `fd*` 字号放大，并通知已打开的页面刷新。
final class AccessibilitySettingsViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
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
        title = "长辈模式"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        buildContent()

        seniorObserver = NotificationCenter.default.addObserver(
            forName: UIFont.seniorModeDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildContent()
        }
    }

    private func rebuildContent() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        buildContent()
    }

    private func buildContent() {
        let heroCard = UIView()
        heroCard.backgroundColor = UIColor(hexString: "#FFF3EE")
        heroCard.layer.cornerRadius = 24

        let heroTitle = UILabel()
        heroTitle.text = "字更大，操作更简单"
        heroTitle.font = .fdMyH3
        heroTitle.textColor = .fdText

        let heroDesc = UILabel()
        heroDesc.text = "开启后，列表、按钮和关键数字会使用更大字号，方便阅读和点按。"
        heroDesc.font = .fdMyBody
        heroDesc.textColor = .fdSubtext
        heroDesc.numberOfLines = 0

        heroCard.addSubview(heroTitle)
        heroCard.addSubview(heroDesc)
        heroTitle.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(18)
        }
        heroDesc.snp.makeConstraints { make in
            make.top.equalTo(heroTitle.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(18)
        }

        let toggle = SettingsToggleCell(
            model: SettingsToggleCell.Model(
                title: "长辈模式",
                subtitle: "字更大，操作更简单",
                isOn: UIFont.isSeniorMode
            ),
            showDivider: false
        )
        toggle.onToggle = { isOn in
            UIFont.isSeniorMode = isOn
        }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        card.addSubview(toggle)
        toggle.snp.makeConstraints { $0.edges.equalToSuperview() }

        contentView.addSubview(heroCard)
        contentView.addSubview(card)
        heroCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        card.snp.makeConstraints { make in
            make.top.equalTo(heroCard.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
}
