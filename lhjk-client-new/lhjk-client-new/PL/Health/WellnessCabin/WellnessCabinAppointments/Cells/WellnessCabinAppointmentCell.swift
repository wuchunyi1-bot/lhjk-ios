import SnapKit
import UIKit

/// 康养小屋预约记录列表卡片 — 视觉对齐订单列表卡片
final class WellnessCabinAppointmentCell: UITableViewCell {

    static let reuseID = "WellnessCabinAppointmentCell"

    var onCancel: (() -> Void)?
    var onBookAgain: (() -> Void)?
    var onDetail: (() -> Void)?

    // MARK: - UI Components

    private let card = UIView()

    private let headerRow = UIStackView()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()

    private let infoContainer = UIView()
    private let durationRow = UIStackView()
    private let durationTitleLabel = UILabel()
    private let durationValueLabel = UILabel()

    private let timeRow = UIStackView()
    private let timeTitleLabel = UILabel()
    private let dateLabel = UILabel()
    private let slotLabel = UILabel()

    private let storeRow = UIStackView()
    private let storeTitleLabel = UILabel()
    private let storeNameLabel = UILabel()
    private let addressLabel = UILabel()

    private let noticeBox = UIView()
    private let noticeIcon = UIImageView()
    private let noticeLabel = UILabel()

    private let actionsRow = UIView()
    private let actionsStack = UIStackView()
    private let cancelButton = UIButton(type: .system)
    private let bookButton = UIButton(type: .system)
    private let detailButton = UIButton(type: .system)

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onCancel = nil
        onBookAgain = nil
        onDetail = nil
        actionsStack.arrangedSubviews.forEach {
            actionsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    // MARK: - Configure

    func configure(_ item: CabinAppointmentVO) {
        nameLabel.text = item.name.isEmpty ? "预约项目" : item.name

        let statusTitle = item.statusTitle
        statusLabel.isHidden = statusTitle.isEmpty
        statusLabel.text = statusTitle

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

        infoContainer.isHidden = durationRow.isHidden && timeRow.isHidden && storeRow.isHidden

        if let notice = item.overdueNotice {
            noticeBox.isHidden = false
            noticeLabel.text = notice
        } else {
            noticeBox.isHidden = true
        }

        configureActions(for: item)
    }

    private func configureActions(for item: CabinAppointmentVO) {
        actionsStack.arrangedSubviews.forEach {
            actionsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        switch item.status ?? 0 {
        case 3:
            actionsRow.isHidden = false
            applyOutlineButton(cancelButton, title: "取消预约")
            applyPrimaryButton(detailButton, title: "查看详情")
            actionsStack.addArrangedSubview(cancelButton)
            actionsStack.addArrangedSubview(detailButton)
        case 4:
            actionsRow.isHidden = false
            applyOutlineButton(detailButton, title: "查看详情")
            actionsStack.addArrangedSubview(detailButton)
        case 5, 6, 7:
            actionsRow.isHidden = false
            if item.canBookAgain {
                applyOutlineButton(detailButton, title: "查看详情")
                applyPrimaryButton(bookButton, title: "再次预约")
                actionsStack.addArrangedSubview(detailButton)
                actionsStack.addArrangedSubview(bookButton)
            } else {
                applyOutlineButton(detailButton, title: "查看详情")
                actionsStack.addArrangedSubview(detailButton)
            }
        default:
            actionsRow.isHidden = true
        }
    }

    // MARK: - Setup UI

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 8
        card.layer.shadowOpacity = 0.04
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-6).priority(UILayoutPriority(999))
        }

        nameLabel.font = .fdFont(ofSize: 18, weight: .medium)
        nameLabel.textColor = UIColor(hexString: "#1F2430")
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        statusLabel.font = .fdFont(ofSize: 16, weight: .medium)
        statusLabel.textColor = UIColor(hexString: "#FF7A50")
        statusLabel.textAlignment = .right
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 8
        headerRow.addArrangedSubview(nameLabel)
        headerRow.addArrangedSubview(statusLabel)

        setupFieldTitle(durationTitleLabel, title: "时长")
        durationValueLabel.font = .fdFont(ofSize: 16, weight: .regular)
        durationValueLabel.textColor = UIColor(hexString: "#1F2430")
        durationRow.axis = .horizontal
        durationRow.alignment = .firstBaseline
        durationRow.spacing = 8
        durationRow.addArrangedSubview(durationTitleLabel)
        durationRow.addArrangedSubview(durationValueLabel)

