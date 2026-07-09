import UIKit
import SnapKit
import Kingfisher

/// 服务首页 Banner 轮播 — 数据来自 `GET /v1/columnContent/getByCode`
final class ServiceBannerCarouselCell: UITableViewCell {

    static let reuseID = "ServiceBannerCarouselCell"

    var onBannerTap: ((ServiceHubBanner) -> Void)?

    private var banners: [ServiceHubBanner] = []
    private var autoScrollTimer: Timer?

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
        collectionView.setContentOffset(.zero, animated: false)
        startAutoScroll()
    }

    private func startAutoScroll() {
        stopAutoScroll()
        guard banners.count > 1 else { return }
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 3.6, repeats: true) { [weak self] _ in
            self?.advancePage()
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func advancePage() {
        guard banners.count > 1, collectionView.bounds.width > 0 else { return }
        let next = (pageControl.currentPage + 1) % banners.count
        let offset = CGPoint(x: CGFloat(next) * collectionView.bounds.width, y: 0)
        collectionView.setContentOffset(offset, animated: true)
        pageControl.currentPage = next
    }
}

// MARK: - UICollectionView

extension ServiceBannerCarouselCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        banners.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerSlideCell.reuseID, for: indexPath) as! BannerSlideCell
        cell.configure(banners[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onBannerTap?(banners[indexPath.item])
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopAutoScroll()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPage()
        startAutoScroll()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }

    private func updateCurrentPage() {
        guard collectionView.bounds.width > 0 else { return }
        pageControl.currentPage = Int(round(collectionView.contentOffset.x / collectionView.bounds.width))
    }
}

// MARK: - Slide Cell

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

    private let textContainer = UIView()
    private let codeBg = UIView()
    private let codeLbl = UILabel()
    private let iconLbl = UILabel()
    private let titleLbl = UILabel()
    private let subtitleLbl = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }

        card.addSubview(bannerImageView)
        bannerImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        card.addSubview(textContainer)
        textContainer.snp.makeConstraints { $0.edges.equalToSuperview() }

        codeBg.layer.cornerRadius = 14
        codeLbl.font = .fdH3
        codeLbl.textAlignment = .center
        codeBg.addSubview(codeLbl)
        codeLbl.snp.makeConstraints { $0.center.equalToSuperview() }
        codeBg.snp.makeConstraints { $0.size.equalTo(44) }

        iconLbl.font = .systemFont(ofSize: 36)
        iconLbl.text = "🏥"
        iconLbl.isHidden = true

        titleLbl.font = .fdBodyBold
        titleLbl.textColor = .fdText
        titleLbl.numberOfLines = 2
        subtitleLbl.font = .fdCaption
        subtitleLbl.textColor = .fdText2
        subtitleLbl.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleLbl, subtitleLbl])
        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.alignment = .leading

        let header = UIStackView(arrangedSubviews: [codeBg, iconLbl, textStack])
        header.spacing = 12
        header.alignment = .top
        textContainer.addSubview(header)
        header.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        bannerImageView.kf.cancelDownloadTask()
        bannerImageView.image = nil
    }

    func configure(_ banner: ServiceHubBanner) {
        if banner.hasImage, let urlString = banner.imageUrl, let url = URL(string: urlString) {
            bannerImageView.isHidden = false
            textContainer.isHidden = true
            bannerImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
            card.backgroundColor = .fdBg2
            card.layer.borderWidth = 0
        } else {
            bannerImageView.isHidden = true
            textContainer.isHidden = false
            card.backgroundColor = banner.background
            card.layer.borderWidth = 1
            card.layer.borderColor = banner.accent.withAlphaComponent(0.2).cgColor

            if let code = banner.codeLabel, !code.isEmpty {
                codeBg.isHidden = false
                iconLbl.isHidden = true
                codeBg.backgroundColor = banner.accent
                codeLbl.text = code
                codeLbl.textColor = .white
            } else {
                codeBg.isHidden = true
                iconLbl.isHidden = true
            }

            titleLbl.text = banner.title
            subtitleLbl.text = banner.subtitle
            subtitleLbl.isHidden = banner.subtitle.isEmpty
        }
    }
}
