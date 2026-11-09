import SnapKit
import UIKit

/// 康养小屋预约记录列表卡片 — 对齐原型设计与订单卡片规范
final class WellnessCabinAppointmentCell: UITableViewCell {

    static let reuseID = "WellnessCabinAppointmentCell"

    var onCancel: (() -> Void)?
    var onBookAgain: (() -> Void)?
    var onDetail: (() -> Void)?

    // MARK: - UI Components

    private let card = UIView()

    // 头部：项目名称与状态标签
    private let headerRow = UIStackView()
    private let nameLabel = UILabel()
    private let statusWrap = UIView()
    private let statusLabel = UILabel()

    // 内容明细（固定标签列宽 60pt，左右整齐对齐）
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

    // 超时提示条
    private let noticeBox = UIView()
    private let noticeIcon = UIImageView()
    private let noticeLabel = UILabel()

    // 底部操作区
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
        // 1. 项目名称
        nameLabel.text = item.name.isEmpty ? "预约项目" : item.name

        // 2. 状态标签
        let statusTitle = item.statusTitle
        statusWrap.isHidden = statusTitle.isEmpty
        statusLabel.text = statusTitle
        applyStatusStyle(item.status)

        // 3. 时长（无时长时整行隐藏）
        if let duration = item.duration, duration > 0 {
            durationRow.isHidden = false
            durationValueLabel.text = "\(duration) 分钟"
        } else {
            durationRow.isHidden = true
        }

        // 4. 预约时间
        dateLabel.text = item.reserveDate
        dateLabel.isHidden = item.reserveDate.isEmpty
        slotLabel.text = item.timeText
        slotLabel.isHidden = item.timeText.isEmpty
        timeRow.isHidden = item.reserveDate.isEmpty && item.timeText.isEmpty

        // 5. 门店信息
        storeNameLabel.text = item.hospitalName
        storeNameLabel.isHidden = item.hospitalName.isEmpty
        addressLabel.text = item.address
        addressLabel.isHidden = item.address.isEmpty
        storeRow.isHidden = item.hospitalName.isEmpty && item.address.isEmpty

        // 6. 超时通知条
        if let notice = item.overdueNotice {
            noticeBox.isHidden = false
            noticeLabel.text = notice
        } else {
            noticeBox.isHidden = true
        }

