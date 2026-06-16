import UIKit
import SnapKit

/// 健康史 2×2 grid Cell
/// 参考 funde-client: hp-history-grid
final class HealthRecordHistoryCell: UITableViewCell {

    static let reuseIdentifier = "HealthRecordHistoryCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(items: [HealthHistoryItem]) {
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let outerStack = UIStackView()
        outerStack.axis = .vertical
        card.addSubview(outerStack)
        outerStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)) }

        // First row: 过敏史 | 既往史
        let row1 = UIStackView()
        row1.axis = .horizontal
        row1.distribution = .fillEqually
        outerStack.addArrangedSubview(row1)

        if items.count >= 2 {
            row1.addArrangedSubview(buildItemView(items[0], showRightBorder: true))
            row1.addArrangedSubview(buildItemView(items[1], showRightBorder: false))
        }

        // Horizontal divider
        if items.count >= 4 {
            let hDivider = UIView()
            hDivider.backgroundColor = .fdBorder
            outerStack.addArrangedSubview(hDivider)
            hDivider.snp.makeConstraints { $0.height.equalTo(1) }
        }

        // Second row: 家族史 | 用药史
        let row2 = UIStackView()
        row2.axis = .horizontal
        row2.distribution = .fillEqually
        outerStack.addArrangedSubview(row2)

        if items.count >= 4 {
            row2.addArrangedSubview(buildItemView(items[2], showRightBorder: true))
            row2.addArrangedSubview(buildItemView(items[3], showRightBorder: false))
        }
    }

    private func buildItemView(_ item: HealthHistoryItem, showRightBorder: Bool) -> UIView {
        let container = UIView()

        let label = UILabel()
        label.text = item.label
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .fdText
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.trailing.equalToSuperview()
        }

        let summary = UILabel()
        summary.text = item.summary
        summary.font = .systemFont(ofSize: 12)
        summary.textColor = item.status == .empty ? .fdMuted : .fdText2
        summary.numberOfLines = 0
        container.addSubview(summary)
        summary.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-14)
        }

        if showRightBorder {
            let border = UIView()
            border.backgroundColor = .fdBorder
            container.addSubview(border)
            border.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(14)
                make.top.bottom.equalToSuperview().inset(4)
                make.width.equalTo(1)
            }
        }

        return container
    }
}
