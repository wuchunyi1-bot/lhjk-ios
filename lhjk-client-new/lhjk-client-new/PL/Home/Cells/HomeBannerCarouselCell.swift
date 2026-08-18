import UIKit
import SnapKit
import Kingfisher

/// 首页 Banner 轮播 — 全宽图；高度按图片比例计算（宽度固定为屏幕宽）
/// 数据来自 `getByCode` + `home_banner_code`
final class HomeBannerCarouselCell: UITableViewCell {

    static let reuseID = "HomeBannerCarouselCell"
    /// 375 稿 288 高，仅作图片未加载时的兜底比例
    static let fallbackRatio: CGFloat = 288.0 / 375.0

    var onBannerTap: ((ServiceHubBanner) -> Void)?
    var onHeightUpdated: (() -> Void)?

    private var banners: [ServiceHubBanner] = []
    private var heightConstraint: Constraint?
    private var resolvedImageSize: CGSize?
    private var lastAppliedHeight: CGFloat = 0
    private var pageWidth: CGFloat = 0

    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.isPagingEnabled = true
        s.showsHorizontalScrollIndicator = false
        s.bounces = false
        return s
    }()

    private let pageControl: UIPageControl = {
        let p = UIPageControl()
        p.currentPageIndicatorTintColor = .white
        p.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.45)
        p.isUserInteractionEnabled = false
        p.hidesForSinglePage = true
        return p
    }()

    private var timer: Timer?
    private var slideViews: [UIView] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        contentView.clipsToBounds = true

        contentView.addSubview(scrollView)
        contentView.addSubview(pageControl)
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            heightConstraint = $0.height.equalTo(Self.fallbackHeight(for: UIScreen.main.bounds.width)).constraint
            $0.bottom.equalToSuperview()
        }
        pageControl.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-16)
        }

        scrollView.delegate = self
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { timer?.invalidate() }

    override func prepareForReuse() {
        super.prepareForReuse()
        timer?.invalidate()
        timer = nil
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, banners.count > 1 {
            startTimer()
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = scrollView.bounds.width
        guard width > 0 else { return }
        applyBannerHeight(width: width, notify: lastAppliedHeight > 0)
        layoutSlides(width: width, height: lastAppliedHeight)
    }

    func configure(_ banners: [ServiceHubBanner]) {
        let next = banners.filter(\.hasImage)
        let sameIds = self.banners.map(\.id) == next.map(\.id)
        self.banners = next
        pageControl.numberOfPages = next.count
        pageControl.currentPage = min(pageControl.currentPage, max(next.count - 1, 0))

        if !sameIds {
            pageWidth = 0
            resolvedImageSize = nil
            lastAppliedHeight = 0
            buildSlides()
            applyBannerHeight(width: bannerWidth(), notify: false)
            setNeedsLayout()
            layoutIfNeeded()
        }

        if window != nil, next.count > 1 {
            startTimer()
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    private func bannerWidth() -> CGFloat {
        let width = scrollView.bounds.width
        return width > 1 ? width : UIScreen.main.bounds.width
    }

    private static func fallbackHeight(for width: CGFloat) -> CGFloat {
        BannerImageAspectLayout.height(width: width, imageSize: nil, fallbackRatio: fallbackRatio)
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
        layoutSlides(width: width, height: height)
        if notify {
            onHeightUpdated?()
        }
    }

    private func adoptImageSize(_ size: CGSize) {
        guard size.width > 1, size.height > 1, resolvedImageSize == nil else { return }
        resolvedImageSize = size
        applyBannerHeight(width: bannerWidth(), notify: true)
    }

    private func layoutSlides(width: CGFloat, height: CGFloat) {
        guard width > 0, height > 0 else { return }
        pageWidth = width
        for (i, sub) in slideViews.enumerated() {
            sub.frame = CGRect(x: CGFloat(i) * width, y: 0, width: width, height: height)
        }
        scrollView.contentSize = CGSize(width: width * CGFloat(max(banners.count, 1)), height: height)
    }

    private func buildSlides() {
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        slideViews.removeAll()

        for (index, banner) in banners.enumerated() {
            let container = UIView()
            container.clipsToBounds = true
            container.tag = index

            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.backgroundColor = UIColor(hexString: banner.backgroundHex)
            imageView.frame = container.bounds
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            if let urlString = banner.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))]) { [weak self] result in
                    if case .success(let value) = result {
                        self?.adoptImageSize(value.image.size)
                    }
                }
            }
            container.addSubview(imageView)

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            container.addGestureRecognizer(tap)
            container.isUserInteractionEnabled = true

            scrollView.addSubview(container)
            slideViews.append(container)
        }
        scrollView.contentOffset = .zero
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag, banners.indices.contains(index) else { return }
        onBannerTap?(banners[index])
    }

    private func startTimer() {
        timer?.invalidate()
        guard banners.count > 1 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 4.2, repeats: true) { [weak self] _ in
            self?.advancePage()
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    private func advancePage() {
        guard pageWidth > 0, banners.count > 1 else { return }
        let next = (pageControl.currentPage + 1) % banners.count
        scrollView.setContentOffset(CGPoint(x: CGFloat(next) * pageWidth, y: 0), animated: true)
        pageControl.currentPage = next
    }
}

extension HomeBannerCarouselCell: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard pageWidth > 0, !banners.isEmpty else { return }
        pageControl.currentPage = Int(round(scrollView.contentOffset.x / pageWidth)) % banners.count
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        timer?.invalidate()
        timer = nil
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { startTimer() }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        startTimer()
    }
}
