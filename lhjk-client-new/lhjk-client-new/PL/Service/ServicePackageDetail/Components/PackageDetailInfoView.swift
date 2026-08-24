import UIKit
import SnapKit

/// 套餐详情价格与标题简介区 — 对齐 Figma 3805:20782 / 3805:20790
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
        titleCardView.clipsToBounds = true

        addSubview(titleCardView)
        titleCardView.snp.makeConstraints {
            $0.top.equalTo(priceHeaderView.snp.bottom).offset(-29)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        bringSubviewToFront(titleCardView)

        titleLabel.font = .fdFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = UIColor(hexString: "#1F2430")
        titleLabel.numberOfLines = 2
        titleCardView.addSubview(titleLabel)

        subtitleLabel.font = .fdFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = UIColor(hexString: "#6D7381")
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
        var rawPrice = pkg.priceText.replacingOccurrences(of: "¥", with: "").trimmingCharacters(in: .whitespaces)
        if rawPrice.isEmpty { rawPrice = "\(pkg.tiers.first?.price ?? 0)" }
        let unit = pkg.priceUnit.isEmpty ? "元起" : pkg.priceUnit
        priceHeaderView.configure(price: rawPrice, unit: unit)

        titleLabel.text = pkg.name
        subtitleLabel.text = pkg.subtitle
        subtitleLabel.isHidden = pkg.subtitle.isEmpty

        let tagText = pkg.tag.trimmingCharacters(in: .whitespacesAndNewlines)
        if tagText.contains("热销") {
            stampBadge.isHidden = false
            stampBadge.configure(style: .hot)
        } else if tagText.contains("推荐") {
            stampBadge.isHidden = false
            stampBadge.configure(style: .recommend)
        } else {
            stampBadge.isHidden = true
        }
    }
}

// MARK: - 顶部渐变价格条

private final class GradientPriceHeaderView: UIView {

    private let bgImageView = UIImageView()
    private let symbolLabel = UILabel()
    private let priceLabel = UILabel()
    private let unitLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        backgroundColor = UIColor(hexString: "#FD383F")

        bgImageView.image = UIImage(named: "package_detail_price_bg")
        bgImageView.contentMode = .scaleAspectFill
        bgImageView.clipsToBounds = true
        addSubview(bgImageView)
        bgImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        symbolLabel.text = "¥"
        symbolLabel.font = .fdFont(ofSize: 20, weight: .bold)
        symbolLabel.textColor = .white

        priceLabel.font = .fdFont(ofSize: 30, weight: .bold)
        priceLabel.textColor = .white

        unitLabel.font = .fdFont(ofSize: 16, weight: .regular)
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

    enum Style {
        case recommend
        case hot
    }

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

    func configure(style: Style) {
        switch style {
        case .hot:
            stampImageView.image = UIImage(named: "package_detail_stamp_hot")
        case .recommend:
            stampImageView.image = UIImage(named: "package_detail_stamp_recommend")
        }
    }
}
