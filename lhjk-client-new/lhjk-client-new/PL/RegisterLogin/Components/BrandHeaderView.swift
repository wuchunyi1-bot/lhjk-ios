import UIKit
import SnapKit

/// 品牌头部 — Figma 3209:298 / 3209:361
/// Logo + 合并后的品牌标题切图（`login_brand_title` 含标题与 slogan）。
final class BrandHeaderView: UIView {

    private let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "login_logo"))
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        iv.accessibilityLabel = "富德联好健康"
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

    private let brandTitleImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "login_brand_title"))
        iv.contentMode = .scaleAspectFit
        iv.accessibilityLabel = "富德联好健康，全生命周期健康守护数智化平台"
        return iv
    }()

    private var logoSizeConstraint: Constraint?
    private var titleWidthConstraint: Constraint?
    private var titleHeightConstraint: Constraint?

    /// iPhone 5 / SE1 等窄屏：略缩小 Logo 与标题切图
    func applyCompactLayout(_ compact: Bool) {
        logoSizeConstraint?.update(offset: compact ? 60 : 72)
        titleWidthConstraint?.update(offset: compact ? 175 : 195)
        titleHeightConstraint?.update(offset: compact ? 50 : 56)
    }

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
        addSubview(brandTitleImageView)

        // Figma 3209:361 — 72×72
        logoShadowHost.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            logoSizeConstraint = make.size.equalTo(72).constraint
        }
        logoImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 合并切图 @2x 390×112 → 195×56 pt
        brandTitleImageView.snp.makeConstraints { make in
            make.top.equalTo(logoShadowHost.snp.bottom).offset(14)
            make.centerX.equalToSuperview()
            titleWidthConstraint = make.width.equalTo(195).constraint
            titleHeightConstraint = make.height.equalTo(56).constraint
            make.bottom.equalToSuperview()
        }
    }
}
