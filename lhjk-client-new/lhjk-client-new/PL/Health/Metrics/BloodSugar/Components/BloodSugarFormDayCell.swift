import UIKit
import SnapKit

/// 表格 Tab 每日行
final class BloodSugarFormDayCell: UITableViewCell {

    static let reuseID = "BloodSugarFormDayCell"

    private let dateLabel = UILabel()
    private let valuesStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdSurface

        dateLabel.font = .fdCaptionSemibold
        dateLabel.textColor = .fdText
        dateLabel.textAlignment = .center
        dateLabel.snp.makeConstraints { $0.width.equalTo(56) }

        valuesStack.axis = .horizontal
        valuesStack.distribution = .fillEqually
        valuesStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [dateLabel, valuesStack])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        contentView.addSubview(row)
        row.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
            make.height.equalTo(35)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(date: String, values: [(text: String, colorHex: String?)], striped: Bool) {
        dateLabel.text = date
        backgroundColor = striped ? UIColor(hexString: "#FCFBFB") : .fdSurface
        valuesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for value in values {
            let label = UILabel()
            label.font = .fdCaption
            label.textAlignment = .center
            label.text = value.text
            label.textColor = value.colorHex.map { UIColor(hexString: $0) } ?? .fdText
            valuesStack.addArrangedSubview(label)
        }
    }
}
