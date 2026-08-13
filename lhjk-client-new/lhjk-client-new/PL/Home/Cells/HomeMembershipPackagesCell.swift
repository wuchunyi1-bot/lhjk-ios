import UIKit
import SnapKit
import Kingfisher

/// 推荐健康套餐 — 标题 + 通栏远程图纵向列表（宽随屏，按比例缩放，不定死像素宽）
final class HomeMembershipPackagesCell: UITableViewCell {

    static let reuseID = "HomeMembershipPackagesCell"
    /// 相对宽度的高度比（设计稿通栏图约 351×100）
    private static let imageAspectHeightOverWidth: CGFloat = 100.0 / 351.0

    struct Package: Hashable {
        let id: String
        let imageUrl: String
        /// 栏位 `pageUrl`（`FundeH5:` / `FundeApp:`，见 `FundePageURL`）
        let pageUrl: String?
    }

    var onPackageTapped: ((Package) -> Void)?

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = 16
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "推荐健康套餐"
        l.font = .fdFont(ofSize: 16, weight: .medium)
        l.textColor = .fdText
        return l
    }()

    private let listStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 12
        s.alignment = .fill
        s.distribution = .fill
        return s
    }()

    private var packagesByTag: [Int: Package] = [:]

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(listStack)

        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }
        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(16)
        }
        listStack.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(packages: [Package]) {
        listStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        packagesByTag.removeAll()
        for (index, pkg) in packages.enumerated() {
            let imageView = UIImageView()
            // 随容器宽高拉伸/压缩，铺满可用宽度
            imageView.contentMode = .scaleToFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 12
            imageView.backgroundColor = UIColor(hexString: "#FFF8F5")
            imageView.isUserInteractionEnabled = true
            imageView.tag = index
            imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
            imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            if let url = URL(string: pkg.imageUrl) {
                imageView.kf.setImage(with: url)
            }
            packagesByTag[index] = pkg
            let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
            imageView.addGestureRecognizer(tap)
            listStack.addArrangedSubview(imageView)
            // 高度随当前屏宽比例变化，不定死绝对宽高
            imageView.snp.makeConstraints {
                $0.height.equalTo(imageView.snp.width).multipliedBy(Self.imageAspectHeightOverWidth)
            }
        }
    }

    @objc private func imageTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view, let package = packagesByTag[view.tag] else { return }
        onPackageTapped?(package)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onPackageTapped = nil
        packagesByTag.removeAll()
        listStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}
