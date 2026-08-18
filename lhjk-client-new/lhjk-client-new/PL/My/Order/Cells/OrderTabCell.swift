import UIKit
import SnapKit

/// 订单列表 Tab 项 — 对齐 Figma 3509:9308
final class OrderTabCell: UICollectionViewCell {

    static let reuseID = "OrderTabCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .regular)
        l.textAlignment = .center
        return l
    }()

    private let indicatorView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#FF7A50")
        v.layer.cornerRadius = 2
        v.clipsToBounds = true
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        contentView.addSubview(indicatorView)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.centerX.equalToSuperview()
        }

        indicatorView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.width.equalTo(18)
            make.height.equalTo(4)
            make.bottom.lessThanOrEqualToSuperview().offset(-2)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        if isSelected {
            titleLabel.font = .fdFont(ofSize: 14, weight: .medium)
            titleLabel.textColor = UIColor(hexString: "#1F2942")
            indicatorView.isHidden = false
        } else {
            titleLabel.font = .fdFont(ofSize: 14, weight: .regular)
            titleLabel.textColor = UIColor(hexString: "#535D72")
            indicatorView.isHidden = true
        }
    }
}
