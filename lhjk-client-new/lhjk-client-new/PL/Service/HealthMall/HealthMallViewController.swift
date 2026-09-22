import UIKit
import SnapKit
import Combine

/// 富德优选商城 — 对齐 Figma 4054:2991（分类 Tab + 双列商品网格，卡片比例随屏宽等比缩放）
final class HealthMallViewController: BaseViewController {

    private let viewModel = HealthMallViewModel()
    private var cancellables = Set<AnyCancellable>()

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
        cv.register(MallProductCell.self, forCellWithReuseIdentifier: MallProductCell.reuseID)
        cv.register(
            MallLoadMoreFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: MallLoadMoreFooterView.reuseID
        )
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private let emptyStateView = FDEmptyStateView(style: .page, message: "该分类暂无商品，敬请期待")

    private let loadingIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        return spinner
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "富德优选"
        viewModel.load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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

        view.addSubview(categoryTabBar)
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        view.addSubview(loadingIndicator)

        categoryTabBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(48)
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(categoryTabBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        emptyStateView.isHidden = true
        emptyStateView.snp.makeConstraints {
            $0.edges.equalTo(collectionView)
        }
        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(collectionView)
        }
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
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(viewModel.$showEmptyState, viewModel.$isLoadingProducts)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showEmpty, isLoading in
                self?.emptyStateView.isHidden = !showEmpty || isLoading
                self?.collectionView.isHidden = showEmpty && !isLoading
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
                let footerIndex = IndexPath(item: 0, section: 0)
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
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.products.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MallProductCell.reuseID, for: indexPath) as! MallProductCell
        let categoryId = viewModel.selectedTab.categoryServiceId
        cell.configure(
            viewModel.products[indexPath.item],
            categoryServiceId: categoryId.isEmpty ? nil : categoryId
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
        let triggerIndex = max(viewModel.products.count - 2, 0)
        guard indexPath.item >= triggerIndex else { return }
        viewModel.loadMore()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard viewModel.hasMore, !viewModel.isLoadingMore, !viewModel.isLoadingProducts else { return }
        let threshold: CGFloat = 100
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        let offset = scrollView.contentOffset.y
        guard contentHeight > 0, offset + frameHeight >= contentHeight - threshold else { return }
        viewModel.loadMore()
    }
}

extension HealthMallViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        guard !viewModel.products.isEmpty else { return .zero }
        if viewModel.isLoadingMore || !viewModel.hasMore {
            return CGSize(width: collectionView.bounds.width, height: 50)
        }
        return .zero
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
