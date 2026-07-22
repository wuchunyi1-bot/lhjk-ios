import UIKit
import SnapKit

/// 富德优选双列商品网格 — 嵌入服务首页 TableView，样式对齐 `/mall` `MallProductCell`
final class MallProductGridCell: UITableViewCell {

    static let reuseID = "MallProductGridCell"

    var onProductTap: ((HealthPackageItem) -> Void)?
    /// CollectionView 实测高度变化时回调，用于触发外层 TableView 重新计算行高
    var onContentHeightChanged: (() -> Void)?

    private var products: [HealthPackageItem] = []
    private var collectionHeightConstraint: Constraint?
    private var lastAppliedHeight: CGFloat = 0
    private var lastLayoutWidth: CGFloat = 0
    private var needsContentReload = false

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: Self.makeGridLayout(containerWidth: UIScreen.main.bounds.width))
        cv.backgroundColor = .fdBg
        cv.isScrollEnabled = false
        cv.showsVerticalScrollIndicator = false
        cv.register(MallProductCell.self, forCellWithReuseIdentifier: MallProductCell.reuseID)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdBg
        contentView.backgroundColor = .fdBg
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            collectionHeightConstraint = $0.height.equalTo(1).constraint
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        products = []
        onProductTap = nil
        onContentHeightChanged = nil
        lastAppliedHeight = 0
        lastLayoutWidth = 0
        needsContentReload = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        refreshLayoutIfNeeded()
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        let width = resolvedContainerWidth(from: targetSize.width)
        guard width > 0 else {
            return super.systemLayoutSizeFitting(
                targetSize,
                withHorizontalFittingPriority: horizontalFittingPriority,
                verticalFittingPriority: verticalFittingPriority
            )
        }
        applyCollectionHeight(for: width, notifyTableView: false)
        return CGSize(width: width, height: lastAppliedHeight)
    }

    func configure(products: [HealthPackageItem]) {
        self.products = products
        needsContentReload = true
        let width = resolvedContainerWidth(from: contentView.bounds.width)
        applyCollectionHeight(for: width, notifyTableView: false)
        setNeedsLayout()
    }

    private func resolvedContainerWidth(from proposedWidth: CGFloat) -> CGFloat {
        if proposedWidth > 0 { return proposedWidth }
        if contentView.bounds.width > 0 { return contentView.bounds.width }
        if bounds.width > 0 { return bounds.width }
        return UIScreen.main.bounds.width
    }

    private func applyCollectionHeight(for width: CGFloat, notifyTableView: Bool) {
        guard width > 0 else { return }

        let targetHeight = Self.gridHeight(productCount: products.count, containerWidth: width)
        if abs(width - lastLayoutWidth) > 0.5 {
            lastLayoutWidth = width
            collectionView.setCollectionViewLayout(Self.makeGridLayout(containerWidth: width), animated: false)
            needsContentReload = true
        }

        if needsContentReload {
            collectionView.reloadData()
            needsContentReload = false
        }

        guard abs(targetHeight - lastAppliedHeight) > 0.5 else { return }

        lastAppliedHeight = targetHeight
        collectionHeightConstraint?.update(offset: max(targetHeight, 0))
        if notifyTableView {
            onContentHeightChanged?()
        }
    }

    private func refreshLayoutIfNeeded() {
        let width = contentView.bounds.width
        guard width > 0, !products.isEmpty else { return }

        if abs(width - lastLayoutWidth) > 0.5 {
            applyCollectionHeight(for: width, notifyTableView: lastAppliedHeight > 0)
            return
        }

        collectionView.layoutIfNeeded()
        let measuredHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
        guard measuredHeight > 0, abs(measuredHeight - lastAppliedHeight) > 0.5 else { return }

        lastAppliedHeight = measuredHeight
        collectionHeightConstraint?.update(offset: measuredHeight)
        onContentHeightChanged?()
    }

    /// 双列网格总高度（含 section 内边距与行间距）
    static func gridHeight(productCount: Int, containerWidth: CGFloat) -> CGFloat {
        guard productCount > 0, containerWidth > 0 else { return 0 }
        let itemHeight = itemSize(for: containerWidth).height
        let rowCount = (productCount + 1) / 2
        let sectionVerticalInset: CGFloat = 24
        let interRowSpacing: CGFloat = 10
        let rows = CGFloat(rowCount)
        return sectionVerticalInset + rows * itemHeight + max(0, rows - 1) * interRowSpacing
    }

    private static func makeGridLayout(containerWidth: CGFloat) -> UICollectionViewCompositionalLayout {
        let itemHeight = itemSize(for: containerWidth).height

        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.5),
                heightDimension: .absolute(itemHeight)
            )
        )
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(itemHeight)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 11, bottom: 12, trailing: 11)
        return UICollectionViewCompositionalLayout(section: section)
    }

    /// 与 `MallProductCell` 约束对齐：1:1 封面 + 文案区 + 44pt 购买按钮
    private static func itemSize(for containerWidth: CGFloat) -> CGSize {
        let horizontalInset: CGFloat = 22
        let interColumnSpacing: CGFloat = 10
        let itemWidth = (containerWidth - horizontalInset - interColumnSpacing) / 2
        let bodyHeight: CGFloat = 12 + 20 + 4 + 17 + 8 + 44 + 12
        return CGSize(width: itemWidth, height: itemWidth + bodyHeight)
    }
}

// MARK: - UICollectionView

extension MallProductGridCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        products.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MallProductCell.reuseID,
            for: indexPath
        ) as! MallProductCell
        cell.configure(products[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onProductTap?(products[indexPath.item])
    }
}
