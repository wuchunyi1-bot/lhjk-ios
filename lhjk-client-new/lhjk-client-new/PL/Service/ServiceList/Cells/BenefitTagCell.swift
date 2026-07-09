import UIKit
import SnapKit

final class BenefitTagCell: UICollectionViewCell {
    static let reuseID = "BenefitTagCell"

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .fdBg2
        label.font = .fdMicro
        label.textColor = .fdText2
        label.textAlignment = .center
        contentView.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ text: String) { label.text = text }

    static func size(for text: String) -> CGSize {
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: 300, height: 22),
            options: [.usesLineFragmentOrigin],
            attributes: [.font: UIFont.fdMicro],
            context: nil
        )
        return CGSize(width: ceil(rect.width) + 16, height: 22)
    }

    /// 预计算总高度：模拟左对齐换行，item 高 22pt, 行间距 6pt, 列间距 5pt
    static func totalHeight(for texts: [String], maxWidth: CGFloat) -> CGFloat {
        guard !texts.isEmpty else { return 0 }
        var rows = 1
        var x: CGFloat = 0
        let itemSpacing: CGFloat = 5
        let lineSpacing: CGFloat = 6
        let itemHeight: CGFloat = 22

        for t in texts {
            let w = size(for: t).width
            if x + w > maxWidth && x > 0 {
                rows += 1
                x = w + itemSpacing
            } else {
                x += w + itemSpacing
            }
        }
        return CGFloat(rows) * itemHeight + CGFloat(rows - 1) * lineSpacing
    }
}
