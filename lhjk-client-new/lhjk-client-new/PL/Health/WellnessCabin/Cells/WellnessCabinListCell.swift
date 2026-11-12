import SnapKit
import UIKit

final class WellnessCabinListCell: UITableViewCell {

    static let reuseID = "WellnessCabinListCell"

    private let card = UIView()
    private let nameLabel = UILabel()
    private let recommendTag = UILabel()
    private let staffTag = UILabel()
    private let statusPill = UILabel()
    private let addressLabel = UILabel()
    private let hoursLabel = UILabel()
    private let tagRow = UIStackView()
    private let slotsLabel = UILabel()
    private let goButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        tagRow.arrangedSubviews.forEach {
            tagRow.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    func configure(_ item: CabinStoreVO) {
        nameLabel.text = item.name
        recommendTag.isHidden = !item.recommended
        staffTag.isHidden = item.internalOnly != 1

        if item.restFlag {
            showClosed(title: "休息中")
        } else if item.isEnterable {
            statusPill.isHidden = true
            goButton.isEnabled = true
            goButton.backgroundColor = .fdPrimary
            goButton.setTitleColor(.white, for: .normal)
        } else {
            showClosed(title: "暂不可预约")
        }

        addressLabel.text = item.addressLine
        addressLabel.isHidden = item.addressLine.isEmpty
        if let hours = item.businessHours, !hours.isEmpty {
            hoursLabel.isHidden = false
            hoursLabel.text = "营业时间：\(hours)"
        } else {
            hoursLabel.isHidden = true
            hoursLabel.text = nil
        }
        rebuildTags(item.serviceTags)

        if let count = item.todayAvailableCount {
            slotsLabel.isHidden = false
            let text = NSMutableAttributedString(
                string: "今日可约：",
                attributes: [
                    .font: UIFont.fdFont(ofSize: 14, weight: .regular),
                    .foregroundColor: UIColor.fdSubtext,
                ]
            )
            text.append(NSAttributedString(
                string: "\(count)",
                attributes: [
                    .font: UIFont.fdFont(ofSize: 14, weight: .semibold),
                    .foregroundColor: UIColor.fdText,
                ]
            ))
            text.append(NSAttributedString(
                string: " 人",
                attributes: [
                    .font: UIFont.fdFont(ofSize: 14, weight: .regular),
                    .foregroundColor: UIColor.fdSubtext,
                ]
            ))
            slotsLabel.attributedText = text
        } else {
            slotsLabel.isHidden = true
            slotsLabel.attributedText = nil
        }
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.clipsToBounds = true

        nameLabel.font = .fdFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2

        recommendTag.text = "推荐"
        recommendTag.font = .fdFont(ofSize: 12, weight: .medium)
        recommendTag.textColor = .fdPrimary
        recommendTag.backgroundColor = .fdPrimarySoft
        recommendTag.textAlignment = .center
        recommendTag.layer.cornerRadius = 4
        recommendTag.clipsToBounds = true

        staffTag.text = "  仅限内部员工  "
        staffTag.font = .fdFont(ofSize: 12, weight: .medium)
        staffTag.textColor = .fdWarning
        staffTag.backgroundColor = .fdWarningSoft
        staffTag.textAlignment = .center
        staffTag.layer.cornerRadius = 4
        staffTag.clipsToBounds = true
        staffTag.setContentCompressionResistancePriority(.required, for: .horizontal)
        staffTag.setContentHuggingPriority(.required, for: .horizontal)

        statusPill.font = .fdFont(ofSize: 12, weight: .semibold)
        statusPill.textColor = .fdWarning
        statusPill.backgroundColor = .fdWarningSoft
        statusPill.textAlignment = .center
        statusPill.layer.cornerRadius = 11
        statusPill.clipsToBounds = true
        statusPill.isHidden = true
        statusPill.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusPill.setContentHuggingPriority(.required, for: .horizontal)

        addressLabel.font = .fdFont(ofSize: 16, weight: .regular)
        addressLabel.textColor = .fdTabInactive
        addressLabel.numberOfLines = 0

        hoursLabel.font = .fdFont(ofSize: 16, weight: .regular)
        hoursLabel.textColor = .fdTabInactive
        hoursLabel.numberOfLines = 1

        tagRow.axis = .horizontal
        tagRow.spacing = 8
        tagRow.alignment = .center

        slotsLabel.numberOfLines = 1

        goButton.setTitle("去门店", for: .normal)
        goButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        goButton.layer.cornerRadius = 16
        goButton.isUserInteractionEnabled = false

        let titleRow = UIStackView(arrangedSubviews: [nameLabel, recommendTag, staffTag])
        titleRow.axis = .horizontal
        titleRow.spacing = 8
        titleRow.alignment = .center

        let head = UIStackView(arrangedSubviews: [titleRow, statusPill])
        head.axis = .horizontal
        head.spacing = 8
        head.alignment = .center

        let infoStack = UIStackView(arrangedSubviews: [addressLabel, hoursLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 8
        infoStack.alignment = .fill

        let footer = UIStackView(arrangedSubviews: [slotsLabel, goButton])
        footer.axis = .horizontal
        footer.alignment = .center
        footer.spacing = 12

        contentView.addSubview(card)
        card.addSubview(head)
        card.addSubview(infoStack)
        card.addSubview(tagRow)
        card.addSubview(footer)

        card.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-12)
        }
        recommendTag.snp.makeConstraints {
            $0.height.equalTo(20)
            $0.width.greaterThanOrEqualTo(36)
        }
        staffTag.snp.makeConstraints {
            $0.height.equalTo(20)
        }
        statusPill.snp.makeConstraints {
            $0.height.equalTo(22)
        }
        goButton.snp.makeConstraints {
            $0.width.equalTo(76)
            $0.height.equalTo(32)
        }
        head.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(16)
        }
        infoStack.snp.makeConstraints {
            $0.top.equalTo(head.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        tagRow.snp.makeConstraints {
            $0.top.equalTo(infoStack.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.lessThanOrEqualToSuperview().inset(16)
        }
        footer.snp.makeConstraints {
            $0.top.equalTo(tagRow.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
        }
    }

    private func showClosed(title: String) {
        statusPill.isHidden = false
        statusPill.text = "  \(title)  "
        goButton.isEnabled = false
        goButton.backgroundColor = .fdBg2
        goButton.setTitleColor(.fdMuted, for: .normal)
    }

    private func rebuildTags(_ tags: [String]) {
        tagRow.isHidden = tags.isEmpty
        for tag in tags.prefix(4) {
            let label = UILabel()
            label.text = "  \(tag)  "
            label.font = .fdFont(ofSize: 12, weight: .medium)
            label.layer.cornerRadius = 6
            label.clipsToBounds = true
            switch tag {
            case "咨询":
                label.textColor = .fdDanger
                label.backgroundColor = .fdDangerSoft
            case "理疗":
                label.textColor = .fdSuccess
                label.backgroundColor = .fdSuccessSoft
            default:
                label.textColor = .fdInfo
                label.backgroundColor = .fdInfoSoft
            }
            tagRow.addArrangedSubview(label)
            label.snp.makeConstraints { $0.height.equalTo(24) }
        }
    }
}
