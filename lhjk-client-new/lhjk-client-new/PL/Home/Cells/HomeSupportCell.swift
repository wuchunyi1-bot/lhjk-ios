import SnapKit
import UIKit

/// 首页咨询客服条：暖米色渐变底 + 耳机图标 +「咨询客服」+ 右侧电话。
final class HomeSupportCell: UITableViewCell {

    static let reuseID = "HomeSupportCell"

    var onTap: (() -> Void)?
    var onAppointments: (() -> Void)?

    private let card = UIControl()
    private let seniorRow = UIStackView()
    private var normalBottom: Constraint?
    private var seniorBottom: Constraint?
    private let bellIcon = UIImageView()
    private let titleLabel = UILabel()
    private let chevronIcon = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        card.backgroundColor = .clear
        card.layer.cornerRadius = 18
        card.clipsToBounds = true
        card.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        contentView.addSubview(card)

        let gradient = SupportGradientView()
        gradient.isUserInteractionEnabled = false
        card.addSubview(gradient)
        gradient.snp.makeConstraints { $0.edges.equalToSuperview() }

        let iconBox = UIView()
        iconBox.backgroundColor = .fdPrimarySoft
        iconBox.layer.cornerRadius = 12
        iconBox.isUserInteractionEnabled = false
        bellIcon.image = UIImage(systemName: "headphones")
        bellIcon.tintColor = .fdPrimary
        bellIcon.contentMode = .scaleAspectFit
        bellIcon.isUserInteractionEnabled = false
        iconBox.addSubview(bellIcon)

        titleLabel.text = "咨询客服"
        titleLabel.font = .fdFont(ofSize: 15, weight: .bold)
        titleLabel.textColor = .fdText
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.isUserInteractionEnabled = false

        chevronIcon.image = UIImage(
            systemName: "phone.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        )
        chevronIcon.tintColor = .fdPrimary
        chevronIcon.contentMode = .scaleAspectFit
        chevronIcon.isUserInteractionEnabled = false

        let phoneCircle = UIView()
        phoneCircle.backgroundColor = .fdPrimarySoft
        phoneCircle.layer.cornerRadius = 18
        phoneCircle.isUserInteractionEnabled = false
        phoneCircle.addSubview(chevronIcon)
        chevronIcon.snp.makeConstraints { $0.center.equalToSuperview() }

        card.addSubview(iconBox)
        card.addSubview(titleLabel)
        card.addSubview(phoneCircle)

        card.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            normalBottom = $0.bottom.equalToSuperview().constraint
            $0.height.equalTo(56)
        }
        buildSeniorRow()
        applyMode()
        iconBox.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(40)
        }
        bellIcon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(22)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconBox.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(phoneCircle.snp.leading).offset(-8)
        }
        phoneCircle.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(14)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(36)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 长辈模式用两张入口卡；普通模式仍是整行咨询客服。
    func applyMode() {
        let senior = UIFont.isSeniorMode
        card.isHidden = senior
        seniorRow.isHidden = !senior
        normalBottom?.isActive = !senior
        seniorBottom?.isActive = senior
    }

    private func buildSeniorRow() {
        seniorRow.axis = .horizontal
        seniorRow.spacing = 11
        seniorRow.distribution = .fillEqually
        seniorRow.addArrangedSubview(shortcutCard(
            imageName: "home_ reserve_card",
            title: "我的权益",
            color: UIColor(hexString: "#005294"),
            action: #selector(appointmentsTapped)
        ))
        seniorRow.addArrangedSubview(shortcutCard(
            imageName: "home_assistant_card",
            title: "咨询客服",
            color: UIColor(hexString: "#945600"),
            action: #selector(tapped)
        ))
        contentView.addSubview(seniorRow)
        seniorRow.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            seniorBottom = $0.bottom.equalToSuperview().constraint
        }
        seniorBottom?.isActive = false
    }

    private func shortcutCard(imageName: String, title: String, color: UIColor, action: Selector) -> UIControl {
        let control = UIControl()
        control.layer.cornerRadius = 12
        control.clipsToBounds = true
        control.addTarget(self, action: action, for: .touchUpInside)

        let imageView = UIImageView(image: UIImage(named: imageName))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = false

        let label = UILabel()
        label.text = title
        label.font = .fdFont(designSize: 14, seniorSize: 18, weight: .medium)
        label.textColor = color
        label.isUserInteractionEnabled = false

        control.addSubview(imageView)
        control.addSubview(label)
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(imageView.snp.width).multipliedBy(168.0 / 332.0)
        }
        label.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(14)
            $0.width.lessThanOrEqualTo(88)
        }
        return control
    }

    @objc private func tapped() { onTap?() }

    @objc private func appointmentsTapped() { onAppointments?() }
}

/// 咨询客服条背景。设计稿暖色渐变 `#FFEFE6` → `#FFF8F3`，135°。
private final class SupportGradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        guard let gradient = layer as? CAGradientLayer else { return }
        gradient.colors = [
            UIColor(hexString: "#FFEFE6").cgColor,
            UIColor(hexString: "#FFF8F3").cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// 客服电话底部弹层：展示号码并拨打。
final class HomeSupportCallSheet: UIViewController {

    private let phone = OrderReturnGoodsSheet.defaultPhoneNumber
    private let panel = UIView()

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        let dim = UIControl()
        dim.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dim.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(dim)
        dim.snp.makeConstraints { $0.edges.equalToSuperview() }

        panel.backgroundColor = .fdSurface
        panel.layer.cornerRadius = 16
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(panel)

        let title = UILabel()
        title.text = "客服电话"
        title.font = .fdFont(ofSize: 18, weight: .medium)
        title.textColor = .fdText
        title.textAlignment = .center

        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
        close.tintColor = .fdSubtext
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let number = UILabel()
        number.text = phone
        number.font = .fdFont(ofSize: 28, weight: .medium)
        number.textColor = .fdText
        number.textAlignment = .center

        let call = UIButton(type: .system)
        call.setTitle("立即拨打", for: .normal)
        call.setTitleColor(.white, for: .normal)
        call.titleLabel?.font = .fdBody
        call.backgroundColor = .fdPrimary
        call.layer.cornerRadius = 22
        call.addTarget(self, action: #selector(callTapped), for: .touchUpInside)

        panel.addSubview(title)
        panel.addSubview(close)
        panel.addSubview(number)
        panel.addSubview(call)

        panel.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }
        title.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
        }
        close.snp.makeConstraints {
            $0.centerY.equalTo(title)
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(32)
        }
        number.snp.makeConstraints {
            $0.top.equalTo(title.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        call.snp.makeConstraints {
            $0.top.equalTo(number.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(44)
            $0.bottom.equalTo(panel.safeAreaLayoutGuide).offset(-16)
        }

    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func callTapped() {
        let digits = phone.filter(\.isNumber)
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else { return }
        UIApplication.shared.open(url)
    }
}
