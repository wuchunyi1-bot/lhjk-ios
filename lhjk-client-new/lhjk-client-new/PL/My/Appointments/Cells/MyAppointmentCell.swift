import SnapKit
import UIKit

/// 我的预约卡片。对齐预约记录：项目名、状态标、时长、预约时间、门店，以及右侧操作。
final class MyAppointmentCell: UITableViewCell {

    static let reuseID = "MyAppointmentCell"

    var onDetail: (() -> Void)?
    var onBookAgain: (() -> Void)?
    var onCancel: (() -> Void)?

    private let card = UIView()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    private var statusWidth: Constraint?
    private let durationTitleLabel = UILabel()
    private let durationValueLabel = UILabel()
    private let durationRow = UIStackView()
    private let timeTitleLabel = UILabel()
    private let dateLabel = UILabel()
    private let slotLabel = UILabel()
    private let timeRow = UIStackView()
    private let storeTitleLabel = UILabel()
    private let storeNameLabel = UILabel()
    private let addressLabel = UILabel()
    private let storeRow = UIStackView()
    private let actionsStack = UIStackView()
    private let bookButton = UIButton(type: .system)
    private let detailButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onDetail = nil
        onBookAgain = nil
        onCancel = nil
        actionsStack.arrangedSubviews.forEach {
            actionsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    func configure(_ item: CabinAppointmentVO) {
        nameLabel.text = item.name.isEmpty ? "预约项目" : item.name
        let title = item.statusTitle
        statusLabel.isHidden = title.isEmpty
        statusLabel.text = title
        let textWidth = (title as NSString).size(withAttributes: [.font: statusLabel.font as Any]).width
        statusWidth?.update(offset: ceil(textWidth) + 16)
        applyStatus(item.status)

        if let duration = item.duration, duration > 0 {
            durationRow.isHidden = false
            durationValueLabel.text = "\(duration) 分钟"
        } else {
            durationRow.isHidden = true
        }

        dateLabel.text = item.reserveDate
        dateLabel.isHidden = item.reserveDate.isEmpty
        slotLabel.text = item.timeText
        slotLabel.isHidden = item.timeText.isEmpty
        timeRow.isHidden = item.reserveDate.isEmpty && item.timeText.isEmpty

        storeNameLabel.text = item.hospitalName
        storeNameLabel.isHidden = item.hospitalName.isEmpty
        addressLabel.text = item.address
        addressLabel.isHidden = item.address.isEmpty
        storeRow.isHidden = item.hospitalName.isEmpty && item.address.isEmpty

        configureActions(for: item)
    }

    private func configureActions(for item: CabinAppointmentVO) {
        actionsStack.arrangedSubviews.forEach {
            actionsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        switch item.status ?? 0 {
        case 3:
            applyOutline(cancelButton, title: "取消预约")
            applyOutline(detailButton, title: "查看详情")
            actionsStack.addArrangedSubview(cancelButton)
            actionsStack.addArrangedSubview(detailButton)
        case 5, 6, 7 where item.canBookAgain:
            applyFilled(bookButton, title: "再次预约")
            applyOutline(detailButton, title: "查看详情")
            actionsStack.addArrangedSubview(bookButton)
            actionsStack.addArrangedSubview(detailButton)
        default:
            applyOutline(detailButton, title: "查看详情")
            actionsStack.addArrangedSubview(detailButton)
        }
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-6).priority(UILayoutPriority(999))
        }

        nameLabel.font = .fdFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = UIColor(hexString: "#1F2430")
        nameLabel.numberOfLines = 2

        statusLabel.font = .fdFont(ofSize: 12, weight: .regular)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 4
        statusLabel.clipsToBounds = true
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let header = UIStackView(arrangedSubviews: [nameLabel, statusLabel])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8

        fieldTitle(durationTitleLabel, text: "时长")
        durationValueLabel.font = .fdFont(ofSize: 14, weight: .regular)
        durationValueLabel.textColor = UIColor(hexString: "#1F2430")
        durationRow.axis = .horizontal
        durationRow.alignment = .firstBaseline
        durationRow.spacing = 8
        durationRow.addArrangedSubview(durationTitleLabel)
        durationRow.addArrangedSubview(durationValueLabel)

        fieldTitle(timeTitleLabel, text: "预约时间")
        dateLabel.font = .fdFont(ofSize: 14, weight: .medium)
        dateLabel.textColor = UIColor(hexString: "#1F2430")
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)
        slotLabel.font = .fdFont(ofSize: 14, weight: .semibold)
        slotLabel.textColor = UIColor(hexString: "#FF7A50")
        slotLabel.setContentHuggingPriority(.required, for: .horizontal)
        let timeValues = UIStackView(arrangedSubviews: [dateLabel, slotLabel])
        timeValues.axis = .horizontal
        timeValues.alignment = .firstBaseline
        timeValues.spacing = 6
        timeRow.axis = .horizontal
        timeRow.alignment = .firstBaseline
        timeRow.spacing = 8
        timeRow.addArrangedSubview(timeTitleLabel)
        timeRow.addArrangedSubview(timeValues)