        // 7. 底部按钮配置（对齐订单 UI 规范与原型状态布局）
        configureActions(for: item)
    }

    private func configureActions(for item: CabinAppointmentVO) {
        // 清理旧布局与子视图
        actionsRow.subviews.forEach { $0.removeFromSuperview() }
        actionsStack.arrangedSubviews.forEach {
            actionsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let status = item.status ?? 0

        switch status {
        case 3:
            // 待服务：右对齐 [取消预约]（次要） + [查看详情]（主色填充）
            actionsRow.isHidden = false
            applyOutlineButton(cancelButton, title: "取消预约")
            applyPrimaryButton(detailButton, title: "查看详情")

            actionsStack.addArrangedSubview(cancelButton)
            actionsStack.addArrangedSubview(detailButton)
            layoutRightActions()

        case 4:
            // 服务中：全宽通栏 [查看详情]（次要描边按钮）
            actionsRow.isHidden = false
            applyOutlineButton(detailButton, title: "查看详情")
            layoutFullWidthAction(detailButton)

        case 5, 6, 7:
            // 已完成 / 已取消 / 已过期
            if item.canBookAgain {
                // 右对齐 [查看详情]（次要） + [再次预约]（主色填充）
                actionsRow.isHidden = false
                applyOutlineButton(detailButton, title: "查看详情")
                applyPrimaryButton(bookButton, title: "再次预约")

                actionsStack.addArrangedSubview(detailButton)
                actionsStack.addArrangedSubview(bookButton)
                layoutRightActions()
            } else {
                // 仅查看详情时全宽展示
                actionsRow.isHidden = false
                applyOutlineButton(detailButton, title: "查看详情")
                layoutFullWidthAction(detailButton)
            }

        default:
            actionsRow.isHidden = true
        }
    }

    private func layoutRightActions() {
        actionsRow.addSubview(actionsStack)
        actionsStack.snp.remakeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.height.equalTo(40)
        }
    }

    private func layoutFullWidthAction(_ button: UIButton) {
        actionsRow.addSubview(button)
        button.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(40)
        }
    }

    // MARK: - Setup UI

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // 白色卡片，平滑阴影无黑边（参考 OrderCardCell）
        card.backgroundColor = .white
        card.layer.cornerRadius = 14
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

        // 1. 标题行：左侧名称，右侧状态标签
        nameLabel.font = .fdFont(ofSize: 16, weight: .bold)
        nameLabel.textColor = UIColor(hexString: "#1F2430")
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        statusWrap.layer.cornerRadius = 4
        statusWrap.clipsToBounds = true
        statusWrap.setContentHuggingPriority(.required, for: .horizontal)
        statusWrap.setContentCompressionResistancePriority(.required, for: .horizontal)

        statusLabel.font = .fdFont(ofSize: 11, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusWrap.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(6)
            make.height.equalTo(18)
        }

        let headerSpacer = UIView()
        headerSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerSpacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 8
        headerRow.addArrangedSubview(nameLabel)
        headerRow.addArrangedSubview(headerSpacer)
        headerRow.addArrangedSubview(statusWrap)

        // 2. 时长行
        setupFieldTitle(durationTitleLabel, title: "时长")
        durationValueLabel.font = .fdFont(ofSize: 14, weight: .regular)
        durationValueLabel.textColor = UIColor(hexString: "#1F2430")

        durationRow.axis = .horizontal
        durationRow.alignment = .firstBaseline
        durationRow.spacing = 8
        durationRow.addArrangedSubview(durationTitleLabel)
        durationRow.addArrangedSubview(durationValueLabel)

        // 3. 预约时间行（日期深色 + 时间段橙色紧跟，左对齐）
        setupFieldTitle(timeTitleLabel, title: "预约时间")
        dateLabel.font = .fdFont(ofSize: 15, weight: .medium)
        dateLabel.textColor = UIColor(hexString: "#1F2430")
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)

        slotLabel.font = .fdFont(ofSize: 15, weight: .semibold)
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

        // 4. 门店信息行（标题顶部对齐，名称 + 详细地址垂直排列）
        setupFieldTitle(storeTitleLabel, title: "门店信息")
        storeNameLabel.font = .fdFont(ofSize: 14, weight: .medium)
        storeNameLabel.textColor = UIColor(hexString: "#1F2430")
        storeNameLabel.lineBreakMode = .byTruncatingTail
        storeNameLabel.numberOfLines = 2

        addressLabel.font = .fdFont(ofSize: 12, weight: .regular)
        addressLabel.textColor = UIColor(hexString: "#8591AB")
        addressLabel.numberOfLines = 0

        let storeTextStack = UIStackView(arrangedSubviews: [storeNameLabel, addressLabel])
        storeTextStack.axis = .vertical
        storeTextStack.alignment = .fill
        storeTextStack.spacing = 3

        storeRow.axis = .horizontal
        storeRow.alignment = .top
        storeRow.spacing = 8
        storeRow.addArrangedSubview(storeTitleLabel)
        storeRow.addArrangedSubview(storeTextStack)

        // 5. 超时提示条（柔和暖橙底，精致圆角无粗边框）
        noticeBox.backgroundColor = UIColor(hexString: "#FFF8F2")
        noticeBox.layer.cornerRadius = 6
        noticeBox.clipsToBounds = true

        noticeIcon.image = UIImage(systemName: "exclamationmark.circle")
        noticeIcon.tintColor = UIColor(hexString: "#FA8C16")
        noticeIcon.contentMode = .scaleAspectFit
        noticeIcon.setContentHuggingPriority(.required, for: .horizontal)

        noticeLabel.font = .fdFont(ofSize: 12, weight: .regular)
        noticeLabel.textColor = UIColor(hexString: "#FA8C16")
        noticeLabel.numberOfLines = 0

        let noticeRow = UIStackView(arrangedSubviews: [noticeIcon, noticeLabel])
        noticeRow.axis = .horizontal
        noticeRow.alignment = .center
        noticeRow.spacing = 6
        noticeBox.addSubview(noticeRow)
        noticeIcon.snp.makeConstraints { $0.size.equalTo(14) }
        noticeRow.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10))
        }

        // 6. 操作按钮设置
        setupActionButton(cancelButton, action: #selector(cancelTapped))
        setupActionButton(bookButton, action: #selector(bookTapped))
        setupActionButton(detailButton, action: #selector(detailTapped))

        actionsStack.axis = .horizontal
        actionsStack.spacing = 10
        actionsStack.alignment = .center
        actionsStack.distribution = .fill

        // 7. 主垂直堆叠（合理间距与层级）
        let mainStack = UIStackView(arrangedSubviews: [
            headerRow,
            durationRow,
            timeRow,
            storeRow,
            noticeBox,
            actionsRow
        ])
        mainStack.axis = .vertical
        mainStack.alignment = .fill
        mainStack.distribution = .fill

        mainStack.setCustomSpacing(12, after: headerRow)
        mainStack.setCustomSpacing(8, after: durationRow)
        mainStack.setCustomSpacing(8, after: timeRow)
        mainStack.setCustomSpacing(14, after: storeRow)
        mainStack.setCustomSpacing(14, after: noticeBox)

        card.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    private func setupFieldTitle(_ label: UILabel, title: String) {
        label.text = title
        label.font = .fdFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(hexString: "#8591AB")
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.snp.makeConstraints { make in
            make.width.equalTo(60)
        }
    }

    private func setupActionButton(_ button: UIButton, action: Selector) {
        button.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.width.greaterThanOrEqualTo(96)
        }
    }

    // MARK: - Button & Status Styles

    private func applyPrimaryButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = UIColor(hexString: "#FF7A50")
        button.setTitleColor(.white, for: .normal)
        button.layer.borderWidth = 0
    }

    private func applyOutlineButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(UIColor(hexString: "#1F2430"), for: .normal)
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor(hexString: "#D8D8D8").cgColor
    }

    private func applyStatusStyle(_ status: Int?) {
        switch status {
        case 3:
            // 待服务（柔和蓝）
            statusLabel.textColor = UIColor(hexString: "#2B70DB")
            statusWrap.backgroundColor = UIColor(hexString: "#EAF2FF")
        case 4:
            // 服务中（柔和橙）
            statusLabel.textColor = UIColor(hexString: "#FF7A50")
            statusWrap.backgroundColor = UIColor(hexString: "#FFF3EA")
        case 5:
            // 已完成（柔和绿）
            statusLabel.textColor = UIColor(hexString: "#2EBA83")
            statusWrap.backgroundColor = UIColor(hexString: "#EBF7F2")
        case 6, 7:
            // 已取消 / 已过期（柔和中性灰）
            statusLabel.textColor = UIColor(hexString: "#8591AB")
            statusWrap.backgroundColor = UIColor(hexString: "#F4F5F7")
        default:
            statusLabel.textColor = UIColor(hexString: "#8591AB")
            statusWrap.backgroundColor = UIColor(hexString: "#F4F5F7")
        }
    }

    // MARK: - Action Callbacks

    @objc private func cancelTapped() { onCancel?() }
    @objc private func detailTapped() { onDetail?() }
    @objc private func bookTapped() { onBookAgain?() }
}
