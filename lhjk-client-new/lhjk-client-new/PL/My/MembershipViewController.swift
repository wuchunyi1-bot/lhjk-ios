import UIKit
import SnapKit

// MARK: - Data Models (fileprivate)

fileprivate struct MbrBenefit {
    let icon: String; let color: UIColor; let title: String; let desc: String; let active: Bool
}

fileprivate struct MbrPlan {
    let name: String; let tag: String; let price: String; let unit: String; let accent: UIColor; let highlight: Bool
}

// MARK: - Cells

/// 权益清单 Cell — 内嵌 6 行 benefit row
fileprivate final class BenefitListCell: UITableViewCell {
    static let reuseID = "BenefitListCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none; backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ benefits: [MbrBenefit]) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor; card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6; card.layer.shadowOpacity = 0.03
        contentView.addSubview(card); card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let stack = UIStackView(); stack.axis = .vertical
        card.addSubview(stack); stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)) }
        for (i, b) in benefits.enumerated() {
            stack.addArrangedSubview(buildRow(b))
            if i < benefits.count - 1 {
                let div = UIView(); div.backgroundColor = .fdBorder; stack.addArrangedSubview(div); div.snp.makeConstraints { $0.height.equalTo(1) }
            }
        }
    }

    private func buildRow(_ b: MbrBenefit) -> UIView {
        let row = UIStackView(); row.spacing = 12; row.alignment = .center
        row.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0); row.isLayoutMarginsRelativeArrangement = true
        let iconBg = UIView(); iconBg.layer.cornerRadius = 11
        iconBg.backgroundColor = b.active ? b.color.withAlphaComponent(0.1) : UIColor(hexString: "#F5F5F5")
        let icon = UIImageView(image: UIImage(systemName: b.icon)); icon.contentMode = .scaleAspectFit
        icon.tintColor = b.active ? b.color : UIColor(hexString: "#BBBBBB")
        iconBg.addSubview(icon); icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(20) }
        iconBg.snp.makeConstraints { $0.size.equalTo(40) }; row.addArrangedSubview(iconBg)

        let info = UIStackView(); info.axis = .vertical; info.spacing = 2
        info.addArrangedSubview(lbl(b.title, size: 14, weight: .semibold, color: b.active ? .fdText : UIColor(hexString: "#BBBBBB")))
        info.addArrangedSubview(lbl(b.desc, size: 12, color: .fdSubtext))
        row.addArrangedSubview(info)

        let tag = UIView(); tag.layer.cornerRadius = 999
        tag.backgroundColor = b.active ? UIColor(hexString: "#F0FAF4") : UIColor(hexString: "#F5F5F5")
        let tl = lbl(b.active ? "已激活" : "未开通", size: 11, weight: .semibold, color: b.active ? UIColor(hexString: "#52B96A") : UIColor(hexString: "#BBBBBB"))
        tag.addSubview(tl); tl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        row.addArrangedSubview(tag); return row
    }

    private func lbl(_ t: String, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor) -> UILabel {
        let l = UILabel(); l.text = t; l.font = .systemFont(ofSize: size, weight: weight); l.textColor = color; return l
    }
}

