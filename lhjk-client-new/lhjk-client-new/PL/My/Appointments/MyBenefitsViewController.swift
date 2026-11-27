import Combine
import Kingfisher
import SnapKit
import UIKit

/// 我的权益。`GET /v1/cabin/entitlementList`。
///
/// 右上角「预约记录」进入原来的状态汇总。康养小屋的预约、取消仍只在预约记录和小屋页里处理。
final class MyBenefitsViewController: BaseViewController {

    private let viewModel = MyBenefitsViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = FDEmptyStateView(style: .page, message: "暂无权益")
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let refresh = UIRefreshControl()
    private var isSubmitting = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.reload()
    }

    override func setupUI() {
        title = "我的权益"
        view.backgroundColor = .fdBg
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "预约记录",
            style: .plain,
            target: self,
            action: #selector(openRecords)
        )
        navigationItem.rightBarButtonItem?.tintColor = .fdPrimary

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.register(MyBenefitCell.self, forCellReuseIdentifier: MyBenefitCell.reuseID)
        refresh.addTarget(self, action: #selector(reload), for: .valueChanged)
        tableView.refreshControl = refresh

        view.addSubview(tableView)
        view.addSubview(emptyView)
        spinner.color = .fdPrimary
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)

        tableView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        emptyView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        spinner.snp.makeConstraints { $0.center.equalTo(tableView) }
        emptyView.isHidden = true
    }

    override func refreshForSeniorMode() {
        super.refreshForSeniorMode()
        tableView.reloadData()
    }

    override func bindViewModel() {
        viewModel.$items
            .combineLatest(viewModel.$isLoading)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.render()
            }
            .store(in: &cancellables)
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let message, !message.isEmpty else { return }
                self?.showToastAlert(message)
                self?.viewModel.clearError()
            }
            .store(in: &cancellables)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(benefitConsumed),
            name: .cabinBenefitConsumed,
            object: nil
        )
    }

    @objc private func benefitConsumed() {
        viewModel.reload()
    }

    @objc private func openRecords() {
        Router.shared.push("/me/appointments/records", from: self)
    }

    @objc private func reload() {
        viewModel.reload()
    }

    private func render() {
        tableView.reloadData()
        let showEmpty = viewModel.items.isEmpty && !viewModel.isLoading
        emptyView.isHidden = !showEmpty
        tableView.isHidden = showEmpty
        if isSubmitting || (viewModel.isLoading && viewModel.items.isEmpty) {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
        if !viewModel.isLoading {
            refresh.endRefreshing()
        }
    }

    private func open(_ item: CabinEntitlementVO) {
        if item.isCabin {
            book(item)
            return
        }
        openProject(item)
    }

    private func book(_ item: CabinEntitlementVO) {
        if item.isExhausted {
            showToastAlert("剩余次数已用完")
            return
        }
        if item.isCabin {
            var params: [String: Any] = [:]
            if !item.projectId.isEmpty { params["projectId"] = item.projectId }
            Router.shared.push("/wellness-cabins", params: params, from: self)
            return
        }
        let label = item.businessType == ServiceItemService.assistBusinessType ? "就医协助" : "体检"
        BenefitConsumeFlow.start(
            from: self,
            kindLabel: label,
            configId: item.configId,
            setLoading: { [weak self] loading in
                self?.isSubmitting = loading
                self?.render()
            }
        )
    }

    private func openProject(_ item: CabinEntitlementVO) {
        guard !item.configId.isEmpty else {
            showToastAlert("暂不可预约")
            return
        }
        Router.shared.push(
            "/wellness-cabins/book",
            params: [
                "configId": item.configId,
                "businessType": item.businessType.map(String.init) ?? "",
            ],
            from: self
        )
    }
}

extension MyBenefitsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MyBenefitCell.reuseID,
            for: indexPath
        ) as! MyBenefitCell
        let item = viewModel.items[indexPath.row]
        cell.configure(item)
        cell.onBook = { [weak self] in
            self?.book(item)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        open(viewModel.items[indexPath.row])
    }
}

enum BenefitConsumeFlow {

