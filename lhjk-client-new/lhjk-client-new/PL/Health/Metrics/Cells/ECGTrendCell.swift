import UIKit
import SnapKit

final class ECGTrendCell: UITableViewCell {

    static let reuseID = "trend"

    private let cardBg = UIView()
    private let titleLbl = UILabel()
    private let dateLbl = UILabel(), barBg = UIView(), barFill = UIView(), valLbl = UILabel()
    private let tagWrap = UIView(), divider = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear; contentView.backgroundColor = .clear

        cardBg.backgroundColor = .fdSurface; cardBg.layer.cornerRadius = 18
        contentView.addSubview(cardBg)
        cardBg.snp.makeConstraints { $0.left.right.equalToSuperview().inset(16); $0.top.bottom.equalToSuperview() }

        titleLbl.font = .fdCaptionSemibold; titleLbl.textColor = .fdSubtext
        titleLbl.text = "历次测量心率趋势"

        dateLbl.font = .fdCaption; dateLbl.textColor = .fdSubtext; dateLbl.textAlignment = .right
        barBg.backgroundColor = .fdBg2; barBg.layer.cornerRadius = 4
        barFill.backgroundColor = UIColor(hexString: "#2E86C1"); barFill.layer.cornerRadius = 4
        valLbl.font = .fdCaptionSemibold; valLbl.textColor = .fdText
        divider.backgroundColor = .fdBorder

        barBg.addSubview(barFill)
        [titleLbl, dateLbl, barBg, valLbl, tagWrap, divider].forEach { cardBg.addSubview($0) }

        titleLbl.snp.makeConstraints { $0.top.equalToSuperview().offset(14); $0.left.equalToSuperview().offset(16) }
        dateLbl.snp.makeConstraints { $0.left.equalToSuperview().offset(16); $0.width.equalTo(44) }
        barBg.snp.makeConstraints { $0.left.equalTo(dateLbl.snp.right).offset(8); $0.height.equalTo(8) }
        barFill.snp.makeConstraints { $0.left.top.bottom.equalToSuperview() }
        valLbl.snp.makeConstraints { $0.left.equalTo(barBg.snp.right).offset(8); $0.width.equalTo(52) }
        tagWrap.snp.makeConstraints { $0.right.equalToSuperview().offset(-16) }
        divider.snp.makeConstraints { $0.left.equalToSuperview().offset(16); $0.right.equalToSuperview().offset(-16); $0.bottom.equalToSuperview(); $0.height.equalTo(1) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(date: String, hr: Int, conclusion: String, position: EcgCardPosition) {
        let isFirst = (position == .first || position == .single)
        titleLbl.isHidden = !isFirst

        dateLbl.text = date; valLbl.text = "\(hr) bpm"
        barFill.snp.remakeConstraints { $0.left.top.bottom.equalToSuperview(); $0.width.equalTo(barBg).multipliedBy(min(Double(hr) / 120.0, 1.0)) }

        tagWrap.subviews.forEach { $0.removeFromSuperview() }
        let t = _tag(conclusion, bg: UIColor(hexString: "#F0FAF4"), fg: UIColor(hexString: "#52B96A"))
        tagWrap.addSubview(t); t.snp.makeConstraints { $0.edges.equalToSuperview() }

        if isFirst {
            dateLbl.snp.remakeConstraints { $0.left.equalToSuperview().offset(16); $0.top.equalTo(titleLbl.snp.bottom).offset(10); $0.width.equalTo(44); $0.bottom.equalToSuperview().offset(-10) }
            barBg.snp.remakeConstraints { $0.left.equalTo(dateLbl.snp.right).offset(8); $0.centerY.equalTo(dateLbl); $0.height.equalTo(8) }
        } else {
            dateLbl.snp.remakeConstraints { $0.left.equalToSuperview().offset(16); $0.centerY.equalToSuperview(); $0.width.equalTo(44) }
            barBg.snp.remakeConstraints { $0.left.equalTo(dateLbl.snp.right).offset(8); $0.centerY.equalToSuperview(); $0.height.equalTo(8) }
        }
        valLbl.snp.remakeConstraints { $0.left.equalTo(barBg.snp.right).offset(8); $0.centerY.equalTo(dateLbl); $0.width.equalTo(52) }
        tagWrap.snp.remakeConstraints { $0.right.equalToSuperview().offset(-16); $0.centerY.equalTo(dateLbl) }

        switch position {
        case .first:  cardBg.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]; divider.isHidden = false
        case .middle: cardBg.layer.maskedCorners = []; divider.isHidden = false
        case .last:   cardBg.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]; divider.isHidden = true
        case .single: cardBg.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]; divider.isHidden = true
        }
    }

    private func _tag(_ t: String, bg: UIColor, fg: UIColor) -> UIView {
        let v = UIView(); v.backgroundColor = bg; v.layer.cornerRadius = 999
        let l = UILabel(); l.text = t; l.font = .fdMicro; l.textColor = fg
        v.addSubview(l); l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        return v
    }
}
