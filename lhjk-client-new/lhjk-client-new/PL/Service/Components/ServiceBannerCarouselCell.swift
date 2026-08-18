import UIKit
import SnapKit
import Kingfisher

/// 服务首页 Banner 轮播 — 宽度为屏宽减左右 16pt，高度按图片比例计算
/// 数据来自 `GET /v1/columnContent/getByCode`；间隔 3.6s 对齐 funde `van-swipe :autoplay="3600"`
final class ServiceBannerCarouselCell: UITableViewCell {

    static let reuseID = "ServiceBannerCarouselCell"

    /// Figma 3042:1521 344×180，仅作图片未加载时的兜底比例
    static let fallbackRatio: CGFloat = 180.0 / 344.0
    /// Figma 左右边距（375 稿宽 → 内容约 343~344）
    static let horizontalInset: CGFloat = 16
    static let cornerRadius: CGFloat = 16

    /// 逻辑页复制倍数，用于始终向右滚动实现循环
    private static let loopMultiplier = 200

    var onBannerTap: ((ServiceHubBanner) -> Void)?
    var onHeightUpdated: (() -> Void)?

    private var banners: [ServiceHubBanner] = []
    private var heightConstraint: Constraint?
    private var resolvedImageSize: CGSize?
    private var lastAppliedHeight: CGFloat = 0
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
        cv.layer.cornerRadius = Self.cornerRadius
        cv.clipsToBounds = true
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
        contentView.backgroundColor = .clear
        contentView.addSubview(collectionView)
        contentView.addSubview(pageControl)
        let initialWidth = UIScreen.main.bounds.width - Self.horizontalInset * 2
        collectionView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalToSuperview().offset(Self.horizontalInset)
            $0.trailing.equalToSuperview().offset(-Self.horizontalInset)
            heightConstraint = $0.height.equalTo(
                BannerImageAspectLayout.height(
                    width: initialWidth,
                    imageSize: nil,
                    fallbackRatio: Self.fallbackRatio
                )
            ).constraint
        }
        pageControl.snp.makeConstraints {
            $0.centerX.equalTo(collectionView)
            $0.bottom.equalTo(collectionView).offset(-12)
        }
        if #available(iOS 14.0, *) {
            pageControl.backgroundStyle = .minimal
            pageControl.allowsContinuousInteraction = false
        }
        pageControl.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopAutoScroll()
    }

    deinit { stopAutoScroll() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = collectionView.bounds.width
        if width > 0 {
            applyBannerHeight(width: width, notify: lastAppliedHeight > 0)
        }
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let size = collectionView.bounds.size
            if size.width > 0, size.height > 0, layout.itemSize != size {
                layout.itemSize = size
                layout.invalidateLayout()
            }
        }
    }

    func configure(_ banners: [ServiceHubBanner]) {
        let sameIds = self.banners.map(\.id) == banners.map(\.id)
        self.banners = banners
        pageControl.numberOfPages = banners.count
        pageControl.currentPage = 0
        if !sameIds {
            resolvedImageSize = nil
            lastAppliedHeight = 0
        }
        applyBannerHeight(width: bannerWidth(), notify: false)
        collectionView.reloadData()

        guard banners.count > 1 else {
            logicalIndex = 0
            collectionView.setContentOffset(.zero, animated: false)
            stopAutoScroll()
            return
        }

        logicalIndex = banners.count * (Self.loopMultiplier / 2)
        DispatchQueue.main.async { [weak self] in
            self?.scrollToLogicalIndex(self?.logicalIndex ?? 0, animated: false)
            self?.startAutoScroll()
        }
    }

    private func bannerWidth() -> CGFloat {
        let width = collectionView.bounds.width
        if width > 1 { return width }
        return UIScreen.main.bounds.width - Self.horizontalInset * 2
    }

    private func applyBannerHeight(width: CGFloat, notify: Bool) {
        guard width > 0 else { return }
        let height = BannerImageAspectLayout.height(
            width: width,
            imageSize: resolvedImageSize,
            fallbackRatio: Self.fallbackRatio
        )
        let heightChanged = abs(height - lastAppliedHeight) > 0.5
        guard heightChanged else { return }
        lastAppliedHeight = height
        heightConstraint?.update(offset: height)
        if notify {
            onHeightUpdated?()
        }
    }

    private func adoptImageSize(_ size: CGSize) {
        guard size.width > 1, size.height > 1, resolvedImageSize == nil else { return }
        resolvedImageSize = size
        applyBannerHeight(width: bannerWidth(), notify: true)
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
        cell.onImageLoaded = { [weak self] size in
            self?.adoptImageSize(size)
        }
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

// MARK: - Slide Cell

private final class BannerSlideCell: UICollectionViewCell {

    static let reuseID = "BannerSlideCell"

    var onImageLoaded: ((CGSize) -> Void)?

    private let bannerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .fdBg2
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = true
        contentView.addSubview(bannerImageView)
        bannerImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        bannerImageView.kf.cancelDownloadTask()
        bannerImageView.image = nil
        onImageLoaded = nil
    }

    func configure(_ banner: ServiceHubBanner) {
        if banner.hasImage, let urlString = banner.imageUrl, let url = URL(string: urlString) {
            bannerImageView.kf.setImage(
                with: url,
                options: [
                    .transition(.fade(0.2)),
                    .scaleFactor(UIScreen.main.scale),
                ]
            ) { [weak self] result in
                if case .success(let value) = result {
                    self?.onImageLoaded?(value.image.size)
                }
            }
        } else {
            bannerImageView.image = nil
            bannerImageView.backgroundColor = banner.background
        }
    }
}
