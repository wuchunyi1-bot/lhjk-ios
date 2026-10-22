import UIKit
import SnapKit
import Combine

/// 富德优选商城 — 对齐 Figma 4054:2991（分类 Tab + 双列商品网格，卡片比例随屏宽等比缩放）
final class HealthMallViewController: BaseViewController {

    private let viewModel = HealthMallViewModel()
    private var cancellables = Set<AnyCancellable>()
    /// 嵌在首页页签里时不改导航栏。
    private let embedsInHomeHub: Bool
    private var banners: [ServiceHubBanner] = []
    private var bannerHeight: CGFloat = 0
    private var bannerLoadTask: Task<Void, Never>?
    /// 首页嵌入时 Banner 和分类栏在列表外面。这里记着 Banner 已经收起了多少，和列表滚动位置无关，
    /// 所以换分类、列表变短都不会让它弹回来。
    private var bannerCollapsed: CGFloat = 0
    private var lastScrollOffset: CGFloat = 0
    private var adjustingOffset = false
    private var renderedProducts: [HealthPackageItem] = []
    private let headerBlock = UIView()
    private var headerTopConstraint: Constraint?
    private var bannerHeightConstraint: Constraint?
    private lazy var bannerPan: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(bannerPanned(_:)))
        pan.delegate = self
        return pan
    }()
    private let productSection = 0

    init(embedsInHomeHub: Bool = false) {
        self.embedsInHomeHub = embedsInHomeHub
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let categoryTabBar = MallCategoryTabBar()
    private var lastCollectionWidth: CGFloat = 0

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = MallProductCell.columnSpacing
        layout.minimumLineSpacing = MallProductCell.rowSpacing
        layout.sectionInset = UIEdgeInsets(
            top: 10,
            left: MallProductCell.sectionInset,
            bottom: 24,
            right: MallProductCell.sectionInset
        )
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        if embedsInHomeHub {
            cv.contentInsetAdjustmentBehavior = .never
            // 商品很少时也要能上推，把 Banner 收起来
            cv.alwaysBounceVertical = true
        }
        cv.register(MallProductCell.self, forCellWithReuseIdentifier: MallProductCell.reuseID)
        cv.register(MallEmptyStateCell.self, forCellWithReuseIdentifier: MallEmptyStateCell.reuseID)
        cv.register(
            MallLoadMoreFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: MallLoadMoreFooterView.reuseID
        )
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private lazy var shelfBannerCarousel: ServiceBannerCarouselCell = {
        let cell = ServiceBannerCarouselCell(style: .default, reuseIdentifier: nil)
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.onBannerTap = { [weak self] banner in
            self?.openShelfBanner(banner)
        }
        cell.onHeightUpdated = { [weak self, weak cell] in
            self?.adoptShelfBannerHeight(from: cell)
        }
        return cell
    }()

    private let emptyStateView = FDEmptyStateView(style: .page, message: "该分类暂无商品，敬请期待")

    private let loadingIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        return spinner
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if !embedsInHomeHub {
            title = "富德优选"
        }
        viewModel.load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !embedsInHomeHub else {
            loadShelfBanners()
            return
        }
        navigationController?.setNavigationBarHidden(false, animated: animated)
        configureNavigationBarAppearance()
    }

    private func configureNavigationBarAppearance() {
        guard let navigationController else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hexString: "#FDF6F3")
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(hexString: "#1F2942"),
            .font: UIFont.fdFont(ofSize: 18, weight: .medium)
        ]
        let backImage = UIImage.fdNavBack
        appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        backButtonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.backButtonAppearance = backButtonAppearance

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = UIColor(hexString: "#1F2942")
    }

    override func setupUI() {
        view.backgroundColor = UIColor(hexString: "#FDF6F3")

        categoryTabBar.onTabSelected = { [weak self] index in
            self?.viewModel.selectTab(at: index)
        }

        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        view.addSubview(loadingIndicator)

        if embedsInHomeHub {
            view.clipsToBounds = true
            categoryTabBar.backgroundColor = UIColor(hexString: "#FDF6F3")
            headerBlock.backgroundColor = UIColor(hexString: "#FDF6F3")
            view.addSubview(headerBlock)
            headerBlock.addSubview(shelfBannerCarousel)
            headerBlock.addSubview(categoryTabBar)
            shelfBannerCarousel.isHidden = true
            shelfBannerCarousel.addGestureRecognizer(bannerPan)
            headerBlock.snp.makeConstraints {
                headerTopConstraint = $0.top.equalToSuperview().constraint
                $0.leading.trailing.equalToSuperview()
            }
            shelfBannerCarousel.snp.makeConstraints {
                $0.top.leading.trailing.equalToSuperview()
                bannerHeightConstraint = $0.height.equalTo(0).constraint
            }
            categoryTabBar.snp.makeConstraints {
                $0.top.equalTo(shelfBannerCarousel.snp.bottom)
                $0.leading.trailing.bottom.equalToSuperview()
                $0.height.equalTo(52)
            }
            collectionView.snp.makeConstraints {
                $0.top.equalTo(headerBlock.snp.bottom)
                $0.leading.trailing.bottom.equalToSuperview()
            }
        } else {
            view.addSubview(categoryTabBar)
            categoryTabBar.snp.makeConstraints {
                $0.top.equalTo(view.safeAreaLayoutGuide)
                $0.leading.trailing.equalToSuperview()
                $0.height.equalTo(48)
            }
            collectionView.snp.makeConstraints {
                $0.top.equalTo(categoryTabBar.snp.bottom)
                $0.leading.trailing.bottom.equalToSuperview()
            }
        }
        emptyStateView.isHidden = true
        emptyStateView.snp.makeConstraints {
            $0.edges.equalTo(collectionView)
        }
        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(collectionView)
        }
    }

    private func loadShelfBanners() {
        bannerLoadTask?.cancel()
        bannerLoadTask = Task { [weak self] in
            let items = await AppContainer.shared.columnContentCacheService.banners(
                for: ColumnContentService.hospitalBannerCode
            )
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.applyShelfBanners(items.filter(\.hasImage))
            }
        }
    }

    private func applyShelfBanners(_ items: [ServiceHubBanner]) {
        let same = banners.map(\.id) == items.map(\.id)
        banners = items
        guard !items.isEmpty else {
            shelfBannerCarousel.isHidden = true
            applyEmbeddedBannerHeight(0)
            return
        }
        shelfBannerCarousel.isHidden = false
        if !same {
            shelfBannerCarousel.configure(items)
        }
        guard !same || bannerHeight < 1 else { return }
        let width = view.bounds.width > 1 ? view.bounds.width : UIScreen.main.bounds.width
        applyEmbeddedBannerHeight(
            BannerImageAspectLayout.height(
                width: max(0, width - ServiceBannerCarouselCell.horizontalInset * 2),
                imageSize: nil,
                fallbackRatio: ServiceBannerCarouselCell.fallbackRatio
            )
        )
    }

    private func adoptShelfBannerHeight(from cell: ServiceBannerCarouselCell?) {
        guard let cell else { return }
        let width = view.bounds.width > 1 ? view.bounds.width : UIScreen.main.bounds.width
        let height = cell.systemLayoutSizeFitting(
            CGSize(width: width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        applyEmbeddedBannerHeight(height)
    }

    private func openShelfBanner(_ banner: ServiceHubBanner) {
        if FundePageURL.open(banner.pageUrl, from: self) { return }
        guard let path = banner.routePath else { return }
        if let id = banner.routeParamId {
            Router.shared.push(path, params: ["id": id])
        } else {
            Router.shared.push(path)
        }
    }

    /// Banner 高度变了：按比例保留已收起的量，已经全收起的就继续全收起。
    private func applyEmbeddedBannerHeight(_ height: CGFloat) {
        let next = max(0, height)
        let previous = bannerHeight
        guard abs(next - previous) > 0.5 else { return }
        bannerHeight = next
        if previous > 1, next > 1 {
            bannerCollapsed = min(next, bannerCollapsed / previous * next)
        } else {
            bannerCollapsed = min(bannerCollapsed, next)
        }
        bannerHeightConstraint?.update(offset: next)
        applyBannerCollapse()
    }

    private func applyBannerCollapse() {
        headerTopConstraint?.update(offset: -bannerCollapsed)
    }

    /// 商品变了。加载更多只往后插入，换分类整段刷新。换分类不动 Banner 的收起量。
    private func reloadProducts() {
        let next = viewModel.products
        let previous = renderedProducts
        renderedProducts = next
        let appended = !previous.isEmpty
            && next.count > previous.count
            && Array(next.prefix(previous.count)) == previous
            && collectionView.numberOfSections > productSection
            && collectionView.numberOfItems(inSection: productSection) == previous.count
        if appended {
            let paths = (previous.count..<next.count).map { IndexPath(item: $0, section: productSection) }
            UIView.performWithoutAnimation {
                collectionView.performBatchUpdates({
                    collectionView.insertItems(at: paths)
                })
            }
            return
        }
        UIView.performWithoutAnimation {
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
        lastScrollOffset = collectionView.contentOffset.y
    }

    // MARK: - Banner 跟随滚动（仅首页嵌入）

    /// 列表还在顶部时，上推先把 Banner 推走，收完才滚商品；下拉到顶后，多出来的部分再把 Banner 放出来。
    private func absorbScroll(_ scrollView: UIScrollView) {
        guard embedsInHomeHub, !adjustingOffset else { return }
        let rest = -scrollView.adjustedContentInset.top
        let current = scrollView.contentOffset.y
        guard bannerHeight > 1 else {
            lastScrollOffset = current
            return
        }
        let previous = lastScrollOffset
        let delta = current - previous
        guard abs(delta) > 0.5 else {
            lastScrollOffset = current
            return
        }
        let remaining = bannerHeight - bannerCollapsed
        var nextCollapsed = bannerCollapsed
        var nextOffset = current
        // 只有越过顶部（rest）之上的那一段才算上滑。下拉回弹时偏移是从负数回到 0，不能算。
        let scrolledUp = current - max(previous, rest)
        if delta > 0, current > rest, scrolledUp > 0, remaining > 0.5 {
            let consume = min(scrolledUp, remaining)
            nextCollapsed += consume
            nextOffset = current - consume
        } else if delta < 0, bannerCollapsed > 0.5, current < rest {
            let pulled = min(-delta, rest - current)
            let reveal = min(pulled, bannerCollapsed)
            nextCollapsed -= reveal
            nextOffset = current + reveal
        } else {
            lastScrollOffset = current
            return
        }
        bannerCollapsed = nextCollapsed
        applyBannerCollapse()
        lastScrollOffset = nextOffset
        guard abs(nextOffset - current) > 0.5 else { return }
        adjustingOffset = true
        scrollView.contentOffset.y = nextOffset
        adjustingOffset = false
    }

    @objc private func bannerPanned(_ pan: UIPanGestureRecognizer) {
        let dy = pan.translation(in: view).y
        pan.setTranslation(.zero, in: view)
        guard bannerHeight > 1 else { return }
        let rest = -collectionView.adjustedContentInset.top
        if dy < 0 {
            let delta = -dy
            let consume = min(delta, max(0, bannerHeight - bannerCollapsed))
            bannerCollapsed += consume
            let restDelta = delta - consume
            if restDelta > 0 {
                adjustingOffset = true
                collectionView.contentOffset.y += restDelta
                adjustingOffset = false
            }
        } else if dy > 0 {
            let offset = collectionView.contentOffset.y
            let fromList = min(dy, max(0, offset - rest))
            if fromList > 0 {
                adjustingOffset = true
                collectionView.contentOffset.y = offset - fromList
                adjustingOffset = false
            }
            bannerCollapsed = max(0, bannerCollapsed - (dy - fromList))
        }
        applyBannerCollapse()
        lastScrollOffset = collectionView.contentOffset.y
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionGridLayoutIfNeeded()
    }

    private func updateCollectionGridLayoutIfNeeded() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let width = collectionView.bounds.width
        guard width > 0 else { return }
        let collectionWidth = width - MallProductCell.sectionInset * 2
        guard abs(collectionWidth - lastCollectionWidth) > 0.5 else { return }
        lastCollectionWidth = collectionWidth
        layout.itemSize = MallProductCell.gridItemSize(collectionWidth: collectionWidth)
        layout.invalidateLayout()
    }

    override func bindViewModel() {
        viewModel.$tabs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tabs in
                guard let self else { return }
                self.categoryTabBar.configure(
                    titles: tabs.map(\.title),
                    selectedIndex: self.viewModel.selectedTabIndex
                )
            }
            .store(in: &cancellables)

        viewModel.$selectedTabIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                self?.categoryTabBar.setSelectedIndex(index)
            }
            .store(in: &cancellables)

        viewModel.$products
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadProducts()
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(viewModel.$showEmptyState, viewModel.$isLoadingProducts)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showEmpty, isLoading in
                guard let self else { return }
                if self.embedsInHomeHub {
                    self.emptyStateView.isHidden = true
                    self.collectionView.isHidden = false
                    if self.viewModel.products.isEmpty {
                        self.reloadProducts()
                    }
                } else {
                    self.emptyStateView.isHidden = !showEmpty || isLoading
                    self.collectionView.isHidden = showEmpty && !isLoading
                }
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(viewModel.$isLoadingProducts, viewModel.$products)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading, products in
                if isLoading, products.isEmpty {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(viewModel.$isLoadingMore, viewModel.$hasMore)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading, hasMore in
                guard let self else { return }
                self.collectionView.collectionViewLayout.invalidateLayout()
                let footerIndex = IndexPath(item: 0, section: self.productSection)
                if let footer = self.collectionView.supplementaryView(
                    forElementKind: UICollectionView.elementKindSectionFooter,
                    at: footerIndex
                ) as? MallLoadMoreFooterView {
                    footer.configure(isLoading: isLoading, hasMore: hasMore)
                }
            }
            .store(in: &cancellables)
    }
}

