import UIKit
import SnapKit
import Kingfisher

/// 体征监测整卡 — 白卡内标题 + 2 列网格（单卡比例 155:144，宽度随屏自适应）
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

    private let listStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.isHidden = true
        return stack
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
        cardView.addSubview(listStack)

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
        clearSeniorList()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !UIFont.isSeniorMode, !metrics.isEmpty else { return }
        let width = resolvedContainerWidth()
        guard width > 0, abs(width - lastMeasuredWidth) > 0.5 else { return }
        lastMeasuredWidth = width
        updateCollectionViewHeight()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    func configure(metrics: [HealthMetricDisplayItem]) {
        self.metrics = metrics
        titleHeightConstraint?.update(offset: Self.titleHeight)
        if UIFont.isSeniorMode {
            applySeniorList()
        } else {
            clearSeniorList()
            lastMeasuredWidth = resolvedContainerWidth()
            collectionView.reloadData()
            updateCollectionViewHeight()
            collectionView.isHidden = metrics.isEmpty
        }
    }

    private func updateCollectionViewHeight() {
        let containerWidth = resolvedContainerWidth()
        let empty = metrics.isEmpty
        let h = empty ? 0 : MetricCardGridLayout.collectionHeight(
            itemCount: metrics.count,
            containerWidth: containerWidth
        )
        applyCollectionLayout(topSpacing: empty ? 0 : 13, height: h)
    }

    private func resolvedContainerWidth() -> CGFloat {
        if bounds.width > 0 { return bounds.width }
        if contentView.bounds.width > 0 { return contentView.bounds.width }
        return fdContainerWidth
    }

    private func makeCollectionLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let contentWidth = environment.container.effectiveContentSize.width
            let cardSize = MetricCardGridLayout.cardSize(forGridContentWidth: contentWidth)

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
            group.interItemSpacing = .fixed(MetricCardGridLayout.interItemSpacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = MetricCardGridLayout.interRowSpacing
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

    /// 与内部约束一致。长辈模式为卡内纵向列表，普通模式为 2 列网格。
    static func height(for count: Int, containerWidth: CGFloat) -> CGFloat {
        let header = 12 + 16 + titleHeight
        guard count > 0 else { return header + 16 }
        if UIFont.isSeniorMode {
            return header + 12 + CGFloat(count) * HealthVitalMetricListRow.rowHeight + 16
        }
        let collectionH = MetricCardGridLayout.collectionHeight(
            itemCount: count,
            containerWidth: containerWidth
        )
        return header + 13 + collectionH + 16
    }

    private static var titleHeight: CGFloat {
        UIFont.isSeniorMode ? 28 : 22
    }

    private func applySeniorList() {
        collectionView.isHidden = true
        collectionView.snp.remakeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0)
        }
        listStack.isHidden = metrics.isEmpty
        listStack.arrangedSubviews.forEach {
            listStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for (index, item) in metrics.enumerated() {
            let row = HealthVitalMetricListRow()
            row.configure(item, showsDivider: index < metrics.count - 1)
            row.onTap = { [weak self] in
                self?.onMetricTap?(item)
            }
            listStack.addArrangedSubview(row)
        }
        listStack.snp.remakeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(metrics.isEmpty ? 0 : 12)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().inset(16)
            if metrics.isEmpty {
                $0.height.equalTo(0)
            }
        }
    }

    private func clearSeniorList() {
        listStack.isHidden = true
        listStack.arrangedSubviews.forEach {
            listStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        listStack.snp.remakeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0)
        }
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

/// 长辈模式体征行：图标、名称、数值、单位、状态、箭头。放在原白卡内部。
final class HealthVitalMetricListRow: UIView {

    static let rowHeight: CGFloat = 64

