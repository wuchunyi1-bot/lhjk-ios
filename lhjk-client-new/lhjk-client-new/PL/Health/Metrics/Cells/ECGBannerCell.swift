import UIKit
import SnapKit

final class ECGBannerCell: UITableViewCell {

    static let reuseID = "banner"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear; contentView.backgroundColor = .clear

        let wrap = UIView()
        wrap.backgroundColor = UIColor(hexString: "#EBF5FB")
        wrap.layer.cornerRadius = 10
        contentView.addSubview(wrap)
        wrap.snp.makeConstraints { $0.left.right.equalToSuperview().inset(16); $0.top.bottom.equalToSuperview() }

        let icon = UIImageView(image: UIImage(systemName: "bluetooth"))
        icon.tintColor = UIColor(hexString: "#3d6fb8")
        wrap.addSubview(icon)
        icon.snp.makeConstraints { $0.left.equalToSuperview().offset(12); $0.centerY.equalToSuperview(); $0.size.equalTo(18) }

        let lbl = UILabel(); lbl.text = "ECG 设备未连接"
        lbl.font = .fdCaption; lbl.textColor = UIColor(hexString: "#3d6fb8")
        wrap.addSubview(lbl)
        lbl.snp.makeConstraints { $0.left.equalTo(icon.snp.right).offset(8); $0.centerY.equalToSuperview() }

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = UIColor(hexString: "#3d6fb8").withAlphaComponent(0.5)
        wrap.addSubview(arrow)
        arrow.snp.makeConstraints { $0.right.equalToSuperview().offset(-12); $0.centerY.equalToSuperview(); $0.size.equalTo(14) }
    }

    required init?(coder: NSCoder) { fatalError() }
}
