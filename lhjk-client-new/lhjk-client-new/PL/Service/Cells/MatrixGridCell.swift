import UIKit
import SnapKit

final class MatrixGridCell: UITableViewCell {
    static let reuseID = "MatrixGridCell"

    var onTileTap: ((String) -> Void)?
    private var items: [ProductMatrixItem] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ items: [ProductMatrixItem]) {
        self.items = items
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)) }

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 4
        card.addSubview(grid)
        grid.snp.makeConstraints { $0.edges.equalToSuperview().inset(8) }

        for r in stride(from: 0, to: items.count, by: 3) {
            let row = UIStackView()
            row.distribution = .fillEqually
            row.spacing = 4
            for c in r..<min(r + 3, items.count) {
                row.addArrangedSubview(buildTile(items[c], index: c))
            }
            grid.addArrangedSubview(row)
        }
    }

    private func buildTile(_ m: ProductMatrixItem, index: Int) -> UIView {
        let tile = UIButton(type: .system)
        tile.backgroundColor = .clear
        tile.layer.cornerRadius = 12
        tile.tag = index

        let icon = UIView()
        icon.layer.cornerRadius = 12
        icon.backgroundColor = m.accent.withAlphaComponent(0.13)
        icon.layer.borderWidth = 1
        icon.layer.borderColor = m.accent.withAlphaComponent(0.2).cgColor
        let il = UILabel()
        il.text = m.code
        il.font = .fdCaptionSemibold
        il.textColor = m.accent
        il.textAlignment = .center
        icon.addSubview(il)
        il.snp.makeConstraints { $0.center.equalToSuperview() }
        icon.snp.makeConstraints { $0.size.equalTo(44) }

        let name = UILabel()
        name.text = m.name
        name.font = .fdCaptionSemibold
        name.textColor = .fdText
        name.textAlignment = .center
        let desc = UILabel()
        desc.text = m.desc
        desc.font = .fdMicro
        desc.textColor = .fdSubtext
        desc.textAlignment = .center
        desc.isHidden = m.desc.isEmpty
        let tier = UILabel()
        tier.text = m.tier
        tier.font = .fdMicroSemibold
        tier.textColor = m.accent
        tier.textAlignment = .center
        tier.isHidden = m.tier.isEmpty

        let stack = UIStackView(arrangedSubviews: [icon, name, desc, tier])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.isUserInteractionEnabled = false
        tile.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 4, bottom: 12, right: 4)) }

        if m.current {
            let badge = UILabel()
            badge.text = "使用中"
            badge.font = .fdMicroSemibold
            badge.textColor = .white
            badge.backgroundColor = .fdPrimary
            badge.layer.cornerRadius = 4
            badge.textAlignment = .center
            badge.clipsToBounds = true
            tile.addSubview(badge)
            badge.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(4); $0.height.equalTo(16); $0.width.equalTo(44) }
        }

        tile.addTarget(self, action: #selector(tileTapped(_:)), for: .touchUpInside)
        return tile
    }

    @objc private func tileTapped(_ sender: UIButton) {
        guard sender.tag < items.count else { return }
        onTileTap?(items[sender.tag].code)
    }
}
