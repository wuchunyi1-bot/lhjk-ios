import UIKit
import SnapKit

final class BloodSugarDiabetesTypeCell: UITableViewCell {

    static let reuseID = "BloodSugarDiabetesTypeCell"

    private let card = UIView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 12, right: 16))
            make.height.equalTo(52)
        }

        titleLabel.text = "糖尿病类型"
        titleLabel.font = .fdBody
        titleLabel.textColor = .fdText
        valueLabel.font = .fdBodySemibold
        valueLabel.textColor = .fdSubtext
        valueLabel.text = "--"
        valueLabel.textAlignment = .right

        card.addSubview(titleLabel)
        card.addSubview(valueLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(typeText: String) {
        valueLabel.text = typeText
    }
}
