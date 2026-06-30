import UIKit
import SnapKit
import Kingfisher

/// 套餐 / 系统通知 Cell
final class SysNotifyCell: UITableViewCell {
    static let reuseID = "SysNotifyCell"

    // MARK: - UI

    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 13, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.layer.cornerRadius = 17
        l.clipsToBounds = true
        return l
    }()

    private let metaLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 10)
        l.textColor = .fdMuted
        return l
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.fdBorder.cgColor
        return v
    }()

    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = UIColor(hexString: "#FFF8F5")
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 15, weight: .semibold)
        l.textColor = .fdText
        l.numberOfLines = 2
        return l
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = .fdBody
        l.textColor = .fdSubtext
        l.numberOfLines = 3
        return l
    }()

    private let actionHint: UILabel = {
        let l = UILabel()
        l.text = "查看详情"
        l.font = .fdFont(ofSize: 12, weight: .medium)
        l.textColor = .fdPrimary
        return l
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdBg

        [avatarLabel, metaLabel, cardView].forEach(contentView.addSubview)
        [coverImageView, titleLabel, descLabel, actionHint].forEach(cardView.addSubview)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(_ msg: ChatMessage, tone: String, convRole: ConversationRole) {
        let isStaff = msg.isStaff
        let notify = msg.sysNotifyContent

        if notify?.isShowUser ?? true {
            avatarLabel.text = isStaff ? (msg.avatar ?? msg.senderName?.prefix(1).description ?? "?") : "我"
            avatarLabel.backgroundColor = isStaff
                ? UIColor(hexString: tone)
                : UIColor(hexString: "#FF7A50")
            avatarLabel.isHidden = false
            metaLabel.isHidden = false
            metaLabel.text = isStaff
                ? [msg.senderName, msg.senderRole, msg.time].compactMap { $0 }.joined(separator: " · ")
                : msg.time
        } else {
            avatarLabel.isHidden = true
            metaLabel.isHidden = true
        }
        metaLabel.textAlignment = isStaff ? .left : .right

        titleLabel.text = notify?.title ?? ""
        descLabel.text = notify?.content ?? ""

        // 封面图
        if let imgUrl = notify?.imageUrl, let url = URL(string: imgUrl) {
            coverImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
            coverImageView.isHidden = false
        } else {
            coverImageView.isHidden = true
        }

        layoutForStaff(isStaff, hasCover: !coverImageView.isHidden, showUser: notify?.isShowUser ?? true)
    }

    private func layoutForStaff(_ isStaff: Bool, hasCover: Bool, showUser: Bool) {
        let metaOffset: ConstraintOffsetTarget = showUser ? 4 : 8

        if showUser {
            avatarLabel.snp.remakeConstraints { make in
                if isStaff {
                    make.leading.equalToSuperview().offset(16)
                } else {
                    make.trailing.equalToSuperview().offset(-16)
                }
                make.top.equalToSuperview().offset(8)
                make.size.equalTo(34)
            }

            metaLabel.snp.remakeConstraints { make in
                make.top.equalTo(avatarLabel)
                if isStaff {
                    make.leading.equalTo(avatarLabel.snp.trailing).offset(8)
                } else {
                    make.trailing.equalTo(avatarLabel.snp.leading).offset(-8)
                }
            }
        }

        cardView.snp.remakeConstraints { make in
            if showUser {
                make.top.equalTo(metaLabel.snp.bottom).offset(metaOffset)
            } else {
                make.top.equalToSuperview().offset(8)
            }
            make.bottom.equalToSuperview().offset(-8)
            make.width.equalTo(260)
            if isStaff {
                make.leading.equalToSuperview().offset(showUser ? 58 : 16)
            } else {
                make.trailing.equalToSuperview().offset(showUser ? -58 : -16)
            }
        }

        if hasCover {
            coverImageView.snp.remakeConstraints { make in
                make.top.leading.trailing.equalToSuperview().inset(12)
                make.height.equalTo(120)
            }

            titleLabel.snp.remakeConstraints { make in
                make.top.equalTo(coverImageView.snp.bottom).offset(10)
                make.leading.trailing.equalToSuperview().inset(12)
            }
        } else {
            titleLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(14)
                make.leading.trailing.equalToSuperview().inset(12)
            }
        }

        descLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        actionHint.snp.remakeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
    }
}
