import UIKit
import SnapKit
import Kingfisher

/// 富德优选商品卡 — 对齐 Figma 4054:2991（153×235：图 152/153 + 文案区 83）
final class MallProductCell: UICollectionViewCell {
    static let reuseID = "MallProductCell"

    /// 双列网格通用间距（与服务首页 `MallProductGridCell` 一致）
    static let columnSpacing: CGFloat = 13
    static let rowSpacing: CGFloat = 12
    static let sectionInset: CGFloat = 16
    /// Figma 商品图高 / 卡宽
    static let imageHeightRatio: CGFloat = 152.0 / 153.0
    /// Figma 文案区固定高度
    static let bodyHeight: CGFloat = 83

    /// 按容器宽计算双列商品卡尺寸（宽高比随宽度等比缩放）
    static func gridItemSize(collectionWidth: CGFloat) -> CGSize {
        let itemWidth = max(0, (collectionWidth - columnSpacing) / 2)
        let imageHeight = itemWidth * imageHeightRatio
        return CGSize(width: itemWidth, height: imageHeight + bodyHeight)
    }

    private static let placeholderImage = UIImage(named: "mall_product_placeholder")
    /// Figma 价格 / 热销角标 `#F93838`
    private static let hotColor = UIColor(hexString: "#F93838")
    /// Figma 推荐角标 `#FF7015`
    private static let recommendColor = UIColor(hexString: "#FF7015")
    /// Figma 新品角标 `#2B73FF`
    private static let newColor = UIColor(hexString: "#2B73FF")
    /// Figma 默认角标 / 购买按钮 `#FF7A50`
    private static let primaryColor = UIColor(hexString: "#FF7A50")
    /// Figma 标题文字 `#1F2942`
    private static let titleColor = UIColor(hexString: "#1F2942")
    /// Figma 简介 `#6D7381`
    private static let descColor = UIColor(hexString: "#6D7381")
    /// Figma 「元起」`#A6ACB8`
    private static let priceUnitColor = UIColor(hexString: "#A6ACB8")

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
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true

        imgArea.backgroundColor = UIColor(hexString: "#F7F7F7")
        imgArea.clipsToBounds = true
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.image = Self.placeholderImage

        contentView.addSubview(imgArea)
        imgArea.addSubview(coverImageView)
        imgArea.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(imgArea.snp.width).multipliedBy(Self.imageHeightRatio)
        }
        coverImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Figma：左上角标 rounded-tl 16 / rounded-br 12，高度 21
        tagLabel.font = .fdFont(ofSize: 12, weight: .medium)
        tagLabel.textColor = .white
        tagLabel.backgroundColor = Self.hotColor
        tagLabel.layer.cornerRadius = 14
        tagLabel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMaxYCorner]
        tagLabel.clipsToBounds = true
        tagLabel.textAlignment = .center
        tagLabel.isHidden = true
        imgArea.addSubview(tagLabel)
        tagLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.height.equalTo(21)
            $0.width.greaterThanOrEqualTo(48)
        }

        nameLabel.font = .fdFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = Self.titleColor
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail

        descLabel.font = .fdFont(ofSize: 12, weight: .regular)
        descLabel.textColor = Self.descColor
        descLabel.numberOfLines = 1
        descLabel.lineBreakMode = .byTruncatingTail

        priceLabel.numberOfLines = 1

        buyBtn.titleLabel?.font = .fdFont(ofSize: 12, weight: .medium)
        buyBtn.setTitle("购买", for: .normal)
        buyBtn.setTitleColor(.white, for: .normal)
        buyBtn.backgroundColor = Self.primaryColor
        buyBtn.layer.cornerRadius = 11
        buyBtn.clipsToBounds = true

        [nameLabel, descLabel, priceLabel, buyBtn].forEach(contentView.addSubview)

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(imgArea.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(10)
            $0.height.equalTo(21)
        }
        descLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom)
            $0.leading.trailing.equalToSuperview().inset(10)
            $0.height.equalTo(18)
        }
        buyBtn.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(10)
            $0.bottom.equalToSuperview().inset(10)
            $0.width.equalTo(52)
            $0.height.equalTo(22)
        }
        priceLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(10)
            $0.trailing.lessThanOrEqualTo(buyBtn.snp.leading).offset(-4)
            $0.centerY.equalTo(buyBtn)
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
        coverImageView.image = Self.placeholderImage
        tagLabel.isHidden = true
    }

    func configure(_ item: HealthPackageItem, categoryServiceId: String? = nil) {
        nameLabel.text = item.name
        descLabel.text = item.subtitle
        priceLabel.attributedText = Self.priceAttributed(from: item.price)
        applyBadge(item.badge)
        setCover(urlString: item.imageUrl)

        productId = item.id
        hospitalId = item.hospitalId
        self.categoryServiceId = categoryServiceId
    }

    func configure(_ p: MallProduct, categoryServiceId: String? = nil) {
        nameLabel.text = p.name
        descLabel.text = p.desc
        priceLabel.attributedText = Self.priceAttributed(from: p.price)
        applyBadge(p.tag.isEmpty ? nil : p.tag)
        setCover(urlString: nil)
        productId = p.id
        hospitalId = nil
        self.categoryServiceId = categoryServiceId
    }

    private func setCover(urlString: String?) {
        let placeholder = Self.placeholderImage
        guard let raw = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let url = URL(string: raw) else {
            coverImageView.kf.cancelDownloadTask()
            coverImageView.image = placeholder
            return
        }
        coverImageView.kf.setImage(with: url, placeholder: placeholder)
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
            tagLabel.backgroundColor = Self.hotColor
        case "推荐":
            tagLabel.backgroundColor = Self.recommendColor
        case "新品":
            tagLabel.backgroundColor = Self.newColor
        default:
            tagLabel.backgroundColor = Self.primaryColor
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
                .font: UIFont.fdFont(ofSize: 12, weight: .medium),
                .foregroundColor: hotColor,
            ]
        ))
        result.append(NSAttributedString(
            string: number,
            attributes: [
                .font: UIFont.fdFont(ofSize: 16, weight: .medium),
                .foregroundColor: hotColor,
            ]
        ))
        result.append(NSAttributedString(
            string: " 元起",
            attributes: [
                .font: UIFont.fdFont(ofSize: 12, weight: .regular),
                .foregroundColor: priceUnitColor,
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
