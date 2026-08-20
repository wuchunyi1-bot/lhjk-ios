import Combine
import SnapKit
import UIKit

/// 设备选择 / 我的设备 — 对齐 funde-client BodyScaleSelectDeviceView + MyScaleDeviceView
final class ScaleDeviceSelectViewController: BaseViewController {

    private let viewModel: ScaleDeviceSelectViewModel
    private var cancellables = Set<AnyCancellable>()

    private enum Section: Int {
        case bound = 0
        case more = 1
    }

    init(viewModel: ScaleDeviceSelectViewModel = ScaleDeviceSelectViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
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
        tv.estimatedRowHeight = 88
        tv.rowHeight = UITableView.automaticDimension
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        return tv
    }()

    private lazy var addButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = .fdBodySemibold
        b.layer.cornerRadius = 18
        b.addTarget(self, action: #selector(handleAddTap), for: .touchUpInside)
        return b
    }()

    private lazy var addButtonContainer: UIView = {
        let v = UIView()
        v.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-8)
        }
        return v
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
        view.addSubview(emptyLabel)
        view.addSubview(loadingIndicator)

        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        loadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    override func bindViewModel() {
        Publishers.CombineLatest4(
            viewModel.$mode,
            viewModel.$boundDevices,
            viewModel.$moreDevices,
            viewModel.$isExpanded
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _, _, _, _ in
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
        refreshAddButton()
        tableView.tableFooterView = viewModel.showsAddButton ? makeFooterView() : UIView(frame: .zero)
        let empty = viewModel.isEmpty && !viewModel.isLoading
        emptyLabel.isHidden = !empty
        tableView.isHidden = viewModel.isLoading || empty
        tableView.reloadData()
    }

    private func refreshAddButton() {
        addButton.setTitle(viewModel.addButtonTitle, for: .normal)
        let expanded = viewModel.isAddButtonExpanded
        let plus = UIImage(systemName: expanded ? "chevron.up" : "plus")
        addButton.setImage(plus, for: .normal)
        addButton.tintColor = expanded ? .fdPrimary : .white
        addButton.setTitleColor(expanded ? .fdPrimary : .white, for: .normal)
        addButton.backgroundColor = expanded ? .clear : .fdPrimary
        addButton.layer.borderWidth = expanded ? 1 : 0
        addButton.layer.borderColor = UIColor.fdPrimary.cgColor
        addButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
    }

    private func makeFooterView() -> UIView {
        addButtonContainer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 64)
        addButtonContainer.setNeedsLayout()
        addButtonContainer.layoutIfNeeded()
        let height = addButtonContainer.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        addButtonContainer.frame.size = CGSize(width: view.bounds.width, height: max(height, 64))
        return addButtonContainer
    }

    @objc private func handleAddTap() {
        viewModel.toggleAddDevices()
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
            if indexPath.section == Section.bound.rawValue {
                guard indexPath.row < viewModel.boundDevices.count else { return nil }
                return viewModel.boundDevices[indexPath.row]
            }
            guard indexPath.row < viewModel.moreDevices.count else { return nil }
            return viewModel.moreDevices[indexPath.row]
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

    func numberOfSections(in tableView: UITableView) -> Int {
        switch viewModel.mode {
        case .select:
            return 1
        case .mine:
            return viewModel.showsMoreSection ? 2 : 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewModel.mode {
        case .select:
            return viewModel.moreDevices.count
        case .mine:
            if section == Section.bound.rawValue {
                return viewModel.boundDevices.count
            }
            return viewModel.moreDevices.count
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

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard viewModel.mode == .mine else { return nil }
        let title = section == Section.bound.rawValue ? "当前设备" : "更多设备"
        return makeSectionHeader(title)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        viewModel.mode == .mine ? 36 : CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }

    private func makeSectionHeader(_ title: String) -> UIView {
        let container = UIView()
        let label = UILabel()
        label.text = title
        label.font = .fdCaptionSemibold
        label.textColor = .fdSubtext
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-8)
        }
        return container
    }
}
