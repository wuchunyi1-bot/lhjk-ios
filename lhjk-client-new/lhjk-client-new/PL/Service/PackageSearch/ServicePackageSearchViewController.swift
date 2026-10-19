import UIKit
import SnapKit
import Combine

/// 搜索页 — `GET /v1/hospitalPackage/searchEnabledPackagePage`
/// 分组：健康服务（当前机构）、富德优选。健康知识后续再接。
final class ServicePackageSearchViewController: BaseViewController {

    private let viewModel: ServicePackageSearchViewModel
    private var cancellables = Set<AnyCancellable>()
    private var renderedTab: PackageSearchTab = .service

    private let searchField: UITextField = {
        let field = UITextField()
        field.placeholder = "搜索套餐、商品或知识"
        field.font = .fdBody
        field.textColor = .fdText
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .search
        field.autocorrectionType = .no
        return field
    }()

    private let searchContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .fdSurface
        view.layer.cornerRadius = 22
        view.clipsToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.fdBorder.cgColor
        return view
    }()

    private let searchIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iv.tintColor = .fdMuted
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("搜索", for: .normal)
        button.setTitleColor(.fdPrimary, for: .normal)
        button.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    private let historyPanel = UIView()
    private let historyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "历史搜索"
        label.font = .fdFont(ofSize: 16, weight: .medium)
        label.textColor = .fdText
        return label
    }()
    private let clearHistoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("清空", for: .normal)
        button.setTitleColor(.fdSubtext, for: .normal)
        button.titleLabel?.font = .fdFont(ofSize: 16, weight: .regular)
        return button
    }()
    private let historyWrap = PackageSearchHistoryWrapView()

    private let resultTabBar = UIView()
    private let serviceTabButton = UIButton(type: .system)
    private let mallTabButton = UIButton(type: .system)
    private let tabIndicator = UIView()
    private var tabBarHeight: Constraint?

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.keyboardDismissMode = .onDrag
        tv.register(HealthPackageCardCell.self, forCellReuseIdentifier: HealthPackageCardCell.reuseID)
        tv.dataSource = self
        tv.delegate = self
        return tv
    }()

    private let emptyView = FDEmptyStateView(style: .page, message: "未找到相关套餐")

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    init(hospitalId: String? = nil) {
        self.viewModel = ServicePackageSearchViewModel(hospitalId: hospitalId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func setupUI() {
        title = "搜索套餐"
        view.backgroundColor = .fdBg

        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(searchField)
        historyPanel.addSubview(historyTitleLabel)
        historyPanel.addSubview(clearHistoryButton)
        historyPanel.addSubview(historyWrap)
        tabIndicator.backgroundColor = .fdPrimary
        tabIndicator.layer.cornerRadius = 1
        resultTabBar.addSubview(serviceTabButton)
        resultTabBar.addSubview(mallTabButton)
        resultTabBar.addSubview(tabIndicator)
        resultTabBar.clipsToBounds = true
        view.addSubview(searchContainer)
        view.addSubview(searchButton)
        view.addSubview(resultTabBar)
        view.addSubview(tableView)
        view.addSubview(historyPanel)
        view.addSubview(emptyView)
        emptyView.isHidden = true
        historyPanel.isHidden = true
        resultTabBar.isHidden = true
        view.addSubview(activityIndicator)

        searchIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(18)
        }
        searchField.snp.makeConstraints {
            $0.leading.equalTo(searchIcon.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().offset(-12)
            $0.top.bottom.equalToSuperview().inset(10)
        }
        searchButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(searchContainer)
        }
        searchContainer.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalTo(searchButton.snp.leading).offset(-8)
            $0.height.greaterThanOrEqualTo(44)
        }
        serviceTabButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.bottom.equalToSuperview()
        }
        mallTabButton.snp.makeConstraints {
            $0.leading.equalTo(serviceTabButton.snp.trailing).offset(22)
            $0.top.bottom.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview().inset(16)
        }
        resultTabBar.snp.makeConstraints {
            $0.top.equalTo(searchContainer.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview()
            tabBarHeight = $0.height.equalTo(0).constraint
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(resultTabBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        historyPanel.snp.makeConstraints { $0.edges.equalTo(tableView) }
        historyTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(16)
        }
        clearHistoryButton.snp.makeConstraints {
            $0.centerY.equalTo(historyTitleLabel)
            $0.trailing.equalToSuperview().inset(16)
            $0.leading.greaterThanOrEqualTo(historyTitleLabel.snp.trailing).offset(12)
        }
        historyWrap.snp.makeConstraints {
            $0.top.equalTo(historyTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.lessThanOrEqualToSuperview()
        }
        emptyView.snp.makeConstraints { $0.edges.equalTo(tableView) }
        activityIndicator.snp.makeConstraints { $0.center.equalTo(tableView) }

        searchField.delegate = self
        searchField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        serviceTabButton.addTarget(self, action: #selector(serviceTabTapped), for: .touchUpInside)
        mallTabButton.addTarget(self, action: #selector(mallTabTapped), for: .touchUpInside)
        clearHistoryButton.addTarget(self, action: #selector(clearHistoryTapped), for: .touchUpInside)
        historyWrap.onSelect = { [weak self] keyword in
            self?.searchField.text = keyword
            self?.viewModel.keyword = keyword
            self?.viewModel.search()
            self?.searchField.resignFirstResponder()
            self?.updateResultChrome()
        }
        historyWrap.onDelete = { [weak self] keyword in
            self?.viewModel.removeHistory(keyword)
        }
    }

    override func bindViewModel() {
        Publishers.CombineLatest3(viewModel.$servicePage, viewModel.$mallPage, viewModel.$activeTab)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, tab in
                guard let self else { return }
                let tabChanged = tab != self.renderedTab
                self.renderedTab = tab
                self.tableView.reloadData()
                if tabChanged {
                    self.tableView.setContentOffset(.zero, animated: false)
                }
                self.updateResultChrome()
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
                self?.updateResultChrome()
            }
            .store(in: &cancellables)

        viewModel.$isLoadingMore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.tableView.tableFooterView = loading ? self?.makeLoadingFooter() : UIView()
            }
            .store(in: &cancellables)

        viewModel.$hasSearched
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateResultChrome() }
            .store(in: &cancellables)

        viewModel.$history
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateResultChrome() }
            .store(in: &cancellables)
    }

    private func makeLoadingFooter() -> UIView {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44))
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        footer.addSubview(indicator)
        indicator.center = CGPoint(x: footer.bounds.midX, y: footer.bounds.midY)
        indicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        return footer
    }

    override func refreshForSeniorMode() {
        super.refreshForSeniorMode()
        historyWrap.setKeywords(viewModel.history)
        updateResultChrome()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reloadHistory()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchField.becomeFirstResponder()
    }

    @objc private func textDidChange() {
        viewModel.keyword = searchField.text ?? ""
        viewModel.noteKeywordEdited()
        updateResultChrome()
    }

    @objc private func serviceTabTapped() {
        viewModel.selectTab(.service)
    }

    @objc private func mallTabTapped() {
        viewModel.selectTab(.mall)
    }

    @objc private func searchTapped() {
        submitSearch()
    }

    @objc private func clearHistoryTapped() {
        viewModel.clearHistory()
    }

    private func submitSearch() {
        viewModel.keyword = searchField.text ?? ""
        viewModel.search()
        searchField.text = viewModel.keyword
        searchField.resignFirstResponder()
        updateResultChrome()
    }

    private var showsHistory: Bool {
        let keyword = viewModel.keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        return keyword.isEmpty && !viewModel.hasSearched && !viewModel.history.isEmpty
    }

    private func updateResultChrome() {
        let showingHistory = showsHistory
        let showTabs = viewModel.hasSearched && !showingHistory
        historyPanel.isHidden = !showingHistory
        tableView.isHidden = showingHistory
        resultTabBar.isHidden = !showTabs
        tabBarHeight?.update(offset: showTabs ? 44 : 0)
        if showingHistory {
            historyWrap.setKeywords(viewModel.history)
            emptyView.isHidden = true
            return
        }

        updateTabButtons()

        guard viewModel.hasSearched, !viewModel.isLoading else {
            emptyView.isHidden = true
            return
        }

        let page = viewModel.visiblePage
        if let error = page.errorMessage, !error.isEmpty, page.items.isEmpty {
            emptyView.configure(message: error)
            emptyView.isHidden = false
            return
        }

        if page.items.isEmpty {
            emptyView.configure(message: "没有找到相关内容")
            emptyView.isHidden = false
            return
        }

        emptyView.isHidden = true
    }

    private func updateTabButtons() {
        applyTab(serviceTabButton, tab: .service, page: viewModel.servicePage)
        applyTab(mallTabButton, tab: .mall, page: viewModel.mallPage)
        let selected = viewModel.activeTab == .service ? serviceTabButton : mallTabButton
        tabIndicator.snp.remakeConstraints { make in
            make.bottom.equalToSuperview()
            make.width.equalTo(24)
            make.height.equalTo(2)
            make.centerX.equalTo(selected)
        }
    }

    private func applyTab(_ button: UIButton, tab: PackageSearchTab, page: PackageSearchPage) {
        let selected = viewModel.activeTab == tab
        let count = page.total > 0 ? " \(page.total)" : ""
        button.setTitle(tab.title + count, for: .normal)
        button.setTitleColor(selected ? .fdPrimary : .fdSubtext, for: .normal)
        button.titleLabel?.font = selected
            ? .fdFont(ofSize: 16, weight: .bold)
            : .fdFont(ofSize: 15, weight: .semibold)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension ServicePackageSearchViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.visiblePage.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: HealthPackageCardCell.reuseID,
            for: indexPath
        ) as! HealthPackageCardCell
        let pkg = viewModel.visiblePage.items[indexPath.row]
        let isService = viewModel.activeTab == .service
        cell.configure(pkg, showsProductCode: isService, showsDetailButton: isService)
        cell.onDetailTap = {
            Router.shared.push("/services/detail", params: pkg.packageDetailRouteParams())
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pkg = viewModel.visiblePage.items[indexPath.row]
        Router.shared.push("/services/detail", params: pkg.packageDetailRouteParams())
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row == viewModel.visiblePage.items.count - 1 else { return }
        viewModel.loadMoreIfNeeded()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}