/// 升级套餐 Cell
fileprivate final class UpgradePlanCell: UITableViewCell {
    static let reuseID = "UpgradePlanCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none; backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ p: MbrPlan) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let card = UIView(); card.backgroundColor = p.highlight ? UIColor(hexString: "#FFF7F1") : .fdSurface
        card.layer.cornerRadius = 18; card.layer.borderWidth = 1.5
        card.layer.borderColor = p.highlight ? UIColor.fdPrimary.withAlphaComponent(0.3).cgColor : p.accent.withAlphaComponent(0.25).cgColor
        card.layer.shadowColor = UIColor.black.cgColor; card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6; card.layer.shadowOpacity = 0.03
        contentView.addSubview(card); card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16); $0.height.equalTo(72) }

        let name = lbl(p.name, size: 16, weight: .bold, color: p.accent)
        let tag = UIView(); tag.backgroundColor = p.accent.withAlphaComponent(0.1); tag.layer.cornerRadius = 999
        let tl = lbl(p.tag, size: 11, weight: .semibold, color: p.accent)
        tag.addSubview(tl); tl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        let info = UIStackView(arrangedSubviews: [name, tag]); info.axis = .vertical; info.spacing = 6
        card.addSubview(info); info.snp.makeConstraints { $0.leading.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }

        let btn = UIButton(type: .system); btn.setTitle("了解", for: .normal); btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        btn.setTitleColor(.white, for: .normal); btn.backgroundColor = p.accent; btn.layer.cornerRadius = 999
        btn.snp.makeConstraints { $0.width.equalTo(52); $0.height.equalTo(28) }
        let priceRow = UIStackView(arrangedSubviews: [lbl(p.price, size: 18, weight: .bold, color: .fdPrimary, mono: true), lbl(p.unit, size: 12, color: .fdSubtext), btn])
        priceRow.spacing = 4; priceRow.alignment = .center
        card.addSubview(priceRow); priceRow.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview() }
    }

    private func lbl(_ t: String, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor, mono: Bool = false) -> UILabel {
        let l = UILabel(); l.text = t; l.textColor = color; l.font = mono ? .monospacedSystemFont(ofSize: size, weight: weight) : .systemFont(ofSize: size, weight: weight); return l
    }
}

// MARK: - ViewController

/// 会员权益页 — UITableView
/// tableHeaderView: Hero · Section 0: 权益清单 · Section 1: 升级套餐
final class MembershipViewController: BaseViewController {

    private let benefits: [MbrBenefit] = [
        MbrBenefit(icon: "heart.text.square", color: .fdPrimary, title: "专属健康管家", desc: "1对1健康管理师，7×12小时在线响应", active: true),
        MbrBenefit(icon: "stethoscope", color: UIColor(hexString: "#6B9FE4"), title: "年度健康体检", desc: "含血常规、生化全套、心电图等30+项", active: true),
        MbrBenefit(icon: "chart.line.uptrend.xyaxis", color: UIColor(hexString: "#52B96A"), title: "健康数据监测", desc: "血压/血糖/心率实时上报与趋势分析", active: true),
        MbrBenefit(icon: "heart.hand.clipboard", color: UIColor(hexString: "#9B7DEA"), title: "慢病专项干预", desc: "高血压/糖尿病专属管理方案（需升级）", active: false),
        MbrBenefit(icon: "building.columns", color: UIColor(hexString: "#F5A623"), title: "就医协助绿通", desc: "三甲医院挂号协助、陪诊服务（需升级）", active: false),
        MbrBenefit(icon: "figure.2.and.child.holdinghands", color: UIColor(hexString: "#E45454"), title: "家庭成员健康档案", desc: "最多可添加 5 位家庭成员档案", active: true),
    ]

