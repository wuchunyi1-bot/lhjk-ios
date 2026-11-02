import SnapKit
import UIKit

final class WellnessCabinAppointmentCell: UITableViewCell {

    static let reuseID = "WellnessCabinAppointmentCell"

    var onBookAgain: (() -> Void)?

    private let card = UIView()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    private let durationLabel = UILabel()
    private let timeTitleLabel = UILabel()
    private let dateLabel = UILabel()
    private let slotLabel = UILabel()
    private let storeTitleLabel = UILabel()
    private let storeNameLabel = UILabel()
    private let addressLabel = UILabel()
    private let noticeLabel = UILabel()
    private let bookButton = UIButton(type: .system)
    private var bookHeight: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onBookAgain = nil
    }

    func configure(_ item: CabinAppointmentVO) {
        nameLabel.text = item.name.isEmpty ? "预约项目" : item.name
        let title = item.statusTitle
        statusLabel.isHidden = title.isEmpty
        statusLabel.text = title
        applyStatus(item.status)

        if let duration = item.durationText {
            durationLabel.isHidden = false
            durationLabel.text = "时长  \(duration)"
        } else {
            durationLabel.isHidden = true
        }

        dateLabel.text = item.reserveDate
        slotLabel.text = item.timeText
        slotLabel.isHidden = item.timeText.isEmpty
        storeNameLabel.text = item.hospitalName
        storeNameLabel.isHidden = item.hospitalName.isEmpty
        addressLabel.text = item.address
        addressLabel.isHidden = item.address.isEmpty

        if let notice = item.overdueNotice {
            noticeLabel.isHidden = false
            noticeLabel.text = notice
        } else {
            noticeLabel.isHidden = true
        }

        let showBook = item.canBookAgain
        bookButton.isHidden = !showBook
        bookHeight?.update(offset: showBook ? 36 : 0)
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdBorder.cgColor
        contentView.addSubview(card)

        nameLabel.font = .fdFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2

        statusLabel.font = .fdFont(ofSize: 12, weight: .semibold)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 10
        statusLabel.clipsToBounds = true
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let titleRow = UIStackView(arrangedSubviews: [nameLabel, statusLabel])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 8

        durationLabel.font = .fdFont(ofSize: 13, weight: .regular)
        durationLabel.textColor = .fdSubtext

        timeTitleLabel.text = "预约时间"
        timeTitleLabel.font = .fdFont(ofSize: 12, weight: .regular)
        timeTitleLabel.textColor = .fdMuted
        dateLabel.font = .fdFont(ofSize: 14, weight: .semibold)
        dateLabel.textColor = .fdText
        slotLabel.font = .fdFont(ofSize: 14, weight: .regular)
        slotLabel.textColor = .fdText2
        let timeRow = UIStackView(arrangedSubviews: [dateLabel, slotLabel])
        timeRow.axis = .horizontal
        timeRow.spacing = 8
        let timeBlock = UIStackView(arrangedSubviews: [timeTitleLabel, timeRow])
        timeBlock.axis = .vertical
        timeBlock.spacing = 4

        storeTitleLabel.text = "门店信息"
        storeTitleLabel.font = .fdFont(ofSize: 12, weight: .regular)
        storeTitleLabel.textColor = .fdMuted
        storeNameLabel.font = .fdFont(ofSize: 14, weight: .semibold)
        storeNameLabel.textColor = .fdText
        storeNameLabel.numberOfLines = 0
        addressLabel.font = .fdFont(ofSize: 13, weight: .regular)
        addressLabel.textColor = .fdSubtext
        addressLabel.numberOfLines = 0
        let storeBlock = UIStackView(arrangedSubviews: [storeTitleLabel, storeNameLabel, addressLabel])
        storeBlock.axis = .vertical
        storeBlock.spacing = 4

        noticeLabel.font = .fdFont(ofSize: 12, weight: .regular)
        noticeLabel.textColor = .fdWarning
        noticeLabel.numberOfLines = 0

        bookButton.setTitle("再次预约", for: .normal)
        bookButton.setTitleColor(.white, for: .normal)
        bookButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .semibold)
        bookButton.backgroundColor = .fdPrimary
        bookButton.layer.cornerRadius = 18
        bookButton.addTarget(self, action: #selector(bookTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            titleRow, durationLabel, timeBlock, storeBlock, noticeLabel, bookButton,
        ])
        stack.axis = .vertical
        stack.spacing = 10
        card.addSubview(stack)

        card.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
        }
        statusLabel.snp.makeConstraints {
            $0.height.equalTo(22)
            $0.width.greaterThanOrEqualTo(52)
        }
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }
        bookButton.snp.makeConstraints { bookHeight = $0.height.equalTo(36).constraint }
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

    @objc private func bookTapped() {
        onBookAgain?()
    }
}
