import UIKit
import SnapKit
import Kingfisher

/// 融云协议卡片 Cell
/// - AD:SysNotify：统一上传卡样式，按顶层 `messageType` 1/2/3 取字段
/// - AD:Vip / ServiceComment / CheckUserMsg
final class SysNotifyCell: UITableViewCell {
    static let reuseID = "SysNotifyCell"

    weak var delegate: ChatCellDelegate?
    private var currentMessage: ChatMessage?
    private var resolved: IMCardResolved?

    // MARK: - Chrome

    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 15, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.clipsToBounds = true
        return l
    }()
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isHidden = true
        return iv
    }()
    private let metaLabel: UILabel = {
        let l = UILabel()
        l.font = ChatBubbleStyle.metaFont
        l.textColor = ChatBubbleStyle.metaColor
        return l
    }()

    private let cardBackground = ChatBubbleBackgroundView()
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
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
        s.spacing = 8
        return s
    }()

    private let monitorIconCircle: UIView = {
        let v = UIView()
        v.backgroundColor = ChatBubbleStyle.iconCircleFill
        v.layer.cornerRadius = ChatBubbleStyle.Card.iconSize / 2
        v.clipsToBounds = true
        v.isHidden = true
        v.snp.makeConstraints { $0.size.equalTo(ChatBubbleStyle.Card.iconSize) }
        return v
    }()

    private let monitorIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = ChatBubbleStyle.Card.titleFont
        l.textColor = ChatBubbleStyle.primaryText
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
        config.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8)
        config.baseForegroundColor = ChatBubbleStyle.userFill
        config.background.backgroundColor = .clear
        config.background.cornerRadius = 29
        config.background.strokeColor = ChatBubbleStyle.userFill.withAlphaComponent(0.5)
        config.background.strokeWidth = 0.5
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = ChatBubbleStyle.Card.tagFont
            return out
        }
        b.configuration = config
        return b
    }()

    private let dividerView: UIView = {
        let v = UIView()
        v.backgroundColor = ChatBubbleStyle.dividerColor
        v.isHidden = true
        return v
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = ChatBubbleStyle.Card.bodyFont
        l.textColor = ChatBubbleStyle.secondaryText
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

    /// SysNotify CTA（`skipTxt`，缺省「去查看」）；仅按钮可点
    private let actionButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = ChatBubbleStyle.Card.actionFont
        b.layer.cornerRadius = ChatBubbleStyle.Card.actionHeight / 2
        b.clipsToBounds = true
        b.isHidden = true
        return b
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdBg

        ChatBubbleStyle.configureAvatar(avatarLabel, imageView: avatarImageView)
        [avatarLabel, avatarImageView, metaLabel, cardBackground, cardView].forEach(contentView.addSubview)
        monitorIconCircle.addSubview(monitorIconView)
        monitorIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(ChatBubbleStyle.Card.iconGlyphSize)
        }

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
        monitorIconView.kf.cancelDownloadTask()
        monitorIconView.image = nil
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

        metaLabel.font = ChatBubbleStyle.metaFont

        if showUser {
            ChatBubbleStyle.applyAvatar(portraitUrl: msg.portraitUrl, label: avatarLabel, imageView: avatarImageView)
            metaLabel.isHidden = false
            if isStaff {
                metaLabel.text = ChatBubbleStyle.staffMetaText(name: msg.senderName)
            } else if let name = msg.senderName, !name.isEmpty {
                metaLabel.text = name
            } else {
                metaLabel.text = msg.time
            }
            metaLabel.textAlignment = isStaff ? .left : .right
            cardBackground.tail = isStaff ? .left : .right
            cardBackground.fill = .staffGradient
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
        case .sysNotify:
            applyUnifiedSysNotify(card)

        case .checkUser:
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

    private func applyUnifiedSysNotify(_ card: IMCardResolved) {
        applyLeadingIcon(card)
        applyDataSourceTag(card)

        let body = card.bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        if card.showsBodyContent && !body.isEmpty {
            descLabel.attributedText = NSAttributedString(
                string: body,
                attributes: [
                    .font: ChatBubbleStyle.Card.bodyFont,
                    .foregroundColor: ChatBubbleStyle.secondaryText,
                    .paragraphStyle: ChatBubbleStyle.cardParagraphStyle,
                ]
            )
            descLabel.isHidden = false
        } else {
            descLabel.text = nil
            descLabel.isHidden = true
        }

        let rows = card.displayRows
        if !rows.isEmpty {
            dividerView.isHidden = false
            rowsStack.isHidden = false
            rowsStack.spacing = 0
            populateMonitorRows(rows, accent: card.monitorAccentColor)
        }

        applyJumpAction(card)
    }

    private func applyLeadingIcon(_ card: IMCardResolved) {
        monitorIconView.kf.cancelDownloadTask()
        monitorIconView.image = nil
        guard card.showsLeadingIcon,
              let urlStr = card.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: urlStr) else {
            monitorIconCircle.isHidden = true
            return
        }
        monitorIconCircle.isHidden = false
        monitorIconCircle.backgroundColor = ChatBubbleStyle.iconCircleFill
        monitorIconView.contentMode = .scaleAspectFit
        monitorIconView.clipsToBounds = false
        monitorIconView.layer.cornerRadius = 0
        monitorIconView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
    }

    private func applyDataSourceTag(_ card: IMCardResolved) {
        var config = tagButton.configuration ?? .plain()
        if card.showsDataSourceTag, let tag = card.dataSourceTag {
            config.title = tag
            tagButton.configuration = config
            tagButton.isHidden = false
        } else {
            config.title = nil
            tagButton.configuration = config
            tagButton.isHidden = true
        }
    }

    private func applyJumpAction(_ card: IMCardResolved) {
        guard card.showsJumpButton else {
            actionButton.isHidden = true
            return
        }
        actionButton.isHidden = false
        actionButton.isEnabled = true
        actionButton.alpha = 1
        actionButton.backgroundColor = ChatBubbleStyle.actionFill
        actionButton.setTitleColor(ChatBubbleStyle.actionText, for: .normal)
        actionButton.setTitle(card.jumpButtonTitle, for: .normal)
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
                    make.top.equalToSuperview().offset(4)
                    make.leading.trailing.bottom.equalToSuperview()
                }
                rowsStack.addArrangedSubview(wrap)
            }
        }
    }

    private func shouldRenderStatusPill(label: String, colorHex: String?) -> Bool {
        if isMeasurementResultRow(label) { return false }
        if let colorHex, !colorHex.isEmpty { return true }
        return false
    }

    private func isMeasurementResultRow(_ label: String) -> Bool {
        label.contains("测量结果") || label.contains("结果")
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
        row.spacing = 8
        row.distribution = .fill

        let left = UILabel()
        left.font = ChatBubbleStyle.Card.rowLabelFont
        left.textColor = ChatBubbleStyle.secondaryText
        left.text = label.hasSuffix("：") || label.hasSuffix(":") ? label : "\(label)"
        left.setContentHuggingPriority(.required, for: .horizontal)
        left.setContentCompressionResistancePriority(.required, for: .horizontal)

        row.addArrangedSubview(left)

        if asStatusPill {
            row.addArrangedSubview(makeStatusPill(text: value, colorHex: colorHex, fallbackAccent: fallbackAccent))
            let spacer = UIView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            row.addArrangedSubview(spacer)
        } else {
            let right = UILabel()
            right.font = ChatBubbleStyle.Card.rowValueFont
            right.textColor = resolvedColor(colorHex) ?? ChatBubbleStyle.primaryText
            right.text = value
            right.numberOfLines = 0
            right.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            row.addArrangedSubview(right)
        }

        let wrap = UIView()
        wrap.addSubview(row)
        row.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(ChatBubbleStyle.Card.rowVerticalInset)
            make.leading.trailing.equalToSuperview()
        }
        return wrap
    }

    private func statusPillBackground(colorHex: String?, accent: UIColor) -> UIColor {
        let hex = (colorHex ?? "").uppercased()
        if hex.contains("2EBA83") { return UIColor(hexString: "#E9F6F2") }
        if hex.contains("DF0340") { return UIColor(hexString: "#FFEDED") }
        return accent.withAlphaComponent(0.12)
    }

    /// 对齐标题行 `tagButton`：Configuration 保证 padding 与 intrinsic size，避免 UIStackView 内 UIView 背景与文字错位
    private func makeStatusPill(text: String, colorHex: String?, fallbackAccent: UIColor) -> UIButton {
        let accent = resolvedColor(colorHex) ?? fallbackAccent
        let button = UIButton(type: .custom)
        button.isUserInteractionEnabled = false
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)

        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8)
        config.baseForegroundColor = accent
        config.background.backgroundColor = statusPillBackground(colorHex: colorHex, accent: accent)
        config.background.cornerRadius = 29
        config.title = text
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = ChatBubbleStyle.Card.statusFont
            return out
        }
        button.configuration = config
        return button
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
        stack.layer.cornerRadius = 12
        stack.layer.borderWidth = 1
        stack.layer.borderColor = ChatBubbleStyle.actionFill.cgColor
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
            row.backgroundColor = ChatBubbleStyle.actionFill
        } else {
            row.backgroundColor = .white
        }
        for text in cols {
            let label = UILabel()
            label.text = text
            label.font = isHeader ? ChatBubbleStyle.Card.rowLabelFont : ChatBubbleStyle.Card.rowValueFont
            label.textColor = isHeader ? ChatBubbleStyle.userFill : ChatBubbleStyle.primaryText
            label.textAlignment = .left
            label.numberOfLines = 2
            let wrap = UIView()
            if !isHeader {
                wrap.layer.borderWidth = 0
            }
            wrap.addSubview(label)
            let columnInset = ChatBubbleStyle.Card.tableColumnHorizontalInset
            let verticalInset = isHeader
                ? ChatBubbleStyle.Card.tableHeaderVerticalInset
                : ChatBubbleStyle.Card.tableCellVerticalInset
            label.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(
                    UIEdgeInsets(top: verticalInset, left: columnInset, bottom: verticalInset, right: columnInset)
                )
            }
            if !isHeader {
                let line = UIView()
                line.backgroundColor = ChatBubbleStyle.dividerColor
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
            nameLabel.font = .fdFont(ofSize: 14)
            nameLabel.textColor = .fdMuted
            let stars = UILabel()
            stars.text = "★★★★★"
            stars.font = .fdFont(ofSize: 16)
            stars.textColor = UIColor.fdBorder
            row.addArrangedSubview(nameLabel)
            row.addArrangedSubview(stars)
            commentStack.addArrangedSubview(row)
        }
        let input = UILabel()
        input.text = "  评价内容（只读）"
        input.font = .fdFont(ofSize: 14)
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
                .font: UIFont.fdFont(ofSize: 17, weight: .bold),
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

    private func layoutForStaff(_ isStaff: Bool, hasCover _: Bool, showUser: Bool, card: IMCardResolved?) {
        let metaOffset: ConstraintOffsetTarget = showUser ? 4 : 8
        let isUnified = card?.isUnifiedSysNotify == true
        let variant = card?.variant
        let showRows = (isUnified && !(card?.displayRows.isEmpty ?? true)) || variant == .vip
        let showComment = variant == .serviceComment
        let showAction = isUnified && (card?.showsJumpButton == true)
        let showDesc: Bool = {
            if isUnified {
                return card?.showsBodyContent == true && !(card?.bodyText.isEmpty ?? true)
            }
            switch variant {
            case .vip: return false
            case .checkUser, .serviceComment:
                return !(card?.bodyText.isEmpty ?? true)
            default: return false
            }
        }()

        if showUser {
            avatarLabel.snp.remakeConstraints { make in
                if isStaff {
                    make.leading.equalToSuperview().offset(ChatBubbleStyle.horizontalInset)
                } else {
                    make.trailing.equalToSuperview().offset(-ChatBubbleStyle.horizontalInset)
                }
                make.top.equalToSuperview().offset(8).priority(999)
                make.size.equalTo(ChatBubbleStyle.avatarSize)
            }
            avatarImageView.snp.remakeConstraints { make in
                make.edges.equalTo(avatarLabel)
            }
            metaLabel.snp.remakeConstraints { make in
                make.top.equalTo(avatarLabel)
                if isStaff {
                    make.leading.equalTo(avatarLabel.snp.trailing).offset(ChatBubbleStyle.avatarToContentGap)
                } else {
                    make.trailing.equalTo(avatarLabel.snp.leading).offset(-ChatBubbleStyle.avatarToContentGap)
                }
            }
        }

        cardBackground.snp.remakeConstraints { make in
            make.edges.equalTo(cardView)
        }

        cardView.snp.remakeConstraints { make in
            if showUser {
                make.top.equalTo(metaLabel.snp.bottom).offset(metaOffset)
            } else {
                make.top.equalToSuperview().offset(8).priority(999)
            }
            make.bottom.equalToSuperview().offset(-8).priority(999)
            make.width.equalTo(ChatBubbleStyle.cardBubbleWidth())
            if isStaff {
                make.leading.equalToSuperview().offset(showUser ? ChatBubbleStyle.contentStartOffset : ChatBubbleStyle.horizontalInset)
            } else {
                make.trailing.equalToSuperview().offset(showUser ? -ChatBubbleStyle.contentStartOffset : -ChatBubbleStyle.horizontalInset)
            }
        }

        let pad = ChatBubbleStyle.Card.padding
        let showTag = isUnified && (card?.showsDataSourceTag == true)

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

        if isUnified {
            layoutUnifiedSysNotify(
                pad: pad,
                showDesc: showDesc,
                showRows: showRows,
                showAction: showAction
            )
            return
        }

        actionButton.snp.remakeConstraints { make in
            make.top.equalTo(titleRow.snp.bottom)
            make.leading.equalToSuperview().offset(pad)
            make.height.equalTo(0)
        }
        dividerView.snp.remakeConstraints { make in
            make.top.equalTo(titleRow.snp.bottom)
            make.leading.equalToSuperview().offset(pad)
            make.height.equalTo(0)
        }

        if showDesc {
            descLabel.snp.remakeConstraints { make in
                make.top.equalTo(titleRow.snp.bottom).offset(6)
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

        if showRows {
            rowsStack.snp.remakeConstraints { make in
                make.top.equalTo(afterDesc).offset(8)
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
                    make.top.equalTo(afterDesc).offset(8)
                    make.leading.trailing.equalToSuperview().inset(pad)
                    make.bottom.equalToSuperview().offset(-pad)
                }
            } else if showDesc {
                descLabel.snp.remakeConstraints { make in
                    make.top.equalTo(titleRow.snp.bottom).offset(6)
                    make.leading.trailing.equalToSuperview().inset(pad)
                    make.bottom.equalToSuperview().offset(-pad)
                }
            } else {
                titleRow.snp.remakeConstraints { make in
                    make.top.equalToSuperview().offset(pad)
                    make.leading.trailing.equalToSuperview().inset(pad)
                    make.bottom.equalToSuperview().offset(-pad)
                }
            }
        }
    }

    /// 统一 SysNotify：title → 可选 content → 可选 rows → 可选 CTA
    private func layoutUnifiedSysNotify(
        pad: CGFloat,
        showDesc: Bool,
        showRows: Bool,
        showAction: Bool
    ) {
        commentStack.snp.remakeConstraints { make in
            make.top.equalTo(titleRow.snp.bottom)
            make.leading.equalToSuperview().offset(pad)
            make.height.equalTo(0)
        }

        if showDesc {
            descLabel.snp.remakeConstraints { make in
                make.top.equalTo(titleRow.snp.bottom).offset(ChatBubbleStyle.Card.titleToBodyGap)
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

        if showRows {
            dividerView.snp.remakeConstraints { make in
                make.top.equalTo(afterDesc).offset(ChatBubbleStyle.Card.bodyToDividerGap)
                make.leading.trailing.equalToSuperview().inset(pad)
                make.height.equalTo(1 / UIScreen.main.scale)
            }
            rowsStack.snp.remakeConstraints { make in
                make.top.equalTo(dividerView.snp.bottom).offset(ChatBubbleStyle.Card.dividerToRowsGap)
                make.leading.trailing.equalToSuperview().inset(ChatBubbleStyle.Card.rowsContentInset)
            }
        } else {
            dividerView.snp.remakeConstraints { make in
                make.top.equalTo(afterDesc)
                make.leading.equalToSuperview().offset(pad)
                make.height.equalTo(0)
            }
            rowsStack.snp.remakeConstraints { make in
                make.top.equalTo(afterDesc)
                make.leading.equalToSuperview().offset(pad)
                make.height.equalTo(0)
            }
        }

        let afterBody = showRows ? rowsStack.snp.bottom : afterDesc

        if showAction {
            actionButton.snp.remakeConstraints { make in
                make.top.equalTo(afterBody).offset(ChatBubbleStyle.Card.actionTopGap)
                make.leading.trailing.equalToSuperview().inset(pad)
                make.height.equalTo(ChatBubbleStyle.Card.actionHeight)
                make.bottom.equalToSuperview().offset(-pad)
            }
        } else {
            actionButton.snp.remakeConstraints { make in
                make.top.equalTo(afterBody)
                make.leading.equalToSuperview().offset(pad)
                make.height.equalTo(0)
            }
            if showRows {
                rowsStack.snp.remakeConstraints { make in
                    make.top.equalTo(dividerView.snp.bottom).offset(ChatBubbleStyle.Card.dividerToRowsGap)
                    make.leading.trailing.equalToSuperview().inset(ChatBubbleStyle.Card.rowsContentInset)
                    make.bottom.equalToSuperview().offset(-pad)
                }
            } else if showDesc {
                descLabel.snp.remakeConstraints { make in
                    make.top.equalTo(titleRow.snp.bottom).offset(ChatBubbleStyle.Card.titleToBodyGap)
                    make.leading.trailing.equalToSuperview().inset(pad)
                    make.bottom.equalToSuperview().offset(-pad)
                }
            } else {
                titleRow.snp.remakeConstraints { make in
                    make.top.equalToSuperview().offset(pad)
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
