import SnapKit
import UIKit

final class MyAppointmentCell: UITableViewCell {

    static let reuseID = "MyAppointmentCell"

    var onDetail: (() -> Void)?

    private let card = UIView()
    private let kindLabel = UILabel()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    private let introLabel = UILabel()
    private let timeLabel = UILabel()
    private let placeLabel = UILabel()
    private let detailButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onDetail = nil
    }

    func configure(_ item: CabinAppointmentVO) {
        nameLabel.text = item.name.isEmpty ? "预约项目" : item.name
        let title = item.statusTitle
        statusLabel.isHidden = title.isEmpty
        statusLabel.text = title
        applyStatus(item.status)

        if let notice = item.overdueNotice {
            introLabel.isHidden = false
            introLabel.text = notice
        } else {
            introLabel.isHidden = true
        }

        let schedule = MyCabinAppointmentDetail(item).scheduleText
        timeLabel.isHidden = schedule.isEmpty
        timeLabel.text = schedule

        let place = MyCabinAppointmentDetail(item).placeText
        placeLabel.isHidden = place.isEmpty
        placeLabel.text = place
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdBorder.cgColor
        contentView.addSubview(card)

        kindLabel.text = "康养小屋"
        kindLabel.font = .fdFont(ofSize: 11, weight: .semibold)
        kindLabel.textColor = .fdSubtext
        kindLabel.backgroundColor = .fdBg2
        kindLabel.layer.cornerRadius = 4
        kindLabel.clipsToBounds = true
        kindLabel.textAlignment = .center

        nameLabel.font = .fdFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2

        statusLabel.font = .fdFont(ofSize: 12, weight: .semibold)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 4
        statusLabel.clipsToBounds = true
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        introLabel.font = .fdFont(ofSize: 13, weight: .regular)
        introLabel.textColor = .fdWarning
        introLabel.numberOfLines = 0

        timeLabel.font = .fdFont(ofSize: 13, weight: .regular)
        timeLabel.textColor = .fdSubtext
        timeLabel.numberOfLines = 0

        placeLabel.font = .fdFont(ofSize: 13, weight: .regular)
        placeLabel.textColor = .fdSubtext
        placeLabel.numberOfLines = 0

        detailButton.setTitle("查看详情", for: .normal)
        detailButton.setTitleColor(.fdPrimary, for: .normal)
        detailButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        detailButton.layer.cornerRadius = 16
        detailButton.layer.borderWidth = 1
        detailButton.layer.borderColor = UIColor.fdPrimary.cgColor
        detailButton.addTarget(self, action: #selector(detailTapped), for: .touchUpInside)

        let heading = UIStackView(arrangedSubviews: [kindLabel, nameLabel])
        heading.axis = .vertical
        heading.alignment = .leading
        heading.spacing = 4
        let titleRow = UIStackView(arrangedSubviews: [heading, statusLabel])
        titleRow.axis = .horizontal
        titleRow.alignment = .top
        titleRow.spacing = 8

        let stack = UIStackView(arrangedSubviews: [titleRow, introLabel, timeLabel, placeLabel, detailButton])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 8
        card.addSubview(stack)

        card.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
        }
        kindLabel.snp.makeConstraints { $0.height.equalTo(18) }
        statusLabel.snp.makeConstraints {
            $0.height.equalTo(22)
            $0.width.greaterThanOrEqualTo(52)
        }
        detailButton.snp.makeConstraints { $0.height.equalTo(44) }
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
    }

    private func applyStatus(_ status: Int?) {
        switch status {
        case 3:
            statusLabel.textColor = .fdInfo
            statusLabel.backgroundColor = .fdInfoSoft
        case 4:
            statusLabel.textColor = .fdPrimary
            statusLabel.backgroundColor = .fdPrimarySoft
        case 5:
            statusLabel.textColor = .fdSuccess
            statusLabel.backgroundColor = .fdSuccessSoft
        case 7:
            statusLabel.textColor = .fdWarning
            statusLabel.backgroundColor = .fdWarningSoft
        default:
            statusLabel.textColor = .fdMuted
            statusLabel.backgroundColor = .fdBg2
        }
    }

    @objc private func detailTapped() {
        onDetail?()
    }
}
