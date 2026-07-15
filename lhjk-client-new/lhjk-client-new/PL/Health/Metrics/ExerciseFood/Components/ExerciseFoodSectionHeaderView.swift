import UIKit
import SnapKit

final class ExerciseFoodSectionHeaderView: UITableViewHeaderFooterView {

    static let reuseID = "ExerciseFoodSectionHeaderView"

    private let card = UIView()
    private let titleLabel = UILabel()
    private let hintLabel = UILabel()
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor(hexString: "#F9F8F8")

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText
        hintLabel.font = .fdCaption
        hintLabel.textColor = .fdMuted
        valueLabel.font = .fdBodySemibold
        valueLabel.textColor = UIColor(hexString: "#FF5B83")
        unitLabel.font = .fdCaption
        unitLabel.textColor = .fdText
        unitLabel.text = "kcal"

        contentView.addSubview(card)
        [titleLabel, hintLabel, valueLabel, unitLabel].forEach(card.addSubview)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 16, bottom: 0, right: 16))
            make.height.equalTo(52)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
        }
        hintLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(6)
            make.bottom.equalTo(titleLabel)
        }
        unitLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalTo(titleLabel)
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(unitLabel.snp.leading)
            make.bottom.equalTo(titleLabel)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, hint: String?, consume: String?) {
        titleLabel.text = title
        hintLabel.text = hint
        valueLabel.text = consume ?? "--"
    }
}
