import UIKit
import SnapKit

/// 居中提示 Cell — 日期分隔 / 撤回通知
/// 外观：居中、背景 clear、字体同 metaLabel（fdFont 11, fdMuted）
final class CenteredTipCell: UITableViewCell {
    static let reuseID = "CenteredTipCell"

    private let tipLabel: UILabel = {
        let l = UILabel()
        l.font = .fdMicro
        l.textColor = .fdMuted
        l.textAlignment = .center
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-6)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(text: String) {
        tipLabel.font = .fdMicro
        tipLabel.text = text
    }
}
