import UIKit
import SnapKit

/// 推荐服务类目筛选条 — 对齐 `ServicesView.vue` → `category-strip`
final class HealthPackageCategoryCell: UITableViewCell {

    static let reuseID = "HealthPackageCategoryCell"

    var onCategorySelected: ((String) -> Void)?

    private var categories: [String] = []
    private var selectedCategory = "推荐"

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(CategoryPillCell.self, forCellWithReuseIdentifier: CategoryPillCell.reuseID)
        return cv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(2)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(34)
            $0.bottom.equalToSuperview().offset(-10)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(categories: [String], selected: String) {
        self.categories = categories
        self.selectedCategory = selected
        collectionView.reloadData()
    }
}

extension HealthPackageCategoryCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        categories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryPillCell.reuseID, for: indexPath) as! CategoryPillCell
        let title = categories[indexPath.item]
        cell.configure(title: title, isSelected: title == selectedCategory)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = categories[indexPath.item]
        guard category != selectedCategory else { return }
        selectedCategory = category
        collectionView.reloadData()
        onCategorySelected?(category)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let title = categories[indexPath.item]
        let width = (title as NSString).size(withAttributes: [.font: UIFont.fdCaptionSemibold]).width + 28
        return CGSize(width: max(width, 56), height: 34)
    }
}

// MARK: - Pill

private final class CategoryPillCell: UICollectionViewCell {

    static let reuseID = "CategoryPillCell"

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 17
        titleLabel.font = .fdCaptionSemibold
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        if isSelected {
            contentView.backgroundColor = .fdPrimary
            titleLabel.textColor = .white
        } else {
            contentView.backgroundColor = .fdBg2
            titleLabel.textColor = .fdSubtext
        }
    }
}
