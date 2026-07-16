import UIKit
import SnapKit
import Kingfisher

/// 服务首页 Banner 轮播 — 仅展示图片，自动轮播单向无限循环（不回退滚动）
/// 数据来自 `GET /v1/columnContent/getByCode`；间隔 3.6s 对齐 funde `van-swipe :autoplay="3600"`
final class ServiceBannerCarouselCell: UITableViewCell {

    static let reuseID = "ServiceBannerCarouselCell"

    /// 逻辑页复制倍数，用于始终向右滚动实现循环
    private static let loopMultiplier = 200

    var onBannerTap: ((ServiceHubBanner) -> Void)?

    private var banners: [ServiceHubBanner] = []
    private var autoScrollTimer: Timer?
    /// 当前逻辑下标（落在 `[0, banners.count * loopMultiplier)`）
    private var logicalIndex = 0

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.decelerationRate = .fast
        cv.dataSource = self
        cv.delegate = self
        cv.register(BannerSlideCell.self, forCellWithReuseIdentifier: BannerSlideCell.reuseID)
        return cv
    }()

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .fdPrimary
        pc.pageIndicatorTintColor = UIColor.fdPrimary.withAlphaComponent(0.25)
        pc.hidesForSinglePage = true
        return pc
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(collectionView)
        contentView.addSubview(pageControl)
        collectionView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(172)
        }
        pageControl.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-4)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopAutoScroll()
    }

    deinit { stopAutoScroll() }

    func configure(_ banners: [ServiceHubBanner]) {
        self.banners = banners
        pageControl.numberOfPages = banners.count
        pageControl.currentPage = 0
        collectionView.reloadData()

        guard banners.count > 1 else {
            logicalIndex = 0
            collectionView.setContentOffset(.zero, animated: false)
            stopAutoScroll()
            return
        }

        // 从中间一组开始，便于向两侧手势滑动，自动播始终 +1
        logicalIndex = banners.count * (Self.loopMultiplier / 2)
        DispatchQueue.main.async { [weak self] in
            self?.scrollToLogicalIndex(self?.logicalIndex ?? 0, animated: false)
            self?.startAutoScroll()
        }
    }

    private var totalItemCount: Int {
        guard banners.count > 1 else { return banners.count }
        return banners.count * Self.loopMultiplier
    }

    private func realIndex(for logical: Int) -> Int {
        guard !banners.isEmpty else { return 0 }
        let count = banners.count
        let mod = logical % count
        return mod >= 0 ? mod : mod + count
    }

    private func scrollToLogicalIndex(_ index: Int, animated: Bool) {
        guard collectionView.bounds.width > 0, totalItemCount > 0 else { return }
        let clamped = max(0, min(index, totalItemCount - 1))
        logicalIndex = clamped
        let offset = CGPoint(x: CGFloat(clamped) * collectionView.bounds.width, y: 0)
        collectionView.setContentOffset(offset, animated: animated)
        pageControl.currentPage = realIndex(for: clamped)
    }

    /// 越界时无动画跳回中间等价页，避免从最后一张滚回第一张产生「往回走」
    private func normalizePositionIfNeeded() {
        guard banners.count > 1 else { return }
        let count = banners.count
        let middleBase = count * (Self.loopMultiplier / 2)
        let real = realIndex(for: logicalIndex)
        if logicalIndex < count || logicalIndex >= totalItemCount - count {
            logicalIndex = middleBase + real
            scrollToLogicalIndex(logicalIndex, animated: false)
        }
    }

    private func startAutoScroll() {
        stopAutoScroll()
        guard banners.count > 1 else { return }
        let timer = Timer(timeInterval: 3.6, repeats: true) { [weak self] _ in
            self?.advancePage()
        }
        RunLoop.main.add(timer, forMode: .common)
        autoScrollTimer = timer
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func advancePage() {
        guard banners.count > 1, collectionView.bounds.width > 0 else { return }
        normalizePositionIfNeeded()
        scrollToLogicalIndex(logicalIndex + 1, animated: true)
    }
}

// MARK: - UICollectionView

extension ServiceBannerCarouselCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        totalItemCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerSlideCell.reuseID, for: indexPath) as! BannerSlideCell
        cell.configure(banners[realIndex(for: indexPath.item)])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onBannerTap?(banners[realIndex(for: indexPath.item)])
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopAutoScroll()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        syncLogicalIndexFromOffset()
        normalizePositionIfNeeded()
        startAutoScroll()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        syncLogicalIndexFromOffset()
        normalizePositionIfNeeded()
    }

    private func syncLogicalIndexFromOffset() {
        guard collectionView.bounds.width > 0 else { return }
        logicalIndex = Int(round(collectionView.contentOffset.x / collectionView.bounds.width))
        pageControl.currentPage = realIndex(for: logicalIndex)
    }
}

// MARK: - Slide Cell（仅 Banner 图）

private final class BannerSlideCell: UICollectionViewCell {

    static let reuseID = "BannerSlideCell"

    private let card = UIView()
    private let bannerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .fdBg2
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        card.addSubview(bannerImageView)
        bannerImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        bannerImageView.kf.cancelDownloadTask()
        bannerImageView.image = nil
    }

    func configure(_ banner: ServiceHubBanner) {
        if banner.hasImage, let urlString = banner.imageUrl, let url = URL(string: urlString) {
            bannerImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            bannerImageView.image = nil
            bannerImageView.backgroundColor = banner.background
        }
    }
}
