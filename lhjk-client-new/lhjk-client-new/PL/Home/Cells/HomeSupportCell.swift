import SnapKit
import UIKit

/// 首页咨询客服条：左侧耳机图标 +「咨询客服」，右侧电话按钮。号码仍用工程里已有的客服电话。
final class HomeSupportCell: UITableViewCell {

    static let reuseID = "HomeSupportCell"

    var onTap: (() -> Void)?

    private let card = UIControl()
    private let headsetBadge = UIView()
    private let headsetIcon = UIImageView()
    private let titleLabel = UILabel()
    private let phoneBadge = UIView()
    private let phoneIcon = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        contentView.addSubview(card)

        headsetBadge.backgroundColor = .fdPrimarySoft
        headsetBadge.layer.cornerRadius = 20
        headsetBadge.isUserInteractionEnabled = false
        headsetIcon.image = UIImage(systemName: "headphones")
        headsetIcon.tintColor = .fdPrimary
        headsetIcon.contentMode = .scaleAspectFit
        headsetIcon.isUserInteractionEnabled = false

        titleLabel.text = "咨询客服"
        titleLabel.font = .fdFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .fdText
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.isUserInteractionEnabled = false

        phoneBadge.backgroundColor = .fdPrimarySoft
        phoneBadge.layer.cornerRadius = 20
        phoneBadge.isUserInteractionEnabled = false
        phoneIcon.image = UIImage(systemName: "phone.fill")
        phoneIcon.tintColor = .fdPrimary
        phoneIcon.contentMode = .scaleAspectFit
        phoneIcon.isUserInteractionEnabled = false

        card.addSubview(headsetBadge)
        headsetBadge.addSubview(headsetIcon)
        card.addSubview(titleLabel)
        card.addSubview(phoneBadge)
        phoneBadge.addSubview(phoneIcon)

        card.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
            $0.height.greaterThanOrEqualTo(64)
        }
        headsetBadge.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(40)
            $0.top.greaterThanOrEqualToSuperview().offset(12)
            $0.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        headsetIcon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(22)
        }
        phoneBadge.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(40)
        }
        phoneIcon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(18)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(headsetBadge.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(phoneBadge.snp.leading).offset(-12)
            $0.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() { onTap?() }
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
