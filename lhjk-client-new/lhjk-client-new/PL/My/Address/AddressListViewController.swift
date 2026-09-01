import UIKit
import SnapKit
import Combine

/// 我的地址列表 — 对齐 Figma 4522:6020
final class AddressListViewController: BaseViewController {

    // MARK: - ViewModel

    private let viewModel = AddressListViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let selectMode: Bool
    private let onSelect: ((MAddress) -> Void)?

    private var showsTipBanner = true

    init(selectMode: Bool = false, onSelect: ((MAddress) -> Void)? = nil) {
        self.selectMode = selectMode
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.register(AddressCell.self, forCellReuseIdentifier: AddressCell.reuseIdentifier)
        tv.dataSource = self
        tv.delegate = self
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        return tv
    }()

    private let tipBanner = AddressListTipBannerView()

    private let bottomBar = UIView()

    private lazy var addButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("添加收货地址", for: .normal)
        btn.titleLabel?.font = AddressStyle.buttonFont
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .fdPrimary
        btn.layer.cornerRadius = AddressStyle.primaryButtonRadius
        btn.addTarget(self, action: #selector(addAddress), for: .touchUpInside)
        return btn
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
        title = selectMode ? "选择收货地址" : "我的地址"
        view.backgroundColor = .fdBg
        navigationItem.rightBarButtonItem = nil

        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
        }

        bottomBar.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(AddressStyle.primaryButtonHeight)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top).offset(-16)
        }

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { $0.edges.equalTo(tableView) }
        emptyView.isHidden = true

        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { $0.center.equalTo(tableView) }

        tipBanner.onClose = { [weak self] in
            self?.showsTipBanner = false
            self?.updateTableHeader()
        }
        updateTableHeader()

        bindViewModel()
    }

    private func updateTableHeader() {
        guard !selectMode, showsTipBanner else {
            tableView.tableHeaderView = nil
            return
        }

        let container = UIView()
        container.addSubview(tipBanner)
        tipBanner.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(AddressStyle.horizontalInset)
            make.bottom.equalToSuperview().offset(-12)
        }

        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        container.frame = CGRect(x: 0, y: 0, width: width, height: 58)
        container.layoutIfNeeded()
        let height = tipBanner.systemLayoutSizeFitting(
            CGSize(width: width - AddressStyle.horizontalInset * 2, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height + 24
        container.frame.size.height = height
        tableView.tableHeaderView = container
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if tableView.tableHeaderView != nil {
            updateTableHeader()
        }
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
        Task { await viewModel.loadAddresses() }
    }

    // MARK: - Actions

    @objc private func addAddress() {
        Router.shared.push("/me/address/edit")
    }

    private func editAddress(_ address: MAddress) {
        guard address.id != nil else { return }
        Router.shared.push("/me/address/edit", params: ["address": address])
    }

    private func deleteAddress(_ address: MAddress) {
        guard let id = address.id else { return }
        let alert = UIAlertController(
            title: "确认删除",
            message: "删除后不可恢复，确定要删除该收货地址吗？",
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
                await MainActor.run { self.showToastAlert("已删除", duration: 1.5) }
            } catch {
                await MainActor.run {
                    self.showToastAlert("删除失败: \(error.localizedDescription)", duration: 1.5)
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension AddressListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.addresses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: AddressCell.reuseIdentifier,
            for: indexPath
        ) as? AddressCell else {
            return UITableViewCell()
        }
        let address = viewModel.addresses[indexPath.row]
        cell.configure(address: address)
        cell.onEdit = { [weak self] in self?.editAddress(address) }
        cell.onDelete = { [weak self] in self?.deleteAddress(address) }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AddressListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        140
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let address = viewModel.addresses[indexPath.row]
        if selectMode {
            onSelect?(address)
            navigationController?.popViewController(animated: true)
        } else {
            editAddress(address)
        }
    }
}
