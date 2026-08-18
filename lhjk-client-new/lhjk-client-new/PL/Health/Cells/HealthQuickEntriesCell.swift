import UIKit
import SnapKit
import Kingfisher

/// 健康快捷入口 — CMS `quickEntryList`（网络图标 URL + pageUrl）
final class HealthQuickEntriesCell: UITableViewCell {

    static let reuseIdentifier = "HealthQuickEntriesCell"

    private var entries: [HealthQuickEntryDisplayItem] = []
    var onEntryTap: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(entries: [HealthQuickEntryDisplayItem]) {
        self.entries = entries
        contentView.subviews.forEach { $0.removeFromSuperview() }
        guard !entries.isEmpty else { return }
        buildContent()
    }

    private func buildContent() {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview()
        }

        let row = UIStackView()
        row.distribution = .fillEqually
        card.addSubview(row)
        row.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8))
        }

        for entry in entries {
            row.addArrangedSubview(buildEntry(entry))
        }
    }

    private func buildEntry(_ e: HealthQuickEntryDisplayItem) -> UIView {
        let item = UIView()

        let iconBg = UIView()
        iconBg.backgroundColor = UIColor(hexString: "#FFF3EE")
        iconBg.layer.cornerRadius = 24
        iconBg.clipsToBounds = true

        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.clipsToBounds = true
        iconBg.addSubview(icon)

        icon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(36)
        }

        icon.kf.cancelDownloadTask()
        if let iconUrl = e.iconUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
           !iconUrl.isEmpty,
           let url = URL(string: iconUrl) {
            icon.tintColor = nil
            icon.kf.setImage(with: url, options: [.transition(.fade(0.15))])
        } else {
            icon.image = UIImage(systemName: "square.grid.2x2.fill")
            icon.tintColor = .fdPrimary
        }

        let label = UILabel()
        label.text = e.name
        label.font = .fdFont(ofSize: 12, weight: .regular)
        label.textColor = .fdText
        label.textAlignment = .center
        label.numberOfLines = 2

        item.addSubview(iconBg)
        item.addSubview(label)
        iconBg.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
            $0.size.equalTo(48)
        }
        label.snp.makeConstraints {
            $0.top.equalTo(iconBg.snp.bottom).offset(6)
            $0.centerX.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(entryTapped(_:)))
        item.addGestureRecognizer(tap)
        item.accessibilityIdentifier = e.pageUrl
        return item
    }

    @objc private func entryTapped(_ gesture: UITapGestureRecognizer) {
        guard let route = gesture.view?.accessibilityIdentifier else { return }
        onEntryTap?(route)
    }
}
