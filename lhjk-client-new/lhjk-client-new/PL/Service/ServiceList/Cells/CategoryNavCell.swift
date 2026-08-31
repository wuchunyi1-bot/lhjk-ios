import UIKit
import SnapKit

/// 套餐列表左栏类目 — Figma 3760:10575（选中白底 + 上下邻接 16pt 内凹圆弧）
final class CategoryNavCell: UITableViewCell {
    static let reuseID = "CategoryNavCell"
    static let rowHeight: CGFloat = 55

    /// 未选中项与选中项相邻一侧的圆弧（露出底层白色形成内凹）
    enum AdjacentCorner {
        case none
        case topRight
        case bottomRight
    }

    private enum Design {
        static let cornerRadius: CGFloat = 16
        static let indicatorWidth: CGFloat = 4
        static let indicatorHeight: CGFloat = 28
        static let indicatorCornerRadius: CGFloat = 8
        static let titleLeading: CGFloat = 16
        static let titleTrailing: CGFloat = 8
        static let titleFontSize: CGFloat = 14
    }

    private let backgroundFill = UIView()
    private let indicator = UIView()
    private let nameLbl = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        backgroundFill.clipsToBounds = true

        indicator.backgroundColor = .fdPrimary
        indicator.layer.cornerRadius = Design.indicatorCornerRadius
        indicator.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        indicator.isHidden = true

        nameLbl.numberOfLines = 2

        contentView.addSubview(backgroundFill)
        contentView.addSubview(indicator)
        contentView.addSubview(nameLbl)

        backgroundFill.snp.makeConstraints { $0.edges.equalToSuperview() }

        indicator.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.equalTo(Design.indicatorWidth)
            $0.height.equalTo(Design.indicatorHeight)
        }
        nameLbl.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Design.titleLeading)
            $0.trailing.equalToSuperview().inset(Design.titleTrailing)
            $0.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(
        title: String,
        active: Bool,
        adjacentCorner: AdjacentCorner = .none,
        connectsAbove: Bool = false,
        connectsBelow: Bool = false
    ) {
        nameLbl.text = title
        indicator.isHidden = !active

        if active {
            backgroundFill.backgroundColor = .fdSurface
            nameLbl.textColor = .fdPrimary
            nameLbl.font = .fdFont(ofSize: Design.titleFontSize, weight: .medium)
            applyCornerRadius(
                on: backgroundFill,
                topRight: connectsAbove,
                bottomRight: connectsBelow
            )
        } else {
            backgroundFill.backgroundColor = .fdBg
            nameLbl.textColor = UIColor(hexString: "#1F2942")
            nameLbl.font = .fdFont(ofSize: Design.titleFontSize, weight: .regular)
            switch adjacentCorner {
            case .none:
                applyCornerRadius(on: backgroundFill, topRight: false, bottomRight: false)
            case .topRight:
                applyCornerRadius(on: backgroundFill, topRight: true, bottomRight: false)
            case .bottomRight:
                applyCornerRadius(on: backgroundFill, topRight: false, bottomRight: true)
            }
        }
    }

    func configure(_ m: SvcMatrix, active: Bool, adjacentCorner: AdjacentCorner = .none) {
        configure(title: m.name, active: active, adjacentCorner: adjacentCorner)
    }

    private func applyCornerRadius(on view: UIView, topRight: Bool, bottomRight: Bool) {
        var corners: CACornerMask = []
        if topRight { corners.insert(.layerMaxXMinYCorner) }
        if bottomRight { corners.insert(.layerMaxXMaxYCorner) }
        if corners.isEmpty {
            view.layer.cornerRadius = 0
            view.layer.maskedCorners = []
        } else {
            view.layer.cornerRadius = Design.cornerRadius
            view.layer.maskedCorners = corners
        }
    }
}
