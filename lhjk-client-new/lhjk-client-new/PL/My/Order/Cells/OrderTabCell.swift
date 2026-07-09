import UIKit
import SnapKit

final class OrderTabCell: UICollectionViewCell {

    static let reuseID = "OrderTabCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdCaptionSemibold
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        titleLabel.textColor = isSelected ? .fdPrimary : .fdSubtext
    }
}
