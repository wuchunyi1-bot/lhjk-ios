import UIKit
import SnapKit
import Combine

/// 团队对话列表 — MessagesViewController 的子 VC
/// 展示三好共管置顶横幅 + 融云会话列表
final class ConversationListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var onDataChanged: (() -> Void)?
    private var conversations: [Conversation] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.dataSource = self
        tv.delegate = self
        tv.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.reuseIdentifier)
        return tv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .fdBg
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        setupSubscriptions()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Subscriptions

    private func setupSubscriptions() {
        // 收到新消息 → 局部更新（匹配不到则全量刷新）
        RongCloudManager.shared.messageReceivedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                print("[ConvList] messageReceived → convId=\(msg.conversationId ?? "nil")")
                self?.handleConversationUpdate(conversationId: msg.conversationId)
            }
            .store(in: &cancellables)

        // 远端会话同步完成 → 全量刷新（涉及新会话）
        RongCloudManager.shared.remoteConversationListDidSyncPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("[ConvList] remoteConversationListDidSync → full reload")
                self?.loadData()
            }
            .store(in: &cancellables)

        // 多端会话同步（已读/新消息等）→ 批量局部更新
        RongCloudManager.shared.conversationDidSyncPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("[ConvList] conversationDidSync → batch update, local count=\(self?.conversations.count ?? 0)")
                self?.handleBatchConversationUpdate()
            }
            .store(in: &cancellables)

        // 自己发送消息成功 → 局部更新（发消息不会触发 onReceived）
        RongCloudManager.shared.messageSentPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] convId in
                print("[ConvList] messageSent → convId=\(convId)")
                self?.handleConversationUpdate(conversationId: convId)
            }
            .store(in: &cancellables)
    }

    // MARK: - Data

    func loadData() {
        Task {
            conversations = await IMService.shared.loadConversations()
            await MainActor.run {
                tableView.reloadData()
                onDataChanged?()
            }
        }
    }

    /// 收到新消息 → B方案局部更新：查单条 RCConversation，匹配到则置顶
    private func handleConversationUpdate(conversationId: String?) {
        guard let convId = conversationId else {
            print("[ConvList] handleConversationUpdate ✗ convId is nil, skip")
            return
        }
        print("[ConvList] handleConversationUpdate → convId=\(convId), local conversations=\(conversations.map { $0.id })")
        Task {
            if let updated = await IMService.shared.updateConversation(id: convId) {
                await MainActor.run {
                    print("[ConvList] ✓ updated convId=\(convId) lastMsg=\(updated.lastMessage) unread=\(updated.unread), moving to top")
                    conversations.removeAll { $0.id == convId }
                    conversations.insert(updated, at: 0)
                    tableView.reloadData()
                    onDataChanged?()
                }
            } else {
                // 本地未匹配 → 全量刷新
                print("[ConvList] ✗ convId=\(convId) not found locally, fallback to full loadData()")
                await MainActor.run { loadData() }
            }
        }
    }

    /// 多端同步 → 批量局部更新 unread/lastMessage/lastTime
    private func handleBatchConversationUpdate() {
        Task {
            var anyChanged = false
            for conv in conversations {
                if let updated = await IMService.shared.updateConversation(id: conv.id) {
                    if let idx = conversations.firstIndex(where: { $0.id == conv.id }) {
                        let oldUnread = conversations[idx].unread
                        conversations[idx] = updated
                        anyChanged = true
                        print("[ConvList] batchUpdate convId=\(conv.id) unread \(oldUnread)→\(updated.unread) lastMsg=\(updated.lastMessage)")
                    }
                }
            }
            if anyChanged {
                print("[ConvList] batchUpdate ✓ \(conversations.filter { $0.unread > 0 }.count) unread conversations")
                await MainActor.run {
                    tableView.reloadData()
                    onDataChanged?()
                }
            } else {
                print("[ConvList] batchUpdate → no changes")
            }
        }
    }

    var totalUnread: Int {
        conversations.reduce(0) { $0 + $1.unread }
    }

    // MARK: - UITableView

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = TeamBannerCell()
            cell.onTap = { [weak self] in
                guard let nav = self?.navigationController else { return }
                nav.pushViewController(ChatViewController(conversationId: "conv-team"), animated: true)
            }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.reuseIdentifier, for: indexPath) as! ConversationCell
        cell.configure(conversations[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? UITableView.automaticDimension : 76
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 1 else { return }
        let conv = conversations[indexPath.row]
        IMService.shared.markAsRead(conv.id)
        navigationController?.pushViewController(ChatViewController(conversationId: conv.id), animated: true)
    }
}

// MARK: - TeamBannerCell

private final class TeamBannerCell: UITableViewCell {
    var onTap: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdBg

        let banner = UIView()
        banner.backgroundColor = UIColor(hexString: "#FFF7F1")
        banner.layer.cornerRadius = 12
        banner.layer.borderWidth = 1
        banner.layer.borderColor = UIColor(hexString: "#FF7A50").withAlphaComponent(0.18).cgColor
        banner.isUserInteractionEnabled = true

        let heart = UIImageView(image: UIImage(systemName: "heart.fill"))
        heart.tintColor = .fdPrimary
        heart.contentMode = .scaleAspectFit

        let mark = UILabel()
        mark.text = "三好共管 · 您的专属团队"
        mark.font = .fdFont(ofSize: 13, weight: .semibold)
        mark.textColor = .fdText

        let badge = UILabel()
        badge.text = "● 3 人在线"
        badge.font = .fdFont(ofSize: 10, weight: .bold)
        badge.textColor = .fdSuccess
        badge.backgroundColor = UIColor(hexString: "#E6F7EF")
        badge.layer.cornerRadius = 8
        badge.clipsToBounds = true
        badge.textAlignment = .center

        let body = UILabel()
        body.text = "优先从服务群发起问题，医生、营养师、健管师会协同回复。"
        body.font = .fdFont(ofSize: 12)
        body.textColor = .fdSubtext
        body.numberOfLines = 0

        [banner, heart, mark, badge, body].forEach(contentView.addSubview)
        banner.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 16, bottom: 0, right: 16)) }
        heart.snp.makeConstraints { make in
            make.top.leading.equalTo(banner).inset(14); make.size.equalTo(16)
        }
        mark.snp.makeConstraints { make in
            make.leading.equalTo(heart.snp.trailing).offset(6); make.centerY.equalTo(heart)
        }
        badge.snp.makeConstraints { make in
            make.trailing.equalTo(banner).inset(14); make.centerY.equalTo(heart)
            make.height.equalTo(20); make.width.equalTo(72)
        }
        body.snp.makeConstraints { make in
            make.top.equalTo(heart.snp.bottom).offset(8)
            make.leading.trailing.equalTo(banner).inset(14)
            make.bottom.equalTo(banner).offset(-14)
        }

        banner.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }

    required init?(coder: NSCoder) { fatalError() }
    @objc private func tapped() { onTap?() }
}
