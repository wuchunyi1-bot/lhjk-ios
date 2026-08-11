import UIKit
import SnapKit

/// 品牌头部 — Figma 3209:298 / 3209:361 / 标题 slogan 切图
/// Logo 使用新品牌标（橙底白标），标题与 slogan 用切图。
final class BrandHeaderView: UIView {

    private let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "login_logo"))
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        iv.accessibilityLabel = "富德健康"
        return iv
    }()

    /// 阴影单独一层，避免 clipsToBounds 裁掉阴影
    private let logoShadowHost: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.shadowColor = UIColor(red: 252 / 255, green: 230 / 255, blue: 214 / 255, alpha: 1).cgColor
        v.layer.shadowOffset = .zero
        v.layer.shadowRadius = 6.8
        v.layer.shadowOpacity = 0.59
        return v
    }()

    private let appNameImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "login_brand_title"))
        iv.contentMode = .scaleAspectFit
        iv.accessibilityLabel = "富德健康"
        return iv
    }()

    private let taglineImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "login_brand_tagline"))
        iv.contentMode = .scaleAspectFit
        iv.accessibilityLabel = "全生命周期健康守护数智化平台"
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(logoShadowHost)
        logoShadowHost.addSubview(logoImageView)
        addSubview(appNameImageView)
        addSubview(taglineImageView)

        // Figma 3209:361 — 72×72
        logoShadowHost.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(72)
        }
        logoImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Figma：logo bottom → 标题 14；slogan 相对 logo bottom 56
        appNameImageView.snp.makeConstraints { make in
            make.top.equalTo(logoShadowHost.snp.bottom).offset(14)
            make.centerX.equalToSuperview()
            make.width.equalTo(124)
            make.height.equalTo(29)
        }

        taglineImageView.snp.makeConstraints { make in
            make.top.equalTo(logoShadowHost.snp.bottom).offset(56)
            make.centerX.equalToSuperview()
            make.width.equalTo(172)
            make.height.equalTo(12)
            make.bottom.equalToSuperview()
        }
    }
}
