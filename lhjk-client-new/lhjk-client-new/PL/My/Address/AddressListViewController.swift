import UIKit
import SnapKit
import Combine

/// 收货地址列表页
final class AddressListViewController: BaseViewController {

    // MARK: - ViewModel

    private let viewModel = AddressListViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.register(AddressCell.self, forCellReuseIdentifier: AddressCell.reuseIdentifier)
        tv.dataSource = self
        tv.delegate = self
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        return tv
    }()

    private lazy var emptyView: UIView = {
        let v = UIView()
        let icon = UIImageView(image: UIImage(systemName: "mappin.slash"))
        icon.tintColor = .fdMuted
        icon.contentMode = .scaleAspectFit
        v.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
            make.size.equalTo(56)
        }

        let label = UILabel()
        label.text = "暂无收货地址"
        label.font = .fdCaption
        label.textColor = .fdMuted
        label.textAlignment = .center
        v.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(icon.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }

        let addBtn = UIButton(type: .system)
        addBtn.setTitle("新增地址", for: .normal)
        addBtn.titleLabel?.font = .fdBodySemibold
        addBtn.setTitleColor(.fdPrimary, for: .normal)
        addBtn.addTarget(self, action: #selector(addAddress), for: .touchUpInside)
        v.addSubview(addBtn)
        addBtn.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }

        return v
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .fdPrimary
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        loadAddresses()
    }

    override func setupUI() {
        title = "收货地址"
        view.backgroundColor = .fdBg

        let addBarButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addAddress)
        )
        addBarButton.tintColor = .fdPrimary
        navigationItem.rightBarButtonItem = addBarButton

        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyView.isHidden = true

        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }

        bindViewModel()
    }

    // MARK: - Binding

    override func bindViewModel() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading {
                    self?.loadingIndicator.startAnimating()
                    self?.tableView.isHidden = true
                    self?.emptyView.isHidden = true
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.$isEmpty
            .receive(on: DispatchQueue.main)
            .sink { [weak self] empty in
                self?.tableView.isHidden = empty
                self?.emptyView.isHidden = !empty
            }
            .store(in: &cancellables)

        viewModel.$addresses
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data

    private func loadAddresses() {
        Task {
            await viewModel.loadAddresses()
        }
    }

    // MARK: - Actions

    @objc private func addAddress() {
        Router.shared.push("/me/address/edit", params: [
            "existingAddressCount": viewModel.addresses.count
        ])
    }

    private func editAddress(_ address: MAddress) {
        guard address.id != nil else { return }
        Router.shared.push("/me/address/edit", params: [
            "address": address,
            "existingAddressCount": viewModel.addresses.count
        ])
    }

    private func deleteAddress(_ address: MAddress, at indexPath: IndexPath) {
        guard let id = address.id else { return }
        let alert = UIAlertController(
            title: "确认删除", message: "删除后不可恢复，确定要删除该收货地址吗？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.performDelete(id: id)
        })
        present(alert, animated: true)
    }

    private func performDelete(id: Int64) {
        Task {
            do {
                try await viewModel.deleteAddress(id: id)
                await MainActor.run { self.showToast("已删除") }
            } catch {
                await MainActor.run { self.showToast("删除失败: \(error.localizedDescription)") }
            }
        }
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}

// MARK: - UITableViewDataSource

extension AddressListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.addresses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AddressCell.reuseIdentifier, for: indexPath) as? AddressCell else {
            return UITableViewCell()
        }
        let address = viewModel.addresses[indexPath.row]
        cell.configure(address: address)
        cell.onEdit = { [weak self] in self?.editAddress(address) }
        cell.onDelete = { [weak self] in self?.deleteAddress(address, at: indexPath) }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AddressListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        120
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        editAddress(viewModel.addresses[indexPath.row])
    }
}
