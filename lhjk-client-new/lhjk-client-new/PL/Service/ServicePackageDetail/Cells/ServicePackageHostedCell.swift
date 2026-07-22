import UIKit
import SnapKit

/// 承载任意子 View 的通用 TableView Cell
final class ServicePackageHostedCell: UITableViewCell {
    static let reuseID = "ServicePackageHostedCell"

    private var hostedView: UIView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    func host(_ view: UIView, insets: UIEdgeInsets) {
        if hostedView !== view {
            hostedView?.removeFromSuperview()
            hostedView = view
            contentView.addSubview(view)
        }
        // bottom 用较低优先级，避免 UITableView 自适应行高时临时 44pt 高度与内容冲突
        view.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(insets.top)
            $0.leading.equalToSuperview().offset(insets.left)
            $0.trailing.equalToSuperview().offset(-insets.right)
            $0.bottom.equalToSuperview().offset(-insets.bottom).priority(.init(999))
        }
    }
}
