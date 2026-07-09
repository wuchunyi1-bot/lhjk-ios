import UIKit
import SnapKit

/// 固定高度 CollectionView — 提前计算总高度避免 intrinsicContentSize 自举循环
final class SelfSizingCollectionView: UICollectionView {
    var fixedHeight: CGFloat = 0 {
        didSet { heightConstraint?.update(offset: fixedHeight) }
    }
    private var heightConstraint: Constraint?

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        snp.makeConstraints { heightConstraint = $0.height.equalTo(0).constraint }
    }

    required init?(coder: NSCoder) { fatalError() }
}
