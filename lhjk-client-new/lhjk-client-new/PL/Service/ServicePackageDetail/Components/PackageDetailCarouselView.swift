import UIKit
import SnapKit

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
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(PackageDetailCarouselSlideCell.self, forCellWithReuseIdentifier: PackageDetailCarouselSlideCell.reuseID)
        cv.layer.cornerRadius = 14
        cv.clipsToBounds = true
        return cv
    }()

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .fdPrimary
        pc.pageIndicatorTintColor = UIColor.fdPrimary.withAlphaComponent(0.25)
        pc.hidesForSinglePage = true
        return pc
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
        addSubview(pageControl)
        collectionView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(collectionView.snp.width).multipliedBy(9.0 / 16.0)
        }
        pageControl.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(6)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        pageControl.numberOfPages = pageCount
    }

    required init?(coder: NSCoder) { fatalError() }

    func advancePage() {
        guard pageCount > 1, collectionView.bounds.width > 0 else { return }
        currentPage = (currentPage + 1) % pageCount
        collectionView.setContentOffset(
            CGPoint(x: CGFloat(currentPage) * collectionView.bounds.width, y: 0),
            animated: true
        )
        pageControl.currentPage = currentPage
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
        pageControl.currentPage = currentPage
    }
}
