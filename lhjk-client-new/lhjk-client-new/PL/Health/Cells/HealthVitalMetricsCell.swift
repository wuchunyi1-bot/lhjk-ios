import UIKit
import SnapKit

/// 体征监测 Cell — 内嵌 UICollectionView 展示 2×N 指标网格
/// 参考 funde-client: metrics-grid section
final class HealthVitalMetricsCell: UITableViewCell {

    static let reuseIdentifier = "HealthVitalMetricsCell"

    typealias MetricItem = (key: String, label: String, value: String, unit: String, status: String, statusType: String, icon: String, time: String, trend: String)

    private var metrics: [MetricItem] = []
    var onMetricTap: ((String) -> Void)?

    private lazy var collectionView: UICollectionView = {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(140))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(140))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10

        let layout = UICollectionViewCompositionalLayout(section: section)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(MetricCardCell.self, forCellWithReuseIdentifier: MetricCardCell.reuseIdentifier)
        return cv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(metrics: [MetricItem]) {
        self.metrics = metrics
        collectionView.reloadData()
        // Update height constraint
        let rows = (metrics.count + 1) / 2
        let h = CGFloat(rows) * 140 + CGFloat(max(0, rows - 1)) * 10
        collectionView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.height.equalTo(h)
        }
    }

    /// Calculate cell height for a given metrics count
    static func height(for count: Int) -> CGFloat {
        let rows = (count + 1) / 2
        return CGFloat(rows) * 140 + CGFloat(max(0, rows - 1)) * 10 + 32
    }
}

extension HealthVitalMetricsCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { metrics.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MetricCardCell.reuseIdentifier, for: indexPath) as? MetricCardCell else {
            return UICollectionViewCell()
        }
        let m = metrics[indexPath.item]
        cell.configure(metricKey: m.key, icon: m.icon, status: m.status, statusType: m.statusType, label: m.label, value: m.value, unit: m.unit, trend: m.trend, time: m.time)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onMetricTap?(metrics[indexPath.item].key)
    }
}
