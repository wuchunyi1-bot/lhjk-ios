import UIKit
import SnapKit
import Combine

/// 选择服务机构 — 对齐 Figma `5336:15506`
final class InstitutionSelectViewController: BaseViewController {

    private let viewModel: InstitutionSelectViewModel
    private var cancellables = Set<AnyCancellable>()

    /// 选中后回调（Onboarding 等场景）；为 nil 时仅写入 InstitutionSelectionStore 并 pop
    var onInstitutionSelected: ((SelectedServiceInstitution) -> Void)?

    private let locationCard = UIView()
    private let cityLabel = UILabel()
    private let districtLabel = UILabel()
    private let relocateButton = UIButton(type: .system)
    private let sheetView = UIView()
    private let searchField = UITextField()
    private let clearButton = UIButton(type: .system)
    private let hintLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = FDEmptyStateView(style: .compact, message: "未找到匹配机构\n请尝试搜索机构名称或详细地址")

    init(selectedId: String? = nil) {
        self.viewModel = InstitutionSelectViewModel(selectedId: selectedId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        title = "选择服务机构"
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

    @objc private func backTapped() {
        view.endEditing(true)
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
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
            }
            .store(in: &cancellables)

        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self else { return }
                self.tableView.reloadData()
                self.emptyView.isHidden = !items.isEmpty || self.viewModel.isLoadingList
            }
            .store(in: &cancellables)

        viewModel.$isLoadingList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                guard let self else { return }
                self.emptyView.isHidden = !self.viewModel.items.isEmpty || loading
            }
            .store(in: &cancellables)

        viewModel.$selectedId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        viewModel.onAppear()
    }

    // MARK: - UI pieces

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

        relocateButton.setTitle("重新定位", for: .normal)
        relocateButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .regular)
        relocateButton.setTitleColor(.fdPrimary, for: .normal)
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
        searchField.clearButtonMode = .never
        searchField.returnKeyType = .search
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        searchField.delegate = self
        searchField.attributedPlaceholder = NSAttributedString(
            string: "搜索机构名称或地址",
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
        hintLabel.text = "以下为可选择的服务机构"

        let hintRow = UIStackView(arrangedSubviews: [bell, hintLabel])
        hintRow.axis = .horizontal
        hintRow.alignment = .center
        hintRow.spacing = 4

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.alwaysBounceVertical = true
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.register(InstitutionSelectCell.self, forCellReuseIdentifier: InstitutionSelectCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 96

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
            $0.edges.equalTo(tableView)
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
}

extension InstitutionSelectViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: InstitutionSelectCell.reuseID,
            for: indexPath
        ) as! InstitutionSelectCell
        let item = viewModel.items[indexPath.row]
        cell.configure(item: item, isSelected: item.id == viewModel.selectedId)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewModel.items[indexPath.row]
        viewModel.select(item)
        let selected = SelectedServiceInstitution(vo: item)
        onInstitutionSelected?(selected)
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
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

extension InstitutionSelectViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
