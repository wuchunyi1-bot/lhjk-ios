import UIKit
import SnapKit
import Kingfisher

/// 套餐详情图楼层 — 全量展示详情长图（自适应原图高宽比，不截断）
final class PackageDetailCardView: UIView {

    var onImagesLoaded: (() -> Void)?

    func configure(with pkg: ServicePackageDetail) {
        subviews.forEach { $0.removeFromSuperview() }

        guard !pkg.detailImageURLs.isEmpty else { return }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        for urlString in pkg.detailImageURLs {
            guard let url = URL(string: urlString) else { continue }
            let iv = FullDetailImageView()
            iv.onImageHeightDetermined = { [weak self] in
                self?.onImagesLoaded?()
            }
            iv.loadImage(url: url)
            stack.addArrangedSubview(iv)
        }

        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

private final class FullDetailImageView: UIImageView {
    var onImageHeightDetermined: (() -> Void)?
    private var aspectConstraint: Constraint?

    init() {
        super.init(frame: .zero)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }

    private func setup() {
        contentMode = .scaleAspectFill
        clipsToBounds = true
        layer.cornerRadius = 8
        backgroundColor = UIColor(hexString: "#F9F9F9")
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    func loadImage(url: URL) {
        kf.setImage(with: url, options: [.transition(.fade(0.15))]) { [weak self] result in
            guard let self, case .success(let value) = result else { return }
            let size = value.image.size
            guard size.width > 0, size.height > 0 else { return }
            let aspect = size.height / size.width
            self.aspectConstraint?.deactivate()
            self.snp.remakeConstraints {
                self.aspectConstraint = $0.height.equalTo(self.snp.width).multipliedBy(aspect).constraint
            }
            self.onImageHeightDetermined?()
        }
    }
}

