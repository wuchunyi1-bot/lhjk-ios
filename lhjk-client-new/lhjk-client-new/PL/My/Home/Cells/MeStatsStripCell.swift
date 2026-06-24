import UIKit
import SnapKit

/// 4 列统计条 Cell
final class MeStatsStripCell: UITableViewCell {

    static let reuseIdentifier = "MeStatsStripCell"

    typealias StatItem = (value: String, label: String, accent: Bool, route: String?)

    private var items: [StatItem] = []
    var onStatTap: ((Int) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(items: [StatItem]) {
        self.items = items
        contentView.subviews.forEach { $0.removeFromSuperview() }
        setupUI()
    }

    private func setupUI() {
        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        container.layer.cornerRadius = 14
        contentView.addSubview(container)
        container.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let stack = UIStackView()
        stack.distribution = .fillEqually
        container.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 9, left: 0, bottom: 7, right: 0)) }

        for (i, item) in items.enumerated() {
            let col = UIView()
            let valLbl = UILabel()
            valLbl.text = item.value
            valLbl.textColor = item.accent ? .fdPrimary : .fdText
            valLbl.font = .fdH2
            valLbl.textAlignment = .center

            let lblLbl = UILabel()
            lblLbl.text = item.label
            lblLbl.font = .fdMicro
            lblLbl.textColor = .fdSubtext
            lblLbl.textAlignment = .center

            col.addSubview(valLbl); col.addSubview(lblLbl)
            valLbl.snp.makeConstraints { $0.top.centerX.equalToSuperview() }
            lblLbl.snp.makeConstraints { $0.top.equalTo(valLbl.snp.bottom).offset(4); $0.centerX.equalToSuperview(); $0.bottom.equalToSuperview() }

            if i < items.count - 1 {
                let divider = UIView()
                divider.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.12)
                col.addSubview(divider)
                divider.snp.makeConstraints { $0.trailing.centerY.equalToSuperview(); $0.width.equalTo(1); $0.height.equalTo(36) }
            }

            col.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(statTapped(_:)))
            col.addGestureRecognizer(tap)
            col.tag = i
            stack.addArrangedSubview(col)
        }
    }

    @objc private func statTapped(_ gesture: UITapGestureRecognizer) {
        guard let idx = gesture.view?.tag else { return }
        onStatTap?(idx)
    }
}
