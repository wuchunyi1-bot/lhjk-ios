import UIKit
import SnapKit

final class CategoryNavCell: UITableViewCell {
    static let reuseID = "CategoryNavCell"

    private let dot = UIView()
    private let nameLbl = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        dot.layer.cornerRadius = 1.5
        dot.isHidden = true

        nameLbl.font = .fdMicro
        nameLbl.textColor = .fdSubtext
        nameLbl.textAlignment = .center
        nameLbl.numberOfLines = 2

        contentView.addSubview(dot)
        contentView.addSubview(nameLbl)

        dot.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(CGSize(width: 3, height: 24))
        }
        nameLbl.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(12)
            $0.leading.trailing.equalToSuperview().inset(8)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, active: Bool) {
        nameLbl.text = title
        dot.isHidden = !active
        dot.backgroundColor = .fdPrimary
        contentView.backgroundColor = active ? .fdSurface : .fdBg2
        nameLbl.textColor = active ? .fdPrimary : .fdSubtext
        nameLbl.font = active ? .fdMicroSemibold : .fdMicro
    }

    func configure(_ m: SvcMatrix, active: Bool) {
        configure(title: m.name, active: active)
    }
}
