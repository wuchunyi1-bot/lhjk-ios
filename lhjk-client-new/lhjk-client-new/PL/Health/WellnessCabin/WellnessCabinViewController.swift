import Combine
import SnapKit
import UIKit

/// 康养小屋列表。未选省市区或 GPS 前不展示驿站，空态引导选择地区。
final class WellnessCabinViewController: BaseViewController {

    private let viewModel = WellnessCabinListViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let regionTitle = UILabel()
    private let regionField = UIControl()
    private let regionValueLabel = UILabel()
    private let gpsButton = UIButton(type: .system)
    private let searchBox = UIView()
    private let searchField = UITextField()
    private let clearButton = UIButton(type: .system)
    private let hintLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyStack = UIStackView()
    private let emptyTitle = UILabel()
    private let emptySubtitle = UILabel()
    private let chooseRegionButton = UIButton(type: .system)

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
        setupRegion()
        setupSearch()
        setupList()
    }

    override func bindViewModel() {
        viewModel.$anchor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)

        viewModel.$isLocating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] locating in
                self?.gpsButton.isEnabled = !locating
                self?.gpsButton.setTitle(locating ? "定位中…" : "使用当前 GPS 定位", for: .normal)
            }
            .store(in: &cancellables)

        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)

        viewModel.$isLoadingList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)

        viewModel.$notice
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let message, !message.isEmpty else { return }
                self?.showToastAlert(message)
                self?.viewModel.clearNotice()
            }
            .store(in: &cancellables)

        viewModel.$asksForRegionPicker
            .receive(on: DispatchQueue.main)
            .sink { [weak self] asks in
                guard asks else { return }
                self?.viewModel.consumeRegionPickerRequest()
                self?.openRegionPicker()
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

    private func render() {
        let ready = viewModel.locationReady
        let text = viewModel.anchor?.fieldText ?? ""
        regionValueLabel.text = text.isEmpty ? "请选择省、市、区" : text
        regionValueLabel.textColor = text.isEmpty ? .fdTabInactive : .fdText
        hintLabel.text = viewModel.hintText
        tableView.reloadData()

        let showStores = ready && !viewModel.items.isEmpty
        tableView.isHidden = !showStores
        emptyStack.isHidden = showStores || viewModel.isLoadingList
        if !ready {
            emptyTitle.text = "请选择所在地区"
            emptySubtitle.text = "支持分步选择省份、城市、区县，选完自动按距离排序"
            chooseRegionButton.isHidden = false
        } else {
            emptyTitle.text = "未找到匹配驿站"
            emptySubtitle.text = "请尝试其他关键词，或更换所在地区"
            chooseRegionButton.isHidden = true
        }
    }

    private func setupRegion() {
        regionTitle.text = "定位区域"
        regionTitle.font = .fdFont(ofSize: 14, weight: .regular)
        regionTitle.textColor = .fdSubtext

        regionField.backgroundColor = .fdSurface
        regionField.layer.cornerRadius = 12
        regionField.addTarget(self, action: #selector(regionTapped), for: .touchUpInside)

        let star = UILabel()
        star.text = "*"
        star.font = .fdFont(ofSize: 16, weight: .medium)
        star.textColor = .fdDanger

        let regionName = UILabel()
        regionName.text = "所在地区"
        regionName.font = .fdFont(ofSize: 16, weight: .regular)
        regionName.textColor = .fdText
        regionName.setContentHuggingPriority(.required, for: .horizontal)

        regionValueLabel.font = .fdFont(ofSize: 16, weight: .regular)
        regionValueLabel.textColor = .fdTabInactive
        regionValueLabel.textAlignment = .right
        regionValueLabel.text = "请选择省、市、区"

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .fdTabInactive
        chevron.contentMode = .scaleAspectFit
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [star, regionName, regionValueLabel, chevron])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 4
        row.isUserInteractionEnabled = false
        regionField.addSubview(row)

        gpsButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .regular)
        gpsButton.setTitleColor(.fdPrimary, for: .normal)
        gpsButton.setTitle("使用当前 GPS 定位", for: .normal)
        gpsButton.setImage(UIImage(systemName: "location"), for: .normal)
        gpsButton.tintColor = .fdPrimary
        gpsButton.semanticContentAttribute = .forceLeftToRight
        gpsButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        gpsButton.addTarget(self, action: #selector(gpsTapped), for: .touchUpInside)

        view.addSubview(regionTitle)
        view.addSubview(regionField)
        view.addSubview(gpsButton)

        regionTitle.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            $0.leading.equalToSuperview().inset(20)
        }
        regionField.snp.makeConstraints {
            $0.top.equalTo(regionTitle.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        row.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }
        chevron.snp.makeConstraints { $0.size.equalTo(14) }
        gpsButton.snp.makeConstraints {
            $0.top.equalTo(regionField.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(32)
        }
    }

    private func setupSearch() {
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

        hintLabel.font = .fdFont(ofSize: 14, weight: .regular)
        hintLabel.textColor = .fdSubtext
        hintLabel.numberOfLines = 0
        hintLabel.text = viewModel.hintText

        searchBox.addSubview(searchIcon)
        searchBox.addSubview(searchField)
        searchBox.addSubview(clearButton)
        view.addSubview(searchBox)
        view.addSubview(hintLabel)

        searchBox.snp.makeConstraints {
            $0.top.equalTo(gpsButton.snp.bottom).offset(12)
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
        hintLabel.snp.makeConstraints {
            $0.top.equalTo(searchBox.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }

    private func setupList() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(WellnessCabinListCell.self, forCellReuseIdentifier: WellnessCabinListCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 168

        emptyTitle.font = .fdFont(ofSize: 16, weight: .medium)
        emptyTitle.textColor = .fdText
        emptyTitle.textAlignment = .center
        emptySubtitle.font = .fdFont(ofSize: 14, weight: .regular)
        emptySubtitle.textColor = .fdSubtext
        emptySubtitle.textAlignment = .center
        emptySubtitle.numberOfLines = 0
        chooseRegionButton.setTitle("选择省市区", for: .normal)
        chooseRegionButton.setTitleColor(.white, for: .normal)
        chooseRegionButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        chooseRegionButton.backgroundColor = .fdPrimary
        chooseRegionButton.layer.cornerRadius = 20
        chooseRegionButton.addTarget(self, action: #selector(regionTapped), for: .touchUpInside)

        emptyStack.axis = .vertical
        emptyStack.alignment = .center
        emptyStack.spacing = 8
        emptyStack.addArrangedSubview(emptyTitle)
        emptyStack.addArrangedSubview(emptySubtitle)
        emptyStack.addArrangedSubview(chooseRegionButton)
        emptyStack.setCustomSpacing(16, after: emptySubtitle)

        view.addSubview(tableView)
        view.addSubview(emptyStack)
        tableView.snp.makeConstraints {
            $0.top.equalTo(hintLabel.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        emptyStack.snp.makeConstraints {
            $0.top.equalTo(hintLabel.snp.bottom).offset(48)
            $0.leading.trailing.equalToSuperview().inset(32)
        }
        chooseRegionButton.snp.makeConstraints {
            $0.width.equalTo(160)
            $0.height.equalTo(40)
        }
    }

    @objc private func regionTapped() {
        openRegionPicker()
    }

    @objc private func gpsTapped() {
        viewModel.useCurrentGPS()
    }

    private func openRegionPicker() {
        let current = viewModel.anchor?.region ?? RegionSelection()
        let sheet = RegionPickerSheet(
            title: "所在地区",
            mode: .provinceCityArea,
            current: current,
            sheetTitle: "选择所在地区"
        )
        sheet.onSave = { [weak self] selection in
            self?.viewModel.applyManualRegion(selection)
        }
        present(sheet, animated: true)
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
        if item.restFlag {
            showToastAlert("当前休息中，暂不可预约")
            return
        }
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
        viewModel.locationReady ? viewModel.items.count : 0
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
