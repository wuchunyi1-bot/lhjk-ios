import UIKit
import SnapKit
import Combine

/// 群成员列表 — 聊天详情右上角入口
final class GroupMembersViewController: BaseViewController {

    private let viewModel: GroupMembersViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .white
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.register(GroupMemberCell.self, forCellReuseIdentifier: GroupMemberCell.reuseID)
        tv.dataSource = self
        tv.delegate = self
        tv.rowHeight = 64
        return tv
    }()

    private lazy var emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "暂无群成员"
        l.font = .fdCaption
        l.textColor = .fdMuted
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .fdPrimary
        indicator.hidesWhenStopped = true
        return indicator
    }()

    init(groupId: String) {
        self.viewModel = GroupMembersViewModel(groupId: groupId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        Task { await viewModel.loadMembers() }
    }

    override func setupUI() {
        title = "群成员"
        view.backgroundColor = .fdBg

        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    override func bindViewModel() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                guard let self else { return }
                if loading {
                    self.loadingIndicator.startAnimating()
                    self.tableView.isHidden = true
                    self.emptyLabel.isHidden = true
                } else {
                    self.loadingIndicator.stopAnimating()
                    self.tableView.isHidden = self.viewModel.isEmpty
                    self.emptyLabel.isHidden = !self.viewModel.isEmpty
                }
            }
            .store(in: &cancellables)

        viewModel.$members
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.toastPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                self?.showToastAlert(msg)
            }
            .store(in: &cancellables)
    }
}

extension GroupMembersViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.members.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: GroupMemberCell.reuseID,
            for: indexPath
        ) as? GroupMemberCell else {
            return UITableViewCell()
        }
        let isLast = indexPath.row == viewModel.members.count - 1
        cell.configure(viewModel.members[indexPath.row], isLast: isLast)
        return cell
    }
}
