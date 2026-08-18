import UIKit
import SnapKit

/// 套餐详情 1:1 顶部全宽轮播视图
final class PackageDetailCarouselView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    let pageCount: Int

    private let labels: [String]
    private let imageURLs: [String]
    private let accent: UIColor
    private var currentPage = 0

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .black
        cv.dataSource = self
        cv.delegate = self
        cv.register(PackageDetailCarouselSlideCell.self, forCellWithReuseIdentifier: PackageDetailCarouselSlideCell.reuseID)
        return cv
    }()

    private let pageIndicatorLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 10, weight: .regular)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor(white: 0, alpha: 0.5)
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }()

    init(labels: [String], imageURLs: [String] = [], accent: UIColor) {
        self.imageURLs = imageURLs
        let count = max(imageURLs.count, labels.count, 1)
        if imageURLs.isEmpty {
            self.labels = labels.isEmpty ? ["套餐详情"] : labels
        } else {
            self.labels = (0..<count).map { idx in
                labels.indices.contains(idx) ? labels[idx] : "套餐图 \(idx + 1)"
            }
        }
        self.accent = accent
        self.pageCount = imageURLs.isEmpty ? self.labels.count : imageURLs.count
        super.init(frame: .zero)

        addSubview(collectionView)
        addSubview(pageIndicatorLabel)

        collectionView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(collectionView.snp.width)
        }

        pageIndicatorLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(40)
            $0.height.equalTo(20)
            $0.width.greaterThanOrEqualTo(32)
        }

        pageIndicatorLabel.isHidden = pageCount <= 1
        updateIndicator()
    }

    required init?(coder: NSCoder) { fatalError() }

    func advancePage() {
        guard pageCount > 1, collectionView.bounds.width > 0 else { return }
        currentPage = (currentPage + 1) % pageCount
        collectionView.setContentOffset(
            CGPoint(x: CGFloat(currentPage) * collectionView.bounds.width, y: 0),
            animated: true
        )
        updateIndicator()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        pageCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PackageDetailCarouselSlideCell.reuseID,
            for: indexPath
        ) as! PackageDetailCarouselSlideCell
        let url = imageURLs.indices.contains(indexPath.item) ? imageURLs[indexPath.item] : nil
        let label = labels.indices.contains(indexPath.item) ? labels[indexPath.item] : ""
        cell.configure(label: label, imageURL: url, accent: accent, alternate: indexPath.item % 2 == 1)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { updatePage() }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) { updatePage() }

    private func updatePage() {
        guard collectionView.bounds.width > 0 else { return }
        currentPage = Int(round(collectionView.contentOffset.x / collectionView.bounds.width))
        updateIndicator()
    }

    private func updateIndicator() {
        pageIndicatorLabel.text = " \(currentPage + 1)/\(pageCount) "
    }
}

