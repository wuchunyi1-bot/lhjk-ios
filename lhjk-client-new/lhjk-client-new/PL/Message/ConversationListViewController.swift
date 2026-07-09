import UIKit
import SnapKit
import Combine

/// 团队对话列表 — MessagesViewController 的子 VC
/// 展示三好共管置顶横幅 + 融云会话列表
final class ConversationListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var onDataChanged: (() -> Void)?
    private let viewModel = ConversationListViewModel()
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
        tv.register(TeamBannerCell.self, forCellReuseIdentifier: TeamBannerCell.reuseID)
        return tv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .fdBg
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        bindViewModel()
        viewModel.loadData()
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$conversations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
                self?.onDataChanged?()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public

    func forceReload() {
        viewModel.forceReload()
    }

    var totalUnread: Int {
        viewModel.totalUnread
    }

    func loadData() {
        viewModel.loadData()
    }

    // MARK: - UITableView

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : viewModel.conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: TeamBannerCell.reuseID, for: indexPath) as! TeamBannerCell
            cell.onTap = { [weak self] in
                guard let nav = self?.navigationController else { return }
                nav.pushViewController(ChatViewController(conversationId: "conv-team"), animated: true)
            }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.reuseIdentifier, for: indexPath) as! ConversationCell
        cell.configure(viewModel.conversations[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? UITableView.automaticDimension : 76
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 1 else { return }
        let conv = viewModel.conversations[indexPath.row]
        viewModel.markAsRead(conv.id)
        navigationController?.pushViewController(ChatViewController(conversationId: conv.id), animated: true)
    }
}
