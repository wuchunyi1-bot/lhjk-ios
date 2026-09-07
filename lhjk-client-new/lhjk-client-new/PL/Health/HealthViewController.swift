import UIKit
import SnapKit
import Combine

/// 健康模块 Hub — 对齐 Figma 3444:4712 / 3021:1121
///
/// Section 0: HealthScoreCardCell（健康评分卡）
/// Section 1: HealthArchiveCardCell（健康档案完整度）
/// Section 2: HealthQuickEntriesCell（金刚区快捷入口）
/// Section 3: HealthVitalMetricsCell（体征监测卡片）
final class HealthViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    private enum SectionType {
        case score
        case archive
        case quickEntries
        case vitalMetrics
    }

    private var activeSections: [SectionType] {
        var list: [SectionType] = [.score, .archive]
        if !viewModel.quickEntries.isEmpty {
            list.append(.quickEntries)
        }
        list.append(.vitalMetrics)
        return list
    }

    private let riskScore = 62

    private var riskLevelText: String {
        let level = UserManager.shared.defaultArchive?.riskLevel
        return DictionaryCacheService.shared.label(parent: .riskLevel, intValue: level) ?? "—"
    }

    private var archiveProgress: Int {
        UserManager.shared.archiveCompletionPercentage ?? 0
    }

    private let viewModel = HealthViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var lastVitalMetricsLayoutWidth: CGFloat = 0

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
        tv.register(HealthQuickEntriesCell.self, forCellReuseIdentifier: HealthQuickEntriesCell.reuseIdentifier)
        tv.register(HealthVitalMetricsCell.self, forCellReuseIdentifier: HealthVitalMetricsCell.reuseIdentifier)
        tv.contentInsetAdjustmentBehavior = .never
        tv.contentInset = .zero
        tv.scrollIndicatorInsets = .zero
        tv.estimatedRowHeight = 200
        tv.rowHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) { tv.sectionHeaderTopPadding = 0 }
        return tv
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        updateTableBottomInsetIfNeeded()
        refreshArchiveCompletionUI()
        viewModel.load()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableBottomInsetIfNeeded()
        reloadVitalMetricsSectionIfWidthChanged()
    }

    private func reloadVitalMetricsSectionIfWidthChanged() {
        let width = tableView.bounds.width
        guard width > 0, abs(width - lastVitalMetricsLayoutWidth) > 0.5 else { return }
        lastVitalMetricsLayoutWidth = width
        guard !viewModel.metrics.isEmpty else { return }
        guard let section = activeSections.firstIndex(of: .vitalMetrics) else { return }
        tableView.reloadSections(IndexSet(integer: section), with: .none)
    }

    private func updateTableBottomInsetIfNeeded() {
        guard let tabBar = tabBarController?.tabBar, !tabBar.isHidden else { return }
        let bottom = tabBar.frame.height + 12
        guard abs(tableView.contentInset.bottom - bottom) > 0.5 else { return }
        tableView.contentInset.bottom = bottom
        tableView.verticalScrollIndicatorInsets.bottom = bottom
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        refreshArchiveCompletionUI()
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
        NotificationCenter.default.publisher(for: .archiveCompletionDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshArchiveCompletionUI()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: DictionaryCacheService.didUpdateNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshArchiveCompletionUI()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .defaultArchiveDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshArchiveCompletionUI()
            }
            .store(in: &cancellables)

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

    func numberOfSections(in tableView: UITableView) -> Int {
        activeSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < activeSections.count else { return UITableViewCell() }
        switch activeSections[indexPath.section] {
        case .score:
            let cell = tableView.dequeueReusableCell(withIdentifier: HealthScoreCardCell.reuseIdentifier, for: indexPath) as! HealthScoreCardCell
            cell.configure(riskScore: riskScore, riskLevel: riskLevelText)
            return cell
        case .archive:
            let cell = tableView.dequeueReusableCell(withIdentifier: HealthArchiveCardCell.reuseIdentifier, for: indexPath) as! HealthArchiveCardCell
            cell.configure(archiveProgress: archiveProgress)
            cell.onCompleteTap = { [weak self] in self?.goToRecord() }
            return cell
        case .quickEntries:
            let cell = tableView.dequeueReusableCell(withIdentifier: HealthQuickEntriesCell.reuseIdentifier, for: indexPath) as! HealthQuickEntriesCell
            cell.configure(entries: viewModel.quickEntries)
            cell.onEntryTap = { [weak self] pageUrl in
                guard let self else { return }
                if FundePageURL.canOpen(pageUrl) {
                    FundePageURL.open(pageUrl, title: self.viewModel.quickEntries.first { $0.pageUrl == pageUrl }?.name, from: self)
                    return
                }
                if pageUrl.hasPrefix("/") {
                    Router.shared.push(pageUrl)
                }
            }
            return cell
        case .vitalMetrics:
            let cell = tableView.dequeueReusableCell(withIdentifier: HealthVitalMetricsCell.reuseIdentifier, for: indexPath) as! HealthVitalMetricsCell
            cell.configure(metrics: viewModel.metrics)
            cell.onMetricTap = { [weak self] item in
                guard let self else { return }
                if FundePageURL.canOpen(item.pageUrl) {
                    FundePageURL.open(item.pageUrl, title: item.label, from: self)
                    return
                }
                if item.hasMonitorData {
                    Router.shared.push(self.viewModel.route(for: item))
                } else {
                    Router.shared.push(MonitorCardDisplayMapper.recordRoute(for: item))
                }
            }
            cell.onEditTap = { Router.shared.push("/health/metrics/edit") }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section < activeSections.count else { return UITableView.automaticDimension }
        switch activeSections[indexPath.section] {
        case .vitalMetrics:
            let width = tableView.bounds.width > 0 ? tableView.bounds.width : view.bounds.width
            return HealthVitalMetricsCell.height(for: viewModel.metrics.count, containerWidth: width)
        default:
            return UITableView.automaticDimension
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

    private func refreshArchiveCompletionUI() {
        brandHeader.configure(
            title: "我的健康",
            subtitle: "档案完整度 \(archiveProgress)%",
            titleColor: .fdText,
            badge: riskLevelText
        )
        if isViewLoaded {
            tableView.reloadData()
        }
    }
}
