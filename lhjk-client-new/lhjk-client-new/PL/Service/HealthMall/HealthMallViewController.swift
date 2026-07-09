import UIKit
import SnapKit

// MARK: - Cell

fileprivate final class MallProductCell: UICollectionViewCell {
    static let reuseID = "MallProductCell"

    private let imgArea = UIView()
    private let tagLabel = UILabel()
    private let nameLabel = UILabel()
    private let descLabel = UILabel()
    private let unitLabel = UILabel()
    private let priceLabel = UILabel()
    private let buyBtn = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface
        layer.cornerRadius = 18
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.03
        layer.masksToBounds = false
        clipsToBounds = false

        // Image placeholder
        imgArea.backgroundColor = .fdBg2
        imgArea.layer.cornerRadius = 0
        contentView.addSubview(imgArea)
        imgArea.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.height.equalTo(90) }

        let placeholder = UILabel()
        placeholder.text = "商品封面"; placeholder.font = .fdMicro; placeholder.textColor = .fdMuted; placeholder.textAlignment = .center
        imgArea.addSubview(placeholder)
        placeholder.snp.makeConstraints { $0.center.equalToSuperview() }

        // Tag badge
        tagLabel.font = .fdMicroSemibold; tagLabel.textColor = .white
        tagLabel.backgroundColor = .fdPrimary; tagLabel.layer.cornerRadius = 4; tagLabel.clipsToBounds = true
        tagLabel.textAlignment = .center; tagLabel.isHidden = true
        imgArea.addSubview(tagLabel)
        tagLabel.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(6); $0.height.equalTo(16) }

        // Info
        nameLabel.font = .fdCaptionSemibold; nameLabel.textColor = .fdText; nameLabel.numberOfLines = 2
        descLabel.font = .fdMicro; descLabel.textColor = .fdSubtext; descLabel.numberOfLines = 1
        unitLabel.font = .fdMicro; unitLabel.textColor = .fdMuted
        priceLabel.font = .fdMonoFont(ofSize: 16, weight: .bold)

        buyBtn.titleLabel?.font = .fdMicroSemibold
        buyBtn.setTitle("购买", for: .normal)
        buyBtn.setTitleColor(.white, for: .normal); buyBtn.layer.cornerRadius = 999

        [nameLabel, descLabel, unitLabel, priceLabel, buyBtn].forEach(contentView.addSubview)
        nameLabel.snp.makeConstraints { $0.top.equalTo(imgArea.snp.bottom).offset(10); $0.leading.trailing.equalToSuperview().inset(10) }
        descLabel.snp.makeConstraints { $0.top.equalTo(nameLabel.snp.bottom).offset(3); $0.leading.trailing.equalToSuperview().inset(10) }
        unitLabel.snp.makeConstraints { $0.top.equalTo(descLabel.snp.bottom).offset(3); $0.leading.trailing.equalToSuperview().inset(10) }
        priceLabel.snp.makeConstraints { $0.top.equalTo(unitLabel.snp.bottom).offset(8); $0.leading.equalToSuperview().inset(10); $0.bottom.equalToSuperview().offset(-10) }
        buyBtn.snp.makeConstraints { $0.centerY.equalTo(priceLabel); $0.trailing.equalToSuperview().inset(10); $0.height.equalTo(26) }

        buyBtn.addTarget(self, action: #selector(tapBuy), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ p: MallProduct) {
        nameLabel.text = p.name; descLabel.text = p.desc; unitLabel.text = p.unit
        priceLabel.text = p.price; priceLabel.textColor = p.accent
        buyBtn.backgroundColor = p.accent
        tagLabel.isHidden = p.tag.isEmpty
        tagLabel.text = " \(p.tag) "
        objc_setAssociatedObject(self, &kMallIdKey, p.id, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    @objc private func tapBuy() {
        if let id = objc_getAssociatedObject(self, &kMallIdKey) as? String {
            Router.shared.push("/mall/detail", params: ["id": id])
        }
    }
}
private var kMallIdKey: UInt8 = 0

// MARK: - ViewController

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
}
