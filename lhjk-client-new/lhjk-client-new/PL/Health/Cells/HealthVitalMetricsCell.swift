import UIKit
import SnapKit

/// 体征监测整卡。普通模式是 155:144 两列卡。长辈模式是 155:96 两列矮卡，标题和「编辑卡片」不动。
final class HealthVitalMetricsCell: UITableViewCell {

    static let reuseIdentifier = "HealthVitalMetricsCell"

    private var metrics: [HealthMetricDisplayItem] = []
    private var lastMeasuredWidth: CGFloat = 0
    var onMetricTap: ((HealthMetricDisplayItem) -> Void)?
    var onEditTap: (() -> Void)?

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "体征监测"
        l.font = .fdFont(ofSize: 16, weight: .medium)
        l.textColor = UIColor(hexString: "#1F2430")
        return l
    }()

    private let editButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("编辑卡片 ›", for: .normal)
        b.titleLabel?.font = .fdFont(ofSize: 12, weight: .regular)
        b.setTitleColor(UIColor(hexString: "#717885"), for: .normal)
        return b
    }()

    private var titleHeightConstraint: Constraint?

    private lazy var collectionView: UICollectionView = {
        let layout = makeCollectionLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        cv.clipsToBounds = true
        cv.dataSource = self
        cv.delegate = self
        cv.register(MetricCardCell.self, forCellWithReuseIdentifier: MetricCardCell.reuseIdentifier)
        cv.register(SeniorVitalCardCell.self, forCellWithReuseIdentifier: SeniorVitalCardCell.reuseIdentifier)
        return cv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.clipsToBounds = true

        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(editButton)
        cardView.addSubview(collectionView)

        // 不钉 contentView.bottom：行高由 heightForRowAt 决定，避免与 Encapsulated-Layout-Height 冲突
        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(12)
            titleHeightConstraint = $0.height.equalTo(22).constraint
        }
        editButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(12)
        }

        applyCollectionLayout(topSpacing: 0, height: 0)

        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
    }

    /// 卡片顶沿。「体征监测」标题算在引导孔里。
    func guideBodyTop() -> CGFloat {
        guideCardFrame().minY
    }

    /// 体征监测白卡。引导橙框贴着这张卡，不按整行宽度挖。
    func guideCardFrame() -> CGRect {
        layoutIfNeeded()
        return cardView.convert(cardView.bounds, to: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !metrics.isEmpty else { return }
        let width = resolvedContainerWidth()
        guard width > 0, abs(width - lastMeasuredWidth) > 0.5 else { return }
        lastMeasuredWidth = width
        updateCollectionViewHeight()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    func configure(metrics: [HealthMetricDisplayItem]) {
        self.metrics = metrics
        titleHeightConstraint?.update(offset: Self.titleHeight)
        lastMeasuredWidth = resolvedContainerWidth()
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        updateCollectionViewHeight()
        collectionView.isHidden = metrics.isEmpty
    }

    private func updateCollectionViewHeight() {
        let containerWidth = resolvedContainerWidth()
        let empty = metrics.isEmpty
        let h = empty ? 0 : Self.gridHeight(count: metrics.count, containerWidth: containerWidth)
        applyCollectionLayout(topSpacing: empty ? 0 : Self.gridTopGap, height: h)
    }

    private func resolvedContainerWidth() -> CGFloat {
        if bounds.width > 0 { return bounds.width }
        if contentView.bounds.width > 0 { return contentView.bounds.width }
        return UIScreen.main.bounds.width
    }

    private func makeCollectionLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let contentWidth = environment.container.effectiveContentSize.width
            let senior = UIFont.isSeniorMode
            let cardSize = senior
                ? SeniorMetricCardLayout.cardSize(forGridContentWidth: contentWidth)
                : MetricCardGridLayout.cardSize(forGridContentWidth: contentWidth)
            let itemGap = senior ? SeniorMetricCardLayout.interItemSpacing : MetricCardGridLayout.interItemSpacing
            let rowGap = senior ? SeniorMetricCardLayout.interRowSpacing : MetricCardGridLayout.interRowSpacing

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(cardSize.width),
                heightDimension: .absolute(cardSize.height)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(cardSize.height)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item, item]
            )
            group.interItemSpacing = .fixed(itemGap)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = rowGap
            return section
        }
    }

    private func applyCollectionLayout(topSpacing: CGFloat, height: CGFloat) {
        collectionView.snp.remakeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(topSpacing)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.height.equalTo(height)
            $0.bottom.equalToSuperview().inset(16)
        }
    }

    /// 与内部约束一致。两种模式都是两列，卡片比例不同。
    static func height(for count: Int, containerWidth: CGFloat) -> CGFloat {
        let header = 12 + 16 + titleHeight
        guard count > 0 else { return header + 16 }
        return header + gridTopGap + gridHeight(count: count, containerWidth: containerWidth) + 16
    }

    private static var gridTopGap: CGFloat { UIFont.isSeniorMode ? 12 : 13 }

    private static func gridHeight(count: Int, containerWidth: CGFloat) -> CGFloat {
        if UIFont.isSeniorMode {
            return SeniorMetricCardLayout.collectionHeight(itemCount: count, containerWidth: containerWidth)
        }
        return MetricCardGridLayout.collectionHeight(itemCount: count, containerWidth: containerWidth)
    }

    private static var titleHeight: CGFloat {
        UIFont.isSeniorMode ? 28 : 22
    }

    @objc private func editTapped() { onEditTap?() }
}

