import UIKit
import SnapKit
import Kingfisher

/// 富德优选商品卡 — 对齐 Figma 3042:1767（153×235 / 图片+文案+购买）
final class MallProductCell: UICollectionViewCell {
    static let reuseID = "MallProductCell"

    private var productId: String?
    private var hospitalId: String?
    private var categoryServiceId: String?
    private let imgArea = UIView()
    private let coverImageView = UIImageView()
    private let tagLabel = UILabel()
    private let nameLabel = UILabel()
    private let descLabel = UILabel()
    private let priceLabel = UILabel()
    private let buyBtn = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .fdBg
        contentView.layer.cornerRadius = 15
        contentView.clipsToBounds = true

        imgArea.backgroundColor = .fdProductImageBg
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true

        contentView.addSubview(imgArea)
        imgArea.addSubview(coverImageView)
        imgArea.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(imgArea.snp.width).multipliedBy(152.0 / 153.0)
        }
        coverImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Figma：左上角标 rounded-br 12 / rounded-tl 16
        tagLabel.font = .fdFont(ofSize: 12, weight: .medium)
        tagLabel.textColor = .white
        tagLabel.backgroundColor = .fdDanger
        tagLabel.layer.cornerRadius = 15
        tagLabel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMaxYCorner]
        tagLabel.clipsToBounds = true
        tagLabel.textAlignment = .center
        tagLabel.isHidden = true
        imgArea.addSubview(tagLabel)
        tagLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.height.equalTo(18)
            $0.width.greaterThanOrEqualTo(46)
        }

        nameLabel.font = .fdFont(ofSize: 12, weight: .medium)
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 1
        descLabel.font = .fdFont(ofSize: 10, weight: .regular)
        descLabel.textColor = .fdSubtext
        descLabel.numberOfLines = 1
        priceLabel.numberOfLines = 1

        buyBtn.titleLabel?.font = .fdFont(ofSize: 11, weight: .medium)
        buyBtn.setTitle("购买", for: .normal)
        buyBtn.setTitleColor(.white, for: .normal)
        buyBtn.backgroundColor = .fdPrimary
        buyBtn.layer.cornerRadius = 10

        [nameLabel, descLabel, priceLabel, buyBtn].forEach(contentView.addSubview)
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(imgArea.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(10)
        }
        descLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview().inset(10)
        }
        priceLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(10)
            $0.trailing.lessThanOrEqualTo(buyBtn.snp.leading).offset(-4)
        }
        buyBtn.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(10)
            $0.centerY.equalTo(priceLabel)
            $0.width.equalTo(47)
            $0.height.equalTo(20)
            $0.bottom.equalToSuperview().inset(10)
        }

        buyBtn.addTarget(self, action: #selector(tapBuy), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        productId = nil
        hospitalId = nil
        categoryServiceId = nil
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        tagLabel.isHidden = true
    }

    func configure(_ item: HealthPackageItem, categoryServiceId: String? = nil) {
        nameLabel.text = item.name
        descLabel.text = item.subtitle
        priceLabel.attributedText = Self.priceAttributed(from: item.price)
        applyBadge(item.badge)

        if let urlString = item.imageUrl,
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            coverImageView.kf.setImage(with: url) { [weak self] result in
                if case .failure = result {
                    self?.coverImageView.image = nil
                }
            }
        } else {
            coverImageView.image = nil
        }

        productId = item.id
        hospitalId = item.hospitalId
        self.categoryServiceId = categoryServiceId
    }

    func configure(_ p: MallProduct, categoryServiceId: String? = nil) {
        nameLabel.text = p.name
        descLabel.text = p.desc
        priceLabel.attributedText = Self.priceAttributed(from: p.price)
        applyBadge(p.tag.isEmpty ? nil : p.tag)
        coverImageView.image = nil
        productId = p.id
        hospitalId = nil
        self.categoryServiceId = categoryServiceId
    }

    private func applyBadge(_ raw: String?) {
        guard let badge = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !badge.isEmpty, badge != "无" else {
            tagLabel.isHidden = true
            return
        }
        tagLabel.isHidden = false
        tagLabel.text = badge
        switch badge {
        case "热销":
            tagLabel.backgroundColor = .fdDanger
        case "新品":
            tagLabel.backgroundColor = .fdInfo
        default:
            // 推荐 / 其它
            tagLabel.backgroundColor = .fdPrimary
        }
    }

    /// 解析「¥120」「120」「¥ 120 元起」→ 富文本 ¥ + 数字 + 元起
    private static func priceAttributed(from raw: String) -> NSAttributedString {
        let digits = raw.filter { $0.isNumber || $0 == "," || $0 == "." }
        let number = digits.isEmpty ? raw : digits
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(
            string: "¥",
            attributes: [
                .font: UIFont.fdFont(ofSize: 10, weight: .medium),
                .foregroundColor: UIColor.fdDanger,
            ]
        ))
        result.append(NSAttributedString(
            string: number,
            attributes: [
                .font: UIFont.fdFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.fdDanger,
            ]
        ))
        result.append(NSAttributedString(
            string: " 元起",
            attributes: [
                .font: UIFont.fdFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.fdMuted,
            ]
        ))
        return result
    }

    @objc private func tapBuy() {
        guard let id = productId else { return }
        Router.shared.push(
            "/services/pkg",
            params: ServiceRoutes.packageDetailParams(
                packageId: id,
                hospitalId: hospitalId,
                categoryServiceId: categoryServiceId
            )
        )
    }
}
