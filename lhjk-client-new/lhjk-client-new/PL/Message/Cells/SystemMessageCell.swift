import UIKit
import SnapKit

/// 系统消息 Cell — 居中灰色胶囊
final class SystemMessageCell: UITableViewCell {
    static let reuseID = "SystemMessageCell"

    private let pillLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 12)
        l.textColor = .fdMuted
        l.textAlignment = .center
        l.backgroundColor = UIColor.black.withAlphaComponent(0.06)
        l.layer.cornerRadius = 12
        l.clipsToBounds = true
        l.numberOfLines = 0
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(pillLabel)
        pillLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.greaterThanOrEqualToSuperview().offset(40)
            make.trailing.lessThanOrEqualToSuperview().offset(-40)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(text: String) {
        pillLabel.text = "  \(text)  "
    }
}
