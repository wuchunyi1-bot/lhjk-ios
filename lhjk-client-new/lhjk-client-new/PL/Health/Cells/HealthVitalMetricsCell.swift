import UIKit
import SnapKit

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

        // 不钉 contentView.bottom：行高由 heightForRowAt 决定，避免与 Encapsulated-Layout-Height 冲突
        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(12)
            $0.height.equalTo(22)
        }
        editButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(12)
        }

        applyCollectionLayout(topSpacing: 0, height: 0)

        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
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
        lastMeasuredWidth = resolvedContainerWidth()
        collectionView.reloadData()
        updateCollectionViewHeight()
        collectionView.isHidden = metrics.isEmpty
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
        return UIScreen.main.bounds.width
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

    /// 与内部约束一致：12 + 16 + 22 + spacing + collectionH + 16
    static func height(for count: Int, containerWidth: CGFloat) -> CGFloat {
        guard count > 0 else { return 12 + 16 + 22 + 0 + 0 + 16 }
        let collectionH = MetricCardGridLayout.collectionHeight(
            itemCount: count,
            containerWidth: containerWidth
        )
        return 12 + 16 + 22 + 13 + collectionH + 16
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
