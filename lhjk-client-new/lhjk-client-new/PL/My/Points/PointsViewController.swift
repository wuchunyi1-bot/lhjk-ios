import UIKit
import SnapKit

/// 积分明细页 — UITableView
/// tableHeaderView: Hero · Section 0: 勋章 · Section 1: 进行中 · Section 2: 最近明细
final class PointsViewController: BaseViewController {

    private let earnedBadges: [PtsBadge] = [
        PtsBadge(id: "b1", name: "连续打卡14天", icon: "calendar.badge.checkmark", color: UIColor(hexString: "#1F9A6B"), status: "done", earnedAt: "2026-05-13", progress: nil, target: nil),
        PtsBadge(id: "b2", name: "控糖标兵", icon: "drop", color: UIColor(hexString: "#7B5E9F"), status: "done", earnedAt: "2026-05-18", progress: nil, target: nil),
        PtsBadge(id: "b3", name: "健康评分80+", icon: "heart", color: .fdPrimary, status: "done", earnedAt: "2026-05-20", progress: nil, target: nil),
    ]

    private let progressBadges: [PtsBadge] = [
        PtsBadge(id: "b4", name: "连续打卡30天", icon: "trophy", color: UIColor(hexString: "#B47300"), status: "progress", earnedAt: nil, progress: 14, target: 30),
        PtsBadge(id: "b5", name: "血压连续达标4周", icon: "heart.slash", color: UIColor(hexString: "#FF4D4F"), status: "progress", earnedAt: nil, progress: 2, target: 4),
    ]

    private let records: [PtsRecord] = [
        PtsRecord(title: "完成健康档案补充", date: "2026-05-25 09:20", points: "+20", isAdd: true),
        PtsRecord(title: "上传体检报告单", date: "2026-05-23 15:42", points: "+30", isAdd: true),
        PtsRecord(title: "兑换血压仪优惠券", date: "2026-05-18 10:06", points: "-100", isAdd: false),
        PtsRecord(title: "完成睡眠质量评估", date: "2026-05-16 20:12", points: "+15", isAdd: true),
    ]

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.backgroundColor = .fdBg; tv.separatorStyle = .none; tv.showsVerticalScrollIndicator = false
        tv.dataSource = self; tv.delegate = self
        tv.register(BadgeGridCell.self, forCellReuseIdentifier: BadgeGridCell.reuseID)
        tv.register(ProgressBadgeCell.self, forCellReuseIdentifier: ProgressBadgeCell.reuseID)
        tv.register(PointRecordCell.self, forCellReuseIdentifier: PointRecordCell.reuseID)
        if #available(iOS 15.0, *) { tv.sectionHeaderTopPadding = 0 }
        return tv
    }()

    override func viewDidLoad() { super.viewDidLoad(); title = "积分明细" }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if tableView.tableHeaderView == nil {
            tableView.tableHeaderView = buildHero().sizedForTableHeader(in: view)
        }
    }

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
        g.frame = CGRect(x: 0, y: 0, width: w - 32, height: 120)
        card.layer.insertSublayer(g, at: 0)

        let label = UILabel(); label.text = "当前健康积分"; label.font = .fdCaption; label.textColor = UIColor.white.withAlphaComponent(0.85)
        let value = UILabel(); value.text = "892"; value.font = .fdMonoFont(ofSize: 42, weight: .heavy); value.textColor = .white
        let desc = UILabel(); desc.text = "可用于兑换服务券、设备优惠和健康礼品"; desc.font = .fdCaption; desc.textColor = UIColor.white.withAlphaComponent(0.9)
        [label, value, desc].forEach(card.addSubview)
        label.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(20) }
        value.snp.makeConstraints { $0.top.equalTo(label.snp.bottom).offset(6); $0.leading.equalToSuperview().inset(20) }
        desc.snp.makeConstraints { $0.top.equalTo(value.snp.bottom).offset(10); $0.leading.trailing.equalToSuperview().inset(20); $0.bottom.equalToSuperview().offset(-20) }

        container.addSubview(card)
        card.snp.makeConstraints { $0.top.equalToSuperview().offset(16); $0.leading.trailing.equalToSuperview().inset(16); $0.bottom.equalToSuperview().offset(-8) }
        let size = container.systemLayoutSizeFitting(CGSize(width: w, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        container.frame.size = CGSize(width: w, height: size.height)
        return container
    }
}

extension PointsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 3 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section { case 0: return 1; case 1: return progressBadges.count; default: return records.count }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: BadgeGridCell.reuseID, for: indexPath) as! BadgeGridCell
            cell.configure(earnedBadges); return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: ProgressBadgeCell.reuseID, for: indexPath) as! ProgressBadgeCell
            cell.configure(progressBadges[indexPath.row], isLast: indexPath.row == progressBadges.count - 1); return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: PointRecordCell.reuseID, for: indexPath) as! PointRecordCell
            cell.configure(records[indexPath.row]); return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let titles = ["我的勋章", "进行中", "最近明细"]
        let mores = ["\(earnedBadges.count) 枚已获得", nil, nil]
        let h = SectionTitleView(title: titles[section], more: mores[section])
        let c = UIView(); c.addSubview(h); h.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }; return c
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 44 }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 8 }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }
}
