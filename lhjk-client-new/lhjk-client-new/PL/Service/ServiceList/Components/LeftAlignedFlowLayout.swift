import UIKit

/// 左对齐换行布局 — 用于 benefits tag 流式展示
final class LeftAlignedFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attrs = super.layoutAttributesForElements(in: rect) else { return nil }
        var x: CGFloat = sectionInset.left
        var y: CGFloat = sectionInset.top
        var maxY: CGFloat = y

        for attr in attrs where attr.representedElementCategory == .cell {
            if attr.frame.origin.y > maxY + 1 {
                x = sectionInset.left
                y = attr.frame.origin.y
                maxY = y
            }
            attr.frame.origin.x = x
            attr.frame.origin.y = y
            x += attr.frame.width + minimumInteritemSpacing
            maxY = max(maxY, y)
        }
        return attrs
    }
}