// MARK: - 2 列网格尺寸（设计稿 155×144，宽度随容器缩放）

private enum MetricCardGridLayout {
    static let designCardWidth: CGFloat = 155
    static let designCardHeight: CGFloat = 144
    static let aspectRatio = designCardHeight / designCardWidth
    static let columnCount = 2
    static let interItemSpacing: CGFloat = 9
    static let interRowSpacing: CGFloat = 12
    /// 白卡左右 16 + 网格左右 12
    static let horizontalInset: CGFloat = 56

    static func gridContentWidth(for containerWidth: CGFloat) -> CGFloat {
        max(0, containerWidth - horizontalInset)
    }

    static func cardSize(forGridContentWidth contentWidth: CGFloat) -> CGSize {
        let cardWidth = (contentWidth - interItemSpacing) / CGFloat(columnCount)
        let cardHeight = cardWidth * aspectRatio
        return CGSize(width: cardWidth, height: cardHeight)
    }

    static func cardSize(for containerWidth: CGFloat) -> CGSize {
        cardSize(forGridContentWidth: gridContentWidth(for: containerWidth))
    }

    static func collectionHeight(itemCount: Int, containerWidth: CGFloat) -> CGFloat {
        guard itemCount > 0 else { return 0 }
        let cardHeight = cardSize(for: containerWidth).height
        let rows = (itemCount + 1) / columnCount
        return CGFloat(rows) * cardHeight + CGFloat(max(0, rows - 1)) * interRowSpacing
    }
}

extension HealthVitalMetricsCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { metrics.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if UIFont.isSeniorMode {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SeniorVitalCardCell.reuseIdentifier,
                for: indexPath
            ) as? SeniorVitalCardCell else {
                return UICollectionViewCell()
            }
            cell.configure(metrics[indexPath.item])
            return cell
        }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MetricCardCell.reuseIdentifier, for: indexPath) as? MetricCardCell else {
            return UICollectionViewCell()
        }
        let m = metrics[indexPath.item]
        cell.configure(
            metricKey: m.metricKey,
            icon: m.iconSF,
            iconUrl: m.iconUrl,
            backgroundUrl: m.backgroundUrl,
            status: m.status,
            statusType: m.statusType,
            resultColor: m.resultColor,
            label: m.label,
            value: m.value,
            unit: m.unit,
            trend: "",
            time: m.time,
            dietSport: m.dietSport,
            bloodLipid: m.bloodLipid
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onMetricTap?(metrics[indexPath.item])
    }
}

/// 长辈模式单卡。375 宽下为 155×96，字号按设计稿固定，不再套一层长辈放大。
private enum SeniorMetricCardLayout {
    static let designCardWidth: CGFloat = 155
    static let designCardHeight: CGFloat = 96
    static let aspectRatio = designCardHeight / designCardWidth
    static let columnCount = 2
    static let interItemSpacing: CGFloat = 9
    static let interRowSpacing: CGFloat = 10
    static let horizontalInset: CGFloat = 56

    static func gridContentWidth(for containerWidth: CGFloat) -> CGFloat {
        max(0, containerWidth - horizontalInset)
    }

    static func cardSize(forGridContentWidth contentWidth: CGFloat) -> CGSize {
        let cardWidth = (contentWidth - interItemSpacing) / CGFloat(columnCount)
        let cardHeight = cardWidth * aspectRatio
        return CGSize(width: cardWidth, height: cardHeight)
    }

    static func collectionHeight(itemCount: Int, containerWidth: CGFloat) -> CGFloat {
        guard itemCount > 0 else { return 0 }
        let cardHeight = cardSize(forGridContentWidth: gridContentWidth(for: containerWidth)).height
        let rows = (itemCount + 1) / columnCount
        return CGFloat(rows) * cardHeight + CGFloat(max(0, rows - 1)) * interRowSpacing
    }
}

final class SeniorVitalCardCell: UICollectionViewCell {

    static let reuseIdentifier = "SeniorVitalCardCell"

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()
    private let valueRow = UIStackView()
    private let badgeWrap = UIView()
    private let badgeLabel = UILabel()
    private var badgeWidth: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor(hexString: "#FFFAF7")
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true

        titleLabel.font = .fdFont(designSize: 18, seniorSize: 18, weight: .regular)
        titleLabel.textColor = UIColor(hexString: "#1F2942")
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8

