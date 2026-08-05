import UIKit
import SnapKit

/// 通知中心列表 — MessagesViewController 的子 VC
/// 白卡容器与团队对话列表对齐 Figma 3042:740
final class NotificationListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var onDataChanged: (() -> Void)?
    private var notifications: [AppNotification] = []

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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .fdBg
        view.addSubview(cardView)
        cardView.addSubview(tableView)
        cardView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().offset(-25)
        }
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    // MARK: - Data

    func loadData() {
        notifications = IMService.shared.getNotifications()
        tableView.reloadData()
        onDataChanged?()
    }

    var unreadCount: Int {
        notifications.filter { $0.unread }.count
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
}
