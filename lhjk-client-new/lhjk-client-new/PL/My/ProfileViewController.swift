import UIKit
import SnapKit

/// 个人信息页
/// 参考 funde-client: ProfileView.vue
final class ProfileViewController: BaseViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let items: [(label: String, value: String, isLink: Bool)] = [
        ("姓名", "李秀英", true),
        ("手机号", "188****6520", true),
        ("富德 ID", "8847291", false),
        ("会员等级", "健康大会员", false),
        ("健管师", "王顾问", false),
    ]

    override func setupUI() {
        title = "个人信息"
        view.backgroundColor = .fdBg

        // Avatar header
        let headerView = UIView()
        let avatarView: UIView = {
            let v = UIView()
            v.backgroundColor = .fdPrimary
            v.layer.cornerRadius = 24
            let label = UILabel()
            label.text = "秀"
            label.font = .fdFont(ofSize: 34, weight: .bold)
            label.textColor = .white
            v.addSubview(label)
            label.snp.makeConstraints { $0.center.equalToSuperview() }
            return v
        }()
        let hint = UILabel()
        hint.text = "点击更换头像"
        hint.font = .fdCaption
        hint.textColor = .fdSubtext
        hint.textAlignment = .center

        headerView.addSubview(avatarView)
        headerView.addSubview(hint)
        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
            make.size.equalTo(80)
        }
        hint.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
        }
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 156)

        tableView.tableHeaderView = headerView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = items[indexPath.row]
        cell.textLabel?.text = item.label
        cell.textLabel?.textColor = .fdText
        cell.detailTextLabel?.text = item.value
        cell.accessoryType = item.isLink ? .disclosureIndicator : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
