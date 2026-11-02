import SnapKit
import UIKit

final class WellnessCabinListCell: UITableViewCell {

    static let reuseID = "WellnessCabinListCell"

    private let card = UIView()
    private let nameLabel = UILabel()
    private let staffTag = UILabel()
    private let distanceLabel = UILabel()
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
        staffTag.isHidden = item.internalOnly != 1

        if item.isEnterable {
            statusPill.isHidden = true
            distanceLabel.isHidden = item.distanceLabel == nil
            distanceLabel.text = item.distanceLabel
            goButton.isEnabled = true
            goButton.backgroundColor = .fdPrimary
            goButton.setTitleColor(.white, for: .normal)
        } else {
            distanceLabel.isHidden = true
            statusPill.isHidden = false
            statusPill.text = "暂不可预约"
            goButton.isEnabled = false
            goButton.backgroundColor = .fdBg2
            goButton.setTitleColor(.fdMuted, for: .normal)
        }

        addressLabel.text = item.addressLine
        addressLabel.isHidden = item.addressLine.isEmpty
        if let openTime = item.openTime, !openTime.isEmpty {
            hoursLabel.isHidden = false
            hoursLabel.text = "营业时间：\(openTime)"
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
                    .font: UIFont.fdFont(ofSize: 13, weight: .regular),
                    .foregroundColor: UIColor.fdSubtext,
                ]
            )
            text.append(NSAttributedString(
                string: "\(count)",
                attributes: [
                    .font: UIFont.fdFont(ofSize: 13, weight: .semibold),
                    .foregroundColor: UIColor.fdText,
                ]
            ))
            text.append(NSAttributedString(
                string: " 人",
                attributes: [
                    .font: UIFont.fdFont(ofSize: 13, weight: .regular),
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
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdBorder.cgColor

        nameLabel.font = .fdFont(ofSize: 17, weight: .semibold)
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2

        staffTag.text = "仅限内部员工"
        staffTag.font = .fdFont(ofSize: 11, weight: .medium)
        staffTag.textColor = .fdSuccess
        staffTag.backgroundColor = .fdSuccessSoft
        staffTag.textAlignment = .center
        staffTag.layer.cornerRadius = 4
        staffTag.clipsToBounds = true

        distanceLabel.font = .fdFont(ofSize: 15, weight: .semibold)
        distanceLabel.textColor = .fdSuccess
        distanceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        statusPill.font = .fdFont(ofSize: 12, weight: .medium)
        statusPill.textColor = .fdWarning
        statusPill.backgroundColor = .fdWarningSoft
        statusPill.textAlignment = .center
        statusPill.layer.cornerRadius = 11
        statusPill.clipsToBounds = true
        statusPill.isHidden = true

        addressLabel.font = .fdFont(ofSize: 13, weight: .regular)
        addressLabel.textColor = .fdSubtext
        addressLabel.numberOfLines = 2

        hoursLabel.font = .fdFont(ofSize: 13, weight: .regular)
        hoursLabel.textColor = .fdSubtext
        hoursLabel.numberOfLines = 1

        tagRow.axis = .horizontal
        tagRow.spacing = 8
        tagRow.alignment = .center

        slotsLabel.numberOfLines = 1

        goButton.setTitle("去门店", for: .normal)
        goButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        goButton.layer.cornerRadius = 16
        goButton.isUserInteractionEnabled = false

        let titleRow = UIStackView(arrangedSubviews: [nameLabel, staffTag])
        titleRow.axis = .horizontal
        titleRow.spacing = 8
        titleRow.alignment = .center

        let head = UIStackView(arrangedSubviews: [titleRow, distanceLabel, statusPill])
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
        staffTag.snp.makeConstraints {
            $0.height.equalTo(20)
            $0.width.greaterThanOrEqualTo(76)
        }
        statusPill.snp.makeConstraints {
            $0.height.equalTo(22)
            $0.width.greaterThanOrEqualTo(76)
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
