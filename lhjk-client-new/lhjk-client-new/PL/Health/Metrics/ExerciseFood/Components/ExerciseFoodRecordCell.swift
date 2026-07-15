import UIKit
import SnapKit
import Kingfisher

final class ExerciseFoodRecordCell: UITableViewCell {

    static let reuseID = "ExerciseFoodRecordCell"

    private let card = UIView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let quantityLabel = UILabel()
    private let calorieLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 8
        nameLabel.font = .fdBody
        nameLabel.textColor = .fdText
        quantityLabel.font = .fdCaption
        quantityLabel.textColor = .fdSubtext
        calorieLabel.font = .fdBodySemibold
        calorieLabel.textColor = UIColor(hexString: "#FF5B83")
        calorieLabel.textAlignment = .right

        contentView.addSubview(card)
        [iconView, nameLabel, quantityLabel, calorieLabel].forEach(card.addSubview)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16))
            make.height.equalTo(72)
        }
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(14)
            make.trailing.lessThanOrEqualTo(calorieLabel.snp.leading).offset(-8)
        }
        quantityLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
        }
        calorieLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(item: ExerciseFoodRecordItem) {
        nameLabel.text = item.name ?? "--"
        quantityLabel.text = item.quantityDisplay
        calorieLabel.text = item.calorieDisplay
        if let url = item.imgSmallUrl.flatMap(URL.init(string:)) {
            iconView.kf.setImage(with: url)
        } else {
            iconView.image = UIImage(systemName: "leaf")
            iconView.tintColor = .fdMuted
        }
    }
}
