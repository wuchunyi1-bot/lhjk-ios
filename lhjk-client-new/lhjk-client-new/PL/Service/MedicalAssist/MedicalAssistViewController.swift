import Combine
import SnapKit
import UIKit

/// 就医协助落地页。`FundeApp:/services/medical-assist`
///
/// 头图与卖点为页面固定文案。套餐来自 `GET /v1/cabin/medicalConfigList?businessType=3`。
/// 使用记录走预约列表并带 `businessType=3`。
final class MedicalAssistViewController: BaseViewController {

    private let viewModel = ExamAppointmentListViewModel(
        businessType: ServiceItemService.assistBusinessType,
        failureMessage: "获取就医协助套餐失败"
    )
    private var cancellables = Set<AnyCancellable>()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let refresh = UIRefreshControl()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.reload()
    }

    override func setupUI() {
        title = "就医协助"
        view.backgroundColor = .fdBg

        let recordsItem = UIBarButtonItem(
            title: "使用记录",
            style: .plain,
            target: self,
            action: #selector(openUsageRecords)
        )
        recordsItem.tintColor = .fdPrimary
        navigationItem.rightBarButtonItem = recordsItem

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        tableView.register(ExamPackageCell.self, forCellReuseIdentifier: ExamPackageCell.reuseID)
        refresh.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableView.refreshControl = refresh

        view.addSubview(tableView)
        spinner.color = .fdPrimary
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        tableView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        spinner.snp.makeConstraints { $0.center.equalTo(tableView) }
        installHeroHeader()
    }

    override func bindViewModel() {
        viewModel.$items
            .combineLatest(viewModel.$isLoading, viewModel.$isLoadingMore)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _ in self?.render() }
            .store(in: &cancellables)
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let message, !message.isEmpty else { return }
                self?.showToastAlert(message)
                self?.viewModel.clearError()
            }
            .store(in: &cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeHeroHeaderIfNeeded()
    }

    override func refreshForSeniorMode() {
        super.refreshForSeniorMode()
        installHeroHeader()
        tableView.reloadData()
    }

    private func render() {
        if viewModel.isLoading, viewModel.items.isEmpty {
            spinner.startAnimating()
            tableView.tableFooterView = nil
        } else {
            spinner.stopAnimating()
            tableView.tableFooterView = viewModel.items.isEmpty ? emptyFooter() : nil
        }
        if !viewModel.isLoading {
            refresh.endRefreshing()
        }
        tableView.reloadData()
    }

    private func emptyFooter() -> UIView {
        let footer = FDEmptyStateView(style: .page, message: "暂无就医协助套餐")
        let width = tableView.bounds.width > 0 ? tableView.bounds.width : view.bounds.width
        footer.frame = CGRect(x: 0, y: 0, width: width, height: 220)
        return footer
    }

    private func installHeroHeader() {
        let hero = MedicalAssistHeroView()
        let width = tableView.bounds.width > 0 ? tableView.bounds.width : view.bounds.width
        hero.frame = CGRect(x: 0, y: 0, width: width, height: 1)
        let height = hero.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        hero.frame.size.height = height
        tableView.tableHeaderView = hero
    }

    private func resizeHeroHeaderIfNeeded() {
        guard let hero = tableView.tableHeaderView else { return }
        let width = tableView.bounds.width
        guard width > 0, abs(hero.frame.width - width) > 0.5 else { return }
        installHeroHeader()
    }

    private func openDetail(_ item: ServiceItemVO) {
        var params: [String: Any] = ["configId": item.id]
        if let price = item.plainPrice {
            params["price"] = price
        }
        Router.shared.push("/appointments/exams/detail", params: params, from: self)
    }

    @objc private func openUsageRecords() {
        Router.shared.push("/services/medical-assist/usage-records", from: self)
    }

    @objc private func pullToRefresh() {
        viewModel.reload()
    }
}

extension MedicalAssistViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ExamPackageCell.reuseID, for: indexPath) as! ExamPackageCell
        let item = viewModel.items[indexPath.row]
        cell.configure(item, isFirst: indexPath.row == 0, isLast: indexPath.row == viewModel.items.count - 1)
        cell.onBook = { [weak self] in self?.openDetail(item) }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openDetail(viewModel.items[indexPath.row])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let height = scrollView.contentSize.height
        let frame = scrollView.bounds.height
        guard height > frame, offset > height - frame - 80 else { return }
        viewModel.loadMore()
    }
}

final class MedicalAssistUsageRecordsViewController: ServiceUsageRecordsViewController {

    init() {
        super.init(businessType: ServiceItemService.assistBusinessType)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Hero

private final class MedicalAssistHeroView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdBg

        let photo = UIView()
        photo.backgroundColor = .fdPrimary

        let titleLabel = UILabel()
        titleLabel.text = "富德联好健康·就医协助"
        titleLabel.font = .fdH2
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let slogan = MedicalAssistSloganLabel()
        slogan.text = "暖心陪诊 护你所爱"
        slogan.font = .fdCaptionSemibold
        slogan.textColor = .fdPrimaryDeep
        slogan.textAlignment = .center
        slogan.backgroundColor = UIColor.fdPrimarySoft.withAlphaComponent(0.92)
        slogan.layer.cornerRadius = 14
        slogan.layer.masksToBounds = true
        slogan.contentInsets = UIEdgeInsets(top: 4, left: 14, bottom: 4, right: 14)

        let features = UIStackView()
        features.axis = .horizontal
        features.distribution = .fillEqually
        features.spacing = 0
        [
            ("cross.case", "陪同就诊", "代办手续"),
            ("mappin.and.ellipse", "覆盖全国", "统一标准"),
            ("gift", "暖心礼包", "贴心助诊"),
        ].forEach { symbol, title, subtitle in
            features.addArrangedSubview(MedicalAssistFeatureView(symbol: symbol, title: title, subtitle: subtitle))
        }

        let featureCard = UIView()
        featureCard.backgroundColor = .fdSurface
        featureCard.layer.cornerRadius = 16
        featureCard.addSubview(features)

        addSubview(photo)
        photo.addSubview(titleLabel)
        photo.addSubview(slogan)
        addSubview(featureCard)

        photo.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(240)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(28)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        slogan.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }
        featureCard.snp.makeConstraints {
            $0.top.equalTo(photo.snp.bottom).offset(-48)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-8)
        }
        features.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 18, left: 8, bottom: 14, right: 8))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class MedicalAssistSloganLabel: UILabel {
    var contentInsets = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }
}

private final class MedicalAssistFeatureView: UIView {

    init(symbol: String, title: String, subtitle: String) {
        super.init(frame: .zero)
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = .fdPrimary
        icon.contentMode = .scaleAspectFit
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .fdCaptionSemibold
        titleLabel.textColor = .fdText
        titleLabel.textAlignment = .center
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .fdFont(ofSize: 12)
        subtitleLabel.textColor = .fdSubtext
        subtitleLabel.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        addSubview(stack)
        icon.snp.makeConstraints { $0.size.equalTo(22) }
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
