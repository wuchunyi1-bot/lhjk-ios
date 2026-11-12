import SnapKit
import UIKit

final class MyActivityCell: UITableViewCell {

    static let reuseID = "MyActivityCell"

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()

    private let backgroundImage = UIImageView()
    private let statusImage = UIImageView()
    private let timeIcon = UIImageView()
    private let ownerIcon = UIImageView()

    private let themeLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 18, weight: .medium)
        label.numberOfLines = 2
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 1
        return label
    }()

    private let ownerLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 1
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ card: MyActivityCard) {
        let ongoing = card.isOngoing
        themeLabel.text = card.theme
        themeLabel.textColor = UIColor(hexString: ongoing ? "#522B0F" : "#303030")
        let meta = UIColor(hexString: ongoing ? "#8C714F" : "#6E6E6E")
        timeLabel.textColor = meta
        ownerLabel.textColor = meta
        timeLabel.text = "活动时间：\(card.timeText)"
        ownerLabel.text = "活动负责人：\(card.owner)"
        backgroundImage.image = UIImage(named: ongoing ? "event_live_bg" : "event_end_bg")
        statusImage.image = UIImage(named: ongoing ? "event_live_status" : "event_end_status")
        timeIcon.image = UIImage(named: ongoing ? "event_live_time" : "event_end_time")
        ownerIcon.image = UIImage(named: ongoing ? "event_live_leader" : "event_end_leader")
        contentView.alpha = card.isTappable ? 1 : 0.45
        isUserInteractionEnabled = card.isTappable
    }

    private func setup() {
        backgroundImage.contentMode = .scaleAspectFill
        statusImage.contentMode = .scaleAspectFit
        timeIcon.contentMode = .scaleAspectFit
        ownerIcon.contentMode = .scaleAspectFit

        contentView.addSubview(cardView)
        cardView.addSubview(backgroundImage)
        cardView.addSubview(themeLabel)
        cardView.addSubview(timeIcon)
        cardView.addSubview(timeLabel)
        cardView.addSubview(ownerIcon)
        cardView.addSubview(ownerLabel)
        cardView.addSubview(statusImage)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-12)
        }
        backgroundImage.snp.makeConstraints { $0.edges.equalToSuperview() }
        statusImage.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(40)
        }
        themeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(statusImage.snp.leading).offset(-8)
        }
        timeIcon.snp.makeConstraints { make in
            make.leading.equalTo(themeLabel)
            make.top.equalTo(themeLabel.snp.bottom).offset(8)
            make.size.equalTo(16)
        }
        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(timeIcon.snp.trailing).offset(3)
            make.centerY.equalTo(timeIcon)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        ownerIcon.snp.makeConstraints { make in
            make.leading.size.equalTo(timeIcon)
            make.top.equalTo(timeIcon.snp.bottom).offset(10)
            make.bottom.equalToSuperview().offset(-20)
        }
        ownerLabel.snp.makeConstraints { make in
            make.leading.equalTo(ownerIcon.snp.trailing).offset(3)
            make.centerY.equalTo(ownerIcon)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
    }
}
