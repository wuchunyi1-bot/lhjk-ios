import SnapKit
import UIKit

final class MyActivityCell: UITableViewCell {

    static let reuseID = "MyActivityCell"

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .fdSurface
        view.layer.cornerRadius = 16
        return view
    }()

    private let themeLabel: UILabel = {
        let label = UILabel()
        label.font = .fdBodyBold
        label.textColor = .fdText
        label.numberOfLines = 2
        return label
    }()

    private let statusWrap: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .fdCaptionSemibold
        label.textAlignment = .center
        return label
    }()

    private let timeLabel = metaLabel()
    private let ownerLabel = metaLabel()

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
        themeLabel.text = card.theme
        statusLabel.text = card.statusText
        timeLabel.attributedText = metaText(symbol: "clock", text: "活动时间 \(card.timeText)")
        ownerLabel.attributedText = metaText(symbol: "person", text: "活动负责人 \(card.owner)")
        if card.isOngoing {
            statusLabel.textColor = .fdSuccess
            statusWrap.backgroundColor = .fdSuccessSoft
        } else {
            statusLabel.textColor = .fdSubtext
            statusWrap.backgroundColor = .fdBg2
        }
        contentView.alpha = card.isTappable ? 1 : 0.45
        isUserInteractionEnabled = card.isTappable
    }

    private func setup() {
        contentView.addSubview(cardView)
        cardView.addSubview(themeLabel)
        cardView.addSubview(statusWrap)
        statusWrap.addSubview(statusLabel)
        cardView.addSubview(timeLabel)
        cardView.addSubview(ownerLabel)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-10)
        }
        statusWrap.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-16)
        }
        statusLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
        }
        statusWrap.setContentHuggingPriority(.required, for: .horizontal)
        statusWrap.setContentCompressionResistancePriority(.required, for: .horizontal)
        themeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(statusWrap.snp.leading).offset(-8)
        }
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(themeLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        ownerLabel.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    private static func metaLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }

    private func metaText(symbol: String, text: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let attachment = NSTextAttachment()
        let image = UIImage(systemName: symbol)?.withTintColor(.fdPrimary, renderingMode: .alwaysOriginal)
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: -3, width: 16, height: 16)
        result.append(NSAttributedString(attachment: attachment))
        result.append(NSAttributedString(
            string: "  \(text)",
            attributes: [
                .font: UIFont.fdBody,
                .foregroundColor: UIColor.fdText2
            ]
        ))
        return result
    }
}
