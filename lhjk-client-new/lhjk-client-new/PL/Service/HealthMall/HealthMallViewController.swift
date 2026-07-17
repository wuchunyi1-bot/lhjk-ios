import UIKit
import SnapKit
import Combine

/// 富德优选商城 — 分类 Tab + 2 列 CollectionView
/// 参考 funde-client: HealthMallView.vue
final class HealthMallViewController: BaseViewController {

    private let viewModel = HealthMallViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let categoryTabBar = MallCategoryTabBar()

    private lazy var collectionView: UICollectionView = {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(280))
        )
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(280)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 11, bottom: 12, trailing: 11)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout(section: section))
        cv.backgroundColor = .fdBg
        cv.showsVerticalScrollIndicator = false
        cv.register(MallProductCell.self, forCellWithReuseIdentifier: MallProductCell.reuseID)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private let emptyStateView: UILabel = {
        let label = UILabel()
        label.text = "该分类暂无商品，敬请期待"
        label.font = .fdCaption
        label.textColor = .fdMuted
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        return spinner
    }()

    private lazy var footerLabel: UILabel = {
        let l = UILabel()
        l.text = "正品保障 · 德好健康监制 · 7天无忧退换"
        l.font = .fdMicro
        l.textColor = .fdMuted
        l.textAlignment = .center
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "富德优选"
        viewModel.load()
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        categoryTabBar.onTabSelected = { [weak self] index in
            self?.viewModel.selectTab(at: index)
        }

        view.addSubview(categoryTabBar)
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        view.addSubview(loadingIndicator)
        view.addSubview(footerLabel)

        categoryTabBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(categoryTabBar.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }
        emptyStateView.snp.makeConstraints {
            $0.center.equalTo(collectionView)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(collectionView)
        }
        footerLabel.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
        }
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
        let id = viewModel.products[indexPath.item].id
        var params: [String: Any] = ["id": id]
        let categoryId = viewModel.selectedTab.categoryServiceId
        if !categoryId.isEmpty {
            params["categoryServiceId"] = categoryId
        }
        Router.shared.push("/services/pkg", params: params)
    }
}
