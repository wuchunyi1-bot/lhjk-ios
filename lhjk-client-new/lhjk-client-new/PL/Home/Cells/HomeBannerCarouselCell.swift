import UIKit
import SnapKit

/// 首页 Banner 轮播 — 对齐 HomeView.vue `.home-banner-section`（原型四色占位）
final class HomeBannerCarouselCell: UITableViewCell {

    static let reuseID = "HomeBannerCarouselCell"

    private let colors: [UIColor] = [
        .fdPrimary,
        UIColor(hexString: "#4B8BFF"),
        UIColor(hexString: "#2EAD8A"),
        UIColor(hexString: "#8B6CFF"),
    ]

    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.isPagingEnabled = true
        s.showsHorizontalScrollIndicator = false
        s.layer.cornerRadius = 18
        s.clipsToBounds = true
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .fdBg
        selectionStyle = .none
        contentView.clipsToBounds = false

        let wrap = UIView()
        wrap.layer.cornerRadius = 18
        wrap.addFundeShadow(radius: 12, opacity: 0.08)
        contentView.addSubview(wrap)
        wrap.addSubview(scrollView)
        wrap.addSubview(pageControl)

        wrap.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(140)
        }
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        pageControl.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-8)
        }

        scrollView.delegate = self
        pageControl.numberOfPages = colors.count
        buildSlides()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { timer?.invalidate() }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            startTimer()
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = scrollView.bounds.width
        guard w > 0, abs(w - pageWidth) > 0.5 else { return }
        pageWidth = w
        for (i, sub) in scrollView.subviews.enumerated() {
            sub.frame = CGRect(x: CGFloat(i) * w, y: 0, width: w, height: 140)
        }
        scrollView.contentSize = CGSize(width: w * CGFloat(colors.count), height: 140)
    }

    private func buildSlides() {
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        for color in colors {
            let slide = UIView()
            slide.backgroundColor = color
            scrollView.addSubview(slide)
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 4.2, repeats: true) { [weak self] _ in
            self?.advancePage()
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func advancePage() {
        guard pageWidth > 0 else { return }
        let next = (pageControl.currentPage + 1) % colors.count
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
