import UIKit
import SnapKit

/// 绑定权益卡入口 — 对齐 Figma 3835:32613
final class VoucherBindEntryCell: UITableViewCell {
    static let reuseID = "VoucherBindEntryCell"

    var onTap: (() -> Void)?

    private let cardButton = UIButton(type: .custom)
    private let bgGradientLayer = CAGradientLayer()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let actionButton = UIButton(type: .custom)
    private let actionBgLayer = CAGradientLayer()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .white

        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        bgGradientLayer.frame = cardButton.bounds
        actionBgLayer.frame = actionButton.bounds
    }

    private func setupUI() {
        // Card Container
        cardButton.layer.cornerRadius = 16
        cardButton.layer.borderWidth = 0.5
        cardButton.layer.borderColor = UIColor(hexString: "#FFECD2").cgColor
        cardButton.clipsToBounds = true
        cardButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        bgGradientLayer.colors = [
            UIColor(hexString: "#FFF3E1").cgColor,
            UIColor(hexString: "#FFFAF3").cgColor
        ]
        bgGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        bgGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        cardButton.layer.insertSublayer(bgGradientLayer, at: 0)

        contentView.addSubview(cardButton)
        cardButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(80)
        }

        // Left Icon (48x48)
        iconImageView.image = UIImage(named: "voucher_bind_entry_icon")
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.cornerRadius = 12
        iconImageView.clipsToBounds = true
        iconImageView.isUserInteractionEnabled = false
        cardButton.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
        }

        // Right Action Button (70x28)
        actionButton.layer.cornerRadius = 14
        actionButton.clipsToBounds = true
        actionButton.setTitle("去绑定", for: .normal)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        actionButton.isUserInteractionEnabled = false

        actionBgLayer.colors = [
            UIColor(hexString: "#C67A2F").cgColor,
            UIColor(hexString: "#AE5500").cgColor,
            UIColor(hexString: "#B56D00").cgColor
        ]
        actionBgLayer.startPoint = CGPoint(x: 0, y: 0.5)
        actionBgLayer.endPoint = CGPoint(x: 1, y: 0.5)
        actionButton.layer.insertSublayer(actionBgLayer, at: 0)

        cardButton.addSubview(actionButton)
        actionButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 70, height: 28))
        }

        // Middle Text Stack
        titleLabel.text = "绑定权益卡"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#522B0F")
        titleLabel.isUserInteractionEnabled = false

        subtitleLabel.text = "输入卡密或扫码绑定"
        subtitleLabel.font = .fdFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = UIColor(hexString: "#8C714F")
        subtitleLabel.isUserInteractionEnabled = false

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.alignment = .leading
        textStack.isUserInteractionEnabled = false
        cardButton.addSubview(textStack)
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(actionButton.snp.leading).offset(-8)
        }
    }

    @objc private func tapped() {
        onTap?()
    }
}
