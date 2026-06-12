import UIKit
import SnapKit

/// 体征监测指标卡片 Cell
/// 参考 funde-client: metric-card
final class MetricCardCell: UICollectionViewCell {

    static let reuseIdentifier = "MetricCardCell"

    // MARK: - UI

    private let iconBg: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 10
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let badgeView = UIView()
    private let badgeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .semibold)
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .fdSubtext
        return l
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.textColor = .fdText
        return l
    }()

    private let unitLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = .fdSubtext
        return l
    }()

    private let trendIcon: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = .fdMuted
        return l
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .fdSurface
        contentView.layer.cornerRadius = 18
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 1)
        contentView.layer.shadowRadius = 6
        contentView.layer.shadowOpacity = 0.03

        badgeView.layer.cornerRadius = 999
        badgeView.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }

        iconBg.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(18)
        }

        contentView.addSubview(iconBg)
        contentView.addSubview(badgeView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(unitLabel)
        contentView.addSubview(trendIcon)
        contentView.addSubview(timeLabel)

        iconBg.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(14)
            make.size.equalTo(30)
        }
        badgeView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(14)
            make.trailing.equalToSuperview().offset(-14)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconBg.snp.bottom).offset(10)
            make.leading.equalToSuperview().inset(14)
        }
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview().inset(14)
        }
        unitLabel.snp.makeConstraints { make in
            make.lastBaseline.equalTo(valueLabel)
            make.leading.equalTo(valueLabel.snp.trailing).offset(4)
        }
        trendIcon.snp.makeConstraints { make in
            make.centerY.equalTo(valueLabel)
            make.trailing.equalToSuperview().offset(-14)
            make.size.equalTo(14)
        }
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(
        icon: String,
        status: String,
        statusType: String,
        label: String,
        value: String,
        unit: String,
        trend: String,
        time: String
    ) {
        let isWarning = statusType == "warning"

        iconBg.backgroundColor = isWarning ? .fdWarningSoft : .fdSuccessSoft
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = isWarning ? UIColor(hexString: "#B47300") : .fdSuccess

        badgeView.backgroundColor = isWarning ? .fdWarningSoft : .fdSuccessSoft
        badgeLabel.text = status
        badgeLabel.textColor = isWarning ? UIColor(hexString: "#B47300") : .fdSuccess

        titleLabel.text = label
        valueLabel.text = value
        unitLabel.text = unit

        switch trend {
        case "up":
            trendIcon.image = UIImage(systemName: "arrow.up.right")
            trendIcon.tintColor = .fdDanger
        case "down":
            trendIcon.image = UIImage(systemName: "arrow.down.right")
            trendIcon.tintColor = .fdSuccess
        default:
            trendIcon.image = UIImage(systemName: "minus")
            trendIcon.tintColor = .fdMuted
        }

        timeLabel.text = time

        // Border for warning
        if isWarning {
            contentView.layer.borderWidth = 1
            contentView.layer.borderColor = UIColor.fdPrimaryEdge.cgColor
        } else {
            contentView.layer.borderWidth = 0
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.layer.borderWidth = 0
    }
}
