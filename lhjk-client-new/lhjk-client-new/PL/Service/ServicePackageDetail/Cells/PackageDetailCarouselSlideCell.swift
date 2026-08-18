import UIKit
import SnapKit
import Kingfisher

/// 套餐详情 1:1 轮播 Slide Cell
/// 规则：宽度为屏幕宽度，高度如果超出截取中间，如果不够上下黑
final class PackageDetailCarouselSlideCell: UICollectionViewCell {
    static let reuseID = "PackageDetailCarouselSlideCell"

    private let gradient = CAGradientLayer()
    private let imageView = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .black
        contentView.clipsToBounds = true

        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        contentView.layer.insertSublayer(gradient, at: 0)

        imageView.contentMode = .scaleToFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        label.font = .fdFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 3
        contentView.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        imageView.frame = .zero
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = contentView.bounds
        layoutBannerImage()
    }

    private func layoutBannerImage() {
        guard let img = imageView.image, img.size.width > 0, img.size.height > 0 else {
            imageView.frame = contentView.bounds
            return
        }
        let containerW = contentView.bounds.width
        let containerH = contentView.bounds.height
        guard containerW > 0, containerH > 0 else { return }

        // 宽度固定为屏幕宽度，高度按图片实际比例计算
        let renderedH = img.size.height * (containerW / img.size.width)
        let y = (containerH - renderedH) / 2.0
        imageView.frame = CGRect(x: 0, y: y, width: containerW, height: renderedH)
    }

    func configure(label text: String, imageURL: String?, accent: UIColor, alternate: Bool) {
        label.text = text
        label.textColor = accent
        let c1 = accent.withAlphaComponent(alternate ? 0.12 : 0.18)
        let c2 = accent.withAlphaComponent(alternate ? 0.22 : 0.32)
        gradient.colors = [c1.cgColor, c2.cgColor]

        if let imageURL, !imageURL.isEmpty, let url = URL(string: imageURL) {
            imageView.isHidden = false
            label.isHidden = true
            imageView.kf.setImage(
                with: url,
                placeholder: UIImage(named: "package_detail_banner_placeholder"),
                options: [.transition(.fade(0.15))]
            ) { [weak self] result in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.layoutBannerImage()
                }
            }
        } else {
            imageView.isHidden = false
            label.isHidden = true
            imageView.image = UIImage(named: "package_detail_banner_placeholder")
            layoutBannerImage()
        }
    }
}
