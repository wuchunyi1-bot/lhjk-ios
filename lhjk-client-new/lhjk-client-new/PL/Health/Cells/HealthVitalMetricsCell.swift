import UIKit
import SnapKit

/// 体征监测整卡 — 对齐 Figma：白卡内标题 + 2 列网格（含圆形水印）
final class HealthVitalMetricsCell: UITableViewCell {

    static let reuseIdentifier = "HealthVitalMetricsCell"

    private var metrics: [HealthMetricDisplayItem] = []
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
        l.textColor = .fdText
        return l
    }()

    private let editButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("编辑卡片 ›", for: .normal)
        b.titleLabel?.font = .fdFont(ofSize: 12, weight: .regular)
        b.setTitleColor(.fdSubtext, for: .normal)
        return b
    }()

    private lazy var collectionView: UICollectionView = {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4.5, bottom: 0, trailing: 4.5)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(144)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12

        let layout = UICollectionViewCompositionalLayout(section: section)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        cv.clipsToBounds = false
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
            $0.leading.equalToSuperview().offset(16)
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

    func configure(metrics: [HealthMetricDisplayItem]) {
        self.metrics = metrics
        collectionView.reloadData()
        let empty = metrics.isEmpty
        let rows = (metrics.count + 1) / 2
        let h = empty ? CGFloat(0) : CGFloat(rows) * 144 + CGFloat(max(0, rows - 1)) * 12
        applyCollectionLayout(topSpacing: empty ? 0 : 14, height: h)
        collectionView.isHidden = empty
    }

    private func applyCollectionLayout(topSpacing: CGFloat, height: CGFloat) {
        collectionView.snp.remakeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(topSpacing)
            $0.leading.trailing.equalToSuperview().inset(7.5)
            $0.height.equalTo(height)
            $0.bottom.equalToSuperview().inset(16)
        }
    }

    /// 与内部约束一致：12 + 16 + 22 + spacing + collectionH + 16
    static func height(for count: Int) -> CGFloat {
        guard count > 0 else { return 12 + 16 + 22 + 0 + 0 + 16 }
        let rows = (count + 1) / 2
        let collectionH = CGFloat(rows) * 144 + CGFloat(max(0, rows - 1)) * 12
        return 12 + 16 + 22 + 14 + collectionH + 16
    }

    @objc private func editTapped() { onEditTap?() }
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
            time: m.time
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onMetricTap?(metrics[indexPath.item])
    }
}
