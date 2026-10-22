import SnapKit
import UIKit

/// 首页「健康知识」页签。列表用现有健康陪伴资讯，详情仍走 H5。
final class HomeKnowledgeViewController: BaseViewController {

    var onArticleTap: ((HomeArticleCell.Article) -> Void)?

    private var articles: [HomeArticleCell.Article] = []
    private var banners: [ServiceHubBanner] = []
    private var bannerRowHeight: CGFloat = 0
    private var loadTask: Task<Void, Never>?
    private var heightUpdateScheduled = false

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 200
        tv.contentInsetAdjustmentBehavior = .never
        return tv
    }()

    private let emptyView = FDEmptyStateView(style: .page, message: "暂无健康知识")

    private var showsBanner: Bool { !banners.isEmpty }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadBanners()
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HomeArticleCell.self, forCellReuseIdentifier: HomeArticleCell.reuseID)
        tableView.register(
            ServiceBannerCarouselCell.self,
            forCellReuseIdentifier: ServiceBannerCarouselCell.reuseID
        )
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    func update(articles: [HomeArticleCell.Article]) {
        self.articles = articles
        guard isViewLoaded else { return }
        layoutEmptyFooter()
        tableView.reloadData()
    }

    private func loadBanners() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            let items = await AppContainer.shared.columnContentCacheService.banners(
                for: ColumnContentService.hospitalBannerCode
            )
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.applyBanners(items.filter(\.hasImage))
            }
        }
    }

    /// 轮播是文章表的一行。不要再套一层表当 tableHeaderView，否则行高在、图不画。
    private func applyBanners(_ next: [ServiceHubBanner]) {
        let same = banners.map(\.id) == next.map(\.id)
        let hadBanner = showsBanner
        banners = next
        if next.isEmpty {
            bannerRowHeight = 0
        } else if bannerRowHeight < 1 {
            bannerRowHeight = fallbackBannerHeight()
        }
        guard isViewLoaded else { return }
        if hadBanner == showsBanner, same {
            if showsBanner,
               let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ServiceBannerCarouselCell {
                cell.configure(banners)
            }
            layoutEmptyFooter()
            return
        }
        let offset = tableView.contentOffset
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableView.contentOffset = offset
        layoutEmptyFooter()
    }

    private func applyBannerRowHeight(_ height: CGFloat) {
        let next = max(height, 1)
        guard showsBanner, abs(next - bannerRowHeight) > 0.5 else { return }
        bannerRowHeight = next
        guard !heightUpdateScheduled else { return }
        heightUpdateScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.heightUpdateScheduled = false
            guard self.showsBanner, self.tableView.numberOfRows(inSection: 0) > 0 else { return }
            UIView.performWithoutAnimation {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }
    }

    private func fallbackBannerHeight() -> CGFloat {
        let width = tableView.bounds.width > 1 ? tableView.bounds.width : view.bounds.width
        return BannerImageAspectLayout.height(
            width: max(0, width - ServiceBannerCarouselCell.horizontalInset * 2),
            imageSize: nil,
            fallbackRatio: ServiceBannerCarouselCell.fallbackRatio
        )
    }

    private func open(_ banner: ServiceHubBanner) {
        if FundePageURL.open(banner.pageUrl, from: self) { return }
        guard let path = banner.routePath else { return }
        if let id = banner.routeParamId {
            Router.shared.push(path, params: ["id": id])
        } else {
            Router.shared.push(path)
        }
    }

    private func layoutEmptyFooter() {
        guard articles.isEmpty else {
            if tableView.tableFooterView != nil {
                tableView.tableFooterView = nil
            }
            return
        }
        let width = tableView.bounds.width > 1 ? tableView.bounds.width : view.bounds.width
        emptyView.frame = CGRect(x: 0, y: 0, width: width, height: 320)
        tableView.tableFooterView = emptyView
    }
}

extension HomeKnowledgeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (showsBanner ? 1 : 0) + (articles.isEmpty ? 0 : 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showsBanner, indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ServiceBannerCarouselCell.reuseID,
                for: indexPath
            ) as! ServiceBannerCarouselCell
            cell.configure(banners)
            cell.onBannerTap = { [weak self] banner in
                self?.open(banner)
            }
            cell.onHeightUpdated = { [weak self, weak cell] in
                guard let self, let cell else { return }
                let width = self.tableView.bounds.width > 1 ? self.tableView.bounds.width : self.view.bounds.width
                let height = cell.systemLayoutSizeFitting(
                    CGSize(width: width, height: 0),
                    withHorizontalFittingPriority: .required,
                    verticalFittingPriority: .fittingSizeLevel
                ).height
                self.applyBannerRowHeight(height)
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(
            withIdentifier: HomeArticleCell.reuseID,
            for: indexPath
        ) as! HomeArticleCell
        cell.configure(articles: articles, title: "健康知识", showsMore: true)
        cell.onTapped = { [weak self] article in
            self?.onArticleTap?(article)
        }
        cell.onMoreTapped = {
            Router.shared.push("/companion")
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard showsBanner, indexPath.row == 0 else { return UITableView.automaticDimension }
        return bannerRowHeight > 1 ? bannerRowHeight : fallbackBannerHeight()
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard showsBanner, indexPath.row == 0 else { return 200 }
        return bannerRowHeight > 1 ? bannerRowHeight : fallbackBannerHeight()
    }
}