extension HealthMallViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if embedsInHomeHub, viewModel.products.isEmpty {
            return viewModel.showEmptyState && !viewModel.isLoadingProducts ? 1 : 0
        }
        return viewModel.products.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if embedsInHomeHub, viewModel.products.isEmpty {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: MallEmptyStateCell.reuseID,
                for: indexPath
            )
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MallProductCell.reuseID, for: indexPath) as! MallProductCell
        let categoryId = viewModel.selectedTab.categoryServiceId
        cell.configure(
            viewModel.products[indexPath.item],
            categoryServiceId: categoryId.isEmpty ? nil : categoryId
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section == productSection, viewModel.products.indices.contains(indexPath.item) else { return }
        let product = viewModel.products[indexPath.item]
        let categoryId = viewModel.selectedTab.categoryServiceId
        Router.shared.push(
            "/services/pkg",
            params: product.packageDetailRouteParams(
                categoryServiceId: categoryId.isEmpty ? nil : categoryId
            )
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionFooter else {
            return UICollectionReusableView()
        }
        let footer = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: MallLoadMoreFooterView.reuseID,
            for: indexPath
        ) as! MallLoadMoreFooterView
        footer.configure(isLoading: viewModel.isLoadingMore, hasMore: viewModel.hasMore)
        return footer
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard indexPath.section == productSection, !viewModel.products.isEmpty else { return }
        let triggerIndex = max(viewModel.products.count - 2, 0)
        guard indexPath.item >= triggerIndex else { return }
        viewModel.loadMore()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        absorbScroll(scrollView)
        guard viewModel.hasMore, !viewModel.isLoadingMore, !viewModel.isLoadingProducts else { return }
        let threshold: CGFloat = 100
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        let offset = scrollView.contentOffset.y
        // 下拉回弹（偏移为负）不触发加载更多，否则短列表一拉就出现底部加载条，内容高度跳动
        guard offset > 0, contentHeight > 0, offset + frameHeight >= contentHeight - threshold else { return }
        viewModel.loadMore()
    }
}

