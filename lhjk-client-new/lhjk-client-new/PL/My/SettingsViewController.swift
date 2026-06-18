import UIKit

/// 设置主列表页
/// 参考 funde-client: prototype/src/views/me/SettingsView.vue
///
/// 布局: UITableView 4 sections（grouped style）
///   Section 0: 通知与提醒 → 消息通知设置
///   Section 1: 显示与辅助 → 大字显示与简洁操作
///   Section 2: 隐私与安全 → 隐私设置 / 账号安全
///   Section 3: 其他 → 关于 / 退出登录
///
/// 使用 SectionTitleView 做 section header，MeFuncRowCell 做行组件
final class SettingsViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Data

    private struct Item {
        let label: String
        let route: String?
        let isDestructive: Bool
    }

    private let groups: [(title: String, items: [Item])] = [
        ("通知与提醒", [
            Item(label: "消息通知设置", route: "/me/settings/notifications", isDestructive: false),
        ]),
        ("显示与辅助", [
            Item(label: "大字显示与简洁操作", route: "/me/settings/accessibility", isDestructive: false),
        ]),
        ("隐私与安全", [
            Item(label: "隐私设置", route: "/me/settings/privacy", isDestructive: false),
            Item(label: "账号安全", route: "/me/settings/security", isDestructive: false),
        ]),
        ("其他", [
            Item(label: "关于", route: "/me/settings/about", isDestructive: false),
            Item(label: "退出登录", route: nil, isDestructive: true),
        ]),
    ]

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.dataSource = self
        tv.delegate = self
        tv.register(MeFuncRowCell.self, forCellReuseIdentifier: MeFuncRowCell.reuseIdentifier)
        if #available(iOS 15.0, *) { tv.sectionHeaderTopPadding = 0 }
        return tv
    }()

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Re-hide nav bar when going back to Me (which has hidden nav bar)
        if navigationController?.viewControllers.last is MyViewController {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }

    override func setupUI() {
        title = "设置"
        view.backgroundColor = .fdBg
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        groups.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groups[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: MeFuncRowCell.reuseIdentifier, for: indexPath
        ) as? MeFuncRowCell else { return UITableViewCell() }

        let item = groups[indexPath.section].items[indexPath.row]
        let isLast = indexPath.row == groups[indexPath.section].items.count - 1

        cell.configure(data: .settingsRow(title: item.label, showDivider: !isLast, destructive: item.isDestructive))

        cell.onTap = { [weak self] in
            self?.handleTap(item)
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        48
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let container = UIView()
        container.backgroundColor = .fdBg
        let titleView = SectionTitleView(title: groups[section].title)
        container.addSubview(titleView)
        titleView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-8)
        }
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        44
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0.01
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        handleTap(groups[indexPath.section].items[indexPath.row])
    }

    // MARK: - Actions

    private func handleTap(_ item: Item) {
        if item.isDestructive {
            let alert = UIAlertController(title: nil, message: "确定要退出登录吗？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "退出", style: .destructive) { _ in
                Router.shared.present("/login")
            })
            present(alert, animated: true)
            return
        }
        if let route = item.route {
            Router.shared.push(route)
        }
    }
}
