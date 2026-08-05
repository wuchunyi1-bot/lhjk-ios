import UIKit
import SnapKit

/// 首页 Banner 轮播 — 对齐 Figma 3021:784（全宽暖橙图；叠层文案暂不展示）
final class HomeBannerCarouselCell: UITableViewCell {

    static let reuseID = "HomeBannerCarouselCell"
    static let bannerHeight: CGFloat = 288

    private let imageNames = ["home_banner_1", "home_banner_2", "home_banner_3"]

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
        pageControl.numberOfPages = imageNames.count
        buildSlides()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { timer?.invalidate() }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { startTimer() } else {
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
        scrollView.contentSize = CGSize(width: w * CGFloat(imageNames.count), height: h)
    }

    private func buildSlides() {
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        slideViews.removeAll()
        for name in imageNames {
            // 仅展示图片；叠层文案暂不创建，避免 frame 布局初始宽度为 0 时约束冲突
            let container = UIView()
            container.clipsToBounds = true

            let imageView = UIImageView(image: UIImage(named: name))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.frame = container.bounds
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            container.addSubview(imageView)

            scrollView.addSubview(container)
            slideViews.append(container)
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 4.2, repeats: true) { [weak self] _ in
            self?.advancePage()
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    private func advancePage() {
        guard pageWidth > 0 else { return }
        let next = (pageControl.currentPage + 1) % imageNames.count
        scrollView.setContentOffset(CGPoint(x: CGFloat(next) * pageWidth, y: 0), animated: true)
        pageControl.currentPage = next
    }
}

extension HomeBannerCarouselCell: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard pageWidth > 0 else { return }
        pageControl.currentPage = Int(round(scrollView.contentOffset.x / pageWidth))
    }
}
