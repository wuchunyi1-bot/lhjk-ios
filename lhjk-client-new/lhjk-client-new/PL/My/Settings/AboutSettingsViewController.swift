import UIKit
import SnapKit

/// 关于富德健康 — 对齐 PRD-213 / AboutSettingsView.vue / me-settings-about.page.yaml
///
/// 品牌 Hero + 信息卡（版本 / 评分 / 联系我们）+ 页脚版权与备案；不展示协议入口。
final class AboutSettingsViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let bgGradient = CAGradientLayer()

    private var appVersionText: String {
        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return "v\(ver)"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "关于富德健康"
        view.backgroundColor = .fdBg

        bgGradient.colors = [
            UIColor(hexString: "#FFF8F4").cgColor,
            UIColor.fdBg.cgColor,
            UIColor.fdBg.cgColor,
        ]
        bgGradient.locations = [0, 0.35, 1]
        view.layer.insertSublayer(bgGradient, at: 0)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        let brand = buildBrandSection()
        contentView.addSubview(brand)
        brand.snp.makeConstraints {
            $0.top.equalToSuperview().offset(28)
            $0.leading.trailing.equalToSuperview()
        }

        let card = buildInfoCard()
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalTo(brand.snp.bottom).offset(22)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        let footer = buildFooter()
        contentView.addSubview(footer)
        footer.snp.makeConstraints {
            $0.top.equalTo(card.snp.bottom).offset(28)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-32)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bgGradient.frame = view.bounds
    }

    // MARK: - Brand

    private func buildBrandSection() -> UIView {
        let wrap = UIView()

        let logo = UIImageView(image: UIImage(named: "login_logo"))
        logo.contentMode = .scaleAspectFill
        logo.clipsToBounds = true
        logo.layer.cornerRadius = 18
        logo.accessibilityLabel = "富德健康"

        let nameLabel = UILabel()
        nameLabel.text = "富德健康"
        nameLabel.font = .fdFont(ofSize: 20, weight: .heavy)
        nameLabel.textColor = .fdText
        nameLabel.textAlignment = .center

        let sloganLabel = UILabel()
        sloganLabel.text = "健康生命 · 美好生活"
        sloganLabel.font = .fdCaption
        sloganLabel.textColor = .fdSubtext
        sloganLabel.textAlignment = .center

        [logo, nameLabel, sloganLabel].forEach(wrap.addSubview)
        logo.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.size.equalTo(68)
        }
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(logo.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }
        sloganLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(6)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        return wrap
    }

    // MARK: - Info card

    private func buildInfoCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        card.clipsToBounds = false

        let stack = UIStackView()
        stack.axis = .vertical
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        stack.addArrangedSubview(makeRow(
            label: "当前版本",
            value: appVersionText,
            showArrow: true,
            showDivider: true,
            tappable: true,
            action: #selector(handleVersionTap)
        ))
        stack.addArrangedSubview(makeRow(
            label: "去应用市场评分",
            value: "去评分",
            showArrow: true,
            showDivider: true,
            tappable: true,
            action: #selector(handleRatingTap)
        ))
        stack.addArrangedSubview(makeRow(
            label: "联系我们",
            value: "400-888-6520",
            showArrow: false,
            showDivider: false,
            tappable: false,
            action: nil
        ))

        return card
    }

    private func makeRow(
        label: String,
        value: String,
        showArrow: Bool,
        showDivider: Bool,
        tappable: Bool,
        action: Selector?
    ) -> UIView {
        let row = UIControl()
        if let action, tappable {
            row.addTarget(self, action: action, for: .touchUpInside)
        }

        let titleLbl = UILabel()
        titleLbl.text = label
        titleLbl.font = .fdBodySemibold
        titleLbl.textColor = .fdText2

        let valueLbl = UILabel()
        valueLbl.text = value
        valueLbl.font = .fdCaption
        valueLbl.textColor = .fdSubtext
        valueLbl.setContentCompressionResistancePriority(.required, for: .horizontal)

        let side = UIStackView()
        side.axis = .horizontal
        side.alignment = .center
        side.spacing = 4
        side.addArrangedSubview(valueLbl)

        if showArrow {
            let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
            arrow.tintColor = .fdMuted
            arrow.contentMode = .scaleAspectFit
            arrow.snp.makeConstraints { $0.size.equalTo(16) }
            side.addArrangedSubview(arrow)
        }

        row.addSubview(titleLbl)
        row.addSubview(side)
        titleLbl.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(side.snp.leading).offset(-12)
        }
        side.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
        row.snp.makeConstraints { $0.height.greaterThanOrEqualTo(52) }

        if showDivider {
            let divider = UIView()
            divider.backgroundColor = .fdBorder
            row.addSubview(divider)
            divider.snp.makeConstraints {
                $0.leading.equalToSuperview().inset(16)
                $0.trailing.bottom.equalToSuperview()
                $0.height.equalTo(1 / UIScreen.main.scale)
            }
        }
        return row
    }

    // MARK: - Footer

    private func buildFooter() -> UIView {
        let wrap = UIView()

        let copyright = UILabel()
        copyright.text = "Copyright © 2026 富德健康"
        copyright.font = .fdMicro
        copyright.textColor = .fdMuted
        copyright.textAlignment = .center

        let icp = UILabel()
        icp.text = "粤ICP备xxxxx号"
        icp.font = .fdMicro
        icp.textColor = .fdMuted
        icp.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [copyright, icp])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .center
        wrap.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
        }
        return wrap
    }

    // MARK: - Actions

    @objc private func handleVersionTap() {
        showToast("当前已经是最新版本")
    }

    @objc private func handleRatingTap() {
        showToast("暂无法打开应用市场")
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
