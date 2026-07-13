import UIKit
import SnapKit

/// 通用功能行 Cell — icon + label + detail + chevron
/// 视图在 init 时创建一次，configure 只更新内容/显隐
final class MeFuncRowCell: UITableViewCell {

    static let reuseIdentifier = "MeFuncRowCell"

    struct RowData {
        let icon: String; let color: UIColor
        let title: String; let detail: String?
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

    // MARK: - Views (created once)

    private let card = UIView()
    private let iconContainer = UIView()
    private let iconImg = UIImageView()
    private let titleLbl = UILabel()
    private let detailLbl = UILabel()
    private let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let divider = UIView()

    // MARK: - Init

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

        titleLbl.font = .fdBody
        arrow.tintColor = .fdMuted
        arrow.contentMode = .scaleAspectFit

        detailLbl.font = .fdCaption
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
        // titleLbl leading differs by showIcon — set in configure()
        divider.snp.makeConstraints { $0.leading.equalTo(titleLbl); $0.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }

        card.snp.makeConstraints { $0.height.equalTo(48) }

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Configure (赋值 only)

    func configure(data: RowData) {
        iconContainer.backgroundColor = data.color.withAlphaComponent(0.10)
        iconContainer.isHidden = !data.showIcon
        iconImg.image = UIImage(systemName: data.icon)
        iconImg.tintColor = data.color

        titleLbl.text = data.title
        titleLbl.textColor = data.titleColor

        detailLbl.text = data.detail
        detailLbl.isHidden = (data.detail == nil)
        arrow.isHidden = !data.showChevron

        divider.isHidden = !data.showDivider

        // Adjust title leading based on icon visibility
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
