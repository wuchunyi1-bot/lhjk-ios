import Combine
import Kingfisher
import SnapKit
import UIKit

/// 康养小屋门店详情。列表点卡片或「去门店」进入，带 `hospitalId` 与距离。
final class WellnessCabinDetailViewController: BaseViewController {

    private let viewModel: WellnessCabinDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerHost = UIView()
    private let headerStack = UIStackView()
    private let gallery = CabinGalleryView()
    private let card = UIView()
    private let nameLabel = UILabel()
    private let switchButton = UIButton(type: .system)
    private let distanceRow = UIStackView()
    private let distanceLabel = UILabel()
    private let hoursRow = UIStackView()
    private let hoursLabel = UILabel()
    private let addressRow = UIStackView()
    private let addressLabel = UILabel()
    private let servicesHeading = UILabel()
    private let segment = UIView()
    private let segmentWrap = UIView()
    private let segmentStack = UIStackView()
    private let footer = UIView()
    private let footerLabel = UILabel()
    private let footerSpinner = UIActivityIndicatorView(style: .medium)
    private let pageSpinner = UIActivityIndicatorView(style: .large)
    private let missingView = FDEmptyStateView(style: .page, message: "未找到该驿站")
    private let backToListButton = UIButton(type: .system)
    private let recordsButton = UIButton(type: .system)
    private var lastHeaderHeight: CGFloat = 0
    private var categoryRenderKey = ""

    init(hospitalId: String = "", distanceLabel: String? = nil) {
        viewModel = WellnessCabinDetailViewModel(hospitalId: hospitalId, distanceLabel: distanceLabel)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        title = "门店详情"
        setupRecordsButton()
        setupHeader()
        setupTable()
        setupMissing()
        setupPageSpinner()
    }

