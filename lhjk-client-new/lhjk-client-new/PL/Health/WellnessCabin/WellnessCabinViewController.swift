import Combine
import SnapKit
import UIKit

/// 康养小屋列表。结构对齐选择服务机构：定位条 + 搜索列表。卡片文案按驿站原型。
final class WellnessCabinViewController: BaseViewController {

    private let viewModel = WellnessCabinListViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let locationCard = UIView()
    private let cityLabel = UILabel()
    private let districtLabel = UILabel()
    private let relocateButton = UIButton(type: .system)
    private let sheetView = UIView()
    private let searchField = UITextField()
    private let clearButton = UIButton(type: .system)
    private let hintLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = FDEmptyStateView(
        style: .compact,
        message: "未找到匹配驿站",
        subtitle: "请尝试其他关键词，或重新定位"
    )

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        title = "康养小屋"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: .fdNavBack,
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .fdText
        setupLocationCard()
        setupSheet()
    }

    override func bindViewModel() {
        Publishers.CombineLatest(viewModel.$cityText, viewModel.$districtText)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] city, district in
                self?.cityLabel.text = city
                self?.districtLabel.text = district
                self?.districtLabel.isHidden = district.isEmpty
            }
            .store(in: &cancellables)

        viewModel.$isLocating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] locating in
                self?.relocateButton.isEnabled = !locating
                self?.relocateButton.setTitle(locating ? "定位中…" : "重新定位", for: .normal)
            }
            .store(in: &cancellables)

        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.renderList() }
            .store(in: &cancellables)

        viewModel.$isLoadingList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.renderList() }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let message, !message.isEmpty else { return }
                self?.showToastAlert(message)
            }
            .store(in: &cancellables)

        viewModel.onAppear()
    }

    @objc private func backTapped() {
        view.endEditing(true)
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func renderList() {
        hintLabel.text = viewModel.hintText
        tableView.reloadData()
        emptyView.isHidden = !viewModel.items.isEmpty || viewModel.isLoadingList
    }

    private func setupLocationCard() {
        locationCard.backgroundColor = .fdSurface
        locationCard.layer.cornerRadius = 16
        locationCard.clipsToBounds = true

        let deco = UIImageView(image: UIImage(named: "onboarding_address_bg"))
        deco.contentMode = .scaleToFill
        deco.clipsToBounds = true

        let iconCircle = UIView()
        iconCircle.backgroundColor = .fdPrimarySoft
        iconCircle.layer.cornerRadius = 22
        let pin = UIImageView(image: UIImage(named: "onboarding_address_icon"))
        pin.contentMode = .scaleAspectFit

        let locateTitle = UILabel()
        locateTitle.text = "当前定位"
        locateTitle.font = .fdFont(ofSize: 16, weight: .regular)
        locateTitle.textColor = .fdTabInactive

        cityLabel.font = .fdFont(ofSize: 18, weight: .medium)
        cityLabel.textColor = .fdText
        districtLabel.font = .fdFont(ofSize: 18, weight: .medium)
        districtLabel.textColor = .fdText

        let placeRow = UIStackView(arrangedSubviews: [cityLabel, districtLabel])
        placeRow.axis = .horizontal
        placeRow.spacing = 8
        placeRow.alignment = .center

        relocateButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .regular)
        relocateButton.setTitleColor(.fdPrimary, for: .normal)
        relocateButton.setTitle("重新定位", for: .normal)
        relocateButton.addTarget(self, action: #selector(relocateTapped), for: .touchUpInside)

        locationCard.addSubview(deco)
        iconCircle.addSubview(pin)
        locationCard.addSubview(iconCircle)
        locationCard.addSubview(locateTitle)
        locationCard.addSubview(placeRow)
        locationCard.addSubview(relocateButton)
        view.addSubview(locationCard)

        locationCard.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(locationCard.snp.width).multipliedBy(80.0 / 343.0)
        }
        deco.snp.makeConstraints { $0.edges.equalToSuperview() }
        iconCircle.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(44)
        }
        pin.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(32)
        }
        locateTitle.snp.makeConstraints {
            $0.leading.equalTo(iconCircle.snp.trailing).offset(12)
            $0.top.equalToSuperview().offset(14)
        }
        relocateButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalTo(locateTitle)
        }
        placeRow.snp.makeConstraints {
            $0.leading.equalTo(locateTitle)
            $0.top.equalTo(locateTitle.snp.bottom).offset(4)
            $0.trailing.lessThanOrEqualTo(relocateButton.snp.leading).offset(-8)
        }
        locationCard.sendSubviewToBack(deco)
    }

    private func setupSheet() {
        sheetView.backgroundColor = .fdSurface
        sheetView.layer.cornerRadius = 16
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetView.clipsToBounds = true
        view.addSubview(sheetView)

        let searchBox = UIView()
        searchBox.backgroundColor = .fdProductImageBg
        searchBox.layer.cornerRadius = 12

        let searchIcon = UIImageView(image: .fdNavSearch)
        searchIcon.tintColor = .fdTabInactive
        searchIcon.contentMode = .scaleAspectFit

        searchField.font = .fdFont(ofSize: 16, weight: .regular)
        searchField.textColor = .fdText
        searchField.returnKeyType = .search
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        searchField.attributedPlaceholder = NSAttributedString(
            string: "搜索驿站名称或地址",
            attributes: [
                .font: UIFont.fdFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor.fdTabInactive,
            ]
        )

        clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearButton.tintColor = .fdMuted
        clearButton.isHidden = true
        clearButton.addTarget(self, action: #selector(clearSearch), for: .touchUpInside)

        let bell = UIImageView(image: UIImage(named: "change_phone_hint_bell"))
        bell.contentMode = .scaleAspectFit
        hintLabel.font = .fdFont(ofSize: 14, weight: .regular)
        hintLabel.textColor = .fdSubtext
        hintLabel.text = viewModel.hintText

        let hintRow = UIStackView(arrangedSubviews: [bell, hintLabel])
        hintRow.axis = .horizontal
        hintRow.alignment = .center
        hintRow.spacing = 4

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.register(WellnessCabinListCell.self, forCellReuseIdentifier: WellnessCabinListCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 168
        emptyView.isHidden = true

        searchBox.addSubview(searchIcon)
        searchBox.addSubview(searchField)
        searchBox.addSubview(clearButton)
        sheetView.addSubview(searchBox)
        sheetView.addSubview(hintRow)
        sheetView.addSubview(tableView)
        sheetView.addSubview(emptyView)

        sheetView.snp.makeConstraints {
            $0.top.equalTo(locationCard.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        searchBox.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(47)
        }
        searchIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }
        clearButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(8)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(28)
        }
        searchField.snp.makeConstraints {
            $0.leading.equalTo(searchIcon.snp.trailing).offset(6)
            $0.trailing.equalTo(clearButton.snp.leading).offset(-4)
            $0.top.bottom.equalToSuperview()
        }
        bell.snp.makeConstraints { $0.size.equalTo(14) }
        hintRow.snp.makeConstraints {
            $0.top.equalTo(searchBox.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(hintRow.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.snp.makeConstraints {
            $0.center.equalTo(tableView)
            $0.leading.trailing.equalTo(tableView).inset(24)
        }
    }

    @objc private func relocateTapped() {
        viewModel.refreshLocation()
    }

    @objc private func searchChanged() {
        let text = searchField.text ?? ""
        clearButton.isHidden = text.isEmpty
        viewModel.keyword = text
    }

    @objc private func clearSearch() {
        searchField.text = ""
        clearButton.isHidden = true
        viewModel.keyword = ""
    }

    private func openStore(_ item: CabinStoreVO) {
        guard item.isEnterable else {
            showToastAlert("当前暂不可预约")
            return
        }
        var params: [String: Any] = ["hospitalId": item.id]
        if let distance = item.distanceLabel {
            params["distanceLabel"] = distance
        }
        Router.shared.push("/wellness-cabins/detail", params: params, from: self)
    }
}

extension WellnessCabinViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: WellnessCabinListCell.reuseID,
            for: indexPath
        ) as! WellnessCabinListCell
        cell.configure(viewModel.items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openStore(viewModel.items[indexPath.row])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard viewModel.hasMore, !viewModel.isLoadingMore, !viewModel.isLoadingList else { return }
        let threshold: CGFloat = 100
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        let offset = scrollView.contentOffset.y
        guard contentHeight > 0, offset + frameHeight >= contentHeight - threshold else { return }
        viewModel.loadMore()
    }
}

extension WellnessCabinViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

/// 活动详情。场次和名额下一步再接。
final class WellnessCabinActivityBookViewController: BaseViewController {

    private let hospitalId: String
    private let configId: String

    init(hospitalId: String = "", configId: String = "") {
        self.hospitalId = hospitalId
        self.configId = configId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func setupUI() {
        title = "活动详情"
        view.backgroundColor = .fdBg
        let empty = FDEmptyStateView(style: .page, message: "暂无活动信息")
        empty.accessibilityLabel = "活动 \(configId) 门店 \(hospitalId)"
        view.addSubview(empty)
        empty.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

/// 预约详情。
final class WellnessCabinAppointmentDetailViewController: BaseViewController {

    override func setupUI() {
        title = "预约详情"
        view.backgroundColor = .fdBg
        let empty = FDEmptyStateView(style: .page, message: "暂无预约详情")
        view.addSubview(empty)
        empty.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}
