import UIKit
import SnapKit

final class PointRecordCell: UITableViewCell {

    static let reuseID = "PointRecordCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ r: PtsRecord) {
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

        let row = UIStackView()
        row.alignment = .center
        row.spacing = 12
        row.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        row.isLayoutMarginsRelativeArrangement = true
        card.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview() }

        let body = UIStackView()
        body.axis = .vertical
        body.spacing = 4
        body.addArrangedSubview({
            let l = UILabel()
            l.text = r.title
            l.font = .fdBodyBold
            l.textColor = .fdText
            return l
        }())
        body.addArrangedSubview({
            let l = UILabel()
            l.text = r.date
            l.font = .fdCaption
            l.textColor = .fdSubtext
            return l
        }())
        row.addArrangedSubview(body)
        row.addArrangedSubview({
            let l = UILabel()
            l.text = r.points
            l.font = .fdH2
            l.textColor = r.isAdd ? .fdPrimary : .fdSubtext
            return l
        }())
    }
}
