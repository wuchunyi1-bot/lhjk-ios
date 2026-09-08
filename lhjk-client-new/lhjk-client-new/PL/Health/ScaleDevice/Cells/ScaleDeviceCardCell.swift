import Kingfisher
import SnapKit
import UIKit

/// 体脂秤设备卡片 — 对齐 Figma 5140:12352 / 5175:12472
final class ScaleDeviceCardCell: UITableViewCell {

    static let reuseID = "ScaleDeviceCardCell"
    static let cardHeight: CGFloat = 65

    var onUnbind: (() -> Void)?

    private let cardView = UIView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let codeLabel = UILabel()
    private let unbindButton = UIButton(type: .system)
    private let chevronView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.kf.cancelDownloadTask()
        iconView.image = UIImage(named: "weight_ble_unbound_scale")
        onUnbind = nil
    }

    func configure(_ item: ScaleDeviceCardItem) {
        nameLabel.text = item.name
        if item.code.isEmpty {
            codeLabel.isHidden = true
            codeLabel.text = nil
        } else {
            codeLabel.isHidden = false
            codeLabel.text = "设备编码｜\(item.code)"
        }

        unbindButton.isHidden = !item.showsUnbind
        chevronView.isHidden = !item.isSelectable

        let placeholder = UIImage(named: "weight_ble_unbound_scale")
        if let raw = item.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty,
           let url = URL(string: raw) {
            iconView.kf.setImage(
                with: url,
                placeholder: placeholder,
                options: [.transition(.fade(0.15))]
            )
        } else {
            iconView.kf.cancelDownloadTask()
            iconView.image = placeholder
        }
    }

    // MARK: - Private

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 12
        cardView.clipsToBounds = true

        iconView.contentMode = .scaleAspectFit
        iconView.image = UIImage(named: "weight_ble_unbound_scale")

        nameLabel.font = .fdFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = UIColor(hexString: "#1F2942")
        nameLabel.numberOfLines = 1

        codeLabel.font = .fdFont(ofSize: 14, weight: .regular)
        codeLabel.textColor = UIColor(hexString: "#6D7381")
        codeLabel.numberOfLines = 1

        unbindButton.setTitle("解除绑定", for: .normal)
        unbindButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        unbindButton.setTitleColor(.fdPrimary, for: .normal)
        unbindButton.addTarget(self, action: #selector(handleUnbind), for: .touchUpInside)

        chevronView.image = UIImage(named: "weight_ble_chevron")
        chevronView.contentMode = .scaleAspectFit

        let textStack = UIStackView(arrangedSubviews: [nameLabel, codeLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading

        let accessoryStack = UIStackView(arrangedSubviews: [unbindButton, chevronView])
        accessoryStack.axis = .horizontal
        accessoryStack.alignment = .center
        accessoryStack.spacing = 0

        contentView.addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(textStack)
        cardView.addSubview(accessoryStack)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(Self.cardHeight)
            make.bottom.equalToSuperview().offset(-12)
        }

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }

        accessoryStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }

        chevronView.snp.makeConstraints { make in
            make.size.equalTo(12)
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(11)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(accessoryStack.snp.leading).offset(-8)
        }

        unbindButton.setContentHuggingPriority(.required, for: .horizontal)
        unbindButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    @objc private func handleUnbind() {
        onUnbind?()
    }
}
