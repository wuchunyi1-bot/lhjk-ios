import UIKit
import SnapKit

/// 品牌头部 — Figma 3021:586 / 3021:589 / 3021:611 / 3021:612
final class BrandHeaderView: UIView {

    private let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "login_logo"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let logoHost = LoginLogoBackgroundView()

    private let appNameLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: "富德健康",
            attributes: [
                .font: UIFont.fdLoginTitle,
                .foregroundColor: UIColor.fdLoginTitle,
                .kern: 0.55,
            ]
        )
        label.textAlignment = .center
        return label
    }()

    private let taglineLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: "全生命周期健康守护数智化平台",
            attributes: [
                .font: UIFont.fdLoginMeta,
                .foregroundColor: UIColor.fdLoginTitle.withAlphaComponent(0.8),
                .kern: 0.55,
            ]
        )
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(logoHost)
        logoHost.addSubview(logoImageView)
        addSubview(appNameLabel)
        addSubview(taglineLabel)

        logoHost.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(72)
        }
        logoImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(44.884)
            make.height.equalTo(45.063)
        }

        appNameLabel.snp.makeConstraints { make in
            make.top.equalTo(logoHost.snp.bottom).offset(9)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        taglineLabel.snp.makeConstraints { make in
            make.top.equalTo(appNameLabel.snp.bottom).offset(3)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
}

private final class LoginLogoBackgroundView: UIView {

    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 16
        layer.masksToBounds = false
        layer.shadowColor = UIColor.fdLoginLogoShadow.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = 6.8
        layer.shadowOpacity = 0.59

        gradientLayer.colors = [
            UIColor.fdLoginLogoSurface.cgColor,
            UIColor.white.cgColor,
            UIColor.fdLoginLogoSurface.cgColor,
        ]
        gradientLayer.locations = [0, 0.45, 1]
        gradientLayer.startPoint = CGPoint(x: 1, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        gradientLayer.cornerRadius = 16
        layer.insertSublayer(gradientLayer, at: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
