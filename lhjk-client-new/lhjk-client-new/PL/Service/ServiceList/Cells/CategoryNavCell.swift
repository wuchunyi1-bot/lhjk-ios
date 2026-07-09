import UIKit
import SnapKit

final class CategoryNavCell: UITableViewCell {
    static let reuseID = "CategoryNavCell"

    private let dot = UIView()
    private let codeLbl = UILabel()
    private let nameLbl = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        dot.layer.cornerRadius = 1.5
        dot.isHidden = true
        codeLbl.font = .fdCaptionSemibold
        codeLbl.textAlignment = .center
        nameLbl.font = .fdMicro
        nameLbl.textColor = .fdSubtext
        nameLbl.textAlignment = .center
        [dot, codeLbl, nameLbl].forEach(contentView.addSubview)
        dot.snp.makeConstraints { $0.leading.equalToSuperview(); $0.centerY.equalToSuperview(); $0.size.equalTo(CGSize(width: 3, height: 24)) }
        codeLbl.snp.makeConstraints { $0.top.equalToSuperview().offset(14); $0.centerX.equalToSuperview() }
        nameLbl.snp.makeConstraints { $0.top.equalTo(codeLbl.snp.bottom).offset(3); $0.centerX.equalToSuperview(); $0.bottom.equalToSuperview().offset(-10) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ m: SvcMatrix, active: Bool) {
        codeLbl.text = m.code
        nameLbl.text = m.name
        dot.isHidden = !active
        dot.backgroundColor = m.accent
        contentView.backgroundColor = active ? .fdSurface : .fdBg2
    }
}
