import UIKit
import SnapKit

/// 收货地址卡片 Cell
///
/// 布局：
/// ┌─────────────────────────────────────┐
/// │ 收货人：张三          138****1234  │
/// │ 广东省深圳市南山区科技园路 1 号     │
/// │ [默认]                    编辑 删除 │
/// └─────────────────────────────────────┘
final class AddressCell: UITableViewCell {

    static let reuseIdentifier = "AddressCell"

    // MARK: - UI

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = 14
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 1)
        v.layer.shadowRadius = 6
        v.layer.shadowOpacity = 0.03
        return v
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .fdBodySemibold
        l.textColor = .fdText
        return l
    }()

    private let phoneLabel: UILabel = {
        let l = UILabel()
        l.font = .fdBody
        l.textColor = .fdSubtext
        return l
    }()

    private let addressLabel: UILabel = {
        let l = UILabel()
        l.font = .fdCaption
        l.textColor = .fdSubtext
        l.numberOfLines = 2
        return l
    }()

    private let defaultTag: UILabel = {
        let l = UILabel()
        l.text = "默认"
        l.font = .fdMicro
        l.textColor = .fdPrimary
        l.backgroundColor = .fdPrimarySoft
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    private let editButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("编辑", for: .normal)
        b.titleLabel?.font = .fdCaption
        b.setTitleColor(.fdSubtext, for: .normal)
        return b
    }()

    private let deleteButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("删除", for: .normal)
        b.titleLabel?.font = .fdCaption
        b.setTitleColor(.fdDanger, for: .normal)
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

        [nameLabel, phoneLabel, addressLabel, defaultTag, editButton, deleteButton].forEach(cardView.addSubview)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.leading.trailing.equalToSuperview().inset(16).priority(750)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        phoneLabel.snp.makeConstraints { make in
            make.centerY.equalTo(nameLabel)
            make.leading.equalTo(nameLabel.snp.trailing).offset(12)
        }

        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        defaultTag.snp.makeConstraints { make in
            make.top.equalTo(addressLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-14)
            make.width.equalTo(40)
            make.height.equalTo(20)
        }

        deleteButton.snp.makeConstraints { make in
            make.centerY.equalTo(defaultTag)
            make.trailing.equalToSuperview().offset(-16)
        }

        editButton.snp.makeConstraints { make in
            make.centerY.equalTo(defaultTag)
            make.trailing.equalTo(deleteButton.snp.leading).offset(-16)
        }

        editButton.addTarget(self, action: #selector(handleEdit), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
    }

    // MARK: - Configure

    func configure(address: MAddress) {
        nameLabel.text = address.name ?? "未设置"
        phoneLabel.text = maskPhone(address.mobile)
        addressLabel.text = address.fullAddress
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
        guard let phone = phone, phone.count == 11 else { return phone ?? "" }
        return "\(phone.prefix(3))****\(phone.suffix(4))"
    }
}
