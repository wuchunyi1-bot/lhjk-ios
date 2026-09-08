import Combine
import SnapKit
import UIKit

/// 设备选择 / 已绑定列表 — 对齐 Figma 5140:12352 / 5175:12472
final class ScaleDeviceSelectViewController: BaseViewController {

    private let viewModel: ScaleDeviceSelectViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: ScaleDeviceSelectViewModel = ScaleDeviceSelectViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(entry: ScaleDeviceSelectViewModel.Entry) {
        self.init(viewModel: ScaleDeviceSelectViewModel(entry: entry))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.register(ScaleDeviceCardCell.self, forCellReuseIdentifier: ScaleDeviceCardCell.reuseID)
        tv.dataSource = self
        tv.delegate = self
        tv.estimatedRowHeight = ScaleDeviceCardCell.cardHeight + 12
        tv.rowHeight = UITableView.automaticDimension
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        return tv
    }()

    private lazy var addButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setTitle("添加设备", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        b.backgroundColor = .fdPrimary
        b.layer.cornerRadius = 25.5
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(handleAddTap), for: .touchUpInside)
        b.isHidden = true
        return b
    }()

    private lazy var emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "暂无可绑定设备"
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.load()
    }

    override func setupUI() {
        title = viewModel.navigationTitle
        view.backgroundColor = .fdBg

        view.addSubview(tableView)
        view.addSubview(addButton)
        view.addSubview(emptyLabel)
        view.addSubview(loadingIndicator)

        addButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(327)
            make.height.equalTo(51)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        emptyLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        loadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    override func bindViewModel() {
        Publishers.CombineLatest3(
            viewModel.$mode,
            viewModel.$boundDevices,
            viewModel.$moreDevices
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _, _, _ in
            self?.reloadContent()
        }
        .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                guard let self else { return }
                if loading {
                    self.loadingIndicator.startAnimating()
                    self.tableView.isHidden = true
                    self.emptyLabel.isHidden = true
                    self.addButton.isHidden = true
                } else {
                    self.loadingIndicator.stopAnimating()
                    self.reloadContent()
                }
            }
            .store(in: &cancellables)

        viewModel.toastPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showToast(message)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private

    private func reloadContent() {
        title = viewModel.navigationTitle
        let showAdd = viewModel.showsAddButton && !viewModel.isLoading
        addButton.isHidden = !showAdd
        tableView.contentInset.bottom = showAdd ? 79 : 16
        tableView.verticalScrollIndicatorInsets.bottom = showAdd ? 63 : 0

        let empty = viewModel.isEmpty && !viewModel.isLoading
        emptyLabel.isHidden = !empty
        tableView.isHidden = viewModel.isLoading || empty
        tableView.reloadData()
    }

    @objc private func handleAddTap() {
        Router.shared.push("/health/scale/devices/add", from: self)
    }

    private func confirmUnbind(_ item: ScaleDeviceCardItem) {
        let alert = UIAlertController(title: nil, message: "确定要解除设备绑定？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认", style: .default) { [weak self] _ in
            self?.viewModel.unbind(item)
        })
        present(alert, animated: true)
    }

    private func handleCatalogTap(_ item: ScaleDeviceCardItem) {
        guard item.isOKOKCatalog else {
            showToast("暂不支持该设备")
            return
        }
        var params: [String: Any] = [:]
        if let typeId = item.equipmentTypeId, !typeId.isEmpty {
            params["equipmentType"] = typeId
        }
        params["bluetoothName"] = item.bluetoothName ?? "OKOK"
        params["equipmentName"] = item.name
        Router.shared.push("/health/scale/bind", params: params, from: self)
    }

    private func item(at indexPath: IndexPath) -> ScaleDeviceCardItem? {
        switch viewModel.mode {
        case .select:
            guard indexPath.row < viewModel.moreDevices.count else { return nil }
            return viewModel.moreDevices[indexPath.row]
        case .mine:
            guard indexPath.row < viewModel.boundDevices.count else { return nil }
            return viewModel.boundDevices[indexPath.row]
        }
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}

// MARK: - UITableView

extension ScaleDeviceSelectViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewModel.mode {
        case .select:
            return viewModel.moreDevices.count
        case .mine:
            return viewModel.boundDevices.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ScaleDeviceCardCell.reuseID,
            for: indexPath
        ) as? ScaleDeviceCardCell ?? ScaleDeviceCardCell(style: .default, reuseIdentifier: ScaleDeviceCardCell.reuseID)
        guard let item = item(at: indexPath) else { return cell }
        cell.configure(item)
        cell.onUnbind = { [weak self] in
            self?.confirmUnbind(item)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let item = item(at: indexPath), item.isSelectable else { return }
        handleCatalogTap(item)
    }
}