// MARK: - UITextFieldDelegate

extension ServicePackageSearchViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        submitSearch()
        return true
    }
}

// MARK: - 历史搜索标签

private final class PackageSearchHistoryWrapView: UIView {

    var onSelect: ((String) -> Void)?
    var onDelete: ((String) -> Void)?

    private var chips: [PackageSearchHistoryChip] = []
    private var appliedHeight: CGFloat = -1
    private var heightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        snp.makeConstraints { heightConstraint = $0.height.equalTo(0).constraint }
    }

    required init?(coder: NSCoder) { fatalError() }

    func setKeywords(_ keywords: [String]) {
        chips.forEach { $0.removeFromSuperview() }
        chips = keywords.map { keyword in
            let chip = PackageSearchHistoryChip(keyword: keyword)
            chip.onSelect = { [weak self] in self?.onSelect?(keyword) }
            chip.onDelete = { [weak self] in self?.onDelete?(keyword) }
            let size = chip.fittingSize()
            chip.frame = CGRect(origin: .zero, size: size)
            addSubview(chip)
            return chip
        }
        appliedHeight = -1
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        guard width > 1 else { return }
        let spacing: CGFloat = 8
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for chip in chips {
            let size = chip.fittingSize()
            let chipWidth = min(size.width, width)
            if x > 0, x + chipWidth > width + 0.5 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            chip.frame = CGRect(x: x, y: y, width: chipWidth, height: size.height)
            x += chipWidth + spacing
            rowHeight = max(rowHeight, size.height)
        }
        let total = chips.isEmpty ? 0 : y + rowHeight
        guard abs(total - appliedHeight) > 0.5 else { return }
        appliedHeight = total
        heightConstraint?.update(offset: total)
    }
}

