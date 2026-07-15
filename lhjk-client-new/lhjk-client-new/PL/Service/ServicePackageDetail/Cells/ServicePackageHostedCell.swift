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
        view.snp.remakeConstraints {
            $0.edges.equalToSuperview().inset(insets)
        }
    }
}