        fieldTitle(storeTitleLabel, text: "门店信息")
        storeNameLabel.font = .fdFont(ofSize: 14, weight: .medium)
        storeNameLabel.textColor = UIColor(hexString: "#1F2430")
        storeNameLabel.numberOfLines = 2
        addressLabel.font = .fdFont(ofSize: 14, weight: .regular)
        addressLabel.textColor = UIColor(hexString: "#8591AB")
        addressLabel.numberOfLines = 0
        let storeText = UIStackView(arrangedSubviews: [storeNameLabel, addressLabel])
        storeText.axis = .vertical
        storeText.spacing = 4
        storeRow.axis = .horizontal
        storeRow.alignment = .top
        storeRow.spacing = 8
        storeRow.addArrangedSubview(storeTitleLabel)
        storeRow.addArrangedSubview(storeText)

        prepare(bookButton, action: #selector(bookTapped))
        prepare(detailButton, action: #selector(detailTapped))
        prepare(cancelButton, action: #selector(cancelTapped))
        actionsStack.axis = .horizontal
        actionsStack.spacing = 8
        actionsStack.alignment = .center
        let actionsRow = UIStackView()
        actionsRow.axis = .horizontal
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        actionsRow.addArrangedSubview(spacer)
        actionsRow.addArrangedSubview(actionsStack)

        let body = UIStackView(arrangedSubviews: [header, durationRow, timeRow, storeRow, actionsRow])
        body.axis = .vertical
        body.spacing = 10
        body.alignment = .fill
        card.addSubview(body)
        body.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        statusLabel.snp.makeConstraints { make in
            make.height.equalTo(22)
            statusWidth = make.width.equalTo(52).constraint
        }
        durationTitleLabel.snp.makeConstraints { $0.width.equalTo(timeTitleLabel) }
        storeTitleLabel.snp.makeConstraints { $0.width.equalTo(timeTitleLabel) }
    }

    private func fieldTitle(_ label: UILabel, text: String) {
        label.text = text
        label.font = .fdFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(hexString: "#8591AB")
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func applyStatus(_ status: Int?) {
        switch status {
        case 3, 4:
            statusLabel.textColor = UIColor(hexString: "#FF7A50")
            statusLabel.backgroundColor = UIColor(hexString: "#FFF3EE")
        case 5:
            statusLabel.textColor = UIColor(hexString: "#2DB983")
            statusLabel.backgroundColor = UIColor(hexString: "#E6F7EF")
        default:
            statusLabel.textColor = UIColor(hexString: "#8C93A3")
            statusLabel.backgroundColor = UIColor(hexString: "#F2F3F5")
        }
    }

    private func prepare(_ button: UIButton, action: Selector) {
        button.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.snp.makeConstraints { make in
            make.height.equalTo(32)
            make.width.greaterThanOrEqualTo(88)
        }
    }

    private func applyFilled(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = UIColor(hexString: "#FF7950")
        button.setTitleColor(.white, for: .normal)
        button.layer.borderWidth = 0
    }

    private func applyOutline(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(UIColor(hexString: "#FF7950"), for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(hexString: "#FF7950").cgColor
    }

    @objc private func detailTapped() { onDetail?() }
    @objc private func bookTapped() { onBookAgain?() }
    @objc private func cancelTapped() { onCancel?() }
}
