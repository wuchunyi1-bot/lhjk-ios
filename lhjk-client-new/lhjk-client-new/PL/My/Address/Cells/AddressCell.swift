import UIKit
import SnapKit

/// 收货地址卡片 — 对齐 Figma 4522:6430
final class AddressCell: UITableViewCell {

    static let reuseIdentifier = "AddressCell"

    // MARK: - UI

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = AddressStyle.cardRadius
        v.clipsToBounds = true
        return v
    }()

    private let regionLabel: UILabel = {
        let l = UILabel()
        l.font = AddressStyle.captionFont
        l.textColor = .fdTabInactive
        l.numberOfLines = 1
        return l
    }()

    private let detailLabel: UILabel = {
        let l = UILabel()
        l.font = AddressStyle.fieldMediumFont
        l.textColor = .fdText
        l.numberOfLines = 2
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = AddressStyle.captionFont
        l.textColor = .fdText
        return l
    }()

    private let phoneLabel: UILabel = {
        let l = UILabel()
        l.font = AddressStyle.captionFont
        l.textColor = .fdTabInactive
        return l
    }()

    private let divider = AddressFormDivider.make()

    private let defaultTag: UILabel = {
        let l = UILabel()
        l.text = "默认"
        l.font = AddressStyle.defaultBadgeFont
        l.textColor = .white
        l.backgroundColor = .fdPrimary
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    private let editButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("编辑", for: .normal)
        b.titleLabel?.font = AddressStyle.captionFont
        b.setTitleColor(.fdTabInactive, for: .normal)
        return b
    }()

    private let deleteButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("删除", for: .normal)
        b.titleLabel?.font = AddressStyle.captionFont
        b.setTitleColor(.fdTabInactive, for: .normal)
        return b
    }()

    // MARK: - Callbacks

    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .fdBg

        contentView.addSubview(cardView)
        [
            regionLabel, detailLabel, nameLabel, phoneLabel,
            divider, defaultTag, deleteButton, editButton
        ].forEach(cardView.addSubview)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.leading.trailing.equalToSuperview().inset(AddressStyle.horizontalInset)
            make.height.greaterThanOrEqualTo(128)
        }

        regionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(AddressStyle.cardHorizontalInset)
        }

        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(regionLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(AddressStyle.cardHorizontalInset)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(detailLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(AddressStyle.cardHorizontalInset)
        }

        phoneLabel.snp.makeConstraints { make in
            make.centerY.equalTo(nameLabel)
            make.leading.equalTo(nameLabel.snp.trailing).offset(4)
            make.trailing.lessThanOrEqualToSuperview().offset(-AddressStyle.cardHorizontalInset)
        }

        divider.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(AddressStyle.cardHorizontalInset)
        }

        defaultTag.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-12)
            make.width.equalTo(31)
            make.height.equalTo(15)
        }

        editButton.snp.makeConstraints { make in
            make.centerY.equalTo(defaultTag)
            make.trailing.equalToSuperview().offset(-AddressStyle.cardHorizontalInset)
        }

        deleteButton.snp.makeConstraints { make in
            make.centerY.equalTo(defaultTag)
            make.trailing.equalTo(editButton.snp.leading).offset(-16)
        }

        editButton.addTarget(self, action: #selector(handleEdit), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
    }

    // MARK: - Configure

    func configure(address: MAddress) {
        regionLabel.text = address.regionSummary.isEmpty ? "—" : address.regionSummary
        detailLabel.text = address.address?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "—"
        nameLabel.text = address.name ?? "未设置"
        phoneLabel.text = maskPhone(address.mobile)
        defaultTag.isHidden = !address.isDefaultAddress
    }

    // MARK: - Actions

    @objc private func handleEdit() {
        onEdit?()
    }

    @objc private func handleDelete() {
        onDelete?()
    }

    // MARK: - Helpers

    private func maskPhone(_ phone: String?) -> String {
        guard let phone, phone.count == 11 else { return phone ?? "" }
        return "\(phone.prefix(3))****\(phone.suffix(4))"
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