private final class PackageSearchHistoryChip: UIView {

    var onSelect: (() -> Void)?
    var onDelete: (() -> Void)?

    private let titleLabel = UILabel()
    private let deleteButton = UIButton(type: .system)

    init(keyword: String) {
        super.init(frame: .zero)
        backgroundColor = .fdBg2
        clipsToBounds = true
        titleLabel.text = keyword
        titleLabel.font = .fdFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = .fdSubtext
        titleLabel.lineBreakMode = .byTruncatingTail
        let symbolSize: CGFloat = UIFont.isSeniorMode ? 12 : 10
        deleteButton.setImage(
            UIImage(
                systemName: "xmark",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .medium)
            ),
            for: .normal
        )
        deleteButton.tintColor = .fdMuted
        addSubview(titleLabel)
        addSubview(deleteButton)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        let deleteSide: CGFloat = UIFont.isSeniorMode ? 22 : 18
        deleteButton.frame = CGRect(
            x: bounds.width - 8 - deleteSide,
            y: (bounds.height - deleteSide) / 2,
            width: deleteSide,
            height: deleteSide
        )
        titleLabel.frame = CGRect(
            x: 12,
            y: 6,
            width: max(0, deleteButton.frame.minX - 4 - 12),
            height: max(0, bounds.height - 12)
        )
    }

    func fittingSize() -> CGSize {
        let height = titleLabel.font.lineHeight + 12
        let deleteSide: CGFloat = UIFont.isSeniorMode ? 22 : 18
        let width = 12 + titleLabel.intrinsicContentSize.width + 4 + deleteSide + 8
        return CGSize(width: ceil(width), height: ceil(height))
    }

    @objc private func tapped() { onSelect?() }
    @objc private func deleteTapped() { onDelete?() }
}