    private let plans: [MbrPlan] = [
        MbrPlan(name: "德康套餐", tag: "慢病管理", price: "¥3,980", unit: "/年", accent: .fdPrimary, highlight: true),
        MbrPlan(name: "德元套餐", tag: "肿瘤防治", price: "¥12,800", unit: "/年", accent: UIColor(hexString: "#9B7DEA"), highlight: false),
    ]

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.backgroundColor = .fdBg; tv.separatorStyle = .none; tv.showsVerticalScrollIndicator = false
        tv.dataSource = self; tv.delegate = self
        tv.register(BenefitListCell.self, forCellReuseIdentifier: BenefitListCell.reuseID)
        tv.register(UpgradePlanCell.self, forCellReuseIdentifier: UpgradePlanCell.reuseID)
        tv.tableHeaderView = buildHero()
        if #available(iOS 15.0, *) { tv.sectionHeaderTopPadding = 0 }
        return tv
    }()

    override func viewDidLoad() { super.viewDidLoad(); title = "会员权益" }

    override func setupUI() {
        view.backgroundColor = .fdBg
        view.addSubview(tableView); tableView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
    }

    private func buildHero() -> UIView {
        let w = view.bounds.width
        let container = UIView()
        let card = UIView(); card.layer.cornerRadius = 24; card.clipsToBounds = true
        let g = CAGradientLayer(); g.colors = [UIColor.fdPrimary.cgColor, UIColor(hexString: "#FFAA80").cgColor]
        g.startPoint = CGPoint(x: 0, y: 0); g.endPoint = CGPoint(x: 1, y: 1)
        g.frame = CGRect(x: 0, y: 0, width: w - 32, height: 160)
        card.layer.insertSublayer(g, at: 0)
        let blob = UIView(); blob.backgroundColor = UIColor.white.withAlphaComponent(0.12); blob.layer.cornerRadius = 60
        card.addSubview(blob); blob.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(-30); $0.size.equalTo(120) }

        func hlbl(_ t: String, s: CGFloat, w: UIFont.Weight = .regular, c: UIColor = .white) -> UILabel {
            let l = UILabel(); l.text = t; l.font = .systemFont(ofSize: s, weight: w); l.textColor = c; return l
        }
        let label = hlbl("当前等级", s: 12, c: UIColor.white.withAlphaComponent(0.85))
        let level = hlbl("健康大会员", s: 26, w: .bold)
        let desc = hlbl("感谢您选择德系健康管理服务", s: 13, c: UIColor.white.withAlphaComponent(0.85))
        let expiry = hlbl("有效期至 2027-01-15", s: 12, c: UIColor.white.withAlphaComponent(0.7))
        let tagRow = UIStackView(); tagRow.spacing = 8
        for t in ["在线激活", "自动续期"] {
            let tag = UIView(); tag.backgroundColor = UIColor.white.withAlphaComponent(0.25); tag.layer.cornerRadius = 999
            let tl = hlbl(t, s: 10, w: .semibold); tag.addSubview(tl)
            tl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
            tagRow.addArrangedSubview(tag)
        }
        [label, level, desc, expiry, tagRow].forEach(card.addSubview)
        label.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(20) }
        level.snp.makeConstraints { $0.top.equalTo(label.snp.bottom).offset(4); $0.leading.equalToSuperview().inset(20) }
        desc.snp.makeConstraints { $0.top.equalTo(level.snp.bottom).offset(6); $0.leading.equalToSuperview().inset(20) }
        expiry.snp.makeConstraints { $0.top.equalTo(desc.snp.bottom).offset(8); $0.leading.equalToSuperview().inset(20) }
        tagRow.snp.makeConstraints { $0.top.equalTo(expiry.snp.bottom).offset(12); $0.leading.equalToSuperview().inset(20); $0.bottom.equalToSuperview().offset(-20) }

        container.addSubview(card)
        card.snp.makeConstraints { $0.top.equalToSuperview().offset(16); $0.leading.trailing.equalToSuperview().inset(16); $0.bottom.equalToSuperview().offset(-8) }
        let size = container.systemLayoutSizeFitting(CGSize(width: w, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        container.frame.size = CGSize(width: w, height: size.height)
        return container
    }
}

extension MembershipViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 2 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { section == 0 ? 1 : plans.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: BenefitListCell.reuseID, for: indexPath) as! BenefitListCell
            cell.configure(benefits); return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: UpgradePlanCell.reuseID, for: indexPath) as! UpgradePlanCell
        cell.configure(plans[indexPath.row]); return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title = section == 0 ? "权益清单" : "升级解锁更多权益"
        let more = section == 0 ? "共 \(benefits.count) 项" : nil
        let h = SectionTitleView(title: title, more: more)
        let c = UIView(); c.addSubview(h); h.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }; return c
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 44 }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 8 }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }
}
