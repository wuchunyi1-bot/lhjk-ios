import UIKit
import SnapKit
import Combine

/// 通知中心独立页 — 参考 funde-client NotificationsView.vue
final class NotificationsViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    private var notifications: [AppNotification] = []
    private var cancellables = Set<AnyCancellable>()

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

    private lazy var emptyView: FDEmptyStateView = {
        let v = FDEmptyStateView(style: .page, message: "暂无通知，平台通知将在此处显示")
        v.isHidden = true
        return v
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
        view.addSubview(emptyView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }

        IMService.shared.notificationsDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                self.notifications = IMService.shared.getNotifications()
                self.emptyView.isHidden = !self.notifications.isEmpty
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    private func loadData() {
        Task {
            _ = await IMService.shared.loadNotifications()
            let list = IMService.shared.getNotifications()
            await MainActor.run {
                self.notifications = list
                self.emptyView.isHidden = !list.isEmpty
                self.tableView.reloadData()
            }
        }
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let noti = notifications[indexPath.row]
        IMService.shared.markNotificationRead(noti.id)
        notifications[indexPath.row].unread = false
        tableView.reloadRows(at: [indexPath], with: .none)
        NotificationMessageMapper.openRoute(noti.route, from: self)
    }
}