    static func start(
        from host: UIViewController,
        kindLabel: String,
        configId: String,
        setLoading: @escaping (Bool) -> Void
    ) {
        guard !configId.isEmpty else {
            host.showToastAlert("暂不可预约")
            return
        }
        let alert = UIAlertController(
            title: "确认消耗权益",
            message: "本次预约将消耗 1 次\(kindLabel)权益。确认后为您展示工作人员企业微信和联系电话。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "再想想", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认消耗", style: .default) { _ in
            submit(from: host, configId: configId, setLoading: setLoading)
        })
        alert.view.tintColor = .fdPrimary
        host.present(alert, animated: true)
    }

    private static func submit(
        from host: UIViewController,
        configId: String,
        setLoading: @escaping (Bool) -> Void
    ) {
        setLoading(true)
        Task {
            do {
                let contact = try await CabinService.shared.consumeBenefit(configId: configId)
                await MainActor.run {
                    setLoading(false)
                    NotificationCenter.default.post(name: .cabinBenefitConsumed, object: nil)
                    let sheet = BenefitManualAccessViewController(contact: contact)
                    host.present(sheet, animated: true)
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "预约失败，请重试"
                await MainActor.run {
                    setLoading(false)
                    host.showToastAlert(message)
                }
            }
        }
    }
}

private final class BenefitManualAccessViewController: UIViewController {

    private let contact: CabinConsumeContact

    init(contact: CabinConsumeContact) {
        self.contact = contact
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let dimView = UIView()
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeTapped)))
        view.addSubview(dimView)

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 20
        card.clipsToBounds = true
        view.addSubview(card)

        let titleLabel = UILabel()
        titleLabel.text = "添加工作人员"
        titleLabel.font = .fdFont(ofSize: 20, weight: .medium)
        titleLabel.textColor = .fdText
        titleLabel.textAlignment = .center

        let hintLabel = UILabel()
        hintLabel.text = "扫码添加企业微信，工作人员会与您联系安排。"
        hintLabel.font = .fdFont(ofSize: 16, weight: .regular)
        hintLabel.textColor = UIColor(hexString: "#A6ACB8")
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 0

        let qrView = UIImageView()
        qrView.contentMode = .scaleAspectFit
        if let image = Self.qrImage(contact.qrCode) {
            qrView.image = image
        } else {
            qrView.kf.setImage(with: contact.qrURL)
        }
        let showsQR = qrView.image != nil || contact.qrURL != nil
        qrView.isHidden = !showsQR

        let nameRow = metaRow(title: "工作人员", value: contact.name)
        let phoneRow = metaRow(title: "联系电话", value: contact.phone)

        let closeButton = UIButton(type: .custom)
        closeButton.setTitle("我知道了", for: .normal)
        closeButton.setTitleColor(.fdPrimary, for: .normal)
        closeButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        closeButton.layer.cornerRadius = 20
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = UIColor.fdPrimary.cgColor
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let callButton = UIButton(type: .custom)
        callButton.setTitle("拨打电话", for: .normal)
        callButton.setTitleColor(.white, for: .normal)
        callButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        callButton.backgroundColor = .fdPrimary
        callButton.layer.cornerRadius = 20
        callButton.isHidden = contact.phone == nil
        callButton.addTarget(self, action: #selector(call), for: .touchUpInside)

        let buttonRow = UIStackView(arrangedSubviews: [closeButton, callButton])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 7
        buttonRow.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [titleLabel, hintLabel, qrView, nameRow, phoneRow, buttonRow])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        stack.setCustomSpacing(4, after: titleLabel)
        card.addSubview(stack)

        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }
        card.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        stack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(28)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().offset(-24)
        }
        qrView.snp.makeConstraints { $0.height.equalTo(showsQR ? 220 : 0) }
        buttonRow.snp.makeConstraints { $0.height.equalTo(44) }
    }

    private func metaRow(title: String, value: String?) -> UIView {
        let row = UIView()
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .fdFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = UIColor(hexString: "#A6ACB8")
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .fdFont(ofSize: 16, weight: .medium)
        valueLabel.textColor = .fdText
        valueLabel.textAlignment = .right
        let line = UIView()
        line.backgroundColor = .fdBorder
        row.addSubview(line)
        row.addSubview(titleLabel)
        row.addSubview(valueLabel)
        line.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(1.0 / UIScreen.main.scale)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(12)
        }
        valueLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(titleLabel)
            $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
        }
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        row.isHidden = trimmed.isEmpty
        return row
    }

    private static func qrImage(_ raw: String?) -> UIImage? {
        guard var text = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        if text.hasPrefix("http://") || text.hasPrefix("https://") { return nil }
        if let range = text.range(of: "base64,") {
            text = String(text[range.upperBound...])
        }
        guard let data = Data(base64Encoded: text) else { return nil }
        return UIImage(data: data)
    }

    @objc private func call() {
        guard let mobile = contact.phone?.trimmingCharacters(in: .whitespacesAndNewlines),
              !mobile.isEmpty else { return }
        let digits = mobile.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel:\(digits)"),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
