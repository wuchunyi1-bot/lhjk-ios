import Combine
import SnapKit
import UIKit

final class MyActivitiesViewController: BaseViewController {

    private let viewModel: MyActivitiesViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = .fdBg
        table.separatorStyle = .none
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 108
        table.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)
        return table
    }()

    private let emptyView = FDEmptyStateView(style: .page, message: "暂无活动")
    private let spinner = UIActivityIndicatorView(style: .medium)

    init(viewModel: MyActivitiesViewModel = MyActivitiesViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        title = "我的活动"
        view.backgroundColor = .fdBg
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MyActivityCell.self, forCellReuseIdentifier: MyActivityCell.reuseID)
        view.addSubview(tableView)
        view.addSubview(emptyView)
        view.addSubview(spinner)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
        spinner.snp.makeConstraints { $0.center.equalToSuperview() }
        emptyView.isHidden = true
    }

    override func bindViewModel() {
        viewModel.$cards
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
                self?.updateEmpty()
            }
            .store(in: &cancellables)
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading {
                    self?.spinner.startAnimating()
                } else {
                    self?.spinner.stopAnimating()
                }
                self?.updateEmpty()
            }
            .store(in: &cancellables)
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { message in
                guard let message, !message.isEmpty else { return }
                FDToast.show(message, duration: 1.5)
            }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.load()
    }

    private func updateEmpty() {
        emptyView.isHidden = viewModel.isLoading || !viewModel.cards.isEmpty
    }
}

extension MyActivitiesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.cards.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MyActivityCell.reuseID, for: indexPath) as! MyActivityCell
        cell.configure(viewModel.cards[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = viewModel.cards[indexPath.row]
        guard card.isTappable else { return }
        Router.shared.push("/home/activities/detail", params: ["activityId": card.id], from: self)
    }
}
