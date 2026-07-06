import UIKit
import SnapKit

/// 收货地址列表页
///
/// TableView 列表展示所有收货地址，支持：
/// - 查看地址列表（默认地址置顶）
/// - 新增地址（导航栏按钮）
/// - 编辑地址（点击编辑按钮）
/// - 删除地址（点击删除按钮，确认弹窗）
/// - 空状态引导
final class AddressListViewController: BaseViewController {

    // MARK: - State

    private var addresses: [MAddress] = []
    private var isLoading = true

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

        // 导航栏右侧新增按钮
        let addBarButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addAddress)
        )
        addBarButton.tintColor = .fdPrimary
        navigationItem.rightBarButtonItem = addBarButton

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        emptyView.isHidden = true

        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    // MARK: - Data Loading

    private func loadAddresses() {
        if isLoading {
            loadingIndicator.startAnimating()
            tableView.isHidden = true
            emptyView.isHidden = true
        }

        Task {
            do {
                let data = try await AddressService.shared.getAddressList()
                await MainActor.run {
                    var list = data.records ?? []
                    // 默认地址置顶
                    list.sort { ($0.isDefault == 1) && ($1.isDefault != 1) }
                    self.addresses = list
                    self.isLoading = false
                    self.loadingIndicator.stopAnimating()
                    self.updateDisplay()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.loadingIndicator.stopAnimating()
                    self.updateDisplay()
                    self.showToast("加载失败: \(error.localizedDescription)")
                }
            }
        }
    }

    private func updateDisplay() {
        let isEmpty = addresses.isEmpty
        tableView.isHidden = isEmpty
        emptyView.isHidden = !isEmpty
        if !isEmpty {
            tableView.reloadData()
        }
    }

    // MARK: - Actions

    @objc private func addAddress() {
        Router.shared.push("/me/address/edit")
    }

    private func editAddress(_ address: MAddress) {
        guard let id = address.id else { return }
        Router.shared.push("/me/address/edit", params: ["id": id])
    }

    private func deleteAddress(_ address: MAddress, at indexPath: IndexPath) {
        guard let id = address.id else { return }

        let alert = UIAlertController(
            title: "确认删除",
            message: "删除后不可恢复，确定要删除该收货地址吗？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.performDelete(id: id, at: indexPath)
        })
        present(alert, animated: true)
    }

    private func performDelete(id: Int64, at indexPath: IndexPath) {
        Task {
            do {
                try await AddressService.shared.deleteAddress(id: id)
                await MainActor.run {
                    self.addresses.remove(at: indexPath.row)
                    self.updateDisplay()
                    self.showToast("已删除")
                }
            } catch {
                await MainActor.run {
                    self.showToast("删除失败: \(error.localizedDescription)")
                }
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
        return addresses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AddressCell.reuseIdentifier, for: indexPath) as? AddressCell else {
            return UITableViewCell()
        }
        let address = addresses[indexPath.row]
        cell.configure(address: address)
        cell.onEdit = { [weak self] in
            self?.editAddress(address)
        }
        cell.onDelete = { [weak self] in
            self?.deleteAddress(address, at: indexPath)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AddressListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        editAddress(addresses[indexPath.row])
    }
}
