import UIKit
import SnapKit

final class ExerciseFoodCategoryCell: UITableViewCell {

    static let reuseID = "ExerciseFoodCategoryCell"

    private let titleLabel = UILabel()
    private let indicator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor(hexString: "#F5F2F3")
        titleLabel.font = .fdCaption
        titleLabel.textColor = .fdSubtext
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        indicator.backgroundColor = UIColor(hexString: "#FF406F")
        indicator.isHidden = true
        contentView.addSubview(indicator)
        contentView.addSubview(titleLabel)
        indicator.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(3)
        }
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, selected: Bool) {
        titleLabel.text = title
        titleLabel.textColor = selected ? UIColor(hexString: "#FF406F") : .fdSubtext
        titleLabel.font = selected ? .fdCaptionSemibold : .fdCaption
        backgroundColor = selected ? .fdSurface : UIColor(hexString: "#F5F2F3")
        indicator.isHidden = !selected
    }
}
