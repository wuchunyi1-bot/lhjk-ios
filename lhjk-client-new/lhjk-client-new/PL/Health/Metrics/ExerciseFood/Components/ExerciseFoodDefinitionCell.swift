import UIKit
import SnapKit
import Kingfisher

final class ExerciseFoodDefinitionCell: UITableViewCell {

    static let reuseID = "ExerciseFoodDefinitionCell"

    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let checkView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 8
        nameLabel.font = .fdBody
        nameLabel.textColor = .fdText
        detailLabel.font = .fdCaption
        detailLabel.textColor = .fdSubtext
        checkView.image = UIImage(systemName: "checkmark.circle.fill")
        checkView.tintColor = UIColor(hexString: "#FF406F")
        checkView.isHidden = true

        contentView.addSubview(iconView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(checkView)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(checkView.snp.leading).offset(-8)
        }
        detailLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
        }
        checkView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.size.equalTo(22)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(item: ExerciseFoodDefinitionItem, selected: Bool) {
        nameLabel.text = item.name
        let qty = item.showQuantity ?? "1份"
        let cal = item.showCalorie ?? item.calorie?.value ?? "--"
        detailLabel.text = "\(qty)/\(cal)kcal"
        checkView.isHidden = !selected
        if let url = item.imgSmallUrl.flatMap(URL.init(string:)) {
            iconView.kf.setImage(with: url)
        } else {
            iconView.image = UIImage(systemName: "leaf")
            iconView.tintColor = .fdMuted
        }
    }
}
