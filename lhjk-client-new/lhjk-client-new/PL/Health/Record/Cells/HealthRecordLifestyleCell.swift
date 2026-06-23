import UIKit
import SnapKit

/// 生活习惯 2×1 grid Cell
/// 参考 funde-client: hp-lifestyle-grid
final class HealthRecordLifestyleCell: UITableViewCell {

    static let reuseIdentifier = "HealthRecordLifestyleCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(items: [LifestyleItem]) {
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 10
        contentView.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        for item in items {
            let card = buildCard(item)
            row.addArrangedSubview(card)
        }
    }

    private func buildCard(_ item: LifestyleItem) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 14
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03

        // Header: icon + label
        let header = UIStackView()
        header.axis = .horizontal
        header.spacing = 6
        header.alignment = .center

        let iconView = UIImageView(image: UIImage(systemName: item.icon))
        iconView.tintColor = .fdPrimary
        iconView.contentMode = .scaleAspectFit
        header.addArrangedSubview(iconView)
        iconView.snp.makeConstraints { $0.size.equalTo(15) }

        let label = UILabel()
        label.text = item.label
        label.font = .fdCaptionSemibold
        label.textColor = .fdText
        header.addArrangedSubview(label)

        card.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(14)
        }

        // Body: summary
        let body = UILabel()
        body.text = item.summary
        body.font = .fdCaption
        body.textColor = .fdText2
        body.numberOfLines = 0

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        body.attributedText = NSAttributedString(
            string: item.summary,
            attributes: [.paragraphStyle: paragraphStyle]
        )

        card.addSubview(body)
        body.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(14)
        }

        return card
    }
}