    override func bindViewModel() {
        viewModel.$store
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)
        viewModel.$categories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)
        viewModel.$selectedCategoryId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)
        viewModel.$services
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)
        viewModel.$isLoadingServices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)
        viewModel.$isMissing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let message, !message.isEmpty else { return }
                self?.showToastAlert(message)
                self?.viewModel.clearError()
            }
            .store(in: &cancellables)

        viewModel.load()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderFrame()
    }

    override func refreshForSeniorMode() {
        super.refreshForSeniorMode()
        categoryRenderKey = ""
        render()
    }

    private func render() {
        let hasStore = viewModel.store != nil && !viewModel.isMissing
        tableView.isHidden = !hasStore
        missingView.isHidden = !viewModel.isMissing
        backToListButton.isHidden = !viewModel.isMissing
        pageSpinner.isHidden = !viewModel.isLoading
        if viewModel.isLoading {
            pageSpinner.startAnimating()
        } else {
            pageSpinner.stopAnimating()
        }
        navigationItem.rightBarButtonItem = hasStore ? UIBarButtonItem(customView: recordsButton) : nil
        title = hasStore ? nil : "门店详情"

        guard let store = viewModel.store else { return }
        nameLabel.text = store.name
        gallery.setURLs(store.galleryURLs)

        if let distance = viewModel.distanceText {
            distanceRow.isHidden = false
            distanceLabel.text = distance
        } else {
            distanceRow.isHidden = true
        }

        if let openTime = store.openTime, !openTime.isEmpty {
            hoursRow.isHidden = false
            hoursLabel.text = openTime
        } else {
            hoursRow.isHidden = true
        }

        if store.placeLine.isEmpty {
            addressRow.isHidden = true
        } else {
            addressRow.isHidden = false
            addressLabel.text = store.placeLine
        }

        var margins = headerStack.layoutMargins
        margins.top = store.galleryURLs.isEmpty ? 12 : 0
        headerStack.layoutMargins = margins
        rebuildCategoriesIfNeeded()
        updateFooter()
        tableView.reloadData()
        updateHeaderFrame()
    }

    private func setupRecordsButton() {
        recordsButton.setTitle("预约记录", for: .normal)
        recordsButton.setTitleColor(.fdText, for: .normal)
        recordsButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .semibold)
        recordsButton.addTarget(self, action: #selector(recordsTapped), for: .touchUpInside)
    }

    private func setupHeader() {
        headerStack.axis = .vertical
        headerStack.spacing = 12
        headerStack.isLayoutMarginsRelativeArrangement = true
        headerStack.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)

        setupCard()

        servicesHeading.text = "服务项目"
        servicesHeading.font = .fdFont(ofSize: 17, weight: .semibold)
        servicesHeading.textColor = .fdText

        segment.backgroundColor = .fdBg2
        segment.layer.cornerRadius = 23
        segmentStack.axis = .horizontal
        segmentStack.spacing = 6
        segmentStack.distribution = .fillEqually
        segment.addSubview(segmentStack)
        segmentStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))
            $0.height.equalTo(36)
        }

        let headingWrap = inset(servicesHeading, horizontal: 16)
        segmentWrap.addSubview(segment)
        segment.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        let cardWrap = inset(card, horizontal: 16)

        headerStack.addArrangedSubview(gallery)
        headerStack.addArrangedSubview(cardWrap)
        headerStack.addArrangedSubview(headingWrap)
        headerStack.addArrangedSubview(segmentWrap)
        headerStack.setCustomSpacing(16, after: cardWrap)

        headerHost.addSubview(headerStack)
        headerStack.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }
        headerHost.translatesAutoresizingMaskIntoConstraints = true
    }

    private func setupCard() {
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdBorder.cgColor

        nameLabel.font = .fdFont(ofSize: 20, weight: .semibold)
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 0

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        switchButton.setImage(UIImage(systemName: "storefront", withConfiguration: iconConfig), for: .normal)
        switchButton.tintColor = .fdSuccess
        switchButton.backgroundColor = .fdSuccessSoft
        switchButton.layer.cornerRadius = 14
        switchButton.accessibilityLabel = "切换门店"
        switchButton.addTarget(self, action: #selector(switchStoreTapped), for: .touchUpInside)

        let titleRow = UIStackView(arrangedSubviews: [nameLabel, switchButton])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 10

        distanceLabel.font = .fdFont(ofSize: 14, weight: .semibold)
        distanceLabel.textColor = .fdInfo
        distanceRow.addArrangedSubview(symbol("location.north.line", tint: .fdInfo))
        distanceRow.addArrangedSubview(distanceLabel)
        distanceRow.axis = .horizontal
        distanceRow.alignment = .center
        distanceRow.spacing = 4

        hoursLabel.font = .fdFont(ofSize: 14, weight: .regular)
        hoursLabel.textColor = .fdSubtext
        hoursLabel.numberOfLines = 0
        hoursRow.addArrangedSubview(symbol("clock", tint: .fdSubtext))
        hoursRow.addArrangedSubview(hoursLabel)
        hoursRow.axis = .horizontal
        hoursRow.alignment = .center
        hoursRow.spacing = 8

        addressLabel.font = .fdFont(ofSize: 14, weight: .regular)
        addressLabel.textColor = .fdSubtext
        addressLabel.numberOfLines = 0
        let pin = symbol("mappin.and.ellipse", tint: .fdSubtext)
        addressRow.addArrangedSubview(pin)
        addressRow.addArrangedSubview(addressLabel)
        addressRow.axis = .horizontal
        addressRow.alignment = .top
        addressRow.spacing = 8

        let navigateButton = actionButton(title: "导去门店", systemName: "location.north.line", filled: true)
        navigateButton.addTarget(self, action: #selector(navigateTapped), for: .touchUpInside)
        let phoneButton = actionButton(title: "电话咨询", systemName: "phone", filled: false)
        phoneButton.addTarget(self, action: #selector(phoneTapped), for: .touchUpInside)
        let actions = UIStackView(arrangedSubviews: [navigateButton, phoneButton])
        actions.axis = .horizontal
        actions.spacing = 8
        actions.distribution = .fillEqually

        let divider = UIView()
        divider.backgroundColor = .fdBorder

        let actionBlock = UIStackView(arrangedSubviews: [divider, actions])
        actionBlock.axis = .vertical
        actionBlock.spacing = 12

        let stack = UIStackView(arrangedSubviews: [titleRow, distanceRow, hoursRow, addressRow, actionBlock])
        stack.axis = .vertical
        stack.spacing = 10
        stack.setCustomSpacing(12, after: addressRow)

        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        switchButton.snp.makeConstraints { $0.size.equalTo(28) }
        divider.snp.makeConstraints { $0.height.equalTo(1.0 / UIScreen.main.scale) }
        navigateButton.snp.makeConstraints { $0.height.equalTo(34) }
    }

    private func setupTable() {
        tableView.backgroundColor = .fdBg
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 92
        tableView.contentInset.bottom = 24
        tableView.register(WellnessCabinServiceItemCell.self, forCellReuseIdentifier: WellnessCabinServiceItemCell.reuseID)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        tableView.tableHeaderView = headerHost

        footerLabel.font = .fdFont(ofSize: 14, weight: .regular)
        footerLabel.textColor = .fdMuted
        footerLabel.textAlignment = .center
        footerSpinner.color = .fdPrimary
        footer.addSubview(footerLabel)
        footer.addSubview(footerSpinner)
        footerLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        footerSpinner.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    private func setupMissing() {
        backToListButton.setTitle("返回列表", for: .normal)
        backToListButton.setTitleColor(.white, for: .normal)
        backToListButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        backToListButton.backgroundColor = .fdPrimary
        backToListButton.layer.cornerRadius = 8
        backToListButton.addTarget(self, action: #selector(switchStoreTapped), for: .touchUpInside)
        missingView.isHidden = true
        backToListButton.isHidden = true
        view.addSubview(missingView)
        view.addSubview(backToListButton)
        missingView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-24)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(220)
        }
        backToListButton.snp.makeConstraints {
            $0.top.equalTo(missingView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(120)
            $0.height.equalTo(36)
        }
    }

    private func setupPageSpinner() {
        pageSpinner.color = .fdPrimary
        pageSpinner.hidesWhenStopped = true
        view.addSubview(pageSpinner)
        pageSpinner.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    private func rebuildCategoriesIfNeeded() {
        let key = viewModel.categories.map { category in
            "\(category.id)#\(category.id == viewModel.selectedCategoryId ? "1" : "0")"
        }.joined(separator: "|")
        segmentWrap.isHidden = viewModel.categories.isEmpty
        guard key != categoryRenderKey else { return }
        categoryRenderKey = key
        segmentStack.arrangedSubviews.forEach {
            segmentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        for category in viewModel.categories {
            let selected = category.id == viewModel.selectedCategoryId
            let button = UIButton(type: .system)
            button.setTitle(category.name, for: .normal)
            button.setImage(
                UIImage(systemName: iconName(for: category), withConfiguration: iconConfig),
                for: .normal
            )
            button.tintColor = selected ? .fdPrimary : .fdSubtext
            button.setTitleColor(selected ? .fdPrimary : .fdSubtext, for: .normal)
            button.titleLabel?.font = .fdFont(ofSize: 13, weight: selected ? .semibold : .medium)
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.backgroundColor = selected ? .fdSurface : .clear
            button.layer.cornerRadius = 18
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
            button.addAction(UIAction { [weak self] _ in
                self?.viewModel.selectCategory(category.id)
            }, for: .touchUpInside)
            segmentStack.addArrangedSubview(button)
        }
    }

    private func updateFooter() {
        if viewModel.isLoadingServices {
            footerLabel.text = nil
            footerSpinner.startAnimating()
            footer.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 56)
        } else if viewModel.services.isEmpty {
            footerSpinner.stopAnimating()
            footerLabel.text = viewModel.categories.isEmpty ? "暂无服务项目" : "暂无项目"
            footer.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 56)
        } else {
            footerSpinner.stopAnimating()
            footerLabel.text = nil
            footer.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 12)
        }
        tableView.tableFooterView = footer
    }

    private func updateHeaderFrame() {
        let width = tableView.bounds.width
        guard width > 0, viewModel.store != nil else { return }
        headerHost.bounds.size.width = width
        headerHost.setNeedsLayout()
        headerHost.layoutIfNeeded()
        let height = headerStack.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        guard height > 0, abs(height - lastHeaderHeight) > 0.5 else { return }
        lastHeaderHeight = height
        headerHost.frame = CGRect(x: 0, y: 0, width: width, height: height)
        tableView.tableHeaderView = headerHost
    }

    private func iconName(for category: CabinCategoryVO) -> String {
        if category.isActivity { return "calendar" }
        if category.name.contains("理疗") { return "cross.case" }
        if category.name.contains("设备") || category.name.contains("检测") { return "waveform.path.ecg" }
        return "square.grid.2x2"
    }

    private func symbol(_ name: String, tint: UIColor) -> UIImageView {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let view = UIImageView(image: UIImage(systemName: name, withConfiguration: config))
        view.tintColor = tint
        view.contentMode = .scaleAspectFit
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.snp.makeConstraints { $0.size.equalTo(16) }
        return view
    }

    private func actionButton(title: String, systemName: String, filled: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.titleLabel?.font = .fdFont(ofSize: 13, weight: .medium)
        button.layer.cornerRadius = 17
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        if filled {
            button.backgroundColor = .fdPrimary
            button.tintColor = .white
            button.setTitleColor(.white, for: .normal)
        } else {
            button.backgroundColor = .fdSurface
            button.tintColor = .fdText
            button.setTitleColor(.fdText, for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.fdBorder.cgColor
        }
        return button
    }

    private func inset(_ content: UIView, horizontal: CGFloat) -> UIView {
        let wrap = UIView()
        wrap.addSubview(content)
        content.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(horizontal)
        }
        return wrap
    }

    @objc private func recordsTapped() {
        Router.shared.push("/wellness-cabins/appointments", from: self)
    }

    @objc private func switchStoreTapped() {
        if let nav = navigationController,
           let list = nav.viewControllers.last(where: { $0 is WellnessCabinViewController }) {
            nav.popToViewController(list, animated: true)
            return
        }
        Router.shared.push("/wellness-cabins", from: self)
    }

    @objc private func navigateTapped() {
        guard let store = viewModel.store, let coordinate = store.coordinate else {
            showToastAlert("暂无门店位置")
            return
        }
        let name = store.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? store.name
        let raw = "https://uri.amap.com/navigation?to=\(coordinate.longitude),\(coordinate.latitude),\(name)&mode=car&coordinate=gaode&callnative=1&src=lhjk"
        guard let url = URL(string: raw) else {
            showToastAlert("暂无门店位置")
            return
        }
        UIApplication.shared.open(url)
    }

    @objc private func phoneTapped() {
        let digits = (viewModel.store?.mobile ?? "").filter { $0.isNumber }
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else {
            showToastAlert("暂无联系电话")
            return
        }
        UIApplication.shared.open(url)
    }

    private func book(_ item: CabinConfigItemVO) {
        let path = viewModel.selectedCategory?.isActivity == true
            ? "/wellness-cabins/activity"
            : "/wellness-cabins/book"
        var params: [String: Any] = [
            "hospitalId": viewModel.hospitalId,
            "configId": item.id,
            "internalOnly": viewModel.store?.internalOnly == 1 ? "1" : "0",
        ]
        if let price = item.plainPrice {
            params["price"] = price
        }
        if let unitName = item.unitName, !unitName.isEmpty {
            params["unitName"] = unitName
        }
        if let distance = viewModel.distanceText {
            params["distanceLabel"] = distance
        }
        Router.shared.push(path, params: params, from: self)
    }
}

extension WellnessCabinDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.services.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: WellnessCabinServiceItemCell.reuseID,
            for: indexPath
        ) as! WellnessCabinServiceItemCell
        let item = viewModel.services[indexPath.row]
        cell.configure(
            item,
            isFirst: indexPath.row == 0,
            isLast: indexPath.row == viewModel.services.count - 1
        )
        cell.onBook = { [weak self] in
            self?.book(item)
        }
        return cell
    }
}

