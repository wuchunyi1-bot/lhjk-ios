import UIKit
import SnapKit

/// 卡券卡片 Cell
///
/// 统一卡片模板，三种状态（未使用/已激活/已过期）共用同一骨架，
/// 仅详情区和按钮按状态变化。
///
/// 布局：
/// ┌─────────────────────────────────────┐
/// │ 套餐名称                    [状态Tag] │
/// │ 🔖 卡号                     [激活btn] │
/// │ ───────────────────────────────────── │
/// │ 详情区（按状态显示不同字段）            │
/// └─────────────────────────────────────┘
final class VoucherCell: UITableViewCell {

    static let reuseIdentifier = "VoucherCell"

    // MARK: - Callbacks

    /// 点击"激活"按钮回调
    var onActivate: (() -> Void)?

    // MARK: - UI

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = 14
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.fdBorder.cgColor
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 1)
        v.layer.shadowRadius = 6
        v.layer.shadowOpacity = 0.03
        return v
    }()

    /// 已激活卡片的绿色渐变背景
    private let activatedGradient: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [UIColor(hexString: "#FDFFF9").cgColor, UIColor(hexString: "#EEF9F3").cgColor]
        g.startPoint = CGPoint(x: 0, y: 0)
        g.endPoint = CGPoint(x: 1, y: 1)
        g.cornerRadius = 14
        g.isHidden = true
        return g
    }()

    // MARK: Header

    private let packageLabel: UILabel = {
        let l = UILabel()
        l.font = .fdBodySemibold
        l.textColor = .fdText
        l.numberOfLines = 1
        return l
    }()

    private let statusTag: UILabel = {
        let l = UILabel()
        l.font = .fdMicro
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()

    // MARK: Card Number Row

    private let cardIcon: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .regular)
        iv.image = UIImage(systemName: "creditcard")?.withConfiguration(config)
        iv.tintColor = .fdSubtext
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let cardNoLabel: UILabel = {
        let l = UILabel()
        l.font = .fdMicro
        l.textColor = .fdSubtext
        l.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return l
    }()

    private let activateButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("激活", for: .normal)
        b.titleLabel?.font = .fdMicroSemibold
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .fdPrimary
        b.layer.cornerRadius = 12
        b.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        b.setContentHuggingPriority(.required, for: .horizontal)
        b.setContentCompressionResistancePriority(.required, for: .horizontal)
        return b
    }()

    // MARK: Separator

    private let separator: UIView = {
        let v = UIView()
        v.backgroundColor = .fdBorder
        return v
    }()

    // MARK: Detail Area

    private let detailStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .top
        s.distribution = .fillEqually
        s.spacing = 20
        return s
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        activatedGradient.frame = cardView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        activatedGradient.isHidden = true
        cardView.backgroundColor = .fdSurface
        cardView.layer.borderColor = UIColor.fdBorder.cgColor
        cardView.alpha = 1
        activateButton.isHidden = true
        detailStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .fdBg

        contentView.addSubview(cardView)
        cardView.layer.insertSublayer(activatedGradient, at: 0)

        [packageLabel, statusTag, cardIcon, cardNoLabel, activateButton, separator, detailStack].forEach(cardView.addSubview)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.bottom.equalToSuperview().offset(-5)
            make.leading.trailing.equalToSuperview().inset(16).priority(750)
        }

        // Header
        packageLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(statusTag.snp.leading).offset(-8)
        }
        statusTag.snp.makeConstraints { make in
            make.centerY.equalTo(packageLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(20)
        }

        // Card number row
        cardIcon.snp.makeConstraints { make in
            make.top.equalTo(packageLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(14)
        }
        cardNoLabel.snp.makeConstraints { make in
            make.centerY.equalTo(cardIcon)
            make.leading.equalTo(cardIcon.snp.trailing).offset(3)
        }
        activateButton.snp.makeConstraints { make in
            make.centerY.equalTo(cardIcon)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(24)
        }

        // Separator
        separator.snp.makeConstraints { make in
            make.top.equalTo(cardIcon.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }

        // Detail area
        detailStack.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-14)
        }

        activateButton.addTarget(self, action: #selector(handleActivate), for: .touchUpInside)
    }

    // MARK: - Configure

    func configure(voucher: MVoucher) {
        packageLabel.text = voucher.packageName
        cardNoLabel.text = voucher.cardNo
        configureStatusTag(voucher.status)

        switch voucher.status {
        case .unused:
            configureForUnused(voucher)
        case .activated:
            configureForActivated(voucher)
        case .expired:
            configureForExpired(voucher)
        }
    }

    // MARK: - Status-specific Configuration

    private func configureForUnused(_ voucher: MVoucher) {
        activateButton.isHidden = false

        // 详情区：激活截止
        if let deadline = voucher.activationDeadline {
            let item = makeDetailItem(label: "激活截止", value: deadline, valueColor: UIColor(hexString: "#B47300"), isBold: true)
            detailStack.addArrangedSubview(item)
        }
        // 占位：让详情左对齐
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        detailStack.addArrangedSubview(spacer)
    }

    private func configureForActivated(_ voucher: MVoucher) {
        activateButton.isHidden = true

        // 绿色渐变背景
        activatedGradient.isHidden = false
        cardView.backgroundColor = .clear
        cardView.layer.borderColor = UIColor(hexString: "#1F9A6B").withAlphaComponent(0.2).cgColor

        // 详情区：激活时间 / 有效期至 / 专属健管师 / 剩余天数
        if let activatedAt = voucher.activatedAt {
            detailStack.addArrangedSubview(makeDetailItem(label: "激活时间", value: activatedAt))
        }
        if let validUntil = voucher.validUntil {
            detailStack.addArrangedSubview(makeDetailItem(label: "有效期至", value: validUntil))
        }
        if let advisor = voucher.advisorName {
            detailStack.addArrangedSubview(makeDetailItem(label: "专属健管师", value: advisor))
        }
        if let days = voucher.daysLeft {
            detailStack.addArrangedSubview(makeDetailItem(label: "剩余天数", value: "\(days) 天", valueColor: UIColor(hexString: "#1F9A6B"), isBold: true))
        }
    }

    private func configureForExpired(_ voucher: MVoucher) {
        activateButton.isHidden = true
        cardView.alpha = 0.72

        // 详情区：激活时间 / 到期时间
        if let activatedAt = voucher.activatedAt {
            detailStack.addArrangedSubview(makeDetailItem(label: "激活时间", value: activatedAt))
        }
        if let validUntil = voucher.validUntil {
            detailStack.addArrangedSubview(makeDetailItem(label: "到期时间", value: validUntil))
        }
        // 占位补齐
        let spacer1 = UIView()
        spacer1.setContentHuggingPriority(.defaultLow, for: .horizontal)
        detailStack.addArrangedSubview(spacer1)
        let spacer2 = UIView()
        spacer2.setContentHuggingPriority(.defaultLow, for: .horizontal)
        detailStack.addArrangedSubview(spacer2)
    }

    // MARK: - Helpers

    private func configureStatusTag(_ status: VoucherStatus) {
        statusTag.text = "  \(status.label)  "
        statusTag.backgroundColor = UIColor(hexString: status.tagBgHex)
        statusTag.textColor = UIColor(hexString: status.tagTextHex)
    }

    private func makeDetailItem(label: String, value: String, valueColor: UIColor = .fdText, isBold: Bool = false) -> UIView {
        let container = UIView()

        let labelLbl = UILabel()
        labelLbl.text = label
        labelLbl.font = .fdMicro
        labelLbl.textColor = .fdMuted

        let valueLbl = UILabel()
        valueLbl.text = value
        valueLbl.font = isBold ? .fdCaptionSemibold : .fdCaption
        valueLbl.textColor = valueColor

        container.addSubview(labelLbl)
        container.addSubview(valueLbl)
        labelLbl.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        valueLbl.snp.makeConstraints { make in
            make.top.equalTo(labelLbl.snp.bottom).offset(2)
            make.leading.trailing.bottom.equalToSuperview()
        }
        return container
    }

    // MARK: - Actions

    @objc private func handleActivate() {
        onActivate?()
    }
}
