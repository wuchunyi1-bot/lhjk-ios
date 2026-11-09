import UIKit
import SnapKit

/// 我的设备。列表来自 `getMyHeaderList?type=2`。左滑删除解绑，卡片不可点。
final class DevicesViewController: BaseViewController {

    private let equipmentBindService: EquipmentBindService
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = DeviceEmptyIllustrationView(text: "暂无设备\n快来添加你的第一个设备吧！")
    private let addButton = UIButton(type: .custom)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private var devices: [MyBoundDevice] = []
    private var didLoad = false
    private weak var swipedCell: MyDeviceSwipeCell?

    init(equipmentBindService: EquipmentBindService = .shared) {
        self.equipmentBindService = equipmentBindService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        loadDevices()
    }

    override func setupUI() {
        title = "我的设备"
        view.backgroundColor = .fdBg

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = MyDeviceSwipeCell.cardHeight + MyDeviceSwipeCell.rowSpacing
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 12, right: 0)
        tableView.register(MyDeviceSwipeCell.self, forCellReuseIdentifier: MyDeviceSwipeCell.reuseID)
        view.addSubview(tableView)

        emptyView.isHidden = true
        view.addSubview(emptyView)

        addButton.setTitle("添加设备", for: .normal)
        addButton.setTitleColor(.white, for: .normal)
        addButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        addButton.backgroundColor = .fdPrimary
        addButton.layer.cornerRadius = 21.5
        addButton.addTarget(self, action: #selector(openCatalog), for: .touchUpInside)
        view.addSubview(addButton)

        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)

        addButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(43)
        }
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(addButton.snp.top).offset(-12)
        }
        emptyView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(tableView).offset(-24)
        }
        loadingIndicator.snp.makeConstraints { $0.center.equalTo(tableView) }
    }

    private func loadDevices() {
        if !didLoad { loadingIndicator.startAnimating() }
        Task { [weak self] in
            guard let self else { return }
            do {
                let list = try await self.equipmentBindService.fetchMyDevices()
                await MainActor.run {
                    self.didLoad = true
                    self.loadingIndicator.stopAnimating()
                    self.swipedCell = nil
                    self.devices = list
                    self.emptyView.isHidden = !list.isEmpty
                    self.tableView.isHidden = list.isEmpty
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.didLoad = true
                    self.loadingIndicator.stopAnimating()
                    self.showToastAlert(error.localizedDescription)
                }
            }
        }
    }

    @objc private func openCatalog() {
        navigationController?.pushViewController(DeviceCatalogViewController(), animated: true)
    }
}

extension DevicesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        devices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MyDeviceSwipeCell.reuseID,
            for: indexPath
        ) as! MyDeviceSwipeCell
        let item = ScaleDeviceCardItem.bound(from: devices[indexPath.row])
        cell.configure(item)
        cell.onWillSwipe = { [weak self, weak cell] in
            guard let self, let cell else { return }
            if self.swipedCell !== cell {
                self.swipedCell?.close(animated: true)
            }
            self.swipedCell = cell
        }
        cell.onDelete = { [weak self] in
            self?.confirmUnbind(item)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        swipedCell?.close(animated: true)
        swipedCell = nil
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        swipedCell?.close(animated: true)
        swipedCell = nil
    }
}

private extension DevicesViewController {
    func confirmUnbind(_ item: ScaleDeviceCardItem) {
        guard presentedViewController == nil else { return }
        let dialog = DeviceUnbindDialogViewController()
        dialog.onConfirm = { [weak self] in
            self?.unbind(item)
        }
        present(dialog, animated: true)
    }

    func unbind(_ item: ScaleDeviceCardItem) {
        guard let equipmentUserId = item.equipmentUserId, equipmentUserId > 0 else {
            showToastAlert("无法解绑该设备")
            return
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.equipmentBindService.unbindEquipment(equipmentUserId: equipmentUserId)
                await MainActor.run {
                    self.showToastAlert("已解除绑定")
                    self.loadDevices()
                }
            } catch {
                await MainActor.run {
                    self.showToastAlert(error.localizedDescription)
                }
            }
        }
    }
}

