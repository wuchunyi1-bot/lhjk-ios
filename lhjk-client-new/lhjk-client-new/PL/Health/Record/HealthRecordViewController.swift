import UIKit
import SnapKit

/// 健康档案主页面
/// 参考 funde-client: HealthProfileView.vue
///
/// 布局: UITableView 5 sections
///   Section 0: HealthRecordUserInfoCell — 用户信息 + 档案完整度 + 六维评测
///   Section 1: HealthRecordBodyCardCell — 人形图 + 风险等级 + 顾问批注
///   Section 2: HealthRecordMetricRowCell — 健康监测最新数据（6 行）
///   Section 3: HealthRecordLifestyleCell — 生活习惯（2×1 grid）
///   Section 4: HealthRecordHistoryCell — 健康史（2×2 grid）
final class HealthRecordViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Mock Data

    private var userName = "加载中…"
    private var avatarText = "我"
    private let archiveProgress = HealthRecordMockData.archiveProgress
    private let riskItems = HealthRecordMockData.riskItems
    private let latestMetrics = HealthRecordMockData.latestMetrics
    private let lifestyleItems = HealthRecordMockData.lifestyleItems
    private let healthHistoryItems = HealthRecordMockData.healthHistoryItems

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.dataSource = self
        tv.delegate = self
        tv.register(HealthRecordUserInfoCell.self, forCellReuseIdentifier: HealthRecordUserInfoCell.reuseIdentifier)
        tv.register(HealthRecordBodyCardCell.self, forCellReuseIdentifier: HealthRecordBodyCardCell.reuseIdentifier)
        tv.register(HealthRecordMetricRowCell.self, forCellReuseIdentifier: HealthRecordMetricRowCell.reuseIdentifier)
        tv.register(HealthRecordLifestyleCell.self, forCellReuseIdentifier: HealthRecordLifestyleCell.reuseIdentifier)
        tv.register(HealthRecordHistoryCell.self, forCellReuseIdentifier: HealthRecordHistoryCell.reuseIdentifier)
        return tv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "健康档案"
        hidesBottomBarWhenPushed = true
        NotificationCenter.default.addObserver(self, selector: #selector(onUserUpdated),
                                               name: .userDidUpdate, object: nil)
        loadUserProfile()
    }

    private func loadUserProfile() {
        guard let user = UserManager.shared.currentUser else { return }
        self.userName = user.chineseName ?? user.surname ?? user.nickname ?? "用户"
        self.avatarText = String(self.userName.prefix(1))
        self.tableView.reloadData()
    }

    @objc private func onUserUpdated() {
        loadUserProfile()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        view.addSubview(tableView)
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int { 5 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HealthRecordUserInfoCell.reuseIdentifier, for: indexPath) as? HealthRecordUserInfoCell else {
                return UITableViewCell()
            }
            cell.configure(userName: userName, avatarText: avatarText, archiveProgress: archiveProgress)
            cell.onSixDimTap = { [weak self] in self?.goToSixDim() }
            return cell

        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HealthRecordBodyCardCell.reuseIdentifier, for: indexPath) as? HealthRecordBodyCardCell else {
                return UITableViewCell()
            }
            cell.configure(riskItems: riskItems)
            return cell

        case 2:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HealthRecordMetricRowCell.reuseIdentifier, for: indexPath) as? HealthRecordMetricRowCell else {
                return UITableViewCell()
            }
            cell.configure(metrics: latestMetrics)
            return cell

        case 3:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HealthRecordLifestyleCell.reuseIdentifier, for: indexPath) as? HealthRecordLifestyleCell else {
                return UITableViewCell()
            }
            cell.configure(items: lifestyleItems)
            return cell

        case 4:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HealthRecordHistoryCell.reuseIdentifier, for: indexPath) as? HealthRecordHistoryCell else {
                return UITableViewCell()
            }
            cell.configure(items: healthHistoryItems)
            return cell

        default:
            return UITableViewCell()
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section >= 2 else { return nil }

        let title: String
        switch section {
        case 2: title = "健康监测"
        case 3: title = "生活习惯"
        case 4: title = "健康史"
        default: return nil
        }

        let header = SectionTitleView(title: title, more: "更多 ›")

        // Determine route for "更多 ›" tap
        let route: String
        switch section {
        case 2: route = "/health/metrics"
        case 3: route = "/health/record/lifestyle"
        case 4: route = "/health/record/history"
        default: return nil
        }

        header.onMoreTapped = { Router.shared.push(route) }

        let container = UIView()
        container.backgroundColor = .fdBg
        container.addSubview(header)
        header.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section >= 2 ? 36 : 8
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    // MARK: - Actions

    private func goToSixDim() {
        Router.shared.push("/health/assessment/six-dim")
    }
}
