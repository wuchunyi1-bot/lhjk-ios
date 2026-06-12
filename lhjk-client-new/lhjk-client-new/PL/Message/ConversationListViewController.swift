import UIKit

/// 会话列表页面
final class ConversationListViewController: BaseViewController {

    // MARK: - UI Components

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "ConversationCell")
        tv.delegate = self
        tv.dataSource = self
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - Data

    private var conversations: [Conversation] = []

    // MARK: - Lifecycle

    override func setupUI() {
        title = "消息"
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadConversations()
    }

    // MARK: - Data Loading

    private func loadConversations() {
        conversations = IMService.shared.getConversations()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension ConversationListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCell", for: indexPath)
        let conversation = conversations[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = conversation.title ?? "会话 \(conversation.id)"
        config.secondaryText = conversation.lastMessage
        config.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator

        if conversation.unreadCount > 0 {
            let badge = UILabel()
            badge.text = "\(conversation.unreadCount)"
            badge.font = .systemFont(ofSize: 11, weight: .bold)
            badge.textColor = .white
            badge.backgroundColor = .systemRed
            badge.textAlignment = .center
            badge.layer.cornerRadius = 10
            badge.clipsToBounds = true
            badge.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            cell.accessoryView = badge
        } else {
            cell.accessoryView = nil
        }

        return cell
    }
}

// MARK: - UITableViewDelegate

extension ConversationListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conversation = conversations[indexPath.row]
        let chatVC = ChatViewController(conversationId: conversation.id)
        navigationController?.pushViewController(chatVC, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            guard let self = self else { return }
            let conversation = self.conversations[indexPath.row]
            IMService.shared.deleteConversation(conversation.id)
            self.conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }

        let pinAction = UIContextualAction(style: .normal, title: "置顶") { [weak self] _, _, completion in
            // TODO: 置顶逻辑
            completion(true)
        }
        pinAction.backgroundColor = .systemOrange

        return UISwipeActionsConfiguration(actions: [deleteAction, pinAction])
    }
}
