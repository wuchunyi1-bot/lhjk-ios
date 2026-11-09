import UIKit
import SnapKit
import Kingfisher

/// 融云协议卡片 Cell
/// - AD:SysNotify：统一上传卡样式，按顶层 `messageType` 1/2/3 取字段
/// - AD:Vip / ServiceComment / CheckUserMsg
final class SysNotifyCell: UITableViewCell {
    static let reuseID = "SysNotifyCell"

    weak var delegate: ChatCellDelegate?
    /// 饮食卡餐食图点击，只预览大图
    var onTapMealPhoto: ((String) -> Void)?
    private var currentMessage: ChatMessage?
    private var resolved: IMCardResolved?

    // MARK: - Chrome

    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(designSize: 15, weight: .bold)
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

    private let summaryStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 10
        s.isHidden = true
        return s
    }()

    private let analysisCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#F4F7FC")
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 0.5
        v.layer.borderColor = UIColor(hexString: "#E3F0FB").cgColor
        v.clipsToBounds = true
        v.isHidden = true
        return v
    }()

    private let rowsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        s.isHidden = true
        return s
    }()

    private let mealPhotoView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = UIColor(hexString: "#FFF8F5")
        iv.isHidden = true
        iv.isUserInteractionEnabled = true
        return iv
    }()

    private let analysisTitleLabel: UILabel = {
        let l = UILabel()
        l.font = ChatBubbleStyle.Card.titleFont
        l.textColor = ChatBubbleStyle.primaryText
        l.numberOfLines = 0
        l.isHidden = true
        return l
    }()

    private let analysisBodyLabel: UILabel = {
        let l = UILabel()
        l.font = ChatBubbleStyle.Card.bodyFont
        l.textColor = ChatBubbleStyle.secondaryText
        l.numberOfLines = 0
        l.isHidden = true
        return l
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
        [coverImageView, titleRow, tagButton, dividerView, descLabel, summaryStack, mealPhotoView, rowsStack, analysisCard, analysisTitleLabel, analysisBodyLabel, commentStack, actionButton]
            .forEach(cardView.addSubview)

        mealPhotoView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(mealPhotoTapped))
        )
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        cardView.addGestureRecognizer(longPress)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        mealPhotoView.kf.cancelDownloadTask()
        mealPhotoView.image = nil
        mealPhotoView.isHidden = true
        clearStack(summaryStack)
        summaryStack.isHidden = true
        analysisCard.isHidden = true
        analysisTitleLabel.text = nil
        analysisTitleLabel.isHidden = true
        analysisBodyLabel.text = nil
        analysisBodyLabel.attributedText = nil
        analysisBodyLabel.isHidden = true
        onTapMealPhoto = nil
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

        avatarLabel.font = .fdFont(designSize: 15, weight: .bold)
        metaLabel.font = ChatBubbleStyle.metaFont
        titleLabel.font = ChatBubbleStyle.Card.titleFont
        descLabel.font = ChatBubbleStyle.Card.bodyFont
        actionButton.titleLabel?.font = ChatBubbleStyle.Card.actionFont
        if var config = tagButton.configuration {
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var out = incoming
                out.font = ChatBubbleStyle.Card.tagFont
                return out
            }
            tagButton.configuration = config
        }

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
        clearStack(summaryStack)
        summaryStack.isHidden = true
        analysisCard.isHidden = true

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
        if card.isDietCard {
            applyDietIcon()
            titleLabel.font = .fdFont(designSize: 14, weight: .medium)
        } else {
            applyLeadingIcon(card)
            titleLabel.font = ChatBubbleStyle.Card.titleFont
        }
        applyDataSourceTag(card)

        let body = card.bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        if card.isDietCard {
            descLabel.text = nil
            descLabel.isHidden = true
            populateDietSummary(body)
            dividerView.backgroundColor = UIColor(hexString: "#EEEEEE")
        } else if card.showsBodyContent && !body.isEmpty {
            summaryStack.isHidden = true
            descLabel.attributedText = NSAttributedString(
                string: body,
                attributes: [
                    .font: ChatBubbleStyle.Card.bodyFont,
                    .foregroundColor: ChatBubbleStyle.secondaryText,
                    .paragraphStyle: ChatBubbleStyle.cardParagraphStyle,
                ]
            )
            descLabel.isHidden = false
            dividerView.backgroundColor = ChatBubbleStyle.dividerColor
        } else {
            summaryStack.isHidden = true
            descLabel.text = nil
            descLabel.isHidden = true
            dividerView.backgroundColor = ChatBubbleStyle.dividerColor
        }

        let rows = card.displayRows
        if card.isDietCard {
            appendDietTextRows(rows)
            let tables = rows.filter { if case .table = $0 { return true }; return false }
            if !tables.isEmpty {
                dividerView.isHidden = false
                rowsStack.isHidden = false
                rowsStack.spacing = 10
                populateMonitorRows(tables, accent: card.monitorAccentColor, dietStyle: true)
            } else if !summaryStack.isHidden || card.dietPhotoURL != nil || card.dietAnalysis != nil {
                dividerView.isHidden = summaryStack.isHidden
            }
        } else if !rows.isEmpty {
            dividerView.isHidden = false
            rowsStack.isHidden = false
            rowsStack.spacing = 0
            populateMonitorRows(rows, accent: card.monitorAccentColor, dietStyle: false)
        }

        applyMealPhoto(card)
        applyDietAnalysis(card)
        applyJumpAction(card)
    }

    private func applyDietIcon() {
        monitorIconView.kf.cancelDownloadTask()
        monitorIconCircle.isHidden = false
        monitorIconCircle.backgroundColor = UIColor(hexString: "#FFF2E6")
        monitorIconView.image = UIImage(named: "im_diet_card_icon")
        monitorIconView.contentMode = .scaleAspectFit
        monitorIconView.tintColor = nil
        monitorIconView.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(16)
            make.height.equalTo(15)
        }
    }

    private func applyMealPhoto(_ card: IMCardResolved) {
        mealPhotoView.kf.cancelDownloadTask()
        mealPhotoView.image = nil
        guard let urlStr = card.dietPhotoURL, let url = URL(string: urlStr) else {
            mealPhotoView.isHidden = true
            return
        }
        mealPhotoView.isHidden = false
        mealPhotoView.layer.cornerRadius = 12
        mealPhotoView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
    }

    private func applyDietAnalysis(_ card: IMCardResolved) {
        guard let analysis = card.dietAnalysis else {
            analysisTitleLabel.text = nil
            analysisTitleLabel.isHidden = true
            analysisBodyLabel.attributedText = nil
            analysisBodyLabel.isHidden = true
            analysisCard.isHidden = true
            return
        }
        if analysis.title.isEmpty {
            analysisTitleLabel.text = nil
            analysisTitleLabel.isHidden = true
        } else {
            analysisTitleLabel.font = .fdFont(designSize: 14, weight: .bold)
            analysisTitleLabel.textColor = UIColor(hexString: "#181D3D")
            analysisTitleLabel.text = analysis.title
            analysisTitleLabel.isHidden = false
        }
        analysisBodyLabel.attributedText = dietAnalysisBody(analysis.content)
        analysisBodyLabel.isHidden = false
        analysisCard.isHidden = false
    }

    private func appendDietTextRows(_ rows: [IMMonitorRow]) {
        for row in rows {
            guard case .text(let label, let value, let colorHex) = row else { continue }
            summaryStack.isHidden = false
            summaryStack.addArrangedSubview(
                makeDietSummaryRow(
                    label: dietPlainLabel(label),
                    value: value,
                    valueColor: resolvedColor(colorHex)
                )
            )
        }
    }

    private func dietAnalysisBody(_ text: String) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.5
        let body = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: UIFont.fdFont(designSize: 12, weight: .regular),
                .foregroundColor: UIColor(hexString: "#8591AB"),
                .paragraphStyle: paragraph,
            ]
        )
        let ns = text as NSString
        for token in ["表扬：", "表扬:", "建议：", "建议:"] {
            var search = NSRange(location: 0, length: ns.length)
            while search.location < ns.length {
                let found = ns.range(of: token, options: [], range: search)
                if found.location == NSNotFound { break }
                body.addAttributes(
                    [
                        .font: UIFont.fdFont(designSize: 12, weight: .medium),
                        .foregroundColor: UIColor(hexString: "#3664B1"),
                    ],
                    range: found
                )
                let next = found.location + found.length
                if next >= ns.length { break }
                search = NSRange(location: next, length: ns.length - next)
            }
        }
        return body
    }

    private func populateDietSummary(_ text: String) {
        clearStack(summaryStack)
        let lines = dietSummaryLines(text)
        guard !lines.isEmpty else {
            summaryStack.isHidden = true
            return
        }
        summaryStack.isHidden = false
        for line in lines {
            summaryStack.addArrangedSubview(makeDietSummaryRow(label: line.label, value: line.value))
        }
    }

    private func dietSummaryLines(_ text: String) -> [(label: String, value: String)] {
        text.components(separatedBy: .newlines).compactMap { raw in
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { return nil }
            for separator in ["：", ":"] {
                guard let range = line.range(of: separator) else { continue }
                let label = String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let value = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !label.isEmpty { return (label, value) }
            }
            let parts = line.split(whereSeparator: { $0 == " " || $0 == "\u{3000}" }).map(String.init)
            if parts.count >= 2 {
                return (parts[0], parts.dropFirst().joined(separator: " "))
            }
            return ("", line)
        }
    }

    private func makeDietSummaryRow(label: String, value: String, valueColor: UIColor? = nil) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        if !label.isEmpty {
            let name = UILabel()
            name.font = .fdFont(designSize: 12, weight: .regular)
            name.textColor = ChatBubbleStyle.secondaryText
            name.text = label
            name.setContentHuggingPriority(.required, for: .horizontal)
            row.addArrangedSubview(name)
        }
        let detail = UILabel()
        detail.font = .fdFont(designSize: 12, weight: label.isEmpty ? .regular : .medium)
        detail.textColor = valueColor ?? (label.isEmpty ? ChatBubbleStyle.secondaryText : ChatBubbleStyle.primaryText)
        detail.text = value
        detail.numberOfLines = 0
        row.addArrangedSubview(detail)
        return row
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
        monitorIconView.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(ChatBubbleStyle.Card.iconGlyphSize)
        }
        monitorIconView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
    }

    private func applyDataSourceTag(_ card: IMCardResolved) {
        var config = tagButton.configuration ?? .plain()
        if card.showsDataSourceTag, let tag = card.dataSourceTag {
            config.title = tag
            if card.isDietCard {
                config.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8)
                config.baseForegroundColor = UIColor(hexString: "#FF7A50")
                config.background.backgroundColor = .clear
                config.background.strokeColor = UIColor(hexString: "#FF7A50").withAlphaComponent(0.5)
                config.background.strokeWidth = 0.5
                config.background.cornerRadius = 29
                config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                    var outgoing = incoming
                    outgoing.font = .fdFont(designSize: 10, weight: .regular)
                    return outgoing
                }
            } else {
                config.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8)
                config.baseForegroundColor = ChatBubbleStyle.userFill
                config.background.backgroundColor = .clear
                config.background.strokeColor = ChatBubbleStyle.userFill.withAlphaComponent(0.5)
                config.background.strokeWidth = 0.5
                config.background.cornerRadius = 29
                config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                    var outgoing = incoming
                    outgoing.font = ChatBubbleStyle.Card.tagFont
                    return outgoing
                }
            }
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

    private func populateMonitorRows(_ rows: [IMMonitorRow], accent: UIColor, dietStyle: Bool = false) {
        for row in rows {
            switch row {
            case .text(let label, let value, let colorHex):
                if dietStyle {
                    rowsStack.addArrangedSubview(
                        makeDietSummaryRow(
                            label: dietPlainLabel(label),
                            value: value,
                            valueColor: resolvedColor(colorHex)
                        )
                    )
                } else {
                    rowsStack.addArrangedSubview(
                        makeMonitorTextRow(
                            label: label,
                            value: value,
                            colorHex: colorHex,
                            asStatusPill: shouldRenderStatusPill(label: label, colorHex: colorHex),
                            fallbackAccent: accent
                        )
                    )
                }
            case .table(let headers, let cells):
                let table = makeTableView(headers: headers, cells: cells, dietStyle: dietStyle)
                if dietStyle {
                    rowsStack.addArrangedSubview(table)
                } else {
                    let wrap = UIView()
                    wrap.addSubview(table)
                    table.snp.makeConstraints { make in
                        make.top.equalToSuperview().offset(4)
                        make.leading.trailing.bottom.equalToSuperview()
                    }
                    rowsStack.addArrangedSubview(wrap)
                }
            }
        }
    }

    /// 饮食卡标签不展示冒号
    private func dietPlainLabel(_ label: String) -> String {
        var trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix("：") || trimmed.hasSuffix(":") {
            trimmed.removeLast()
            trimmed = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
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
        emphasizeValue: Bool = false,
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
            right.font = emphasizeValue
                ? .fdFont(designSize: 14, weight: .semibold)
                : ChatBubbleStyle.Card.rowValueFont
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

    private func makeTableView(headers: [String], cells: [[String]], dietStyle: Bool = false) -> UIView {
        if dietStyle {
            return makeDietTableView(headers: headers, cells: cells)
        }
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

    private func makeDietTableView(headers: [String], cells: [[String]]) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.layer.cornerRadius = 12
        stack.layer.borderWidth = 1
        stack.layer.borderColor = UIColor(hexString: "#FDF6F3").cgColor
        stack.clipsToBounds = true
        stack.backgroundColor = .white

        stack.addArrangedSubview(makeDietTableRow(headers, isHeader: true))
        for cellRow in cells {
            let padded = headers.indices.map { i in i < cellRow.count ? cellRow[i] : "" }
            stack.addArrangedSubview(makeDietTableRow(padded, isHeader: false))
        }
        return stack
    }

    private func makeDietTableRow(_ cols: [String], isHeader: Bool) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 0
        row.backgroundColor = isHeader ? UIColor(hexString: "#FDF6F3") : .white
        for (index, text) in cols.enumerated() {
            let wrap = UIView()
            let label = UILabel()
            label.text = text
            label.font = .fdFont(designSize: 12, weight: .regular)
            label.textColor = isHeader ? ChatBubbleStyle.userFill : ChatBubbleStyle.primaryText
            label.numberOfLines = 2
            wrap.addSubview(label)
            label.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
            }
            if index < cols.count - 1 {
                let line = UIView()
                line.backgroundColor = UIColor(hexString: "#F6EDE6")
                wrap.addSubview(line)
                line.snp.makeConstraints { make in
                    make.top.bottom.trailing.equalToSuperview()
                    make.width.equalTo(1 / UIScreen.main.scale)
                }
            }
            if !isHeader {
                let line = UIView()
                line.backgroundColor = UIColor(hexString: "#F6EDE6")
                wrap.addSubview(line)
                line.snp.makeConstraints { make in
                    make.leading.trailing.top.equalToSuperview()
                    make.height.equalTo(1 / UIScreen.main.scale)
                }
            }
            row.addArrangedSubview(wrap)
        }
        return row
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
            nameLabel.font = .fdFont(designSize: 14)
            nameLabel.textColor = .fdMuted
            let stars = UILabel()
            stars.text = "★★★★★"
            stars.font = .fdFont(designSize: 16)
            stars.textColor = UIColor.fdBorder
            row.addArrangedSubview(nameLabel)
            row.addArrangedSubview(stars)
            commentStack.addArrangedSubview(row)
        }
        let input = UILabel()
        input.text = "  评价内容（只读）"
        input.font = .fdFont(designSize: 14)
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
                .font: UIFont.fdFont(designSize: 17, weight: .bold),
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
        if card?.isDietCard != true {
            mealPhotoView.snp.remakeConstraints { make in
                make.top.leading.equalToSuperview()
                make.width.height.equalTo(0)
            }
            summaryStack.snp.remakeConstraints { make in
                make.top.leading.equalToSuperview()
                make.width.height.equalTo(0)
            }
            analysisCard.snp.remakeConstraints { make in
                make.top.leading.equalToSuperview()
                make.width.height.equalTo(0)
            }
            analysisTitleLabel.snp.remakeConstraints { make in
                make.top.leading.equalToSuperview()
                make.width.height.equalTo(0)
            }
            analysisBodyLabel.snp.remakeConstraints { make in
                make.top.leading.equalToSuperview()
                make.width.height.equalTo(0)
            }
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
            if card?.isDietCard == true {
                layoutDietCard(pad: pad, showTag: showTag, card: card)
            } else {
                layoutUnifiedSysNotify(
                    pad: pad,
                    showDesc: showDesc,
                    showRows: showRows,
                    showAction: showAction
                )
            }
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
        titleRow.spacing = 8
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

    /// 饮食卡：图标标题 → 摘要 → 餐食图 → 明细 → 分析。空块不占位，无底部跳转按钮。
    private func layoutDietCard(pad: CGFloat, showTag: Bool, card: IMCardResolved?) {
        titleRow.spacing = 7
        let showTitle = card?.showsDietTitle == true
        let showHeader = showTitle || showTag
        let showBody = card?.showsBodyContent == true
            && !(card?.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasTextRows = card?.displayRows.contains { if case .text = $0 { return true }; return false } ?? false
        let showSummary = showBody || hasTextRows
        let showPhoto = card?.dietPhotoURL != nil
        let showTable = card?.displayRows.contains { if case .table = $0 { return true }; return false } ?? false
        let analysis = card?.dietAnalysis
        let showAnalysisTitle = !(analysis?.title.isEmpty ?? true)
        let showAnalysis = analysis != nil
        let showDivider = showSummary && (showPhoto || showTable || showAnalysis)
        dividerView.isHidden = !showDivider

        commentStack.snp.remakeConstraints { make in
            make.top.equalTo(titleRow.snp.bottom)
            make.leading.equalToSuperview().offset(pad)
            make.height.equalTo(0)
        }
        actionButton.snp.remakeConstraints { make in
            make.top.equalTo(titleRow.snp.bottom)
            make.leading.equalToSuperview().offset(pad)
            make.height.equalTo(0)
        }
        descLabel.snp.remakeConstraints { make in
            make.top.leading.equalToSuperview()
            make.width.height.equalTo(0)
        }

        if showHeader {
            titleRow.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(pad)
                make.leading.equalToSuperview().inset(pad)
                if showTag {
                    make.trailing.equalTo(tagButton.snp.leading).offset(-8)
                } else {
                    make.trailing.equalToSuperview().inset(pad)
                }
            }
            tagButton.snp.remakeConstraints { make in
                make.centerY.equalTo(titleRow)
                make.trailing.equalToSuperview().inset(pad)
                if !showTag {
                    make.width.height.equalTo(0)
                }
            }
        } else {
            titleRow.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(pad)
                make.leading.equalToSuperview().inset(pad)
                make.height.equalTo(0)
            }
            tagButton.snp.remakeConstraints { make in
                make.centerY.equalTo(titleRow)
                make.trailing.equalToSuperview().inset(pad)
                make.width.height.equalTo(0)
            }
        }

        let headerBottom = showHeader ? titleRow.snp.bottom : titleRow.snp.top

        if showSummary {
            summaryStack.snp.remakeConstraints { make in
                make.top.equalTo(headerBottom).offset(showHeader ? 12 : 0)
                make.leading.trailing.equalToSuperview().inset(pad)
            }
        } else {
            summaryStack.snp.remakeConstraints { make in
                make.top.equalTo(headerBottom)
                make.leading.equalToSuperview().offset(pad)
                make.height.equalTo(0)
            }
        }
        let afterSummary = showSummary ? summaryStack.snp.bottom : headerBottom

        if showDivider {
            dividerView.snp.remakeConstraints { make in
                make.top.equalTo(afterSummary).offset(12)
                make.leading.trailing.equalToSuperview().inset(pad)
                make.height.equalTo(0.5)
            }
        } else {
            dividerView.snp.remakeConstraints { make in
                make.top.equalTo(afterSummary)
                make.leading.equalToSuperview().offset(pad)
                make.height.equalTo(0)
            }
        }
        let afterDivider = showDivider ? dividerView.snp.bottom : afterSummary

        if showPhoto {
            mealPhotoView.snp.remakeConstraints { make in
                let gap: CGFloat = (showDivider || showSummary || showHeader) ? 12 : 0
                make.top.equalTo(afterDivider).offset(gap)
                make.leading.trailing.equalToSuperview().inset(pad)
                make.height.equalTo(80)
            }
        } else {
            mealPhotoView.snp.remakeConstraints { make in
                make.top.equalTo(afterDivider)
                make.leading.equalToSuperview().offset(pad)
                make.height.equalTo(0)
            }
        }
        let afterPhoto = showPhoto ? mealPhotoView.snp.bottom : afterDivider

        if showTable {
            rowsStack.snp.remakeConstraints { make in
                let gap: CGFloat = showPhoto ? 10 : ((showDivider || showSummary || showHeader) ? 12 : 0)
                make.top.equalTo(afterPhoto).offset(gap)
                make.leading.trailing.equalToSuperview().inset(pad)
            }
        } else {
            rowsStack.snp.remakeConstraints { make in
                make.top.equalTo(afterPhoto)
                make.leading.equalToSuperview().offset(pad)
                make.height.equalTo(0)
            }
        }
        let afterRows = showTable ? rowsStack.snp.bottom : afterPhoto

        if showAnalysis {
            analysisCard.snp.remakeConstraints { make in
                make.top.equalTo(afterRows).offset(12)
                make.leading.trailing.equalToSuperview().inset(pad)
                make.bottom.equalToSuperview().offset(-pad)
            }
            if showAnalysisTitle {
                analysisTitleLabel.snp.remakeConstraints { make in
                    make.top.equalTo(analysisCard).offset(12)
                    make.leading.trailing.equalTo(analysisCard).inset(12)
                }
            } else {
                analysisTitleLabel.snp.remakeConstraints { make in
                    make.top.equalTo(analysisCard).offset(12)
                    make.leading.equalTo(analysisCard).offset(12)
                    make.height.equalTo(0)
                }
            }
            analysisBodyLabel.snp.remakeConstraints { make in
                make.top.equalTo(showAnalysisTitle ? analysisTitleLabel.snp.bottom : analysisCard.snp.top)
                    .offset(showAnalysisTitle ? 6 : 12)
                make.leading.trailing.equalTo(analysisCard).inset(12)
                make.bottom.equalTo(analysisCard).offset(-12)
            }
        } else {
            analysisCard.snp.remakeConstraints { make in
                make.top.equalTo(afterRows)
                make.leading.equalToSuperview().offset(pad)
                make.height.equalTo(0)
            }
            analysisTitleLabel.snp.remakeConstraints { make in
                make.top.equalTo(afterRows)
                make.leading.equalToSuperview().offset(pad)
                make.height.equalTo(0)
            }
            analysisBodyLabel.snp.remakeConstraints { make in
                make.top.equalTo(afterRows)
                make.leading.equalToSuperview().offset(pad)
                make.height.equalTo(0)
            }
            pinDietBottom(
                showRows: showTable,
                showPhoto: showPhoto,
                showDesc: showSummary,
                showHeader: showHeader,
                pad: pad
            )
        }
    }

    private func pinDietBottom(
        showRows: Bool,
        showPhoto: Bool,
        showDesc: Bool,
        showHeader: Bool,
        pad: CGFloat
    ) {
        if showRows {
            rowsStack.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-pad)
            }
        } else if showPhoto {
            mealPhotoView.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-pad)
            }
        } else if showDesc {
            summaryStack.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-pad)
            }
        } else if showHeader {
            titleRow.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-pad)
            }
        }
    }

    @objc private func mealPhotoTapped() {
        guard let url = resolved?.dietPhotoURL else { return }
        onTapMealPhoto?(url)
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
