import UIKit

/// 体征监测编辑卡片页 — 所有指标卡片的 2 列网格
/// 参考 funde-client: MetricsView.vue
final class MetricsViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    // MARK: - Mock Data

    private let metrics: [(key: String, label: String, value: String, unit: String, status: String, statusType: String, icon: String, time: String, trend: String)] = [
        ("blood-pressure", "血压", "138/88", "mmHg", "偏高", "warning", "drop", "今天 07:32", "up"),
        ("blood-sugar", "血糖", "5.8", "mmol/L", "正常", "success", "capsule", "昨天 08:10", "flat"),
        ("weight", "体重", "68.5", "kg", "正常", "success", "scalemass", "3 天前", "down"),
        ("heart-rate", "心率", "76", "bpm", "正常", "success", "heart", "今天 07:32", "flat"),
        ("sleep", "睡眠", "7.2", "小时", "良好", "success", "moon", "昨晚", "flat"),
        ("ecg", "心电", "正常", "", "无异常", "success", "waveform.path.ecg", "本月 12 日", "flat"),
        ("fundus", "鹰瞳眼底", "无异常", "", "无异常", "success", "eye", "2 个月前", "flat"),
        ("exercise", "饮食运动", "6,230", "步", "达标", "success", "figure.walk", "今天", "up"),
        ("spo2", "血氧", "98", "%", "正常", "success", "lungs", "今天 07:32", "flat"),
        ("digestive", "消化道", "无异常", "", "无异常", "success", "stethoscope", "3 个月前", "flat"),
    ]

    // MARK: - UI

    private lazy var collectionView: UICollectionView = {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(140))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(140))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 11, bottom: 12, trailing: 11)

        let layout = UICollectionViewCompositionalLayout(section: section)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .fdBg
        cv.showsVerticalScrollIndicator = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(MetricCardCell.self, forCellWithReuseIdentifier: MetricCardCell.reuseIdentifier)
        return cv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "体征监测"
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        metrics.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MetricCardCell.reuseIdentifier, for: indexPath) as? MetricCardCell else {
            return UICollectionViewCell()
        }
        let m = metrics[indexPath.item]
        cell.configure(metricKey: m.key, icon: m.icon, status: m.status, statusType: m.statusType, label: m.label, value: m.value, unit: m.unit, trend: m.trend, time: m.time)
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let key = metrics[indexPath.item].key
        Router.shared.push("/health/metrics/\(key)")
    }
}
