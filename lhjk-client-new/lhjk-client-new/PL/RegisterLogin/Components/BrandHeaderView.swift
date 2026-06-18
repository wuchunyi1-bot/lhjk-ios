import UIKit
import SnapKit

/// 品牌头部视图 — Logo Mark + 应用名称 + Slogan
/// 参考 funde-client: login-brand / login-brand__mark / login-brand__name / login-brand__tagline
final class BrandHeaderView: UIView {

    // MARK: - UI

    /// Logo Mark: 72×72 品牌色圆角方块 + 白色品牌简称
    private let logoMarkView: UIView = {
        let view = UIView()
        view.backgroundColor = .fdPrimary
        view.layer.cornerRadius = 22
        view.layer.shadowColor = UIColor.fdPrimary.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowRadius = 24
        view.layer.shadowOpacity = 0.35
        return view
    }()

    private let logoLabel: UILabel = {
        let label = UILabel()
        label.text = "富德"
        label.font = .fdH2
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    /// 应用名称: 22pt bold
    private let appNameLabel: UILabel = {
        let label = UILabel()
        label.text = "富德健康"
        label.font = .fdH2
        label.textColor = .fdText
        label.textAlignment = .center
        return label
    }()

    /// Slogan: 13pt muted
    private let taglineLabel: UILabel = {
        let label = UILabel()
        label.text = "全生命周期健康守护数智化平台"
        label.font = .fdCaption
        label.textColor = .fdSubtext
        label.textAlignment = .center
        return label
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(logoMarkView)
        logoMarkView.addSubview(logoLabel)
        addSubview(appNameLabel)
        addSubview(taglineLabel)

        logoMarkView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(72)
        }

        logoLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        appNameLabel.snp.makeConstraints { make in
            make.top.equalTo(logoMarkView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }

        taglineLabel.snp.makeConstraints { make in
            make.top.equalTo(appNameLabel.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
}
