import UIKit
import SnapKit

/// 富德优选双列商品网格 — 对齐 Figma 3444:5385
/// 外层白卡包含标题与商品网格；375pt 稿面下白卡宽 343，商品卡为 153×235。
final class MallProductGridCell: UITableViewCell {

    static let reuseID = "MallProductGridCell"

    private static let outerHorizontalInset: CGFloat = 16
    private static let cardContentInset: CGFloat = 12
    private static let headerHeight: CGFloat = 51
    private static let cardBottomInset: CGFloat = 12
    private static let columnSpacing: CGFloat = 13
    private static let rowSpacing: CGFloat = 12
    private static let itemBodyHeight: CGFloat = 83

    var onProductTap: ((HealthPackageItem) -> Void)?
    var onMoreTapped: (() -> Void)?
    /// CollectionView 实测高度变化时回调，用于触发外层 TableView 重新计算行高
    var onContentHeightChanged: (() -> Void)?

    private var products: [HealthPackageItem] = []
    private var collectionHeightConstraint: Constraint?
    private var lastAppliedHeight: CGFloat = 0
    private var lastLayoutWidth: CGFloat = 0
    private var needsContentReload = false

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .fdSurface
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: "富德优选",
            attributes: [
                .font: UIFont.fdFont(ofSize: 18, weight: .medium),
                .foregroundColor: UIColor.fdText,
                .kern: 0.55,
            ]
        )
        return label
    }()

    private let moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("查看全部", for: .normal)
        button.titleLabel?.font = .fdFont(ofSize: 12, weight: .regular)
        let moreColor = UIColor(hexString: "#717885")
        button.setTitleColor(moreColor, for: .normal)
        let chevron = UIImage(
            systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .regular)
        )
        button.setImage(chevron, for: .normal)
        button.tintColor = moreColor
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        button.contentHorizontalAlignment = .right
        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(
            frame: .zero,
            collectionViewLayout: Self.makeGridLayout(outerWidth: UIScreen.main.bounds.width)
        )
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.showsVerticalScrollIndicator = false
        view.register(MallProductCell.self, forCellWithReuseIdentifier: MallProductCell.reuseID)
        view.dataSource = self
        view.delegate = self
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdBg
        contentView.backgroundColor = .fdBg

        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(moreButton)
        cardView.addSubview(collectionView)

        cardView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalToSuperview().offset(Self.outerHorizontalInset)
            $0.trailing.equalToSuperview().offset(-Self.outerHorizontalInset)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
        }
        moreButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14)
            $0.trailing.equalToSuperview().inset(12)
            $0.height.equalTo(24)
            $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
        }
        collectionView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Self.headerHeight)
            $0.leading.equalToSuperview().offset(Self.cardContentInset)
            $0.trailing.equalToSuperview().offset(-Self.cardContentInset)
            $0.bottom.equalToSuperview().inset(Self.cardBottomInset)
            collectionHeightConstraint = $0.height.equalTo(1).constraint
        }

        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        products = []
        onProductTap = nil
        onMoreTapped = nil
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
        applyLayout(for: width, notifyTableView: false)
        return CGSize(width: width, height: lastAppliedHeight)
    }

    func configure(products: [HealthPackageItem]) {
        self.products = products
        needsContentReload = true
        let width = resolvedContainerWidth(from: contentView.bounds.width)
        applyLayout(for: width, notifyTableView: false)
        setNeedsLayout()
    }

    private func resolvedContainerWidth(from proposedWidth: CGFloat) -> CGFloat {
        if proposedWidth > 0 { return proposedWidth }
        if contentView.bounds.width > 0 { return contentView.bounds.width }
        if bounds.width > 0 { return bounds.width }
        return UIScreen.main.bounds.width
    }

    private func applyLayout(for width: CGFloat, notifyTableView: Bool) {
        guard width > 0 else { return }

        if abs(width - lastLayoutWidth) > 0.5 {
            lastLayoutWidth = width
            collectionView.setCollectionViewLayout(Self.makeGridLayout(outerWidth: width), animated: false)
            needsContentReload = true
        }

        if needsContentReload {
            collectionView.reloadData()
            needsContentReload = false
        }

        let collectionHeight = Self.collectionHeight(productCount: products.count, outerWidth: width)
        let totalHeight = Self.gridHeight(productCount: products.count, containerWidth: width)
        let heightChanged = abs(totalHeight - lastAppliedHeight) > 0.5

        collectionHeightConstraint?.update(offset: max(collectionHeight, 1))
        lastAppliedHeight = totalHeight

        if notifyTableView, heightChanged {
            onContentHeightChanged?()
        }
    }

    private func refreshLayoutIfNeeded() {
        let width = contentView.bounds.width
        guard width > 0, !products.isEmpty else { return }
        if abs(width - lastLayoutWidth) > 0.5 {
            applyLayout(for: width, notifyTableView: lastAppliedHeight > 0)
        }
    }

    /// 富德优选白卡总高度（标题 51 + 网格 + 底部 12）。
    static func gridHeight(productCount: Int, containerWidth: CGFloat) -> CGFloat {
        guard productCount > 0, containerWidth > 0 else { return 0 }
        return headerHeight
            + collectionHeight(productCount: productCount, outerWidth: containerWidth)
            + cardBottomInset
    }

    private static func collectionHeight(productCount: Int, outerWidth: CGFloat) -> CGFloat {
        guard productCount > 0 else { return 0 }
        let rowCount = (productCount + 1) / 2
        let itemHeight = itemSize(for: outerWidth).height
        return CGFloat(rowCount) * itemHeight
            + CGFloat(max(rowCount - 1, 0)) * rowSpacing
    }

    private static func makeGridLayout(outerWidth: CGFloat) -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = columnSpacing
        layout.minimumLineSpacing = rowSpacing
        layout.sectionInset = .zero
        layout.itemSize = itemSize(for: outerWidth)
        return layout
    }

    /// Figma 商品卡：图片 152 + 文案区 83；375pt 稿面下为 153×235。
    private static func itemSize(for outerWidth: CGFloat) -> CGSize {
        let collectionWidth = outerWidth
            - (outerHorizontalInset * 2)
            - (cardContentInset * 2)
        let itemWidth = max(0, (collectionWidth - columnSpacing) / 2)
        let imageHeight = itemWidth * (152.0 / 153.0)
        return CGSize(width: itemWidth, height: imageHeight + itemBodyHeight)
    }

    @objc private func moreTapped() {
        onMoreTapped?()
    }
}

// MARK: - UICollectionView

extension MallProductGridCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        products.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
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
