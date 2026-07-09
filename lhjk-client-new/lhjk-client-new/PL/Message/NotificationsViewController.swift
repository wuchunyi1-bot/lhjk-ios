import UIKit
import SnapKit

/// 通知中心独立页 — 参考 funde-client NotificationsView.vue
final class NotificationsViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    private var notifications: [AppNotification] = []

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.dataSource = self
        tv.delegate = self
        tv.register(NotificationCardCell.self, forCellReuseIdentifier: NotificationCardCell.reuseID)
        return tv
    }()

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        loadData()
    }

    override func setupUI() {
        title = "通知中心"
        view.backgroundColor = .fdBg

        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func loadData() {
        notifications = IMService.shared.getNotifications()
        IMService.shared.markNotificationsRead()
        tableView.reloadData()
    }

    // MARK: - UITableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notifications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCardCell.reuseID, for: indexPath) as! NotificationCardCell
        cell.configure(notifications[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}