        valueLabel.textColor = UIColor(hexString: "#1F2430")
        valueLabel.font = .fdFont(designSize: 24, seniorSize: 24, weight: .medium)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        unitLabel.font = .fdFont(designSize: 14, seniorSize: 14, weight: .regular)
        unitLabel.textColor = UIColor(hexString: "#717885")
        unitLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        valueRow.axis = .horizontal
        valueRow.alignment = .lastBaseline
        valueRow.spacing = 4
        valueRow.addArrangedSubview(valueLabel)
        valueRow.addArrangedSubview(unitLabel)

        badgeWrap.layer.cornerRadius = 12.5
        badgeWrap.clipsToBounds = true
        badgeLabel.font = .fdFont(designSize: 14, seniorSize: 14, weight: .medium)
        badgeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        badgeWrap.addSubview(badgeLabel)

        contentView.addSubview(titleLabel)
        contentView.addSubview(badgeWrap)
        contentView.addSubview(valueRow)

        badgeLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)).priority(750)
        }
        badgeWrap.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().offset(-10)
            $0.height.greaterThanOrEqualTo(25)
            badgeWidth = $0.width.equalTo(0).constraint
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(10)
            $0.trailing.lessThanOrEqualTo(badgeWrap.snp.leading).offset(-4)
            $0.trailing.lessThanOrEqualToSuperview().offset(-10)
        }
        valueRow.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(10)
            $0.trailing.lessThanOrEqualToSuperview().offset(-10)
            $0.bottom.equalToSuperview().offset(-12)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ item: HealthMetricDisplayItem) {
        titleLabel.text = item.label
        if !item.hasMonitorData {
            showValue(nil, unit: nil, phrase: false)
            applyBadge(text: "去记录", kind: .record, resultColor: nil)
            return
        }
        if item.bloodLipid != nil {
            showValue(nil, unit: nil, phrase: false)
            applyBadge(text: item.status, kind: badgeKind(item.statusType), resultColor: item.resultColor)
            return
        }
        if let diet = item.dietSport {
            showValue(diet.remainingText, unit: "还可摄入", phrase: false)
            applyBadge(text: item.status, kind: badgeKind(item.statusType), resultColor: item.resultColor)
            return
        }
        let phrase = Self.isPhrase(item.value)
        showValue(item.value, unit: phrase ? nil : item.unit, phrase: phrase)
        if phrase || Self.hidesStatus(item.cardType) {
            applyBadge(text: "", kind: .success, resultColor: nil)
        } else {
            applyBadge(text: item.status, kind: badgeKind(item.statusType), resultColor: item.resultColor)
        }
    }

    private func showValue(_ value: String?, unit: String?, phrase: Bool) {
        let text = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let unitText = unit?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        valueRow.isHidden = text.isEmpty
        valueLabel.text = text
        valueLabel.font = phrase
            ? .fdFont(designSize: 20, seniorSize: 20, weight: .medium)
            : .fdFont(designSize: 24, seniorSize: 24, weight: .medium)
        unitLabel.isHidden = unitText.isEmpty
        unitLabel.text = unitText
    }

    /// 用药、营养补剂、饮水在设计稿上不放状态标签。
    private static func hidesStatus(_ cardType: Int) -> Bool {
        cardType == 11 || cardType == 12 || cardType == 18
    }

    private static func isPhrase(_ value: String) -> Bool {
        value.range(of: "[\\p{Han}A-Za-z]", options: .regularExpression) != nil
    }

    private enum BadgeKind {
        case warning, info, success, record
    }

    private func badgeKind(_ statusType: String) -> BadgeKind {
        switch statusType {
        case "warning": return .warning
        case "info", "device": return .info
        default: return .success
        }
    }

    private func applyBadge(text: String, kind: BadgeKind, resultColor: String?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let hidden = trimmed.isEmpty
        badgeWrap.isHidden = hidden
        badgeLabel.text = trimmed
        badgeWidth?.isActive = hidden
        if hidden { return }
        if kind != .record, let color = UIColor.fdMonitorBadgeColor(hexString: resultColor) {
            badgeLabel.textColor = color
            badgeWrap.backgroundColor = color.withAlphaComponent(CGFloat(0x1A) / 255)
            return
        }
        switch kind {
        case .warning:
            badgeWrap.backgroundColor = UIColor(hexString: "#FFEDED")
            badgeLabel.textColor = UIColor(hexString: "#DF0340")
        case .info:
            badgeWrap.backgroundColor = UIColor(hexString: "#FFF0E0")
            badgeLabel.textColor = UIColor(hexString: "#FF6637")
        case .record:
            badgeWrap.backgroundColor = UIColor(hexString: "#FFF0E0")
            badgeLabel.textColor = .fdPrimary
        case .success:
            badgeWrap.backgroundColor = UIColor(hexString: "#E9F6F2")
            badgeLabel.textColor = UIColor(hexString: "#2EBA83")
        }
    }
}
