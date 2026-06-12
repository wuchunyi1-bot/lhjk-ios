import UIKit

/// 设置页面
/// 参考 funde-client: SettingsView.vue
final class SettingsViewController: BaseViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let groups: [(title: String, items: [(label: String, route: String?)])] = [
        ("通知与提醒", [
            ("消息通知设置", "/me/settings/notifications"),
        ]),
        ("显示与辅助", [
            ("大字显示与简洁操作", "/me/settings/accessibility"),
        ]),
        ("隐私与安全", [
            ("隐私设置", "/me/settings/privacy"),
            ("账号安全", "/me/settings/security"),
        ]),
        ("其他", [
            ("关于", "/me/settings/about"),
            ("退出登录", nil),
        ]),
    ]

    override func setupUI() {
        title = "设置"
        view.backgroundColor = .fdBg

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

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        groups.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groups[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        groups[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = groups[indexPath.section].items[indexPath.row]
        cell.textLabel?.text = item.label

        if item.route == nil && item.label == "退出登录" {
            cell.textLabel?.textColor = .fdDanger
            cell.accessoryType = .none
        } else {
            cell.textLabel?.textColor = .fdText
            cell.accessoryType = .disclosureIndicator
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = groups[indexPath.section].items[indexPath.row]

        if item.label == "退出登录" {
            let alert = UIAlertController(title: nil, message: "确定要退出登录吗？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "退出", style: .destructive) { _ in
                Router.shared.present("/login")
            })
            present(alert, animated: true)
            return
        }

        // Route via Router
        if let route = item.route {
            Router.shared.push(route)
        }
    }
}