/// 添加设备。左侧栏目来自字典 `deviceCategory`，右侧型号来自 `getEquipmenByApp`。
final class DeviceCatalogViewController: BaseViewController {

    /// 左侧分类栏宽度。设计稿 74pt 放不下四字以上栏目名。
    private static let categoryColumnWidth: CGFloat = 108

    private struct Tab {
        let name: String
        let type: Int
    }

    private let equipmentBindService: EquipmentBindService
    private let dictionaryService: DictionaryService
    private let categoryTable = UITableView(frame: .zero, style: .plain)
    private var categoryWidth: Constraint?
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let contentPanel = UIView()
    private let emptyView = DeviceEmptyIllustrationView(text: "暂无设备")
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private var tabs: [Tab] = []
    private var selectedIndex = 0
    private var models: [EquipmentCatalogItemVO] = []

    init(
        equipmentBindService: EquipmentBindService = .shared,
        dictionaryService: DictionaryService = .shared
    ) {
        self.equipmentBindService = equipmentBindService
        self.dictionaryService = dictionaryService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func setupUI() {
        title = "添加设备"
        view.backgroundColor = .fdBg

        categoryTable.backgroundColor = .fdSurface
        categoryTable.separatorStyle = .none
        categoryTable.showsVerticalScrollIndicator = false
        categoryTable.dataSource = self
        categoryTable.delegate = self
        categoryTable.rowHeight = DeviceCatalogCategoryCell.rowHeight
        categoryTable.register(
            DeviceCatalogCategoryCell.self,
            forCellReuseIdentifier: DeviceCatalogCategoryCell.reuseID
        )
        view.addSubview(categoryTable)

        contentPanel.backgroundColor = .fdSurface
        view.addSubview(contentPanel)

        tableView.backgroundColor = .fdSurface
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = DeviceCatalogRowCell.rowHeight
        tableView.register(DeviceCatalogRowCell.self, forCellReuseIdentifier: DeviceCatalogRowCell.reuseID)
        contentPanel.addSubview(tableView)

        emptyView.isHidden = true
        contentPanel.addSubview(emptyView)
        loadingIndicator.hidesWhenStopped = true
        contentPanel.addSubview(loadingIndicator)

        categoryTable.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.bottom.equalToSuperview()
            categoryWidth = $0.width.equalTo(Self.categoryColumnWidth).constraint
        }
        contentPanel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.equalTo(categoryTable.snp.trailing)
            $0.trailing.bottom.equalToSuperview()
        }
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-40)
        }
        loadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
        loadTabs()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let rowsHeight = CGFloat(tabs.count) * DeviceCatalogCategoryCell.rowHeight
        let extra = max(0, categoryTable.bounds.height - rowsHeight)
        let current = categoryTable.tableFooterView?.bounds.height ?? -1
        guard abs(current - extra) > 0.5 else { return }
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: categoryTable.bounds.width, height: extra))
        footer.backgroundColor = .fdLoginBackground
        categoryTable.tableFooterView = footer
    }

    private func loadTabs() {
        loadingIndicator.startAnimating()
        Task { [weak self] in
            guard let self else { return }
            do {
                let nodes = try await self.dictionaryService.fetchNodes(
                    parentId: DictionaryParent.deviceCategory.rawValue
                )
                let tabs = Self.tabs(from: nodes)
                await MainActor.run {
                    self.tabs = tabs
                    self.categoryTable.reloadData()
                    if tabs.isEmpty {
                        self.loadingIndicator.stopAnimating()
                        self.models = []
                        self.tableView.reloadData()
                        self.tableView.isHidden = true
                        self.emptyView.isHidden = false
                        self.categoryTable.isHidden = true
                        self.categoryWidth?.update(offset: 0)
                    } else {
                        self.categoryTable.isHidden = false
                        self.categoryWidth?.update(offset: Self.categoryColumnWidth)
                        self.selectTab(0)
                    }
                }
            } catch {
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.showToastAlert(error.localizedDescription)
                }
            }
        }
    }

    private static func tabs(from nodes: [SDictionary]) -> [Tab] {
        let children = nodes.compactMap(\.children).flatMap { $0 }
        let source = children.isEmpty
            ? nodes.filter { $0.id != DictionaryParent.deviceCategory.rawValueString }
            : children
        return source
            .filter { $0.status == nil || $0.status == 1 }
            .sorted { ($0.sortId ?? Int.max) < ($1.sortId ?? Int.max) }
            .compactMap { node in
                let name = node.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let raw = node.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard !name.isEmpty, let type = Int(raw) else { return nil }
                return Tab(name: name, type: type)
            }
    }

    private func selectTab(_ index: Int) {
        guard tabs.indices.contains(index) else { return }
        selectedIndex = index
        categoryTable.reloadData()
        loadModels(type: tabs[index].type)
    }

    private func loadModels(type: Int) {
        loadingIndicator.startAnimating()
        emptyView.isHidden = true
        let userId = UserManager.shared.resolvedUserId.flatMap { Int64($0) }
        Task { [weak self] in
            guard let self else { return }
            do {
                let page = try await self.equipmentBindService.fetchEquipmentCatalog(
                    type: type,
                    userId: userId
                )
                let items = (page.records ?? []).filter(\.isBindable)
                await MainActor.run {
                    guard self.tabs.indices.contains(self.selectedIndex),
                          self.tabs[self.selectedIndex].type == type else { return }
                    self.loadingIndicator.stopAnimating()
                    self.models = items
                    self.tableView.reloadData()
                    self.tableView.isHidden = items.isEmpty
                    self.emptyView.isHidden = !items.isEmpty
                }
            } catch {
                await MainActor.run {
                    guard self.tabs.indices.contains(self.selectedIndex),
                          self.tabs[self.selectedIndex].type == type else { return }
                    self.loadingIndicator.stopAnimating()
                    self.models = []
                    self.tableView.reloadData()
                    self.tableView.isHidden = true
                    self.emptyView.isHidden = false
                    self.showToastAlert(error.localizedDescription)
                }
            }
        }
    }
}

