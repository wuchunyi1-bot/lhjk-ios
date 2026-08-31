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
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private let emptyStateView: UILabel = {
        let label = UILabel()
        label.text = "该分类暂无商品，敬请期待"
        label.font = .fdFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(hexString: "#8591AB")
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

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
        emptyStateView.snp.makeConstraints {
            $0.center.equalTo(collectionView)
            $0.leading.trailing.equalToSuperview().inset(24)
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

        viewModel.$isLoadingProducts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
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
}
