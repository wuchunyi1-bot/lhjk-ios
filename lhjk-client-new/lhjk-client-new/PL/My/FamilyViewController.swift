import UIKit
import SnapKit

// MARK: - Data (fileprivate)

fileprivate struct FamMember {
    let id: String; let name: String; let relation: String; let avatar: String
    let plan: String; let planWeek: Int; let planTotal: Int; let phase: String
    let checkInDone: Int; let checkInTotal: Int; let alerts: [String]
    let keyMetrics: [(label: String, value: String, unit: String, status: String)]
}

fileprivate let famPhaseColors: [String: UIColor] = [
    "适应期": UIColor(hexString: "#8B8B8B"), "见效期": .fdPrimary,
    "巩固期": UIColor(hexString: "#1F9A6B"), "习惯养成": UIColor(hexString: "#7B5E9F"),
]

// MARK: - Cell

fileprivate final class FamilyMemberCell: UITableViewCell {
    static let reuseID = "FamilyMemberCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none; backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ m: FamMember) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor; card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6; card.layer.shadowOpacity = 0.03
        contentView.addSubview(card); card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        // Header
        let avatar = UIView(); avatar.layer.cornerRadius = 12; avatar.clipsToBounds = true
        let ag = CAGradientLayer(); ag.colors = [UIColor.fdPrimary.cgColor, UIColor(hexString: "#FFAA80").cgColor]
        ag.startPoint = CGPoint(x: 0, y: 0); ag.endPoint = CGPoint(x: 1, y: 1)
        ag.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        avatar.layer.insertSublayer(ag, at: 0)
        let al = UILabel(); al.text = m.avatar; al.font = .systemFont(ofSize: 17, weight: .bold); al.textColor = .white; al.textAlignment = .center
        avatar.addSubview(al); al.snp.makeConstraints { $0.center.equalToSuperview() }; avatar.snp.makeConstraints { $0.size.equalTo(44) }

        let name = flbl(m.name, s: 15, w: .semibold, c: .fdText)
        let relation = ftag(m.relation, bg: .fdBg, text: .fdSubtext)
        let phaseColor = famPhaseColors[m.phase] ?? UIColor(hexString: "#8B8B8B")
        let phase = ftag(m.phase, bg: phaseColor.withAlphaComponent(0.1), text: phaseColor)
        let arrow = UIImageView(image: UIImage(systemName: "chevron.right")); arrow.tintColor = .fdSubtext; arrow.contentMode = .scaleAspectFit

        let nameRow = UIStackView(arrangedSubviews: [name, relation, phase, UIView(), arrow]); nameRow.spacing = 6; nameRow.alignment = .center
        let planLabel = UILabel()
        let pt = NSMutableAttributedString(string: m.plan, attributes: [.font: UIFont.systemFont(ofSize: 13), .foregroundColor: UIColor.fdText])
        pt.append(NSAttributedString(string: "  第 \(m.planWeek) 周 / 共 \(m.planTotal) 周", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.fdSubtext]))
        planLabel.attributedText = pt
        let infoStack = UIStackView(arrangedSubviews: [nameRow, planLabel]); infoStack.axis = .vertical; infoStack.spacing = 4
        let headerRow = UIStackView(arrangedSubviews: [avatar, infoStack]); headerRow.spacing = 10; headerRow.alignment = .top

        card.addSubview(headerRow)
        headerRow.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(14) }
        var prev = headerRow.snp.bottom

        // Alert
        if let alert = m.alerts.first {
            let ab = UIView(); ab.backgroundColor = UIColor(hexString: "#FFFBEB"); ab.layer.cornerRadius = 8; ab.layer.borderWidth = 1; ab.layer.borderColor = UIColor(hexString: "#FDE68A").cgColor
            let wi = UIImageView(image: UIImage(systemName: "exclamationmark.triangle")); wi.tintColor = UIColor(hexString: "#B45309"); wi.contentMode = .scaleAspectFit
            let al = flbl(alert, s: 12, c: UIColor(hexString: "#92400E"))
            ab.addSubview(wi); ab.addSubview(al)
            wi.snp.makeConstraints { $0.leading.equalToSuperview().offset(10); $0.centerY.equalToSuperview(); $0.size.equalTo(14) }
            al.snp.makeConstraints { $0.leading.equalTo(wi.snp.trailing).offset(6); $0.trailing.equalToSuperview().offset(-10); $0.top.bottom.equalToSuperview().inset(8) }
            card.addSubview(ab)
            ab.snp.makeConstraints { $0.top.equalTo(prev).offset(10); $0.leading.trailing.equalToSuperview().inset(14) }
            prev = ab.snp.bottom
        }

        // Bottom grid
        let div = UIView(); div.backgroundColor = UIColor(hexString: "#F0F0F0")
        card.addSubview(div); div.snp.makeConstraints { $0.top.equalTo(prev).offset(12); $0.leading.trailing.equalToSuperview().inset(14); $0.height.equalTo(1) }

        let grid = UIStackView(); grid.distribution = .fillEqually
        card.addSubview(grid); grid.snp.makeConstraints { $0.top.equalTo(div.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(14); $0.bottom.equalToSuperview().offset(-14) }

        for metric in m.keyMetrics {
            let col = UIStackView(); col.axis = .vertical; col.alignment = .center; col.spacing = 2
            col.addArrangedSubview(flbl(metric.label, s: 11, c: .fdSubtext))
            col.addArrangedSubview(flbl(metric.value, s: 16, w: .bold, c: metric.status == "warning" ? .fdPrimary : .fdText))
            if !metric.unit.isEmpty { col.addArrangedSubview(flbl(metric.unit, s: 10, c: .fdSubtext)) }
            grid.addArrangedSubview(col)
        }
        // Checkin dots
        let cc = UIStackView(); cc.axis = .vertical; cc.alignment = .center; cc.spacing = 2
        cc.addArrangedSubview(flbl("本周打卡", s: 11, c: .fdSubtext))
        let dots = UIStackView(); dots.spacing = 3
        for i in 1...m.checkInTotal {
            let dot = UIView(); dot.layer.cornerRadius = 4; dot.backgroundColor = i <= m.checkInDone ? .fdPrimary : UIColor(hexString: "#E5E7EB")
            dots.addArrangedSubview(dot); dot.snp.makeConstraints { $0.size.equalTo(8) }
        }
        cc.addArrangedSubview(dots)
        cc.addArrangedSubview(flbl("\(m.checkInDone)/\(m.checkInTotal)", s: 10, c: .fdSubtext))
        grid.addArrangedSubview(cc)
    }

    private func flbl(_ t: String, s: CGFloat, w: UIFont.Weight = .regular, c: UIColor) -> UILabel {
        let l = UILabel(); l.text = t; l.font = .systemFont(ofSize: s, weight: w); l.textColor = c; return l
    }
    private func ftag(_ t: String, bg: UIColor, text: UIColor) -> UIView {
        let v = UIView(); v.backgroundColor = bg; v.layer.cornerRadius = 4
        let l = UILabel(); l.text = t; l.font = .systemFont(ofSize: 11, weight: .semibold); l.textColor = text
        v.addSubview(l); l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6)) }; return v
    }
}

