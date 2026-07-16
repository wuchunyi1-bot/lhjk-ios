import UIKit
import SnapKit
import Kingfisher

final class MallProductCell: UICollectionViewCell {
    static let reuseID = "MallProductCell"

    private var productId: String?
    private let imgArea = UIView()
    private let coverImageView = UIImageView()
    private let placeholderLabel = UILabel()
    private let tagLabel = UILabel()
    private let nameLabel = UILabel()
    private let descLabel = UILabel()
    private let priceLabel = UILabel()
    private let buyBtn = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface
        layer.cornerRadius = 18
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.03
        layer.masksToBounds = false
        clipsToBounds = false
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 18

        imgArea.backgroundColor = .fdBg2
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        placeholderLabel.text = "商品封面"
        placeholderLabel.font = .fdMicro
        placeholderLabel.textColor = .fdMuted
        placeholderLabel.textAlignment = .center

        let dashedBorder = UIView()
        dashedBorder.backgroundColor = .fdBorderStrong

        contentView.addSubview(imgArea)
        imgArea.addSubview(coverImageView)
        imgArea.addSubview(placeholderLabel)
        imgArea.addSubview(dashedBorder)
        imgArea.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(imgArea.snp.width)
        }
        coverImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        placeholderLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        dashedBorder.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }

        tagLabel.font = .fdMicroSemibold
        tagLabel.textColor = .white
        tagLabel.backgroundColor = .fdPrimary
        tagLabel.layer.cornerRadius = 4
        tagLabel.clipsToBounds = true
        tagLabel.textAlignment = .center
        tagLabel.isHidden = true
        imgArea.addSubview(tagLabel)
        tagLabel.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(7); $0.height.equalTo(16) }

        nameLabel.font = .fdCaptionSemibold
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 1
        descLabel.font = .fdCaption
        descLabel.textColor = .fdSubtext
        descLabel.numberOfLines = 1
        priceLabel.font = .fdMonoFont(ofSize: 15, weight: .bold)

        buyBtn.titleLabel?.font = .fdCaptionSemibold
        buyBtn.setTitle("购买", for: .normal)
        buyBtn.setTitleColor(.white, for: .normal)
        buyBtn.backgroundColor = .fdPrimary
        buyBtn.layer.cornerRadius = 22
        buyBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)

        [nameLabel, descLabel, priceLabel, buyBtn].forEach(contentView.addSubview)
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(imgArea.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(12)
        }
        descLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(12)
        }
        priceLabel.snp.makeConstraints {
            $0.top.equalTo(descLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().offset(-12)
        }
        buyBtn.snp.makeConstraints {
            $0.centerY.equalTo(priceLabel)
            $0.trailing.equalToSuperview().inset(12)
            $0.height.equalTo(44)
        }

        buyBtn.addTarget(self, action: #selector(tapBuy), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        productId = nil
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        placeholderLabel.isHidden = false
    }

    func configure(_ item: HealthPackageItem) {
        nameLabel.text = item.name
        descLabel.text = item.subtitle
        priceLabel.text = item.price
        priceLabel.textColor = item.accent
        buyBtn.backgroundColor = item.accent

        if let badge = item.badge, !badge.isEmpty, badge != "无" {
            tagLabel.isHidden = false
            tagLabel.text = " \(badge) "
        } else {
            tagLabel.isHidden = true
        }

        if let urlString = item.imageUrl,
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            placeholderLabel.isHidden = true
            coverImageView.kf.setImage(with: url) { [weak self] result in
                if case .failure = result {
                    self?.placeholderLabel.isHidden = false
                }
            }
        } else {
            coverImageView.image = nil
            placeholderLabel.isHidden = false
        }

        productId = item.id
    }

    func configure(_ p: MallProduct) {
        nameLabel.text = p.name
        descLabel.text = p.desc
        priceLabel.text = p.price
        priceLabel.textColor = p.accent
        buyBtn.backgroundColor = p.accent
        tagLabel.isHidden = p.tag.isEmpty
        tagLabel.text = " \(p.tag) "
        coverImageView.image = nil
        placeholderLabel.isHidden = false
        productId = p.id
    }

    @objc private func tapBuy() {
        guard let id = productId else { return }
        Router.shared.push("/services/pkg", params: ["id": id])
    }
}