    var onTap: (() -> Void)?

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()
    private let badgeWrap = UIView()
    private let badgeLabel = UILabel()
    private let chevron = UIImageView()
    private let divider = UIView()
    private let trailingStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .fdFont(ofSize: 20, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#1F2942")
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        valueLabel.font = .fdFont(ofSize: 18, weight: .medium)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        unitLabel.font = .fdFont(ofSize: 12, weight: .regular)
        unitLabel.textColor = UIColor(hexString: "#717885")
        unitLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        unitLabel.setContentHuggingPriority(.required, for: .horizontal)

        badgeWrap.layer.cornerRadius = 11
        badgeWrap.clipsToBounds = true
        badgeLabel.font = .fdFont(ofSize: 12, weight: .regular)
        badgeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        badgeWrap.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8))
        }

        chevron.image = UIImage(systemName: "chevron.right")
        chevron.tintColor = UIColor(hexString: "#C5CAD3")
        chevron.contentMode = .scaleAspectFit
        chevron.snp.makeConstraints { $0.size.equalTo(12) }

        trailingStack.axis = .horizontal
        trailingStack.alignment = .center
        trailingStack.spacing = 6
        trailingStack.addArrangedSubview(valueLabel)
        trailingStack.addArrangedSubview(unitLabel)
        trailingStack.addArrangedSubview(badgeWrap)
        trailingStack.addArrangedSubview(chevron)
        trailingStack.setCustomSpacing(2, after: valueLabel)
        trailingStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        divider.backgroundColor = UIColor(hexString: "#EEEEEE")

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(trailingStack)
        addSubview(divider)

        snp.makeConstraints { $0.height.equalTo(Self.rowHeight) }
        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(28)
        }
        trailingStack.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(10)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(trailingStack.snp.leading).offset(-8)
        }
        divider.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.trailing.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ item: HealthMetricDisplayItem, showsDivider: Bool) {
        titleLabel.text = item.label
        divider.isHidden = !showsDivider
        loadIcon(urlString: item.iconUrl, fallback: item.iconSF)

        if !item.hasMonitorData {
            valueLabel.isHidden = true
            unitLabel.isHidden = true
            applyBadge(text: "去记录", kind: .record)
            return
        }

        if item.bloodLipid != nil {
            valueLabel.isHidden = true
            unitLabel.isHidden = true
            applyBadge(text: item.status, kind: badgeKind(item.statusType))
            return
        }

        if let diet = item.dietSport {
            showValue(diet.remainingText, unit: "", statusType: item.statusType)
            applyBadge(text: item.status, kind: badgeKind(item.statusType))
            return
        }

        showValue(item.value, unit: item.unit, statusType: item.statusType)
        applyBadge(text: item.status, kind: badgeKind(item.statusType))
    }

    private func showValue(_ value: String, unit: String, statusType: String) {
        valueLabel.isHidden = false
        valueLabel.text = value
        valueLabel.textColor = Self.valueColor(statusType: statusType)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        unitLabel.isHidden = trimmedUnit.isEmpty
        unitLabel.text = trimmedUnit
    }

    private func loadIcon(urlString: String?, fallback: String) {
        iconView.kf.cancelDownloadTask()
        let trimmed = urlString?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let url = URL(string: trimmed), !trimmed.isEmpty {
            iconView.tintColor = nil
            iconView.kf.setImage(with: url, options: [.transition(.fade(0.15))])
        } else {
            iconView.image = UIImage(systemName: fallback)
            iconView.tintColor = .fdPrimary
        }
    }

    private enum BadgeKind {
        case warning, info, success, record
    }

    private func badgeKind(_ statusType: String) -> BadgeKind {
        switch statusType {
        case "warning": return .warning
        case "info": return .info
        default: return .success
        }
    }

    private func applyBadge(text: String, kind: BadgeKind) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        badgeWrap.isHidden = trimmed.isEmpty
        badgeLabel.text = trimmed
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

    private static func valueColor(statusType: String) -> UIColor {
        switch statusType {
        case "warning", "info":
            return UIColor(hexString: "#FF6637")
        default:
            return UIColor(hexString: "#1F2942")
        }
    }

    @objc private func tapped() { onTap?() }
}
