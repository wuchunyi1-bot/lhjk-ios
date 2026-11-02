import Kingfisher
import SnapKit
import UIKit

/// 添加设备左侧分类。选中项为白底主色，相邻项靠内容区一侧圆角 16。
final class DeviceCatalogCategoryCell: UITableViewCell {

    static let reuseID = "DeviceCatalogCategoryCell"
    static let rowHeight: CGFloat = 55

    enum InnerCorner {
        case none
        case topRight
        case bottomRight
    }

    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.clipsToBounds = true

        titleLabel.font = .fdFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = .fdText
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-4)
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.layer.cornerRadius = 0
        contentView.layer.maskedCorners = []
    }

    func configure(title: String, selected: Bool, corner: InnerCorner) {
        titleLabel.text = title
        titleLabel.font = .fdFont(ofSize: 14, weight: selected ? .medium : .regular)
        titleLabel.textColor = selected ? .fdPrimary : .fdText
        contentView.backgroundColor = selected ? .fdSurface : .fdLoginBackground
        switch corner {
        case .none:
            contentView.layer.cornerRadius = 0
        case .topRight:
            contentView.layer.cornerRadius = 16
            contentView.layer.maskedCorners = [.layerMaxXMinYCorner]
        case .bottomRight:
            contentView.layer.cornerRadius = 16
            contentView.layer.maskedCorners = [.layerMaxXMaxYCorner]
        }
    }
}

/// 添加设备右侧型号行：白底、右侧箭头，无卡片间距。
final class DeviceCatalogRowCell: UITableViewCell {

    static let reuseID = "DeviceCatalogRowCell"
    static let rowHeight: CGFloat = 65

    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let codeLabel = UILabel()
    private let chevronView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .fdSurface
        contentView.backgroundColor = .fdSurface
        selectionStyle = .none

        iconView.contentMode = .scaleAspectFit
        iconView.image = UIImage(named: "weight_ble_unbound_scale")

        nameLabel.font = .fdFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 1

        codeLabel.font = .fdFont(ofSize: 12, weight: .regular)
        codeLabel.textColor = UIColor(hexString: "#6D7381")
        codeLabel.numberOfLines = 1

        chevronView.image = UIImage(named: "weight_ble_chevron")
        chevronView.contentMode = .scaleAspectFit

        let textStack = UIStackView(arrangedSubviews: [nameLabel, codeLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading

        contentView.addSubview(iconView)
        contentView.addSubview(textStack)
        contentView.addSubview(chevronView)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        chevronView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(11)
            make.trailing.lessThanOrEqualTo(chevronView.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.kf.cancelDownloadTask()
        iconView.image = UIImage(named: "weight_ble_unbound_scale")
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

        let placeholder = UIImage(named: "weight_ble_unbound_scale")
        if let raw = item.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty,
           let url = URL(string: raw) {
            iconView.kf.setImage(with: url, placeholder: placeholder, options: [.transition(.fade(0.15))])
        } else {
            iconView.kf.cancelDownloadTask()
            iconView.image = placeholder
        }
    }
}
