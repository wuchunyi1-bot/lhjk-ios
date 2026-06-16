import UIKit
import SnapKit

// MARK: - Data

fileprivate struct MallProduct {
    let id: String; let name: String; let desc: String; let price: String; let unit: String
    let tag: String; let accent: UIColor; let category: String
}

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
        placeholder.text = "商品封面"; placeholder.font = .systemFont(ofSize: 11); placeholder.textColor = .fdMuted; placeholder.textAlignment = .center
        imgArea.addSubview(placeholder)
        placeholder.snp.makeConstraints { $0.center.equalToSuperview() }

        // Tag badge
        tagLabel.font = .systemFont(ofSize: 9, weight: .semibold); tagLabel.textColor = .white
        tagLabel.backgroundColor = .fdPrimary; tagLabel.layer.cornerRadius = 4; tagLabel.clipsToBounds = true
        tagLabel.textAlignment = .center; tagLabel.isHidden = true
        imgArea.addSubview(tagLabel)
        tagLabel.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(6); $0.height.equalTo(16) }

        // Info
        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold); nameLabel.textColor = .fdText; nameLabel.numberOfLines = 2
        descLabel.font = .systemFont(ofSize: 11); descLabel.textColor = .fdSubtext; descLabel.numberOfLines = 1
        unitLabel.font = .systemFont(ofSize: 10); unitLabel.textColor = .fdMuted
        priceLabel.font = .monospacedSystemFont(ofSize: 16, weight: .bold)

        buyBtn.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
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
    private let allProducts: [MallProduct] = [
        MallProduct(id: "m001", name: "德好·控糖益生菌", desc: "餐后血糖平稳配方", price: "¥128", unit: "60粒/盒", tag: "热销", accent: .fdPrimary, category: "营养补充"),
        MallProduct(id: "m002", name: "深海鱼油软胶囊", desc: "EPA+DHA 心脑血管养护", price: "¥98", unit: "90粒/瓶", tag: "", accent: UIColor(hexString: "#2C7BB0"), category: "营养补充"),
        MallProduct(id: "m003", name: "膳食纤维复合粉", desc: "助消化·促代谢·饱腹感", price: "¥76", unit: "30袋/盒", tag: "推荐", accent: UIColor(hexString: "#1F9A6B"), category: "功能食品"),
        MallProduct(id: "m004", name: "辅酶Q10胶囊", desc: "心肌细胞能量代谢支持", price: "¥168", unit: "60粒/瓶", tag: "", accent: UIColor(hexString: "#D6602B"), category: "营养补充"),
        MallProduct(id: "m005", name: "维生素D3+K2", desc: "钙吸收协同·骨骼强健", price: "¥88", unit: "120粒/瓶", tag: "", accent: UIColor(hexString: "#B47300"), category: "营养补充"),
        MallProduct(id: "m006", name: "乳清蛋白质粉", desc: "肌肉维持·体重管理首选", price: "¥218", unit: "500g/罐", tag: "精选", accent: UIColor(hexString: "#7B5E9F"), category: "功能食品"),
        MallProduct(id: "m007", name: "血压臂式监测仪", desc: "医疗级精准·家庭自测", price: "¥298", unit: "1台", tag: "", accent: UIColor(hexString: "#3D6FB8"), category: "健康器械"),
        MallProduct(id: "m008", name: "德康·抗氧化套装", desc: "白藜芦醇+虾青素+葡萄籽", price: "¥368", unit: "3瓶组合", tag: "套装", accent: UIColor(hexString: "#5C8DC9"), category: "营养补充"),
        MallProduct(id: "m009", name: "血糖连续监测贴", desc: "免扎针14天连续监测", price: "¥186", unit: "2片/盒", tag: "新品", accent: UIColor(hexString: "#1A7A6E"), category: "健康器械"),
    ]

    private var activeCategory = "全部"
    private var filteredProducts: [MallProduct] { activeCategory == "全部" ? allProducts : allProducts.filter { $0.category == activeCategory } }

    private lazy var segmentedControl: UISegmentedControl = {
        let seg = UISegmentedControl(items: categories)
        seg.selectedSegmentIndex = 0
        seg.selectedSegmentTintColor = .fdPrimary
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 12, weight: .semibold)], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.systemFont(ofSize: 12)], for: .normal)
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
        l.font = .systemFont(ofSize: 11); l.textColor = .fdMuted; l.textAlignment = .center
        return l
    }()

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
