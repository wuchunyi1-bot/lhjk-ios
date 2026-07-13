import UIKit
import SnapKit

/// 富德优选商城 — SegmentedControl + 2 列 CollectionView
/// 参考 funde-client: HealthMallView.vue
final class HealthMallViewController: BaseViewController {

    private let categories = ["全部", "营养补充", "功能食品", "健康器械"]
    private let allProducts: [MallProduct]

    private var activeCategory = "全部"
    private var filteredProducts: [MallProduct] { activeCategory == "全部" ? allProducts : allProducts.filter { $0.category == activeCategory } }

    private lazy var segmentedControl: UISegmentedControl = {
        let seg = UISegmentedControl(items: categories)
        seg.selectedSegmentIndex = 0
        seg.selectedSegmentTintColor = .fdPrimary
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.fdCaptionSemibold], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.fdCaption], for: .normal)
        seg.backgroundColor = .fdBg2
        seg.addTarget(self, action: #selector(categoryChanged), for: .valueChanged)
        return seg
    }()

    private lazy var collectionView: UICollectionView = {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(260)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(260)), subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 11, bottom: 12, trailing: 11)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout(section: section))
        cv.backgroundColor = .fdBg; cv.showsVerticalScrollIndicator = false
        cv.register(MallProductCell.self, forCellWithReuseIdentifier: MallProductCell.reuseID)
        cv.dataSource = self; cv.delegate = self
        return cv
    }()

    private lazy var footerLabel: UILabel = {
        let l = UILabel()
        l.text = "🛡 正品保障 · 德好健康监制 · 7天无忧退换"
        l.font = .fdMicro; l.textColor = .fdMuted; l.textAlignment = .center
        return l
    }()

    init(catalogService: ServiceCatalogService = AppContainer.shared.serviceCatalogService) {
        allProducts = catalogService.loadMallProducts()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() { super.viewDidLoad(); title = "富德优选" }

    override func setupUI() {
        view.backgroundColor = .fdBg
        view.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(8); $0.leading.trailing.equalToSuperview().inset(16); $0.height.equalTo(32) }

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.top.equalTo(segmentedControl.snp.bottom).offset(8); $0.leading.trailing.equalToSuperview() }

        view.addSubview(footerLabel)
        footerLabel.snp.makeConstraints { $0.top.equalTo(collectionView.snp.bottom).offset(12); $0.centerX.equalToSuperview(); $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24) }
    }

    @objc private func categoryChanged() {
        activeCategory = categories[segmentedControl.selectedSegmentIndex]
        collectionView.reloadData()
    }
}

extension HealthMallViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { filteredProducts.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MallProductCell.reuseID, for: indexPath) as! MallProductCell
        cell.configure(filteredProducts[indexPath.item]); return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let id = filteredProducts[indexPath.item].id
        Router.shared.push("/mall/detail", params: ["id": id])
    }
}
