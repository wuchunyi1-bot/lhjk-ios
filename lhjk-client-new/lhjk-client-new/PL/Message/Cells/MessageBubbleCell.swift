import UIKit
import SnapKit

/// 文本消息气泡 Cell — 患者右侧 / 健管师左侧
/// 参考 funde-im MessageBubble.vue
final class MessageBubbleCell: UITableViewCell {

    static let reuseIdentifier = "MessageBubbleCell"

    private let bubbleView = UIView()
    private let contentLabel = UILabel()
    private var bubbleLeading: Constraint?
    private var bubbleTrailing: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentLabel.numberOfLines = 0; contentLabel.font = .fdBody

        bubbleView.layer.cornerRadius = 16
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ msg: Message, showTime: String?) {
        contentLabel.text = msg.content

        bubbleLeading?.deactivate(); bubbleTrailing?.deactivate()
        bubbleView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(showTime != nil ? 28 : 4)
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.75)
            make.bottom.equalToSuperview().offset(-4)
            if msg.isPatient {
                bubbleTrailing = make.trailing.equalToSuperview().offset(-16).constraint
                bubbleLeading = make.leading.greaterThanOrEqualToSuperview().offset(60).constraint
            } else {
                bubbleLeading = make.leading.equalToSuperview().offset(16).constraint
                bubbleTrailing = make.trailing.lessThanOrEqualToSuperview().offset(-60).constraint
            }
        }

        if msg.isPatient {
            bubbleView.backgroundColor = .fdPrimarySoft
            contentLabel.textColor = .fdText
            bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        } else {
            bubbleView.backgroundColor = .fdSurface
            contentLabel.textColor = .fdText
            bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            bubbleView.layer.shadowColor = UIColor.black.cgColor
            bubbleView.layer.shadowOffset = CGSize(width: 0, height: 1)
            bubbleView.layer.shadowRadius = 2; bubbleView.layer.shadowOpacity = 0.04
        }

        if let time = showTime {
            let timeLbl = contentView.viewWithTag(999) as? UILabel ?? { let l = UILabel(); l.tag = 999; l.font = .fdMicro; l.textColor = .fdMuted; l.textAlignment = .center; contentView.addSubview(l); return l }()
            timeLbl.text = time
            timeLbl.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(6); make.centerX.equalToSuperview()
            }
        } else {
            contentView.viewWithTag(999)?.removeFromSuperview()
        }
    }
}

/// 健康通知卡片 Cell — 居中结构化卡片，使用垂直 StackView 布局
final class NotificationCardCell: UITableViewCell {

    static let reuseIdentifier = "NotificationCardCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none; backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ msg: Message, showTime: String?) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        guard let p = msg.payload else { return }

        let topOffset: CGFloat = showTime != nil ? 32 : 12

        if let time = showTime {
            let tl = UILabel(); tl.text = time; tl.font = .fdMicro; tl.textColor = .fdMuted; tl.textAlignment = .center
            contentView.addSubview(tl)
            tl.snp.makeConstraints { $0.top.equalToSuperview().offset(6); $0.centerX.equalToSuperview() }
        }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 8; card.layer.shadowOpacity = 0.06
        contentView.addSubview(card)

        let contentStack = UIStackView(); contentStack.axis = .vertical; contentStack.spacing = 6
        card.addSubview(contentStack)

        // Header
        let header = buildHeader(p)
        contentStack.addArrangedSubview(header)
        header.snp.makeConstraints { $0.height.equalTo(36) }

        // Data rows
        for row in p.rows {
            contentStack.addArrangedSubview(buildRow(row))
        }

        // Footnote
        if let note = p.footnote {
            let noteBox = UIView(); noteBox.backgroundColor = .fdBg2; noteBox.layer.cornerRadius = 8
            let nl = UILabel(); nl.text = note; nl.font = .fdCaption; nl.textColor = .fdSubtext; nl.numberOfLines = 0
            noteBox.addSubview(nl)
            nl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)) }
            contentStack.addArrangedSubview(noteBox)
        }

        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(topOffset)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.85)
            make.bottom.equalToSuperview().offset(-8)
        }
        contentStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
    }

    private func buildHeader(_ p: NotificationPayload) -> UIView {
        let h = UIView()
        h.backgroundColor = UIColor(hexString: p.accent.softHex); h.layer.cornerRadius = 8
        let icon = UIImageView(image: UIImage(systemName: p.icon.sfSymbol))
        icon.tintColor = UIColor(hexString: p.accent.mainHex); icon.contentMode = .scaleAspectFit
        let title = UILabel(); title.text = p.title; title.font = .fdBodySemibold; title.textColor = .fdText
        h.addSubview(icon); h.addSubview(title)
        icon.snp.makeConstraints { $0.leading.equalToSuperview().offset(10); $0.centerY.equalToSuperview(); $0.size.equalTo(20) }
        title.snp.makeConstraints { $0.leading.equalTo(icon.snp.trailing).offset(8); $0.centerY.equalToSuperview(); $0.trailing.equalToSuperview().offset(-10) }
        return h
    }

    private func buildRow(_ row: NotificationRow) -> UIView {
        let r = UIView()
        let label = UILabel(); label.text = row.label; label.font = .fdCaption; label.textColor = .fdSubtext
        let value = UILabel(); value.text = row.value; value.font = .fdBody; value.textColor = .fdText; value.textAlignment = .right
        r.addSubview(label); r.addSubview(value)
        label.snp.makeConstraints { $0.leading.top.bottom.equalToSuperview() }
        value.snp.makeConstraints { $0.trailing.equalToSuperview(); $0.centerY.equalToSuperview(); $0.leading.greaterThanOrEqualTo(label.snp.trailing).offset(12) }

        if let tone = row.statusTone, let text = row.statusText {
            let badge = UIView(); badge.layer.cornerRadius = 999
            switch tone {
            case .danger: badge.backgroundColor = .fdDangerSoft
            case .warning: badge.backgroundColor = .fdWarningSoft
            case .success: badge.backgroundColor = .fdSuccessSoft
            }
            let bl = UILabel(); bl.text = text; bl.font = .fdMicroSemibold
            switch tone {
            case .danger: bl.textColor = .fdDanger
            case .warning: bl.textColor = UIColor(hexString: "#B47300")
            case .success: bl.textColor = .fdSuccess
            }
            badge.addSubview(bl); r.addSubview(badge)
            bl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 1, left: 5, bottom: 1, right: 5)) }
            badge.snp.makeConstraints { $0.trailing.equalTo(value.snp.leading).offset(-6); $0.centerY.equalTo(value) }
        }
        return r
    }
}

/// 系统消息 Cell — 居中灰色文字
final class SystemMessageCell: UITableViewCell {

    static let reuseIdentifier = "SystemMessageCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none; backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ msg: Message) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let l = UILabel(); l.text = msg.content; l.font = .fdCaption; l.textColor = .fdMuted; l.textAlignment = .center
        contentView.addSubview(l)
        l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 40, bottom: 8, right: 40)) }
    }
}
