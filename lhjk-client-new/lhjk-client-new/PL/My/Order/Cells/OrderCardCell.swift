import UIKit
import SnapKit

/// 订单卡片 Cell — 服务名 + 状态标签 + 服务标签 + 日期 + 价格 + 剩余天数
/// 参考 funde-client: order-card
final class OrderCardCell: UITableViewCell {

    static let reuseIdentifier = "OrderCardCell"

    // MARK: - UI

    private let cardView = UIView()
    private let nameLabel = UILabel()
    private let statusContainer = UIView()
    private let statusLabel = UILabel()
    private let tagLabel = UILabel()
    private let dateLabel = UILabel()
    private let priceLabel = UILabel()
    private let daysRow = UIView()
    private let daysIcon = UIImageView()
    private let daysLabel = UILabel()

    // MARK: - Status Color Map

    struct StatusStyle {
        let bg: UIColor; let text: UIColor
    }

    private let statusColors: [String: StatusStyle] = [
        "pending_use":    StatusStyle(bg: UIColor(hexString: "#FFF3EE"), text: UIColor(hexString: "#FF7A50")),
        "in_progress":    StatusStyle(bg: UIColor(hexString: "#EEF6FF"), text: UIColor(hexString: "#3D6FB8")),
        "completed":      StatusStyle(bg: UIColor(hexString: "#F0FAF4"), text: UIColor(hexString: "#52B96A")),
        "pending_review": StatusStyle(bg: UIColor(hexString: "#FFF8E8"), text: UIColor(hexString: "#B47300")),
    ]

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupCard()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCard() {
        cardView.backgroundColor = .fdSurface
        cardView.layer.cornerRadius = 24
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 1)
        cardView.layer.shadowRadius = 6
        cardView.layer.shadowOpacity = 0.03
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)) }

        // Status badge
        statusContainer.layer.cornerRadius = 999
        statusLabel.font = .fdMicroSemibold
        statusContainer.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }

        // Header row: name + status
        nameLabel.font = .fdBodyBold
        nameLabel.textColor = .fdText

        cardView.addSubview(nameLabel)
        cardView.addSubview(statusContainer)

        nameLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualTo(statusContainer.snp.leading).offset(-12)
        }
        statusContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // Service tag
        tagLabel.font = .fdCaption
        tagLabel.textColor = .fdSubtext
        cardView.addSubview(tagLabel)
        tagLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(16)
        }

        // Date
        dateLabel.font = .fdCaption
        dateLabel.textColor = .fdSubtext
        cardView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(tagLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().inset(16)
        }

        // Price
        priceLabel.font = .fdBodyBold
        priceLabel.textColor = .fdPrimary
        cardView.addSubview(priceLabel)
        priceLabel.snp.makeConstraints { make in
            make.centerY.equalTo(dateLabel)
            make.trailing.equalToSuperview().offset(-16)
        }

        // Days row
        daysIcon.image = UIImage(systemName: "clock")
        daysIcon.tintColor = .fdPrimary
        daysIcon.contentMode = .scaleAspectFit
        daysRow.addSubview(daysIcon)
        daysIcon.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(14)
        }

        daysLabel.font = .fdCaption
        daysLabel.textColor = .fdPrimary
        daysRow.addSubview(daysLabel)
        daysLabel.snp.makeConstraints { make in
            make.leading.equalTo(daysIcon.snp.trailing).offset(4)
            make.top.bottom.trailing.equalToSuperview()
        }

        daysRow.isHidden = true
        cardView.addSubview(daysRow)
        daysRow.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        // When daysRow is hidden, anchor bottom to dateLabel
        dateLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16).priority(.low)
        }
    }

    // MARK: - Configure

    func configure(name: String, status: String, statusKey: String, tag: String, startDate: String, endDate: String, price: Int, daysLeft: Int) {
        nameLabel.text = name
        statusLabel.text = status
        tagLabel.text = tag
        dateLabel.text = "\(startDate) — \(endDate)"
        priceLabel.text = "¥\(price.formattedWithSeparator)"

        // Status style
        if let style = statusColors[statusKey] {
            statusContainer.backgroundColor = style.bg
            statusLabel.textColor = style.text
        }

        // Days left
        if daysLeft > 0 {
            daysRow.isHidden = false
            daysLabel.text = "剩余 \(daysLeft) 天"

            // Reprioritize bottom to daysRow
            dateLabel.snp.removeConstraints()
            dateLabel.snp.makeConstraints { make in
                make.top.equalTo(tagLabel.snp.bottom).offset(10)
                make.leading.equalToSuperview().inset(16)
            }
        } else {
            daysRow.isHidden = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        statusLabel.text = nil
        tagLabel.text = nil
        dateLabel.text = nil
        priceLabel.text = nil
        daysLabel.text = nil
    }
}

// MARK: - Number Formatter

private extension Int {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
