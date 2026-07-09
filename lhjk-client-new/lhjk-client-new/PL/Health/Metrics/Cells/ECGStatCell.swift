import UIKit
import SnapKit

final class ECGStatCell: UITableViewCell {

    static let reuseID = "stat"

    private let cardBg = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear; contentView.backgroundColor = .clear

        cardBg.backgroundColor = .fdSurface; cardBg.layer.cornerRadius = 18
        contentView.addSubview(cardBg)
        cardBg.snp.makeConstraints { $0.left.right.equalToSuperview().inset(16); $0.top.bottom.equalToSuperview() }

        let stack = UIStackView(); stack.axis = .horizontal; stack.alignment = .center; stack.distribution = .fillEqually
        cardBg.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        func item(_ val: String, _ lbl: String, _ c: UIColor = .fdText) -> UIView {
            let v = UIView()
            let vl = UILabel(); vl.text = val; vl.font = UIFont.fdFont(ofSize: 28, weight: .bold); vl.textColor = c; vl.textAlignment = .center
            let ll = UILabel(); ll.text = lbl; ll.font = .fdMicro; ll.textColor = .fdSubtext; ll.textAlignment = .center; ll.numberOfLines = 2
            v.addSubview(vl); v.addSubview(ll)
            vl.snp.makeConstraints { $0.top.centerX.equalToSuperview(); $0.height.equalTo(34) }
            ll.snp.makeConstraints { $0.top.equalTo(vl.snp.bottom).offset(2); $0.centerX.bottom.equalToSuperview() }
            return v
        }
        func div() -> UIView { let d = UIView(); d.backgroundColor = .fdBorder; d.snp.makeConstraints { $0.width.equalTo(1); $0.height.equalTo(40) }; return d }

        stack.addArrangedSubview(item("76", "最近心率\n(bpm)"))
        stack.addArrangedSubview(div())
        stack.addArrangedSubview(item("5", "历史测量\n(次)"))
        stack.addArrangedSubview(div())
        stack.addArrangedSubview(item("正常", "心律状态", UIColor(hexString: "#52B96A")))
    }

    required init?(coder: NSCoder) { fatalError() }
}