private final class CabinGalleryView: UIView, UIScrollViewDelegate {

    private let scroll = UIScrollView()
    private let pageControl = UIPageControl()
    private var imageViews: [UIImageView] = []
    private var heightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdProductImageBg
        scroll.isPagingEnabled = true
        scroll.showsHorizontalScrollIndicator = false
        scroll.bounces = false
        scroll.delegate = self
        pageControl.currentPageIndicatorTintColor = .fdPrimary
        pageControl.pageIndicatorTintColor = .fdBorderStrong
        pageControl.isUserInteractionEnabled = false
        addSubview(scroll)
        addSubview(pageControl)
        scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        pageControl.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-6)
        }
        snp.makeConstraints { heightConstraint = $0.height.equalTo(160).constraint }
    }

    required init?(coder: NSCoder) { fatalError() }

    func setURLs(_ urls: [URL]) {
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews = urls.map { url in
            let image = UIImageView()
            image.contentMode = .scaleAspectFill
            image.clipsToBounds = true
            image.backgroundColor = .fdProductImageBg
            image.kf.setImage(with: url)
            scroll.addSubview(image)
            return image
        }
        pageControl.numberOfPages = urls.count
        pageControl.currentPage = 0
        pageControl.isHidden = urls.count <= 1
        isHidden = urls.isEmpty
        heightConstraint?.update(offset: urls.isEmpty ? 0 : 160)
        scroll.contentOffset = .zero
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        let height = bounds.height
        guard width > 0, height > 0 else { return }
        scroll.contentSize = CGSize(width: width * CGFloat(max(imageViews.count, 1)), height: height)
        for (index, image) in imageViews.enumerated() {
            image.frame = CGRect(x: width * CGFloat(index), y: 0, width: width, height: height)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.width
        guard width > 0 else { return }
        pageControl.currentPage = Int(round(scrollView.contentOffset.x / width))
    }
}
