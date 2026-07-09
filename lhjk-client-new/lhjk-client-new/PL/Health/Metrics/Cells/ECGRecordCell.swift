import UIKit
import SnapKit

final class ECGRecordCell: UITableViewCell {

    static let reuseID = "record"

    private let cardBg = UIView()
    private let headerBar = UIView(), headerLbl = UILabel()
    private let timeLbl = UILabel(), valueLbl = UILabel(), srcTag = UILabel(), divider = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear; contentView.backgroundColor = .clear

        cardBg.backgroundColor = .fdSurface; cardBg.layer.cornerRadius = 18
        contentView.addSubview(cardBg)
        cardBg.snp.makeConstraints { $0.left.right.equalToSuperview().inset(16); $0.top.bottom.equalToSuperview() }

        headerBar.backgroundColor = UIColor(hexString: "#2E86C1"); headerBar.layer.cornerRadius = 2
        headerLbl.text = "心电记录"; headerLbl.font = .fdBodySemibold; headerLbl.textColor = .fdSubtext

        timeLbl.font = .fdCaption; timeLbl.textColor = .fdText
        valueLbl.font = .fdBodySemibold; valueLbl.textColor = .fdText
        srcTag.font = .fdMicro; srcTag.textAlignment = .center; srcTag.layer.cornerRadius = 999; srcTag.clipsToBounds = true
        divider.backgroundColor = .fdBorder

        [headerBar, headerLbl, timeLbl, valueLbl, srcTag, divider].forEach { cardBg.addSubview($0) }
        headerBar.snp.makeConstraints { $0.left.equalToSuperview().offset(16); $0.width.equalTo(3); $0.height.equalTo(16) }
        headerLbl.snp.makeConstraints { $0.left.equalTo(headerBar.snp.right).offset(8); $0.centerY.equalTo(headerBar) }
        timeLbl.snp.makeConstraints { $0.left.equalToSuperview().offset(16) }
        valueLbl.snp.makeConstraints { $0.left.equalToSuperview().offset(16) }
        srcTag.snp.makeConstraints { $0.right.equalToSuperview().offset(-16); $0.width.equalTo(64); $0.height.equalTo(20) }
        divider.snp.makeConstraints { $0.left.equalToSuperview().offset(16); $0.right.equalToSuperview().offset(-16); $0.bottom.equalToSuperview(); $0.height.equalTo(1) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(time: String, value: String, source: String, position: EcgCardPosition) {
        let isFirst = (position == .first || position == .single)
        headerBar.isHidden = !isFirst; headerLbl.isHidden = !isFirst

        timeLbl.text = time; valueLbl.text = value
        if source == "bluetooth" {
            srcTag.text = "蓝牙记录"; srcTag.backgroundColor = UIColor(hexString: "#E8F4FD"); srcTag.textColor = UIColor(hexString: "#3D6FB8")
        } else {
            srcTag.text = "手动记录"; srcTag.backgroundColor = UIColor(hexString: "#F5F5F5"); srcTag.textColor = UIColor(hexString: "#999999")
        }

        if isFirst {
            headerBar.snp.remakeConstraints { $0.top.equalToSuperview().offset(14); $0.left.equalToSuperview().offset(16); $0.width.equalTo(3); $0.height.equalTo(16) }
            headerLbl.snp.remakeConstraints { $0.left.equalTo(headerBar.snp.right).offset(8); $0.centerY.equalTo(headerBar) }
            timeLbl.snp.remakeConstraints { $0.top.equalTo(headerBar.snp.bottom).offset(8); $0.left.equalToSuperview().offset(16) }
        } else {
            timeLbl.snp.remakeConstraints { $0.top.equalToSuperview().offset(12); $0.left.equalToSuperview().offset(16) }
        }
        valueLbl.snp.remakeConstraints { $0.top.equalTo(timeLbl.snp.bottom).offset(2); $0.left.equalToSuperview().offset(16); $0.bottom.equalToSuperview().offset(-12) }
        srcTag.snp.remakeConstraints { $0.right.equalToSuperview().offset(-16); $0.centerY.equalToSuperview(); $0.width.equalTo(64); $0.height.equalTo(20) }

        switch position {
        case .first:  cardBg.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]; divider.isHidden = false
        case .middle: cardBg.layer.maskedCorners = []; divider.isHidden = false
        case .last:   cardBg.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]; divider.isHidden = true
        case .single: cardBg.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]; divider.isHidden = true
        }
    }
}
