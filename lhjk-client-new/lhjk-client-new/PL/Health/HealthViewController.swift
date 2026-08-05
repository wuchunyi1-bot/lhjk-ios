import UIKit
import SnapKit
import Combine

/// 健康模块 Hub — 对齐 Figma 3021:1121
///
/// Section 0: HealthScoreCardCell（本地）
/// Section 1: HealthArchiveCardCell（本地）
/// Section 2: HealthVitalMetricsCell（API）
/// Section 3: HealthQuickEntriesCell（CMS，可空隐藏）
final class HealthViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    private let riskScore = 62
    private let riskLevel = "中风险"
    private let archiveProgress = 72

    private let viewModel = HealthViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let brandHeader = TabHubBrandHeaderView()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.dataSource = self
        tv.delegate = self
        tv.register(HealthScoreCardCell.self, forCellReuseIdentifier: HealthScoreCardCell.reuseIdentifier)
        tv.register(HealthArchiveCardCell.self, forCellReuseIdentifier: HealthArchiveCardCell.reuseIdentifier)
        tv.register(HealthVitalMetricsCell.self, forCellReuseIdentifier: HealthVitalMetricsCell.reuseIdentifier)
        tv.register(HealthQuickEntriesCell.self, forCellReuseIdentifier: HealthQuickEntriesCell.reuseIdentifier)
        tv.contentInsetAdjustmentBehavior = .never
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 90, right: 0)
        tv.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 90, right: 0)
        tv.estimatedRowHeight = 200
        tv.rowHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) { tv.sectionHeaderTopPadding = 0 }
        return tv
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.load()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        brandHeader.configure(
            title: "我的健康",
            subtitle: "档案完整度 \(archiveProgress)%",
            titleColor: .fdText,
            badge: riskLevel
        )
        view.addSubview(brandHeader)
        view.addSubview(tableView)
        brandHeader.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(brandHeader.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func bindViewModel() {
        viewModel.$metrics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        viewModel.$quickEntries
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)
    }

    // MARK: - Sections

    private var sectionCount: Int {
        viewModel.quickEntries.isEmpty ? 3 : 4
    }

    func numberOfSections(in tableView: UITableView) -> Int { sectionCount }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: HealthScoreCardCell.reuseIdentifier, for: indexPath) as! HealthScoreCardCell
            cell.configure(riskScore: riskScore, riskLevel: riskLevel)
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: HealthArchiveCardCell.reuseIdentifier, for: indexPath) as! HealthArchiveCardCell
            cell.configure(archiveProgress: archiveProgress)
            cell.onCompleteTap = { [weak self] in self?.goToRecord() }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: HealthVitalMetricsCell.reuseIdentifier, for: indexPath) as! HealthVitalMetricsCell
            cell.configure(metrics: viewModel.metrics)
            cell.onMetricTap = { [weak self] item in
                guard let self else { return }
                Router.shared.push(self.viewModel.route(for: item))
            }
            cell.onEditTap = { Router.shared.push("/health/metrics/edit") }
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: HealthQuickEntriesCell.reuseIdentifier, for: indexPath) as! HealthQuickEntriesCell
            cell.configure(entries: viewModel.quickEntries)
            // quickEntryList 暂不做跳转
            cell.onEntryTap = nil
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 2: return HealthVitalMetricsCell.height(for: viewModel.metrics.count)
        default: return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { nil }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { nil }

    @objc private func goToRecord() {
        Router.shared.push("/health/record")
    }
}
