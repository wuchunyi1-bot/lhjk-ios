import UIKit
import SnapKit

/// 套餐列表左栏类目 — 对齐 Figma 3021:2256（宽 115 / 高约 55）
final class CategoryNavCell: UITableViewCell {
    static let reuseID = "CategoryNavCell"
    static let rowHeight: CGFloat = 55

    private let indicator = UIView()
    private let nameLbl = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .fdBg

        indicator.backgroundColor = .fdPrimary
        indicator.layer.cornerRadius = 8
        indicator.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        indicator.isHidden = true

        nameLbl.font = .fdFont(ofSize: 14, weight: .regular)
        nameLbl.textColor = .fdText
        nameLbl.numberOfLines = 2

        contentView.addSubview(indicator)
        contentView.addSubview(nameLbl)

        indicator.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.equalTo(4)
            $0.height.equalTo(28)
        }
        nameLbl.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(8)
            $0.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, active: Bool) {
        nameLbl.text = title
        indicator.isHidden = !active
        // 选中：白底；未选中：暖米底（对齐稿面左右分区）
        contentView.backgroundColor = active ? .fdSurface : .fdBg
        nameLbl.textColor = .fdText
        nameLbl.font = .fdFont(ofSize: 14, weight: .regular)
    }

    func configure(_ m: SvcMatrix, active: Bool) {
        configure(title: m.name, active: active)
    }
}
