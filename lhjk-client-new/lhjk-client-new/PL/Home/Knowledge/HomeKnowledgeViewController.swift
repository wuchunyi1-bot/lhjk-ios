import SnapKit
import UIKit

/// 首页「健康知识」页签。列表用现有健康陪伴资讯，详情仍走 H5。
final class HomeKnowledgeViewController: BaseViewController {

    var onArticleTap: ((HomeArticleCell.Article) -> Void)?

    private var articles: [HomeArticleCell.Article] = []
    private let serviceBanner = ServiceHubBannerBar()

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        serviceBanner.load()
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        serviceBanner.onBannerTap = { [weak self] banner in
            self?.serviceBanner.open(banner, from: self)
        }
        tableView.dataSource = self
        tableView.register(HomeArticleCell.self, forCellReuseIdentifier: HomeArticleCell.reuseID)
        view.addSubview(serviceBanner)
        view.addSubview(tableView)
        view.addSubview(emptyView)
        serviceBanner.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(serviceBanner.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.snp.makeConstraints {
            $0.edges.equalTo(tableView)
        }
        emptyView.isHidden = true
    }

    func update(articles: [HomeArticleCell.Article]) {
        self.articles = articles
        guard isViewLoaded else { return }
        emptyView.isHidden = !articles.isEmpty
        tableView.isHidden = articles.isEmpty
        tableView.reloadData()
    }
}

extension HomeKnowledgeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        articles.isEmpty ? 0 : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
}
