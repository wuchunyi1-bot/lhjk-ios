import UIKit
import SnapKit
import Combine

/// 团队对话列表 — MessagesViewController 的子 VC
/// 对齐 Figma 3042:740：白色圆角列表卡 + 会话行（无置顶横幅）
final class ConversationListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var onDataChanged: (() -> Void)?
    private let viewModel = ConversationListViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI

    /// 白色圆角容器（对齐 Figma 列表外框 351 / radius 16）
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
        tv.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.reuseIdentifier)
        tv.contentInset = .zero
        tv.scrollIndicatorInsets = .zero
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
            // Figma 卡片底部与 TabBar 顶部保留约 25pt 空隙
            $0.bottom.equalToSuperview().offset(-25)
        }
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

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.reuseIdentifier, for: indexPath) as! ConversationCell
        let conv = viewModel.conversations[indexPath.row]
        let isLast = indexPath.row == viewModel.conversations.count - 1
        cell.configure(conv, hideSeparator: isLast)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        84
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conv = viewModel.conversations[indexPath.row]
        viewModel.markAsRead(conv.id)
        navigationController?.pushViewController(ChatViewController(conversationId: conv.id), animated: true)
    }
}
