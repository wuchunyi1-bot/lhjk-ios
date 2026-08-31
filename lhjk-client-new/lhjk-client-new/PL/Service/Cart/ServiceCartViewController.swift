import UIKit
import SnapKit
import Combine

/// 购物车页 — 对齐 funde `CartView.vue`：单卡结算，无底栏合计
final class ServiceCartViewController: BaseViewController {

    private let viewModel: ServiceCartViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    init(viewModel: ServiceCartViewModel = ServiceCartViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func setupUI() {
        view.backgroundColor = .fdBg
        title = "购物车"

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CartItemCell.self, forCellReuseIdentifier: CartItemCell.reuseID)
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        buildEmpty()

        loadingIndicator.color = .fdPrimary
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reload()
    }

    override func bindViewModel() {
        viewModel.$lines
            .combineLatest(viewModel.$isLoading, viewModel.$isCheckingOut)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] lines, loading, checkingOut in
                guard let self else { return }
                let busy = loading || checkingOut
                if busy {
                    self.loadingIndicator.startAnimating()
                } else {
                    self.loadingIndicator.stopAnimating()
                }
                self.tableView.isUserInteractionEnabled = !checkingOut
                self.tableView.reloadData()
                let showEmpty = lines.isEmpty && !loading
                self.emptyView.isHidden = !showEmpty
                self.tableView.isHidden = showEmpty || loading
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .sink { [weak self] message in
                self?.showToast(message)
            }
            .store(in: &cancellables)

        viewModel.$toastMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] message in
                self?.showToast(message) {
                    self?.viewModel.consumeToast()
                }
            }
            .store(in: &cancellables)

        viewModel.$confirmRoute
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] route in
                self?.openConfirmOrder(route)
                self?.viewModel.consumeConfirmRoute()
            }
            .store(in: &cancellables)
    }

    private func buildEmpty() {
        emptyView.isHidden = true
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        emptyView.addSubview(card)
        card.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        let icon = UIImageView(image: UIImage(named: "serice_cart"))
        icon.contentMode = .scaleAspectFit

        let tip = UILabel()
        tip.text = "购物车还是空的"
        tip.font = .fdFont(ofSize: 16, weight: .medium)
        tip.textColor = .fdText
        tip.textAlignment = .center

        let sub = UILabel()
        sub.text = "去服务页挑选心仪套餐吧"
        sub.font = .fdFont(ofSize: 14, weight: .regular)
        sub.textColor = .fdTabInactive
        sub.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [icon, tip, sub])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        icon.snp.makeConstraints { $0.size.equalTo(48) }
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(32) }
    }

    private func checkout(line: CartLineDisplay) {
        viewModel.checkout(line: line)
    }

    private func openConfirmOrder(_ route: CartConfirmRoute) {
        var params: [String: Any] = [
            "orderId": String(route.orderId),
            "entry": "cart",
        ]
        if let serial = route.serialNumber {
            params["serialNumber"] = String(serial)
        }
        Router.shared.push("/orders/confirm", params: params)
    }

    private func confirmRemove(line: CartLineDisplay) {
        guard !viewModel.isDeleting else { return }
        let alert = UIAlertController(
            title: "确认删除",
            message: "确认删除该套餐「\(line.name)」？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.viewModel.remove(id: line.id)
        })
        present(alert, animated: true)
    }

    private func showToast(_ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            alert.dismiss(animated: true) {
                completion?()
            }
        }
    }
}

// MARK: - Table

extension ServiceCartViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.lines.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CartItemCell.reuseID,
            for: indexPath
        ) as! CartItemCell
        let line = viewModel.lines[indexPath.row]
        cell.configure(line)
        cell.onCheckout = { [weak self] in self?.checkout(line: line) }
        cell.onDelete = { [weak self] in self?.confirmRemove(line: line) }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        219
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let line = viewModel.lines[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            guard let self, !self.viewModel.isDeleting else {
                completion(false)
                return
            }
            self.confirmRemove(line: line)
            completion(true)
        }
        delete.backgroundColor = .fdDanger
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
