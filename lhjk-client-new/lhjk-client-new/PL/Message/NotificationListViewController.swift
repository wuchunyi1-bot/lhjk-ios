import UIKit
import SnapKit
import Combine

/// 通知中心列表 — MessagesViewController 的子 VC
/// 数据源：单聊会话列表中最新一条会话的历史消息
/// 对齐 Figma 3444:5773：去除外层固定白卡，列表自然滚动，由 Cell 内部自适应首尾圆角白卡
final class NotificationListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var onDataChanged: (() -> Void)?
    private var notifications: [AppNotification] = []
    private var isLoading = false
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.contentInsetAdjustmentBehavior = .never
        tv.dataSource = self
        tv.delegate = self
        tv.register(NotificationCell.self, forCellReuseIdentifier: NotificationCell.reuseIdentifier)
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        tv.scrollIndicatorInsets = .zero
        return tv
    }()

    private lazy var emptyContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        v.isHidden = true

        let label = UILabel()
        label.text = "暂无通知"
        label.font = .fdCaption
        label.textColor = .fdMuted
        label.textAlignment = .center
        v.addSubview(label)
        label.snp.makeConstraints { $0.center.equalToSuperview() }
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        view.addSubview(tableView)
        view.addSubview(emptyContainer)

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        emptyContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(180)
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
        emptyContainer.isHidden = !notifications.isEmpty
        tableView.reloadData()
        onDataChanged?()
    }

    // MARK: - UITableView

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notifications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCell.reuseIdentifier, for: indexPath) as! NotificationCell
        let count = notifications.count
        let noti = notifications[indexPath.row]
        let isSingle = count == 1
        let isFirst = indexPath.row == 0
        let isLast = indexPath.row == count - 1
        cell.configure(noti, isFirst: isFirst, isLast: isLast, isSingle: isSingle)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        74
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