extension HealthMallViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        guard section == productSection, !viewModel.products.isEmpty else { return .zero }
        if viewModel.isLoadingMore || !viewModel.hasMore {
            return CGSize(width: collectionView.bounds.width, height: 50)
        }
        return .zero
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if embedsInHomeHub, viewModel.products.isEmpty {
            let width = max(0, collectionView.bounds.width - MallProductCell.sectionInset * 2)
            return CGSize(width: width, height: 280)
        }
        let collectionWidth = max(0, collectionView.bounds.width - MallProductCell.sectionInset * 2)
        return MallProductCell.gridItemSize(collectionWidth: collectionWidth)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(
            top: 10,
            left: MallProductCell.sectionInset,
            bottom: 24,
            right: MallProductCell.sectionInset
        )
    }
}

// MARK: - Load more footer

private final class MallLoadMoreFooterView: UICollectionReusableView {
    static let reuseID = "MallLoadMoreFooterView"

    private let spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }()

    private let endLabel: UILabel = {
        let label = UILabel()
        label.text = "没有更多数据了"
        label.font = .fdCaption
        label.textColor = .fdMuted
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(spinner)
        addSubview(endLabel)
        spinner.snp.makeConstraints { $0.center.equalToSuperview() }
        endLabel.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(isLoading: Bool, hasMore: Bool) {
        if isLoading {
            endLabel.isHidden = true
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
            endLabel.isHidden = hasMore
        }
    }
}

extension HealthMallViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, pan === bannerPan else { return true }
        let translation = pan.translation(in: view)
        if abs(translation.y) < 4, abs(translation.x) < 4 { return false }
        return abs(translation.y) > abs(translation.x)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        gestureRecognizer === bannerPan
    }
}

private final class MallEmptyStateCell: UICollectionViewCell {
    static let reuseID = "MallEmptyStateCell"

    private let emptyView = FDEmptyStateView(style: .page, message: "该分类暂无商品，敬请期待")

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(emptyView)
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }
}
