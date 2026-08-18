import UIKit
import SnapKit
import Combine

/// 团队对话列表 — MessagesViewController 的子 VC
/// 对齐 Figma 3444:5583：去除外层固定白卡，列表自然滚动，由 Cell 内部自适应首尾圆角白卡
final class ConversationListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var onDataChanged: (() -> Void)?
    private let viewModel = ConversationListViewModel()
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
        tv.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.reuseIdentifier)
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
        label.text = "暂无团队对话"
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

        bindViewModel()
        viewModel.loadData()
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$conversations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] list in
                self?.emptyContainer.isHidden = !list.isEmpty
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
        let count = viewModel.conversations.count
        let conv = viewModel.conversations[indexPath.row]
        let isSingle = count == 1
        let isFirst = indexPath.row == 0
        let isLast = indexPath.row == count - 1
        cell.configure(conv, isFirst: isFirst, isLast: isLast, isSingle: isSingle)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        78
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conv = viewModel.conversations[indexPath.row]
        viewModel.markAsRead(conv.id)
        navigationController?.pushViewController(ChatViewController(conversationId: conv.id), animated: true)
    }
}
