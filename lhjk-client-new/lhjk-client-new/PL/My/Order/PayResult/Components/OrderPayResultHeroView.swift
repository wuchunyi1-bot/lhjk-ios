import UIKit
import SnapKit

/// 支付结果英雄区：`pay_success` / `pay_failed` 80pt 切图
final class OrderPayResultHeroView: UIView {

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let amountLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { $0.size.equalTo(80) }

        titleLabel.font = .fdFont(ofSize: 18, weight: .regular)
        titleLabel.textColor = UIColor(hexString: "#1F2942")
        titleLabel.textAlignment = .center

        amountLabel.textAlignment = .center

        descriptionLabel.font = .fdFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = UIColor(hexString: "#8591AB")
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(amountLabel)
        stack.addArrangedSubview(descriptionLabel)
        stack.setCustomSpacing(16, after: iconView)

        addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        titleLabel.snp.makeConstraints { $0.leading.trailing.equalToSuperview() }
        amountLabel.snp.makeConstraints { $0.leading.trailing.equalToSuperview() }
        descriptionLabel.snp.makeConstraints { $0.leading.trailing.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(payload: OrderPayResultPayload, amountYuan: Double) {
        titleLabel.text = payload.titleText
        iconView.image = UIImage(named: payload.outcome == .success ? "pay_success" : "pay_failed")
        descriptionLabel.text = payload.descriptionText
        descriptionLabel.isHidden = false

        switch payload.outcome {
        case .success:
            amountLabel.isHidden = false
            amountLabel.attributedText = Self.formatHeroPrice(amountYuan)
        case .failure:
            amountLabel.isHidden = true
        }
    }

    private static func formatHeroPrice(_ value: Double) -> NSAttributedString {
        let safe = max(0, value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        let num = formatter.string(from: NSNumber(value: safe)) ?? String(format: "%.2f", safe)

        let color = UIColor(hexString: "#1F2942")
        let attr = NSMutableAttributedString()
        attr.append(NSAttributedString(
            string: "¥ ",
            attributes: [
                .font: UIFont.fdFont(ofSize: 24, weight: .medium),
                .foregroundColor: color
            ]
        ))
        attr.append(NSAttributedString(
            string: num,
            attributes: [
                .font: UIFont.fdFont(ofSize: 32, weight: .medium),
                .foregroundColor: color
            ]
        ))
        return attr
    }
}
