import UIKit
import SnapKit
import Kingfisher

final class PackageDetailCarouselSlideCell: UICollectionViewCell {
    static let reuseID = "PackageDetailCarouselSlideCell"

    private let gradient = CAGradientLayer()
    private let imageView = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        contentView.layer.insertSublayer(gradient, at: 0)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }

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
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = contentView.bounds
    }

    func configure(label text: String, imageURL: String?, accent: UIColor, alternate: Bool) {
        label.text = text
        label.textColor = accent
        let c1 = accent.withAlphaComponent(alternate ? 0.12 : 0.18)
        let c2 = accent.withAlphaComponent(alternate ? 0.22 : 0.32)
        gradient.colors = [c1.cgColor, c2.cgColor]

        if let imageURL, let url = URL(string: imageURL) {
            imageView.isHidden = false
            label.isHidden = true
            imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            imageView.isHidden = true
            label.isHidden = false
            imageView.image = nil
        }
    }
}