extension DeviceCatalogViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView === categoryTable ? tabs.count : models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === categoryTable {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: DeviceCatalogCategoryCell.reuseID,
                for: indexPath
            ) as! DeviceCatalogCategoryCell
            let corner: DeviceCatalogCategoryCell.InnerCorner
            if indexPath.row == selectedIndex + 1 {
                corner = .topRight
            } else if indexPath.row == selectedIndex - 1 {
                corner = .bottomRight
            } else {
                corner = .none
            }
            cell.configure(
                title: tabs[indexPath.row].name,
                selected: indexPath.row == selectedIndex,
                corner: corner
            )
            return cell
        }
        let cell = tableView.dequeueReusableCell(
            withIdentifier: DeviceCatalogRowCell.reuseID,
            for: indexPath
        ) as! DeviceCatalogRowCell
        cell.configure(ScaleDeviceCardItem.catalog(from: models[indexPath.row], nameFallback: "设备"))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView === categoryTable {
            selectTab(indexPath.row)
            return
        }
        guard models.indices.contains(indexPath.row) else { return }
        openCatalogItem(ScaleDeviceCardItem.catalog(from: models[indexPath.row], nameFallback: "设备"))
    }

    private func openCatalogItem(_ item: ScaleDeviceCardItem) {
        let page = ScaleDeviceBindViewController(
            equipmentTypeId: item.equipmentTypeId ?? "",
            bluetoothName: item.bluetoothName ?? "OKOK",
            displayName: item.name,
            returnsToMyDevices: true
        )
        navigationController?.pushViewController(page, animated: true)
    }
}

