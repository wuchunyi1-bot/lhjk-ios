import UIKit
import SnapKit

/// 健康管理卡片视图 — 对齐 Figma 3594:8653
final class MeHealthManagementCardView: UIView {

    struct RowItem {
        let iconName: String
        let title: String
        let detail: String?
        let route: String?
    }

    var onRowTap: ((String) -> Void)?

    private let titleLabel = UILabel()
    private let rowsStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 16
        clipsToBounds = true

        // Title: 健康管理
        titleLabel.text = "健康管理"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#1F2430")
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(16)
        }

        // Rows Stack
        rowsStack.axis = .vertical
        rowsStack.distribution = .fill
        rowsStack.alignment = .fill
        rowsStack.spacing = 0
        addSubview(rowsStack)
        rowsStack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalToSuperview().offset(50)
            $0.bottom.equalToSuperview().offset(-8)
        }
    }

    func configure(rows: [RowItem]) {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for (index, row) in rows.enumerated() {
            let rowView = buildRowView(row: row, showDivider: index < rows.count - 1)
            rowsStack.addArrangedSubview(rowView)
        }
    }

    private func buildRowView(row: RowItem, showDivider: Bool) -> UIView {
        let container = UIView()

        let button = UIButton(type: .custom)
        button.addAction(UIAction { [weak self] _ in
            guard let route = row.route, !route.isEmpty else { return }
            self?.onRowTap?(route)
        }, for: .touchUpInside)
        container.addSubview(button)
        button.snp.makeConstraints { $0.edges.equalToSuperview() }

        let iconView = UIImageView()
        iconView.image = UIImage(named: row.iconName)
        iconView.contentMode = .scaleAspectFit
        button.addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        let titleLbl = UILabel()
        titleLbl.text = row.title
        titleLbl.font = .fdFont(ofSize: 17, weight: .regular)
        titleLbl.textColor = UIColor(hexString: "#1F2942")
        button.addSubview(titleLbl)
        titleLbl.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(10)
            $0.centerY.equalToSuperview()
        }

        let arrow = UIImageView(image: UIImage(named: "me_list_more_arrow"))
        arrow.contentMode = .scaleAspectFit
        button.addSubview(arrow)
        arrow.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-14)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(12)
        }

        if let detail = row.detail, !detail.isEmpty {
            let detailLbl = UILabel()
            detailLbl.text = detail
            detailLbl.font = .fdFont(ofSize: 15, weight: .regular)
            detailLbl.textColor = UIColor(hexString: "#717885")
            detailLbl.textAlignment = .right
            button.addSubview(detailLbl)
            detailLbl.snp.makeConstraints {
                $0.trailing.equalTo(arrow.snp.leading).offset(-4)
                $0.centerY.equalToSuperview()
                $0.leading.greaterThanOrEqualTo(titleLbl.snp.trailing).offset(8)
            }
        }

        if showDivider {
            let divider = UIView()
            divider.backgroundColor = UIColor(hexString: "#EEEEEE")
            container.addSubview(divider)
            divider.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview().inset(14)
                $0.bottom.equalToSuperview()
                $0.height.equalTo(0.5)
            }
        }

        container.snp.makeConstraints {
            $0.height.equalTo(56)
        }

        return container
    }
}

/// 通用功能行 Cell 兼容包装
final class MeFuncRowCell: UITableViewCell {

    static let reuseIdentifier = "MeFuncRowCell"

    struct RowData {
        let icon: String
        let color: UIColor
        let title: String
        let detail: String?
        let showDivider: Bool
        var showIcon: Bool = true
        var titleColor: UIColor = .fdText
        var showChevron: Bool = true

        static func settingsRow(title: String, showDivider: Bool, destructive: Bool = false) -> RowData {
            RowData(icon: "", color: .clear, title: title, detail: nil,
                    showDivider: showDivider, showIcon: false,
                    titleColor: destructive ? .fdDanger : .fdText)
        }
    }

    var onTap: (() -> Void)?

    private let card = UIView()
    private let iconContainer = UIView()
    private let iconImg = UIImageView()
    private let titleLbl = UILabel()
    private let detailLbl = UILabel()
    private let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let divider = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        card.backgroundColor = .fdSurface
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)) }

        iconContainer.layer.cornerRadius = 10
        iconContainer.addSubview(iconImg)
        iconImg.contentMode = .scaleAspectFit

        titleLbl.font = .fdMyBody
        arrow.tintColor = .fdMuted
        arrow.contentMode = .scaleAspectFit

        detailLbl.font = .fdMyCaption
        detailLbl.textColor = .fdMuted

        divider.backgroundColor = .fdBorder

        card.addSubview(iconContainer)
        card.addSubview(titleLbl)
        card.addSubview(detailLbl)
        card.addSubview(arrow)
        card.addSubview(divider)

        iconContainer.snp.makeConstraints { $0.leading.equalToSuperview().inset(16); $0.centerY.equalToSuperview(); $0.size.equalTo(32) }
        iconImg.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(18) }
        arrow.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview(); $0.size.equalTo(16) }
        detailLbl.snp.makeConstraints { $0.trailing.equalTo(arrow.snp.leading).offset(-4); $0.centerY.equalToSuperview() }
        divider.snp.makeConstraints { $0.leading.equalTo(titleLbl); $0.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }

        card.snp.makeConstraints { $0.height.equalTo(48) }

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(data: RowData) {
        iconContainer.backgroundColor = data.color.withAlphaComponent(0.10)
        iconContainer.isHidden = !data.showIcon
        if let customImg = UIImage(named: data.icon) {
            iconImg.image = customImg
        } else {
            iconImg.image = UIImage(systemName: data.icon)
        }
        iconImg.tintColor = data.color

        titleLbl.text = data.title
        titleLbl.textColor = data.titleColor

        detailLbl.text = data.detail
        detailLbl.isHidden = (data.detail == nil)
        arrow.isHidden = !data.showChevron
        divider.isHidden = !data.showDivider

        if data.showIcon {
            iconContainer.snp.updateConstraints { $0.size.equalTo(32) }
            titleLbl.snp.remakeConstraints {
                $0.leading.equalTo(iconContainer.snp.trailing).offset(12)
                $0.centerY.equalToSuperview()
                if data.detail != nil {
                    $0.trailing.lessThanOrEqualTo(detailLbl.snp.leading).offset(-8)
                }
            }
        } else {
            iconContainer.snp.updateConstraints { $0.size.equalTo(0) }
            titleLbl.snp.remakeConstraints {
                $0.leading.equalToSuperview().inset(16)
                $0.centerY.equalToSuperview()
                if data.detail != nil {
                    $0.trailing.lessThanOrEqualTo(detailLbl.snp.leading).offset(-8)
                }
            }
        }
    }

    @objc private func didTap() { onTap?() }
}