// MARK: - ViewController

/// 家庭成员页 — UITableView
/// Section 0: FamilyMemberCell × N
final class FamilyViewController: BaseViewController {

    private let members: [FamMember] = [
        FamMember(id: "self", name: "李梅", relation: "本人", avatar: "李", plan: "慢病逆转 12 周", planWeek: 5, planTotal: 12, phase: "见效期", checkInDone: 5, checkInTotal: 7, alerts: [], keyMetrics: [("血压", "138/88", "mmHg", "warning"), ("血糖", "6.1", "mmol/L", "normal")]),
        FamMember(id: "father", name: "李大山", relation: "父亲", avatar: "父", plan: "糖尿病管理方案", planWeek: 8, planTotal: 12, phase: "巩固期", checkInDone: 6, checkInTotal: 7, alerts: [], keyMetrics: [("血糖", "6.8", "mmol/L", "normal"), ("体重", "71.2", "kg", "normal")]),
        FamMember(id: "mother", name: "王桂花", relation: "母亲", avatar: "母", plan: "高血压管理方案", planWeek: 3, planTotal: 12, phase: "见效期", checkInDone: 3, checkInTotal: 7, alerts: ["本周打卡未完成，请提醒"], keyMetrics: [("血压", "145/92", "mmHg", "warning"), ("用药", "按时", "", "normal")]),
        FamMember(id: "husband", name: "陈志远", relation: "丈夫", avatar: "夫", plan: "脂肪肝逆转计划", planWeek: 2, planTotal: 12, phase: "适应期", checkInDone: 4, checkInTotal: 7, alerts: [], keyMetrics: [("体重", "82.5", "kg", "warning"), ("运动", "3次", "/周", "normal")]),
    ]

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg; tv.separatorStyle = .none; tv.showsVerticalScrollIndicator = false
        tv.dataSource = self; tv.delegate = self
        tv.register(FamilyMemberCell.self, forCellReuseIdentifier: FamilyMemberCell.reuseID)
        tv.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "家族健康看板"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addMember))
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        view.addSubview(tableView); tableView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
    }

    @objc private func addMember() {
        let a = UIAlertController(title: nil, message: "添加家庭成员功能即将上线", preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "确定", style: .default)); present(a, animated: true)
    }
}

extension FamilyViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { members.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FamilyMemberCell.reuseID, for: indexPath) as! FamilyMemberCell
        cell.configure(members[indexPath.row]); return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }
}
