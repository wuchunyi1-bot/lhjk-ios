import UIKit
import SnapKit

final class FamilyMemberCell: UITableViewCell {

    static let reuseID = "FamilyMemberCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ m: FamMember) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        // Header
        let avatar = UIView()
        avatar.layer.cornerRadius = 12
        avatar.clipsToBounds = true
        let ag = CAGradientLayer()
        ag.colors = [UIColor.fdPrimary.cgColor, UIColor(hexString: "#FFAA80").cgColor]
        ag.startPoint = CGPoint(x: 0, y: 0)
        ag.endPoint = CGPoint(x: 1, y: 1)
        ag.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        avatar.layer.insertSublayer(ag, at: 0)
        let al = UILabel()
        al.text = m.avatar
        al.font = .fdH2
        al.textColor = .white
        al.textAlignment = .center
        avatar.addSubview(al)
        al.snp.makeConstraints { $0.center.equalToSuperview() }
        avatar.snp.makeConstraints { $0.size.equalTo(44) }

        let name = flbl(m.name, s: 15, w: .semibold, c: .fdText)
        let relation = ftag(m.relation, bg: .fdBg, text: .fdSubtext)
        let phaseColor = famPhaseColors[m.phase] ?? UIColor(hexString: "#8B8B8B")
        let phase = ftag(m.phase, bg: phaseColor.withAlphaComponent(0.1), text: phaseColor)
        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .fdSubtext
        arrow.contentMode = .scaleAspectFit

        let nameRow = UIStackView(arrangedSubviews: [name, relation, phase, UIView(), arrow])
        nameRow.spacing = 6
        nameRow.alignment = .center
        let planLabel = UILabel()
        let pt = NSMutableAttributedString(string: m.plan, attributes: [.font: UIFont.fdCaption, .foregroundColor: UIColor.fdText])
        pt.append(NSAttributedString(string: "  第 \(m.planWeek) 周 / 共 \(m.planTotal) 周", attributes: [.font: UIFont.fdCaption, .foregroundColor: UIColor.fdSubtext]))
        planLabel.attributedText = pt
        let infoStack = UIStackView(arrangedSubviews: [nameRow, planLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 4
        let headerRow = UIStackView(arrangedSubviews: [avatar, infoStack])
        headerRow.spacing = 10
        headerRow.alignment = .top

        card.addSubview(headerRow)
        headerRow.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(14) }
        var prev = headerRow.snp.bottom

        // Alert
        if let alert = m.alerts.first {
            let ab = UIView()
            ab.backgroundColor = UIColor(hexString: "#FFFBEB")
            ab.layer.cornerRadius = 8
            ab.layer.borderWidth = 1
            ab.layer.borderColor = UIColor(hexString: "#FDE68A").cgColor
            let wi = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))
            wi.tintColor = UIColor(hexString: "#B45309")
            wi.contentMode = .scaleAspectFit
            let alertLabel = flbl(alert, s: 12, c: UIColor(hexString: "#92400E"))
            ab.addSubview(wi)
            ab.addSubview(alertLabel)
            wi.snp.makeConstraints { $0.leading.equalToSuperview().offset(10); $0.centerY.equalToSuperview(); $0.size.equalTo(14) }
            alertLabel.snp.makeConstraints { $0.leading.equalTo(wi.snp.trailing).offset(6); $0.trailing.equalToSuperview().offset(-10); $0.top.bottom.equalToSuperview().inset(8) }
            card.addSubview(ab)
            ab.snp.makeConstraints { $0.top.equalTo(prev).offset(10); $0.leading.trailing.equalToSuperview().inset(14) }
            prev = ab.snp.bottom
        }

        // Bottom grid
        let div = UIView()
        div.backgroundColor = UIColor(hexString: "#F0F0F0")
        card.addSubview(div)
        div.snp.makeConstraints { $0.top.equalTo(prev).offset(12); $0.leading.trailing.equalToSuperview().inset(14); $0.height.equalTo(1) }

        let grid = UIStackView()
        grid.distribution = .fillEqually
        card.addSubview(grid)
        grid.snp.makeConstraints { $0.top.equalTo(div.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(14); $0.bottom.equalToSuperview().offset(-14) }

        for metric in m.keyMetrics {
            let col = UIStackView()
            col.axis = .vertical
            col.alignment = .center
            col.spacing = 2
            col.addArrangedSubview(flbl(metric.label, s: 11, c: .fdSubtext))
            col.addArrangedSubview(flbl(metric.value, s: 16, w: .bold, c: metric.status == "warning" ? .fdPrimary : .fdText))
            if !metric.unit.isEmpty { col.addArrangedSubview(flbl(metric.unit, s: 10, c: .fdSubtext)) }
            grid.addArrangedSubview(col)
        }
        // Checkin dots
        let cc = UIStackView()
        cc.axis = .vertical
        cc.alignment = .center
        cc.spacing = 2
        cc.addArrangedSubview(flbl("本周打卡", s: 11, c: .fdSubtext))
        let dots = UIStackView()
        dots.spacing = 3
        for i in 1...m.checkInTotal {
            let dot = UIView()
            dot.layer.cornerRadius = 4
            dot.backgroundColor = i <= m.checkInDone ? .fdPrimary : UIColor(hexString: "#E5E7EB")
            dots.addArrangedSubview(dot)
            dot.snp.makeConstraints { $0.size.equalTo(8) }
        }
        cc.addArrangedSubview(dots)
        cc.addArrangedSubview(flbl("\(m.checkInDone)/\(m.checkInTotal)", s: 10, c: .fdSubtext))
        grid.addArrangedSubview(cc)
    }

    private func flbl(_ t: String, s: CGFloat, w: UIFont.Weight = .regular, c: UIColor) -> UILabel {
        let l = UILabel()
        l.text = t
        l.font = .fdFont(ofSize: s, weight: w)
        l.textColor = c
        return l
    }

    private func ftag(_ t: String, bg: UIColor, text: UIColor) -> UIView {
        let v = UIView()
        v.backgroundColor = bg
        v.layer.cornerRadius = 4
        let l = UILabel()
        l.text = t
        l.font = .fdMicroSemibold
        l.textColor = text
        v.addSubview(l)
        l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6)) }
        return v
    }
}
