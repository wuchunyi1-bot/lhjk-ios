import UIKit
import SnapKit
import Kingfisher

/// 融云协议卡片 Cell
/// - AD:SysNotify：`monitorReminder`（实时提醒）/ `monitor`（录入成功）/ `sysNotify`（C-sys）
/// - AD:Vip / ServiceComment / CheckUserMsg
final class SysNotifyCell: UITableViewCell {
    static let reuseID = "SysNotifyCell"

    weak var delegate: ChatCellDelegate?
    private var currentMessage: ChatMessage?
    private var resolved: IMCardResolved?

    // MARK: - Chrome

    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 13, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.layer.cornerRadius = 17
        l.clipsToBounds = true
        return l
    }()
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 17
        iv.clipsToBounds = true
        iv.isHidden = true
        return iv
    }()
    private let metaLabel: UILabel = {
        let l = UILabel()
        l.font = .fdMicro
        l.textColor = .fdMuted
        return l
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 18
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(hexString: "#F0F0F0").cgColor
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

    // MARK: - Monitor / common header

    /// 标题行：icon + title（tag 单独 SnapKit 贴右侧，避免 Stack 压宽）
    private let titleRow: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 10
        return s
    }()

    private let monitorIconCircle: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14
        v.clipsToBounds = true
        v.isHidden = true
        v.snp.makeConstraints { $0.size.equalTo(28) }
        return v
    }()

    private let monitorIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 15, weight: .bold)
        l.textColor = .fdText
        l.numberOfLines = 2
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        l.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return l
    }()

    /// 原型 `chat-card__source-tag`：custom button，避免 system tint；Configuration 保证 padding
    private let tagButton: UIButton = {
        let b = UIButton(type: .custom)
        b.isUserInteractionEnabled = false
        b.isHidden = true
        b.setContentHuggingPriority(.required, for: .horizontal)
        b.setContentCompressionResistancePriority(.required, for: .horizontal)

        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10)
        config.baseForegroundColor = UIColor(hexString: "#9A9DA8")
        config.background.backgroundColor = UIColor(hexString: "#F0F0F0")
        config.background.cornerRadius = 999
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = .fdFont(ofSize: 11, weight: .regular)
            return out
        }
        b.configuration = config
        return b
    }()

    private let dividerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#F0F0F0")
        v.isHidden = true
        return v
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = .fdBody
        l.textColor = .fdSubtext
        l.numberOfLines = 0
        return l
    }()

    private let rowsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        s.isHidden = true
        return s
    }()

    private let commentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 8
        s.isHidden = true
        return s
    }()

    /// 实时提醒 CTA「去完成 ›」
    private let actionButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = .fdFont(ofSize: 13, weight: .bold)
        b.layer.cornerRadius = 12
        b.clipsToBounds = true
        b.isHidden = true
        return b
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdBg

        [avatarLabel, avatarImageView, metaLabel, cardView].forEach(contentView.addSubview)
        monitorIconCircle.addSubview(monitorIconView)
        monitorIconView.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(14) }

        titleRow.addArrangedSubview(monitorIconCircle)
        titleRow.addArrangedSubview(titleLabel)
        [coverImageView, titleRow, tagButton, dividerView, descLabel, rowsStack, commentStack, actionButton]
            .forEach(cardView.addSubview)

        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        cardView.addGestureRecognizer(longPress)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        clearStack(rowsStack)
        clearStack(commentStack)
        resolved = nil
        currentMessage = nil
        monitorIconCircle.isHidden = true
        tagButton.isHidden = true
        if var config = tagButton.configuration {
            config.title = nil
            tagButton.configuration = config
        }
        dividerView.isHidden = true
        actionButton.isHidden = true
        actionButton.setTitle(nil, for: .normal)
    }

    // MARK: - Configure

    func configure(_ msg: ChatMessage, tone: String, convRole: ConversationRole) {
        currentMessage = msg
        let card = IMCardResolver.resolve(from: msg)
        resolved = card
        let isStaff = msg.isStaff
        let showUser = card?.isShowUser ?? true

        metaLabel.font = .fdMicro

        if showUser {
            if let urlStr = msg.portraitUrl, !urlStr.isEmpty, let url = URL(string: urlStr) {
                avatarImageView.isHidden = false
                avatarLabel.isHidden = true
                avatarImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
            } else {
                avatarImageView.isHidden = true
                avatarLabel.isHidden = false
                avatarLabel.text = isStaff
                    ? (msg.avatar ?? msg.senderName?.prefix(1).description ?? "?")
                    : "我"
                avatarLabel.backgroundColor = isStaff
                    ? UIColor(hexString: tone)
                    : UIColor(hexString: "#FF7A50")
            }
            metaLabel.isHidden = false
            if isStaff {
                metaLabel.text = [msg.senderName, msg.senderRole, msg.time]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }
                    .joined(separator: " · ")
            } else if let name = msg.senderName, !name.isEmpty {
                metaLabel.text = [name, msg.time]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }
                    .joined(separator: " · ")
            } else {
                metaLabel.text = msg.time
            }
            metaLabel.textAlignment = isStaff ? .left : .right
        } else {
            avatarLabel.isHidden = true
            avatarImageView.isHidden = true
            metaLabel.isHidden = true
        }

        applyCardContent(card)
        layoutForStaff(isStaff, hasCover: card?.showsCover == true, showUser: showUser, card: card)
    }

    private func applyCardContent(_ card: IMCardResolved?) {
        guard let card else {
            titleLabel.text = ""
            descLabel.text = ""
            coverImageView.isHidden = true
            rowsStack.isHidden = true
            commentStack.isHidden = true
            dividerView.isHidden = true
            monitorIconCircle.isHidden = true
            actionButton.isHidden = true
            return
        }

        titleLabel.attributedText = nil
        titleLabel.text = card.title
        if card.variant == .vip {
            titleLabel.attributedText = highlightPregnancyWeek(in: card.title)
        }

        rowsStack.isHidden = true
        commentStack.isHidden = true
        descLabel.isHidden = false
        dividerView.isHidden = true
        monitorIconCircle.isHidden = true
        actionButton.isHidden = true
        tagButton.isHidden = true
        if var config = tagButton.configuration {
            config.title = nil
            tagButton.configuration = config
        }
        clearStack(rowsStack)
        clearStack(commentStack)

        switch card.variant {
        case .monitorReminder:
            applyMonitorHeader(card)
            descLabel.text = card.bodyText
            descLabel.isHidden = card.bodyText.isEmpty
            dividerView.isHidden = false
            rowsStack.isHidden = false
            rowsStack.spacing = 0
            populateMonitorRows(card.monitorRows, accent: card.monitorAccentColor)
            applyReminderAction(card)

        case .monitor:
            applyMonitorHeader(card)
            descLabel.isHidden = true
            dividerView.isHidden = false
            rowsStack.isHidden = false
            rowsStack.spacing = 0
            populateMonitorRows(card.monitorRows, accent: card.monitorAccentColor)

        case .sysNotify, .checkUser:
            descLabel.text = card.bodyText
            descLabel.isHidden = card.bodyText.isEmpty

        case .vip:
            descLabel.isHidden = true
            rowsStack.isHidden = false
            rowsStack.spacing = 6
            populateLabelValueRows(card.contentRows)

        case .serviceComment:
            descLabel.text = card.bodyText
            commentStack.isHidden = false
            populateCommentReadonly()
        }

        if card.showsCover, let imgUrl = card.imageUrl, let url = URL(string: imgUrl) {
            coverImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
            coverImageView.isHidden = false
        } else {
            coverImageView.image = nil
            coverImageView.isHidden = true
        }
    }

    private func applyMonitorHeader(_ card: IMCardResolved) {
        // 图标色仅跟 monitorType
        let accent = card.monitorAccentColor
        monitorIconCircle.isHidden = false
        monitorIconCircle.backgroundColor = accent.withAlphaComponent(0.08)
        monitorIconView.tintColor = accent
        monitorIconView.image = UIImage(systemName: monitorSymbol(for: card.monitorType))?.withRenderingMode(.alwaysTemplate)

        // dataSourceTag → 原型 source-tag
        var config = tagButton.configuration ?? .plain()
        if let tag = card.dataSourceTag?.trimmingCharacters(in: .whitespacesAndNewlines), !tag.isEmpty {
            config.title = tag
            tagButton.configuration = config
            tagButton.isHidden = false
        } else {
            config.title = nil
            tagButton.configuration = config
            tagButton.isHidden = true
        }
    }

    private func applyReminderAction(_ card: IMCardResolved) {
        let accent = card.monitorAccentColor
        actionButton.isHidden = false
        actionButton.backgroundColor = accent.withAlphaComponent(0.12)
        actionButton.setTitleColor(accent, for: .normal)
        if card.isReminderCompleted {
            actionButton.setTitle("已完成", for: .normal)
            actionButton.isEnabled = false
            actionButton.alpha = 0.55
        } else {
            actionButton.setTitle("去完成 ›", for: .normal)
            actionButton.isEnabled = true
            actionButton.alpha = 1
        }
    }

    private func monitorSymbol(for type: String?) -> String {
        switch IMMonitorReminderRoute.normalizeMonitorType(type) {
        case "pressure": return "waveform.path.ecg"
        case "sugar": return "drop.fill"
        case "weight": return "chart.bar.fill"
        case "temperature": return "thermometer.medium"
        case "diet": return "fork.knife"
        case "sport": return "figure.walk"
        default: return "heart.fill"
        }
    }

    // MARK: - Monitor rows（对齐 funde-client chat-card__rows）

    private func populateMonitorRows(_ rows: [IMMonitorRow], accent: UIColor) {
        for row in rows {
            switch row {
            case .text(let label, let value, let colorHex):
                let isStatus = shouldRenderStatusPill(label: label, colorHex: colorHex)
                rowsStack.addArrangedSubview(
                    makeMonitorTextRow(
                        label: label,
                        value: value,
                        colorHex: colorHex,
                        asStatusPill: isStatus,
                        fallbackAccent: accent
                    )
                )
            case .table(let headers, let cells):
                let wrap = UIView()
                let table = makeTableView(headers: headers, cells: cells)
                wrap.addSubview(table)
                table.snp.makeConstraints { make in
                    make.top.equalToSuperview().offset(8)
                    make.leading.trailing.bottom.equalToSuperview()
                }
                rowsStack.addArrangedSubview(wrap)
            }
        }
    }

    private func shouldRenderStatusPill(label: String, colorHex: String?) -> Bool {
        if let colorHex, !colorHex.isEmpty { return true }
        return label.contains("测量结果") || label.contains("结果")
    }

    private func makeMonitorTextRow(
        label: String,
        value: String,
        colorHex: String?,
        asStatusPill: Bool,
        fallbackAccent: UIColor
    ) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 4
        row.distribution = .fill

        let left = UILabel()
        left.font = .fdFont(ofSize: 12)
        left.textColor = .fdMuted
        left.text = label.hasSuffix("：") || label.hasSuffix(":") ? label : "\(label)："
        left.setContentHuggingPriority(.required, for: .horizontal)
        left.setContentCompressionResistancePriority(.required, for: .horizontal)

        row.addArrangedSubview(left)

        if asStatusPill {
            let accent = resolvedColor(colorHex) ?? fallbackAccent
            let pillWrap = UIView()
            pillWrap.backgroundColor = accent.withAlphaComponent(0.12)
            pillWrap.layer.cornerRadius = 8
            pillWrap.clipsToBounds = true
            pillWrap.setContentHuggingPriority(.required, for: .horizontal)
            pillWrap.setContentCompressionResistancePriority(.required, for: .horizontal)

            let pill = UILabel()
            pill.text = value
            pill.font = .fdFont(ofSize: 10, weight: .bold)
            pill.textColor = accent
            pill.numberOfLines = 1
            pill.setContentCompressionResistancePriority(.required, for: .horizontal)
            pillWrap.addSubview(pill)
            pill.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
            }
            row.addArrangedSubview(pillWrap)
            let spacer = UIView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            row.addArrangedSubview(spacer)
        } else {
            let right = UILabel()
            right.font = .fdFont(ofSize: 12)
            right.textColor = .fdText
            right.text = value
            right.numberOfLines = 0
            right.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            row.addArrangedSubview(right)
        }

        let wrap = UIView()
        wrap.addSubview(row)
        row.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(5)
            make.leading.trailing.equalToSuperview()
        }
        return wrap
    }

    private func resolvedColor(_ hex: String?) -> UIColor? {
        guard var h = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !h.isEmpty else { return nil }
        if !h.hasPrefix("#") { h = "#\(h)" }
        return UIColor(hexString: h)
    }

    private func populateLabelValueRows(_ rows: [(label: String, value: String)]) {
        for row in rows {
            if row.label.isEmpty {
                let line = UILabel()
                line.numberOfLines = 0
                line.font = .fdBody
                line.textColor = .fdSubtext
                line.text = row.value
                rowsStack.addArrangedSubview(line)
            } else {
                rowsStack.addArrangedSubview(
                    makeMonitorTextRow(
                        label: row.label,
                        value: row.value,
                        colorHex: nil,
                        asStatusPill: false,
                        fallbackAccent: .fdPrimary
                    )
                )
            }
        }
    }

    private func makeTableView(headers: [String], cells: [[String]]) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.layer.cornerRadius = 10
        stack.layer.borderWidth = 1
        stack.layer.borderColor = UIColor(hexString: "#F0F0F0").cgColor
        stack.clipsToBounds = true

        stack.addArrangedSubview(makeTableRow(headers, isHeader: true))
        for cellRow in cells {
            let padded = headers.indices.map { i in i < cellRow.count ? cellRow[i] : "" }
            stack.addArrangedSubview(makeTableRow(padded, isHeader: false))
        }
        return stack
    }

    private func makeTableRow(_ cols: [String], isHeader: Bool) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 0
        if isHeader {
            row.backgroundColor = UIColor(hexString: "#F5F5F5")
        } else {
            row.backgroundColor = .white
        }
        for text in cols {
            let label = UILabel()
            label.text = text
            label.font = .fdFont(ofSize: 12)
            label.textColor = isHeader ? .fdSubtext : .fdText
            label.textAlignment = .left
            label.numberOfLines = 2
            let wrap = UIView()
            if !isHeader {
                wrap.layer.borderWidth = 0
            }
            wrap.addSubview(label)
            label.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10))
            }
            // 底部分隔
            if !isHeader {
                let line = UIView()
                line.backgroundColor = UIColor(hexString: "#F0F0F0")
                wrap.addSubview(line)
                line.snp.makeConstraints { make in
                    make.leading.trailing.bottom.equalToSuperview()
                    make.height.equalTo(1 / UIScreen.main.scale)
                }
            }
            row.addArrangedSubview(wrap)
        }
        return row
    }

    private func populateCommentReadonly() {
        let labels = ["服务态度", "专业程度", "整体满意度"]
        for name in labels {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.alignment = .center
            let nameLabel = UILabel()
            nameLabel.text = name
            nameLabel.font = .fdFont(ofSize: 12)
            nameLabel.textColor = .fdMuted
            let stars = UILabel()
            stars.text = "★★★★★"
            stars.font = .fdFont(ofSize: 14)
            stars.textColor = UIColor.fdBorder
            row.addArrangedSubview(nameLabel)
            row.addArrangedSubview(stars)
            commentStack.addArrangedSubview(row)
        }
        let input = UILabel()
        input.text = "  评价内容（只读）"
        input.font = .fdFont(ofSize: 12)
        input.textColor = .fdMuted
        input.backgroundColor = .fdBg2
        input.layer.cornerRadius = 8
        input.clipsToBounds = true
        input.snp.makeConstraints { $0.height.equalTo(36) }
        commentStack.addArrangedSubview(input)
    }

    private func highlightPregnancyWeek(in title: String) -> NSAttributedString {
        let attr = NSMutableAttributedString(
            string: title,
            attributes: [
                .font: UIFont.fdFont(ofSize: 15, weight: .bold),
                .foregroundColor: UIColor.fdText,
            ]
        )
        guard let regex = try? NSRegularExpression(pattern: #"孕\d+-\d+周"#) else { return attr }
        let range = NSRange(title.startIndex..., in: title)
        regex.enumerateMatches(in: title, options: [], range: range) { match, _, _ in
            guard let match else { return }
            attr.addAttributes([.foregroundColor: UIColor.fdPrimary], range: match.range)
        }
        return attr
    }

    private func clearStack(_ stack: UIStackView) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    // MARK: - Layout

    private func layoutForStaff(_ isStaff: Bool, hasCover: Bool, showUser: Bool, card: IMCardResolved?) {
        let metaOffset: ConstraintOffsetTarget = showUser ? 4 : 8
        let variant = card?.variant
        let isMonitor = variant == .monitor
        let isReminder = variant == .monitorReminder
        let isMonitorLike = isMonitor || isReminder
        let showRows = isMonitorLike || variant == .vip
        let showComment = variant == .serviceComment
        let showAction = isReminder && !actionButton.isHidden
        let showDesc: Bool = {
            switch variant {
            case .monitor, .vip: return false
            case .monitorReminder:
                return !(card?.bodyText.isEmpty ?? true)
            case .sysNotify, .checkUser, .serviceComment:
                return !(card?.bodyText.isEmpty ?? true)
            case .none: return false
            }
        }()

        if showUser {
            avatarLabel.snp.remakeConstraints { make in
                if isStaff {
                    make.leading.equalToSuperview().offset(16)
                } else {
                    make.trailing.equalToSuperview().offset(-16)
                }
                make.top.equalToSuperview().offset(8).priority(999)
                make.size.equalTo(34)
            }
            avatarImageView.snp.remakeConstraints { make in
                make.edges.equalTo(avatarLabel)
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
                make.top.equalToSuperview().offset(8).priority(999)
            }
            make.bottom.equalToSuperview().offset(-8).priority(999)
            make.width.equalTo(isMonitorLike ? 268 : 260)
            if isStaff {
                make.leading.equalToSuperview().offset(showUser ? 58 : 16)
            } else {
                make.trailing.equalToSuperview().offset(showUser ? -58 : -16)
            }
        }

        let pad: CGFloat = isMonitorLike ? 14 : 12
        let showTag = isMonitorLike && !tagButton.isHidden

        if hasCover {
            coverImageView.snp.remakeConstraints { make in
                make.top.leading.trailing.equalToSuperview().inset(pad)
                make.height.equalTo(120)
            }
            titleRow.snp.remakeConstraints { make in
                make.top.equalTo(coverImageView.snp.bottom).offset(10)
                make.leading.equalToSuperview().inset(pad)
                if showTag {
                    make.trailing.equalTo(tagButton.snp.leading).offset(-8)
                } else {
                    make.trailing.equalToSuperview().inset(pad)
                }
            }
        } else {
            coverImageView.snp.remakeConstraints { make in
                make.top.leading.equalToSuperview()
                make.width.height.equalTo(0)
            }
            titleRow.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(pad)
                make.leading.equalToSuperview().inset(pad)
                if showTag {
                    make.trailing.equalTo(tagButton.snp.leading).offset(-8)
                } else {
                    make.trailing.equalToSuperview().inset(pad)
                }
            }
        }

        if showTag {
            tagButton.snp.remakeConstraints { make in
                make.centerY.equalTo(titleRow)
                make.trailing.equalToSuperview().inset(pad)
            }
        } else {
            tagButton.snp.remakeConstraints { make in
                make.centerY.equalTo(titleRow)
                make.trailing.equalToSuperview().inset(pad)
                make.width.height.equalTo(0)
            }
        }

        // 提醒卡：title → desc → divider → rows → action
        // 录入成功：title → divider → rows
        if isReminder {
            if showDesc {
                descLabel.snp.remakeConstraints { make in
                    make.top.equalTo(titleRow.snp.bottom).offset(8)
                    make.leading.trailing.equalToSuperview().inset(pad)
                }
            } else {
                descLabel.snp.remakeConstraints { make in
                    make.top.equalTo(titleRow.snp.bottom)
                    make.leading.equalToSuperview().offset(pad)
                    make.height.equalTo(0)
                }
            }
            let afterDesc = showDesc ? descLabel.snp.bottom : titleRow.snp.bottom
            dividerView.snp.remakeConstraints { make in
                make.top.equalTo(afterDesc).offset(10)
                make.leading.trailing.equalToSuperview().inset(pad)
                make.height.equalTo(1 / UIScreen.main.scale)
            }
            rowsStack.snp.remakeConstraints { make in
                make.top.equalTo(dividerView.snp.bottom).offset(2)
                make.leading.trailing.equalToSuperview().inset(pad)
            }
            commentStack.snp.remakeConstraints { make in
                make.top.equalTo(rowsStack.snp.bottom)
                make.leading.equalToSuperview().offset(pad)
                make.height.equalTo(0)
            }
            if showAction {
                actionButton.snp.remakeConstraints { make in
                    make.top.equalTo(rowsStack.snp.bottom).offset(10)
                    make.leading.trailing.equalToSuperview().inset(pad)
                    make.height.equalTo(36)
                    make.bottom.equalToSuperview().offset(-pad)
                }
            } else {
                actionButton.snp.remakeConstraints { make in
                    make.top.equalTo(rowsStack.snp.bottom)
                    make.leading.equalToSuperview().offset(pad)
                    make.height.equalTo(0)
                }
                rowsStack.snp.remakeConstraints { make in
                    make.top.equalTo(dividerView.snp.bottom).offset(2)
                    make.leading.trailing.equalToSuperview().inset(pad)
                    make.bottom.equalToSuperview().offset(-pad)
                }
            }
            return
        }

        actionButton.snp.remakeConstraints { make in
            make.top.equalTo(titleRow.snp.bottom)
            make.leading.equalToSuperview().offset(pad)
            make.height.equalTo(0)
        }

        let showDivider = isMonitor
        if showDivider {
            dividerView.snp.remakeConstraints { make in
                make.top.equalTo(titleRow.snp.bottom).offset(10)
                make.leading.trailing.equalToSuperview().inset(pad)
                make.height.equalTo(1 / UIScreen.main.scale)
            }
        } else {
            dividerView.snp.remakeConstraints { make in
                make.top.equalTo(titleRow.snp.bottom)
                make.leading.equalToSuperview().offset(pad)
                make.height.equalTo(0)
            }
        }

        let afterHeader = showDivider ? dividerView.snp.bottom : titleRow.snp.bottom

        if showDesc {
            descLabel.snp.remakeConstraints { make in
                make.top.equalTo(afterHeader).offset(6)
                make.leading.trailing.equalToSuperview().inset(pad)
            }
        } else {
            descLabel.snp.remakeConstraints { make in
                make.top.equalTo(afterHeader)
                make.leading.equalToSuperview().offset(pad)
                make.height.equalTo(0)
            }
        }

        let afterDesc = showDesc ? descLabel.snp.bottom : afterHeader

        if showRows {
            rowsStack.snp.remakeConstraints { make in
                make.top.equalTo(afterDesc).offset(showDivider ? 2 : 8)
                make.leading.trailing.equalToSuperview().inset(pad)
            }
        } else {
            rowsStack.snp.remakeConstraints { make in
                make.top.equalTo(afterDesc)
                make.leading.equalToSuperview().offset(pad)
                make.height.equalTo(0)
            }
        }

        let afterRows = showRows ? rowsStack.snp.bottom : afterDesc

        if showComment {
            commentStack.snp.remakeConstraints { make in
                make.top.equalTo(afterRows).offset(8)
                make.leading.trailing.equalToSuperview().inset(pad)
                make.bottom.equalToSuperview().offset(-pad)
            }
        } else {
            commentStack.snp.remakeConstraints { make in
                make.top.equalTo(afterRows)
                make.leading.equalToSuperview().offset(pad)
                make.height.equalTo(0)
            }
            if showRows {
                rowsStack.snp.remakeConstraints { make in
                    make.top.equalTo(afterDesc).offset(showDivider ? 2 : 8)
                    make.leading.trailing.equalToSuperview().inset(pad)
                    make.bottom.equalToSuperview().offset(-pad)
                }
            } else if showDesc {
                descLabel.snp.remakeConstraints { make in
                    make.top.equalTo(afterHeader).offset(6)
                    make.leading.trailing.equalToSuperview().inset(pad)
                    make.bottom.equalToSuperview().offset(-pad)
                }
            } else {
                titleRow.snp.remakeConstraints { make in
                    if hasCover {
                        make.top.equalTo(coverImageView.snp.bottom).offset(10)
                    } else {
                        make.top.equalToSuperview().offset(pad)
                    }
                    make.leading.trailing.equalToSuperview().inset(pad)
                    make.bottom.equalToSuperview().offset(-pad)
                }
            }
        }
    }

    @objc private func actionTapped() {
        guard let msg = currentMessage else { return }
        delegate?.cellDidTapIMCard(self, message: msg)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let msg = currentMessage else { return }
        delegate?.cellDidLongPress(self, message: msg)
    }
}
