import UIKit
import SnapKit

/// 套餐详情价格与标题简介区 — 对齐 Figma 3449:7777 / 3449:7785
final class PackageDetailInfoView: UIView {

    private let priceHeaderView = GradientPriceHeaderView()
    private let titleCardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let stampBadge = PackageSealStampView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(priceHeaderView)
        priceHeaderView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(81)
        }

        titleCardView.backgroundColor = .white
        titleCardView.layer.cornerRadius = 16
        titleCardView.layer.borderWidth = 1
        titleCardView.layer.borderColor = UIColor.white.cgColor
        titleCardView.layer.shadowColor = UIColor.black.cgColor
        titleCardView.layer.shadowOpacity = 0.06
        titleCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        titleCardView.layer.shadowRadius = 8
        titleCardView.clipsToBounds = false

        addSubview(titleCardView)
        titleCardView.snp.makeConstraints {
            $0.top.equalTo(priceHeaderView.snp.bottom).offset(-29)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        titleLabel.font = .fdFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .fdText
        titleLabel.numberOfLines = 2
        titleCardView.addSubview(titleLabel)

        subtitleLabel.font = .fdBody
        subtitleLabel.textColor = .fdSubtext
        subtitleLabel.numberOfLines = 2
        titleCardView.addSubview(subtitleLabel)

        titleCardView.addSubview(stampBadge)
        stampBadge.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.trailing.equalToSuperview().offset(-8)
            $0.size.equalTo(64)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualTo(stampBadge.snp.leading).offset(-8)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-16)
        }
    }

    func configure(with pkg: ServicePackageDetail) {
        // 价格数字提取（去掉 "¥" 与 "元起"）
        var rawPrice = pkg.priceText.replacingOccurrences(of: "¥", with: "").trimmingCharacters(in: .whitespaces)
        if rawPrice.isEmpty { rawPrice = "\(pkg.tiers.first?.price ?? 0)" }
        let unit = pkg.priceUnit.isEmpty ? "元起" : pkg.priceUnit
        priceHeaderView.configure(price: rawPrice, unit: unit)

        titleLabel.text = pkg.name
        subtitleLabel.text = pkg.subtitle
        subtitleLabel.isHidden = pkg.subtitle.isEmpty

        let tagText = pkg.tag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tagText.isEmpty {
            stampBadge.isHidden = false
            stampBadge.configure(text: tagText)
        } else {
            stampBadge.isHidden = true
        }
    }
}

// MARK: - 顶部渐变价格条

private final class GradientPriceHeaderView: UIView {

    private let bgImageView = UIImageView()
    private let gradientLayer = CAGradientLayer()
    private let symbolLabel = UILabel()
    private let priceLabel = UILabel()
    private let unitLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        gradientLayer.colors = [
            UIColor(hexString: "#FD383F").cgColor,
            UIColor(hexString: "#FE3E39").cgColor,
            UIColor(hexString: "#FE8A54").cgColor
        ]
        gradientLayer.locations = [0.0, 0.6, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)

        bgImageView.image = UIImage(named: "package_detail_price_bg")
        bgImageView.contentMode = .scaleAspectFill
        bgImageView.clipsToBounds = true
        addSubview(bgImageView)
        bgImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        symbolLabel.text = "¥"
        symbolLabel.font = .fdFont(ofSize: 18, weight: .bold)
        symbolLabel.textColor = .white

        priceLabel.font = .fdFont(ofSize: 28, weight: .bold)
        priceLabel.textColor = .white

        unitLabel.font = .fdFont(ofSize: 14, weight: .regular)
        unitLabel.textColor = .white

        addSubview(symbolLabel)
        addSubview(priceLabel)
        addSubview(unitLabel)

        priceLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(32)
            $0.top.equalToSuperview().offset(10)
        }

        symbolLabel.snp.makeConstraints {
            $0.trailing.equalTo(priceLabel.snp.leading).offset(-2)
            $0.bottom.equalTo(priceLabel.snp.bottom).offset(-3)
        }

        unitLabel.snp.makeConstraints {
            $0.leading.equalTo(priceLabel.snp.trailing).offset(4)
            $0.bottom.equalTo(priceLabel.snp.bottom).offset(-3)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func configure(price: String, unit: String) {
        let cleanPrice = price.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanPrice.isEmpty || cleanPrice == "0" || cleanPrice.contains("面议") {
            priceLabel.text = "0"
            unitLabel.text = "元起"
        } else {
            priceLabel.text = cleanPrice
            unitLabel.text = (unit.isEmpty || unit.contains("面议")) ? "元起" : unit
        }
        symbolLabel.isHidden = false
    }
}

// MARK: - 推荐/热销印章角标

private final class PackageSealStampView: UIView {

    private let stampImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear
        stampImageView.contentMode = .scaleAspectFit
        addSubview(stampImageView)
        stampImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func configure(text: String) {
        if text.contains("热销") {
            stampImageView.image = UIImage(named: "package_detail_stamp_hot")
        } else {
            stampImageView.image = UIImage(named: "package_detail_stamp_recommend")
        }
    }
}

