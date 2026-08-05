import UIKit
import SnapKit

/// Tab 根页统一品牌顶栏 — 首页 / 健康 / 服务 / 消息共用
///
/// 几何与字号对齐 Vue `.home-header` / `.fd-topbar` / `.services-header__*`：
/// 标题 22 bold（fdH2）、副标题 12、间距 2、水平 16、safeArea 下 top 12。
/// 健康页可附带风险胶囊（Figma 3021:1341）。
final class TabHubBrandHeaderView: UIView {

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdH2
        l.textColor = .fdText
        l.numberOfLines = 1
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 12, weight: .regular)
        l.textColor = .fdSubtext
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let badgeLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 10, weight: .medium)
        l.textColor = UIColor(hexString: "#FF7802")
        l.backgroundColor = UIColor(hexString: "#FFEEE5")
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    private let subtitleRow = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdBg

        subtitleRow.axis = .horizontal
        subtitleRow.spacing = 6
        subtitleRow.alignment = .center
        subtitleRow.addArrangedSubview(subtitleLabel)
        subtitleRow.addArrangedSubview(badgeLabel)

        addSubview(titleLabel)
        addSubview(subtitleRow)
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        subtitleRow.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(2)
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.lessThanOrEqualToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-8)
        }
        badgeLabel.snp.makeConstraints {
            $0.height.equalTo(18)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(
        title: String,
        subtitle: String,
        titleColor: UIColor = .fdText,
        badge: String? = nil
    ) {
        titleLabel.text = title
        titleLabel.textColor = titleColor
        subtitleLabel.text = subtitle
        if let badge, !badge.isEmpty {
            badgeLabel.isHidden = false
            badgeLabel.text = " \(badge) "
        } else {
            badgeLabel.isHidden = true
            badgeLabel.text = nil
        }
    }
}
