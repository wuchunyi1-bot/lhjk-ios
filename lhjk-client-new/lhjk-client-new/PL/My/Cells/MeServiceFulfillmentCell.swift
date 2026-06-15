import UIKit
import SnapKit

/// 服务履约区块 Cell
final class MeServiceFulfillmentCell: UITableViewCell {

    static let reuseIdentifier = "MeServiceFulfillmentCell"

    typealias StatItem = (value: String, label: String, accent: Bool)
    typealias ServiceItem = (icon: String, iconBg: String, iconColorHex: String, name: String, status: String, statusType: String, detail: String)

    private var stats: [StatItem] = []
    private var services: [ServiceItem] = []
    var onServiceTap: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(stats: [StatItem], services: [ServiceItem]) {
        self.stats = stats; self.services = services
        contentView.subviews.forEach { $0.removeFromSuperview() }
        setupUI()
    }

    private func setupUI() {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        // Stats row
        let statsStack = UIStackView(); statsStack.distribution = .fillEqually
        card.addSubview(statsStack)
        statsStack.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(14) }

        for (value, label, accent) in stats {
            let col = UIView()
            let valLbl = UILabel(); valLbl.text = value; valLbl.textColor = accent ? .fdPrimary : .fdText
            valLbl.font = .systemFont(ofSize: 22, weight: .bold); valLbl.textAlignment = .center
            let lblLbl = UILabel(); lblLbl.text = label; lblLbl.font = .systemFont(ofSize: 11); lblLbl.textColor = .fdSubtext; lblLbl.textAlignment = .center
            col.addSubview(valLbl); col.addSubview(lblLbl)
            valLbl.snp.makeConstraints { $0.top.centerX.equalToSuperview() }
            lblLbl.snp.makeConstraints { $0.top.equalTo(valLbl.snp.bottom).offset(2); $0.centerX.bottom.equalToSuperview() }
            statsStack.addArrangedSubview(col)
        }

        let divider = UIView(); divider.backgroundColor = .fdBorder
        card.addSubview(divider)
        divider.snp.makeConstraints { $0.top.equalTo(statsStack.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(14); $0.height.equalTo(1) }

        // Service rows
        var prevBottom = divider.snp.bottom
        for (i, svc) in services.enumerated() {
            let row = buildServiceRow(svc)
            card.addSubview(row)
            row.snp.makeConstraints { make in
                make.top.equalTo(prevBottom)
                make.leading.trailing.equalToSuperview().inset(14)
                if i == services.count - 1 { make.bottom.equalToSuperview() }
            }
            prevBottom = row.snp.bottom
        }
    }

    private func buildServiceRow(_ svc: ServiceItem) -> UIView {
        let row = UIView()
        row.isUserInteractionEnabled = true
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(serviceTapped)))

        let iconView = UIView()
        iconView.backgroundColor = UIColor(hexString: svc.iconBg)
        iconView.layer.cornerRadius = 11
        let iconLbl = UILabel()
        iconLbl.text = svc.icon; iconLbl.font = .systemFont(ofSize: 13, weight: .bold)
        iconLbl.textColor = UIColor(hexString: svc.iconColorHex)
        iconView.addSubview(iconLbl)
        iconLbl.snp.makeConstraints { $0.center.equalToSuperview() }

        let nameLbl = UILabel(); nameLbl.text = svc.name; nameLbl.font = .systemFont(ofSize: 13, weight: .semibold); nameLbl.textColor = .fdText
        let badge = buildBadge(svc.status, type: svc.statusType)
        let detailLbl = UILabel(); detailLbl.text = svc.detail; detailLbl.font = .systemFont(ofSize: 11); detailLbl.textColor = .fdSubtext
        let arrow = UIImageView(image: UIImage(systemName: "chevron.right")); arrow.tintColor = .fdMuted

        let topDiv = UIView(); topDiv.backgroundColor = .fdBorder

        [topDiv, iconView, nameLbl, badge, detailLbl, arrow].forEach(row.addSubview)
        topDiv.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.height.equalTo(1) }
        iconView.snp.makeConstraints { $0.top.equalTo(topDiv.snp.bottom).offset(10); $0.leading.equalToSuperview(); $0.size.equalTo(40); $0.bottom.equalToSuperview().offset(-10) }
        nameLbl.snp.makeConstraints { $0.top.equalTo(iconView); $0.leading.equalTo(iconView.snp.trailing).offset(10) }
        badge.snp.makeConstraints { $0.centerY.equalTo(nameLbl); $0.leading.equalTo(nameLbl.snp.trailing).offset(6) }
        detailLbl.snp.makeConstraints { $0.top.equalTo(nameLbl.snp.bottom).offset(2); $0.leading.equalTo(nameLbl) }
        arrow.snp.makeConstraints { $0.centerY.equalToSuperview(); $0.trailing.equalToSuperview(); $0.size.equalTo(16) }

        return row
    }

    private func buildBadge(_ text: String, type: String) -> UIView {
        let badge = UIView(); badge.layer.cornerRadius = 999
        let label = UILabel(); label.text = text; label.font = .systemFont(ofSize: 10, weight: .semibold)
        if type == "success" { badge.backgroundColor = .fdSuccessSoft; label.textColor = .fdSuccess }
        else { badge.backgroundColor = .fdWarningSoft; label.textColor = UIColor(hexString: "#B47300") }
        badge.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        return badge
    }

    @objc private func serviceTapped() { onServiceTap?() }
}
