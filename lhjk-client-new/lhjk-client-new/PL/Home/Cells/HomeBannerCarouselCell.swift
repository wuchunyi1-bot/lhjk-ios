import UIKit
import SnapKit
import Kingfisher

/// 首页 Banner 轮播 — 全宽图；数据来自 `getByCode` + `home_banner_code`
final class HomeBannerCarouselCell: UITableViewCell {

    static let reuseID = "HomeBannerCarouselCell"
    static let bannerHeight: CGFloat = 288

    var onBannerTap: ((ServiceHubBanner) -> Void)?

    private var banners: [ServiceHubBanner] = []

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
    private var pageWidth: CGFloat = 0
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
            $0.height.equalTo(Self.bannerHeight)
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
        let w = scrollView.bounds.width
        let h = Self.bannerHeight
        guard w > 0, abs(w - pageWidth) > 0.5 else { return }
        pageWidth = w
        for (i, sub) in slideViews.enumerated() {
            sub.frame = CGRect(x: CGFloat(i) * w, y: 0, width: w, height: h)
        }
        scrollView.contentSize = CGSize(width: w * CGFloat(max(banners.count, 1)), height: h)
    }

    func configure(_ banners: [ServiceHubBanner]) {
        let next = banners.filter(\.hasImage)
        let sameIds = self.banners.map(\.id) == next.map(\.id)
        self.banners = next
        pageControl.numberOfPages = next.count
        pageControl.currentPage = min(pageControl.currentPage, max(next.count - 1, 0))

        if !sameIds {
            pageWidth = 0
            buildSlides()
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
                imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
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
