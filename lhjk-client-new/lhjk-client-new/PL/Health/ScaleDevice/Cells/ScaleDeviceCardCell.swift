import Kingfisher
import SnapKit
import UIKit

/// 体脂秤设备卡片 — 对齐 BodyScaleSelectDeviceView / MyScaleDeviceView
final class ScaleDeviceCardCell: UITableViewCell {

    static let reuseID = "ScaleDeviceCardCell"

    var onUnbind: (() -> Void)?

    private let cardView = UIView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let codeLabel = UILabel()
    private let unbindButton = UIButton(type: .system)
    private let chevronView = UIImageView()
    private let nameRow = UIStackView()
    private var chevronWidthConstraint: Constraint?

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
        iconView.image = nil
        onUnbind = nil
    }

    func configure(_ item: ScaleDeviceCardItem) {
        nameLabel.text = item.name
        if item.code.isEmpty {
            codeLabel.isHidden = true
            codeLabel.text = nil
        } else {
            codeLabel.isHidden = false
            codeLabel.text = "设备编码：\(item.code)"
        }

        unbindButton.isHidden = !item.showsUnbind
        chevronView.isHidden = !item.isSelectable
        chevronWidthConstraint?.update(offset: item.isSelectable ? 18 : 0)

        let placeholder = UIImage(systemName: "scalemass.fill")
        if let raw = item.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty,
           let url = URL(string: raw) {
            iconView.tintColor = nil
            iconView.kf.setImage(
                with: url,
                placeholder: placeholder,
                options: [.transition(.fade(0.15))]
            )
        } else {
            iconView.image = placeholder
            iconView.tintColor = .fdPrimary
        }
    }

    // MARK: - Private

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        cardView.backgroundColor = .fdSurface
        cardView.layer.cornerRadius = 18

        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)

        nameLabel.font = .fdBodySemibold
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 1

        codeLabel.font = .fdCaption
        codeLabel.textColor = .fdSubtext
        codeLabel.numberOfLines = 1

        unbindButton.setTitle("解除绑定", for: .normal)
        unbindButton.titleLabel?.font = .fdCaption
        unbindButton.setTitleColor(.fdPrimary, for: .normal)
        unbindButton.layer.borderWidth = 1
        unbindButton.layer.borderColor = UIColor.fdPrimary.cgColor
        unbindButton.layer.cornerRadius = 6
        unbindButton.contentEdgeInsets = UIEdgeInsets(top: 3, left: 10, bottom: 3, right: 10)
        unbindButton.addTarget(self, action: #selector(handleUnbind), for: .touchUpInside)

        chevronView.image = UIImage(systemName: "chevron.right")
        chevronView.tintColor = .fdMuted
        chevronView.contentMode = .scaleAspectFit
        chevronView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)

        nameRow.axis = .horizontal
        nameRow.alignment = .center
        nameRow.spacing = 8
        nameRow.addArrangedSubview(nameLabel)
        nameRow.addArrangedSubview(unbindButton)

        let infoStack = UIStackView(arrangedSubviews: [nameRow, codeLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 4
        infoStack.alignment = .fill

        contentView.addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(infoStack)
        cardView.addSubview(chevronView)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-10)
        }

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
            make.top.greaterThanOrEqualToSuperview().offset(16)
            make.bottom.lessThanOrEqualToSuperview().offset(-16)
        }

        chevronView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            chevronWidthConstraint = make.width.height.equalTo(18).constraint
        }

        infoStack.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.equalTo(chevronView.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(16)
            make.bottom.lessThanOrEqualToSuperview().offset(-16)
        }

        unbindButton.setContentHuggingPriority(.required, for: .horizontal)
        unbindButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    @objc private func handleUnbind() {
        onUnbind?()
    }
}