        setupFieldTitle(timeTitleLabel, title: "预约时间")
        dateLabel.font = .fdFont(ofSize: 16, weight: .medium)
        dateLabel.textColor = UIColor(hexString: "#1F2430")
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)
        slotLabel.font = .fdFont(ofSize: 16, weight: .semibold)
        slotLabel.textColor = UIColor(hexString: "#FF7A50")
        slotLabel.setContentHuggingPriority(.required, for: .horizontal)
        let timeValueStack = UIStackView(arrangedSubviews: [dateLabel, slotLabel])
        timeValueStack.axis = .horizontal
        timeValueStack.alignment = .firstBaseline
        timeValueStack.spacing = 6
        timeRow.axis = .horizontal
        timeRow.alignment = .firstBaseline
        timeRow.spacing = 8
        timeRow.addArrangedSubview(timeTitleLabel)
        timeRow.addArrangedSubview(timeValueStack)

        setupFieldTitle(storeTitleLabel, title: "门店信息")
        storeNameLabel.font = .fdFont(ofSize: 16, weight: .medium)
        storeNameLabel.textColor = UIColor(hexString: "#1F2430")
        storeNameLabel.lineBreakMode = .byTruncatingTail
        storeNameLabel.numberOfLines = 2
        addressLabel.font = .fdFont(ofSize: 16, weight: .regular)
        addressLabel.textColor = UIColor(hexString: "#8591AB")
        addressLabel.numberOfLines = 0
        let storeTextStack = UIStackView(arrangedSubviews: [storeNameLabel, addressLabel])
        storeTextStack.axis = .vertical
        storeTextStack.alignment = .fill
        storeTextStack.spacing = 4
        storeRow.axis = .horizontal
        storeRow.alignment = .top
        storeRow.spacing = 8
        storeRow.addArrangedSubview(storeTitleLabel)
        storeRow.addArrangedSubview(storeTextStack)

        infoContainer.backgroundColor = UIColor(hexString: "#FFF9F6")
        infoContainer.layer.cornerRadius = 12
        infoContainer.clipsToBounds = true
        let infoStack = UIStackView(arrangedSubviews: [durationRow, timeRow, storeRow])
        infoStack.axis = .vertical
        infoStack.spacing = 8
        infoContainer.addSubview(infoStack)
        infoStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        durationTitleLabel.snp.makeConstraints { $0.width.equalTo(timeTitleLabel) }
        storeTitleLabel.snp.makeConstraints { $0.width.equalTo(timeTitleLabel) }

        noticeBox.backgroundColor = UIColor(hexString: "#F93838").withAlphaComponent(0.05)
        noticeBox.layer.cornerRadius = 8
        noticeBox.clipsToBounds = true
        noticeIcon.image = UIImage(named: "order_notice_alert_icon")
        noticeIcon.contentMode = .scaleAspectFit
        noticeBox.addSubview(noticeIcon)
        noticeIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }
        noticeLabel.font = .fdFont(ofSize: 12, weight: .regular)
        noticeLabel.textColor = UIColor(hexString: "#F93838")
        noticeLabel.numberOfLines = 0
        noticeBox.addSubview(noticeLabel)
        noticeLabel.snp.makeConstraints { make in
            make.leading.equalTo(noticeIcon.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
        noticeBox.isHidden = true

        setupActionButton(cancelButton, action: #selector(cancelTapped))
        setupActionButton(bookButton, action: #selector(bookTapped))
        setupActionButton(detailButton, action: #selector(detailTapped))
        actionsStack.axis = .horizontal
        actionsStack.spacing = 12
        actionsStack.alignment = .center
        actionsRow.addSubview(actionsStack)
        actionsStack.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.height.equalTo(28)
        }
        actionsRow.isHidden = true

        let mainStack = UIStackView(arrangedSubviews: [
            headerRow,
            noticeBox,
            infoContainer,
            actionsRow
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.alignment = .fill
        card.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
    }

    private func setupFieldTitle(_ label: UILabel, title: String) {
        label.text = title
        label.font = .fdFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor(hexString: "#8591AB")
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func setupActionButton(_ button: UIButton, action: Selector) {
        button.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 14
        button.clipsToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.snp.makeConstraints { make in
            make.height.equalTo(28)
            make.width.greaterThanOrEqualTo(77)
        }
    }

    private func applyPrimaryButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = UIColor(hexString: "#FF7950")
        button.setTitleColor(.white, for: .normal)
        button.layer.borderWidth = 0
    }

    private func applyOutlineButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(UIColor(hexString: "#FF7950"), for: .normal)
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor(hexString: "#FF7950").cgColor
    }

    @objc private func cancelTapped() { onCancel?() }
    @objc private func detailTapped() { onDetail?() }
    @objc private func bookTapped() { onBookAgain?() }
}
