import UIKit
import SnapKit

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
