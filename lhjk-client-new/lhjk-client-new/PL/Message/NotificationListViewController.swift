import UIKit
import SnapKit
import Combine

/// 通知中心列表 — MessagesViewController 的子 VC
/// 数据源：单聊会话列表中最新一条会话的历史消息
/// 白卡容器与团队对话列表对齐 Figma 3042:740
final class NotificationListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var onDataChanged: (() -> Void)?
    private var notifications: [AppNotification] = []
    private var isLoading = false
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI

    private lazy var cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        return v
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdSurface
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.contentInsetAdjustmentBehavior = .never
        tv.dataSource = self
        tv.delegate = self
        tv.register(NotificationCell.self, forCellReuseIdentifier: NotificationCell.reuseIdentifier)
        tv.contentInset = .zero
        return tv
    }()

    private lazy var emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "暂无通知"
        l.font = .fdCaption
        l.textColor = .fdMuted
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .fdBg
        view.addSubview(cardView)
        cardView.addSubview(tableView)
        cardView.addSubview(emptyLabel)
        cardView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().offset(-25)
        }
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        IMService.shared.notificationsDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                self.notifications = IMService.shared.getNotifications()
                self.reloadUI()
            }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    // MARK: - Data

    func loadData() {
        let cached = IMService.shared.getNotifications()
        if !cached.isEmpty {
            notifications = cached
            reloadUI()
        }
        guard !isLoading else { return }
        isLoading = true
        Task {
            let list = await IMService.shared.loadNotifications()
            await MainActor.run {
                self.isLoading = false
                self.notifications = list
                self.reloadUI()
            }
        }
    }

    var unreadCount: Int {
        notifications.filter { $0.unread }.count
    }

    private func reloadUI() {
        emptyLabel.isHidden = !notifications.isEmpty
        tableView.reloadData()
        onDataChanged?()
    }

    // MARK: - UITableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notifications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCell.reuseIdentifier, for: indexPath) as! NotificationCell
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
        onDataChanged?()
        NotificationMessageMapper.openRoute(noti.route, from: self)
    }
}
