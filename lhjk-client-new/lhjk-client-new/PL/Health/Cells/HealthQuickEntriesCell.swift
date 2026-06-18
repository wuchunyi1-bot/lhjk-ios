import UIKit
import SnapKit

/// 快速入口 Cell — 4 列 icon + label
/// 参考 funde-client: quick-entries section
final class HealthQuickEntriesCell: UITableViewCell {

    static let reuseIdentifier = "HealthQuickEntriesCell"

    struct Entry {
        let key: String; let label: String; let icon: String
        let bgColor: UIColor; let fgColor: UIColor; let route: String
    }

    private var entries: [Entry] = []
    var onEntryTap: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(entries: [Entry]) {
        self.entries = entries
        contentView.subviews.forEach { $0.removeFromSuperview() }
        buildContent()
    }

    private func buildContent() {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let row = UIStackView()
        row.distribution = .fillEqually
        card.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 18, left: 8, bottom: 18, right: 8)) }

        for entry in entries {
            let item = buildEntry(entry)
            row.addArrangedSubview(item)
        }
    }

    private func buildEntry(_ e: Entry) -> UIView {
        let item = UIView()
        let iconBg = UIView()
        iconBg.backgroundColor = e.bgColor
        iconBg.layer.cornerRadius = 16
        let icon = UIImageView(image: UIImage(systemName: e.icon))
        icon.tintColor = e.fgColor; icon.contentMode = .scaleAspectFit
        iconBg.addSubview(icon)

        let label = UILabel()
        label.text = e.label; label.font = .fdCaption
        label.textColor = .fdText2; label.textAlignment = .center

        item.addSubview(iconBg); item.addSubview(label)
        iconBg.snp.makeConstraints { $0.top.centerX.equalToSuperview(); $0.size.equalTo(48) }
        icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(24) }
        label.snp.makeConstraints { $0.top.equalTo(iconBg.snp.bottom).offset(6); $0.centerX.equalToSuperview(); $0.bottom.equalToSuperview() }

        let tap = UITapGestureRecognizer(target: self, action: #selector(entryTapped(_:)))
        item.addGestureRecognizer(tap)
        item.accessibilityIdentifier = e.route
        return item
    }

    @objc private func entryTapped(_ gesture: UITapGestureRecognizer) {
        guard let route = gesture.view?.accessibilityIdentifier else { return }
        onEntryTap?(route)
    }
}
