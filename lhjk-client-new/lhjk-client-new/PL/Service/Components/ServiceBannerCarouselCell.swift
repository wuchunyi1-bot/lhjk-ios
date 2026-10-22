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
            ).priority(999).constraint
        }
        pageControl.snp.makeConstraints {
            $0.centerX.equalTo(collectionView)
            $0.bottom.equalTo(collectionView).offset(-12)
        }
        pageControl.backgroundStyle = .minimal
        pageControl.allowsContinuousInteraction = false
        pageControl.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        lastAppliedHeight = BannerImageAspectLayout.height(
            width: initialWidth,
            imageSize: nil,
            fallbackRatio: Self.fallbackRatio
        )
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

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        let width = targetSize.width > 0 ? targetSize.width : UIScreen.main.bounds.width
        let bannerWidth = max(0, width - Self.horizontalInset * 2)
        let height = lastAppliedHeight > 0
            ? lastAppliedHeight
            : BannerImageAspectLayout.height(
                width: bannerWidth,
                imageSize: resolvedImageSize,
                fallbackRatio: Self.fallbackRatio
            )
        return CGSize(width: width, height: height)
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

/// 与健康服务页相同的顶部 Banner。高度仍由轮播按图片比例计算，不把图片裁进固定框。
final class ServiceHubBannerBar: UIView, UITableViewDataSource, UITableViewDelegate {

    var onBannerTap: ((ServiceHubBanner) -> Void)?
    /// 高度变化（含无图时的 0）。首页页签用来把 Banner 放进滚动内容。
    var onHeightChange: ((CGFloat) -> Void)?
    var displayedHeight: CGFloat { banners.isEmpty ? 0 : bannerHeight }

    private var banners: [ServiceHubBanner] = []
    private var bannerHeight: CGFloat = 0
    private var heightConstraint: Constraint?
    private var loadTask: Task<Void, Never>?
    private var heightUpdateScheduled = false

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.isScrollEnabled = false
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 180
        tv.sectionHeaderHeight = 0
        tv.sectionFooterHeight = 0
        tv.contentInsetAdjustmentBehavior = .never
        if #available(iOS 15.0, *) {
            tv.sectionHeaderTopPadding = 0
        }
        return tv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ServiceBannerCarouselCell.self, forCellReuseIdentifier: ServiceBannerCarouselCell.reuseID)
        addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        snp.makeConstraints { make in
            heightConstraint = make.height.equalTo(0).constraint
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            let items = await AppContainer.shared.columnContentCacheService.banners(
                for: ColumnContentService.hospitalBannerCode
            )
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.apply(items.filter(\.hasImage))
            }
        }
    }

    func open(_ banner: ServiceHubBanner, from viewController: UIViewController?) {
        if FundePageURL.open(banner.pageUrl, from: viewController) { return }
        guard let path = banner.routePath else { return }
        if let id = banner.routeParamId {
            Router.shared.push(path, params: ["id": id])
        } else {
            Router.shared.push(path)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        banners.isEmpty ? 0 : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ServiceBannerCarouselCell.reuseID,
            for: indexPath
        ) as! ServiceBannerCarouselCell
        cell.configure(banners)
        cell.onBannerTap = { [weak self] banner in
            self?.onBannerTap?(banner)
        }
        cell.onHeightUpdated = { [weak self, weak cell] in
            guard let self, let cell else { return }
            let width = self.bounds.width > 1 ? self.bounds.width : UIScreen.main.bounds.width
            let height = cell.systemLayoutSizeFitting(
                CGSize(width: width, height: 0),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height
            self.applyHeight(height)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        bannerHeight > 1 ? bannerHeight : fallbackHeight()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }

    private func apply(_ banners: [ServiceHubBanner]) {
        self.banners = banners
        isHidden = banners.isEmpty
        if banners.isEmpty {
            bannerHeight = 0
            heightConstraint?.update(offset: 0)
        } else if bannerHeight < 1 {
            bannerHeight = fallbackHeight()
            heightConstraint?.update(offset: bannerHeight)
        }
        tableView.reloadData()
        onHeightChange?(displayedHeight)
    }

    /// 只改已有行的高度。行数变化必须走 reloadData，不能 beginUpdates。
    private func applyHeight(_ height: CGFloat) {
        let next = max(height, 1)
        guard abs(next - bannerHeight) > 0.5 else { return }
        bannerHeight = next
        heightConstraint?.update(offset: next)
        guard !heightUpdateScheduled else { return }
        heightUpdateScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.heightUpdateScheduled = false
            guard self.tableView.numberOfRows(inSection: 0) == 1 else { return }
            UIView.performWithoutAnimation {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
            self.onHeightChange?(self.displayedHeight)
        }
    }

    private func fallbackHeight() -> CGFloat {
        let width = bounds.width > 1 ? bounds.width : UIScreen.main.bounds.width
        return BannerImageAspectLayout.height(
            width: max(0, width - ServiceBannerCarouselCell.horizontalInset * 2),
            imageSize: nil,
            fallbackRatio: ServiceBannerCarouselCell.fallbackRatio
        )
    }
}
