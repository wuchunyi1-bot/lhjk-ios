import Combine
import SnapKit
import UIKit
import WebKit

@MainActor
final class WellnessCabinAppointmentDetailViewModel: ObservableObject {

    let reservationId: String
    /// 列表带入。详情接口没有项目配置 id。
    let configId: String

    @Published private(set) var detail: CabinReservationDetailVO?
    @Published private(set) var isLoading = false
    @Published private(set) var isMissing = false
    @Published private(set) var isCancelling = false
    @Published private(set) var errorMessage: String?

    private let cabinService: CabinService
    private var didStart = false

    init(
        reservationId: String,
        configId: String = "",
        cabinService: CabinService = AppContainer.shared.cabinService
    ) {
        self.reservationId = reservationId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.configId = configId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.cabinService = cabinService
        load()
    }

    var canBookAgain: Bool {
        guard let detail else { return false }
        guard detail.status == 5 || detail.status == 6 || detail.status == 7 else { return false }
        return !configId.isEmpty || !detail.configId.isEmpty || !detail.hospitalId.isEmpty
    }

    func load() {
        guard !didStart else { return }
        didStart = true
        let id = reservationId
        guard !id.isEmpty else {
            isMissing = true
            return
        }
        isLoading = true
        isMissing = false
        let service = cabinService
        Task.detached {
            let loaded = try? await service.reservationDetail(id: id)
            await self.finish(loaded)
        }
    }

    func cancel() async throws {
        guard !isCancelling else { return }
        isCancelling = true
        defer { isCancelling = false }
        try await cabinService.cancelReservation(id: reservationId)
    }

    func clearError() {
        errorMessage = nil
    }

    private func finish(_ detail: CabinReservationDetailVO?) {
        isLoading = false
        guard let detail else {
            isMissing = true
            self.detail = nil
            return
        }
        isMissing = false
        self.detail = detail
    }
}

/// 康养小屋预约详情。加载 `GET /v1/cabin/reservationDetail`。
final class WellnessCabinAppointmentDetailViewController: BaseViewController {

    private let viewModel: WellnessCabinAppointmentDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let bottomBar = UIView()
    private let actionButton = UIButton(type: .system)
    private let pageSpinner = UIActivityIndicatorView(style: .large)
    private let missingView = FDEmptyStateView(style: .page, message: "未找到该预约")
    private var barHeight: Constraint?

    init(reservationId: String = "", configId: String = "") {
        viewModel = WellnessCabinAppointmentDetailViewModel(
            reservationId: reservationId,
            configId: configId
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func setupUI() {
        title = "预约详情"
        view.backgroundColor = .fdBg
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        contentStack.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        bottomBar.backgroundColor = .fdSurface
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .semibold)
        actionButton.layer.cornerRadius = 22
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        bottomBar.addSubview(actionButton)
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            barHeight = $0.height.equalTo(0).constraint
        }
        actionButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }

        pageSpinner.color = .fdPrimary
        pageSpinner.hidesWhenStopped = true
        view.addSubview(pageSpinner)
        pageSpinner.snp.makeConstraints { $0.center.equalToSuperview() }
        view.addSubview(missingView)
        missingView.snp.makeConstraints { $0.edges.equalToSuperview() }
        missingView.isHidden = true
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        if !bottomBar.isHidden {
            setBar(visible: true)
        }
    }

    override func bindViewModel() {
        viewModel.$detail
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                guard let self else { return }
                self.pageSpinner.isHidden = !loading
                if loading { self.pageSpinner.startAnimating() } else { self.pageSpinner.stopAnimating() }
            }
            .store(in: &cancellables)
        viewModel.$isMissing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] missing in
                self?.missingView.isHidden = !missing
                self?.scrollView.isHidden = missing
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
    }

    private func render() {
        guard let detail = viewModel.detail else {
            scrollView.isHidden = true
            setBar(visible: false)
            return
        }
        scrollView.isHidden = viewModel.isMissing
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        contentStack.addArrangedSubview(headerBlock(detail))
        if let statusCard = statusBlock(detail) {
            contentStack.addArrangedSubview(statusCard)
        }
        if let info = infoBlock(detail) {
            contentStack.addArrangedSubview(info)
        }
        if let service = serviceBlock(detail) {
            contentStack.addArrangedSubview(service)
        }
        if let store = storeBlock(detail) {
            contentStack.addArrangedSubview(store)
        }

        if detail.canCancel {
            actionButton.setTitle("取消预约", for: .normal)
            actionButton.backgroundColor = .fdDanger
            setBar(visible: true)
        } else if viewModel.canBookAgain {
            actionButton.setTitle("再次预约", for: .normal)
            actionButton.backgroundColor = .fdPrimary
            setBar(visible: true)
        } else {
            setBar(visible: false)
        }
    }

    private func headerBlock(_ detail: CabinReservationDetailVO) -> UIView {
        let status = badge(detail.statusTitle, status: detail.status)
        let name = UILabel()
        name.font = .fdFont(ofSize: 20, weight: .semibold)
        name.textColor = .fdText
        name.numberOfLines = 0
        name.text = detail.name.isEmpty ? "预约项目" : detail.name

        var summary = [String]()
        if let duration = detail.durationText { summary.append(duration) }
        if let parent = detail.parentName, !parent.isEmpty { summary.append(parent) }
        let meta = UILabel()
        meta.font = .fdFont(ofSize: 13, weight: .regular)
        meta.textColor = .fdSubtext
        meta.numberOfLines = 0
        meta.text = summary.joined(separator: " · ")
        meta.isHidden = summary.isEmpty

        let timeTitle = UILabel()
        timeTitle.text = "预约时间"
        timeTitle.font = .fdFont(ofSize: 12, weight: .regular)
        timeTitle.textColor = .fdMuted
        let timeValue = UILabel()
        timeValue.font = .fdFont(ofSize: 15, weight: .semibold)
        timeValue.textColor = .fdText
        timeValue.textAlignment = .right
        timeValue.numberOfLines = 0
        let time = [detail.reserveDate, detail.timeText].filter { !$0.isEmpty }.joined(separator: " ")
        timeValue.text = time
        let timeRow = UIStackView(arrangedSubviews: [timeTitle, timeValue])
        timeRow.axis = .horizontal
        timeRow.alignment = .center
        timeRow.spacing = 12
        timeRow.isHidden = time.isEmpty

        let badgeRow = UIStackView(arrangedSubviews: [status, UIView()])
        badgeRow.axis = .horizontal
        let stack = UIStackView(arrangedSubviews: [badgeRow, name, meta, timeRow])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 8
        status.snp.makeConstraints {
            $0.height.equalTo(22)
            $0.width.greaterThanOrEqualTo(52)
        }
        return stack
    }

    private func statusBlock(_ detail: CabinReservationDetailVO) -> UIView? {
        switch detail.status {
        case 3:
            return verifyCard(detail)
        case 4:
            return statusCard(
                title: "已到店核销",
                rows: [("核销时间", detail.verifyTime ?? "")],
                note: "服务进行中，请按门店指引使用设备或接受服务"
            )
        case 5:
            return statusCard(
                title: "服务已完成",
                rows: [("核销时间", detail.verifyTime ?? ""), ("完成时间", detail.finishTime ?? "")],
                note: nil
            )
        case 6:
            return statusCard(
                title: "预约已取消",
                rows: [("取消时间", detail.cancelTime ?? "")],
                note: detail.cancelReason
            )
        case 7:
            return statusCard(
                title: "预约已过期",
                rows: [("过期时间", detail.expireTime ?? "")],
                note: nil
            )
        default:
            return nil
        }
    }

    private func verifyCard(_ detail: CabinReservationDetailVO) -> UIView {
        let card = makeCard()
        let body = UIStackView()
        body.axis = .vertical
        body.alignment = .center
        body.spacing = 12
        if let notice = detail.overdueNotice {
            let text = UILabel()
            text.text = "预约已超时，当日仍可核销\n\(notice)"
            text.font = .fdFont(ofSize: 13, weight: .regular)
            text.textColor = .fdWarning
            text.numberOfLines = 0
            body.addArrangedSubview(text)
        }
        body.addArrangedSubview(sectionTitle("到店核销"))
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = Self.qrImage(base64: detail.qrCode) ?? Self.qrImage(from: detail.cancellationCode ?? "")
        body.addArrangedSubview(imageView)
        imageView.snp.makeConstraints { $0.width.height.equalTo(160) }
        if let code = detail.cancellationCode, !code.isEmpty {
            let codeButton = UIButton(type: .system)
            codeButton.setTitle(code, for: .normal)
            codeButton.setTitleColor(.fdText, for: .normal)
            codeButton.titleLabel?.font = .fdFont(ofSize: 22, weight: .semibold)
            codeButton.addTarget(self, action: #selector(copyCode), for: .touchUpInside)
            body.addArrangedSubview(codeButton)
        }
        let hint = UILabel()
        hint.text = "向工作人员出示二维码，或报上方核销码"
        hint.font = .fdFont(ofSize: 12, weight: .regular)
        hint.textColor = .fdSubtext
        hint.numberOfLines = 0
        hint.textAlignment = .center
        body.addArrangedSubview(hint)
        card.addSubview(body)
        body.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        return card
    }

    private func statusCard(title: String, rows: [(String, String)], note: String?) -> UIView? {
        let visible = rows.filter { !$0.1.isEmpty }
        let noteText = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !visible.isEmpty || !noteText.isEmpty else { return nil }
        let card = makeCard()
        let body = UIStackView()
        body.axis = .vertical
        body.spacing = 10
        body.addArrangedSubview(sectionTitle(title))
        for row in visible {
            body.addArrangedSubview(infoRow(row.0, row.1, tappable: false))
        }
        if !noteText.isEmpty {
            let label = UILabel()
            label.text = noteText
            label.font = .fdFont(ofSize: 13, weight: .regular)
            label.textColor = .fdSubtext
            label.numberOfLines = 0
            body.addArrangedSubview(label)
        }
        card.addSubview(body)
        body.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        return card
    }

    private func infoBlock(_ detail: CabinReservationDetailVO) -> UIView? {
        var rows: [(String, String)] = []
        if let number = detail.reservationNumber, !number.isEmpty { rows.append(("预约编号", number)) }
        if let created = detail.createTime, !created.isEmpty { rows.append(("创建时间", created)) }
        guard !rows.isEmpty else { return nil }
        return card(title: "预约信息", rows: rows)
    }

    private func serviceBlock(_ detail: CabinReservationDetailVO) -> UIView? {
        let card = makeCard()
        let body = UIStackView()
        body.axis = .vertical
        body.spacing = 12
        body.addArrangedSubview(sectionTitle("服务信息"))
        var hasContent = false
        if !detail.name.isEmpty {
            body.addArrangedSubview(infoRow("名称", detail.name, tappable: false))
            hasContent = true
        }
        if let description = detail.description, !description.isEmpty {
            let title = UILabel()
            title.text = "项目介绍"
            title.font = .fdFont(ofSize: 13, weight: .regular)
            title.textColor = .fdMuted
            body.addArrangedSubview(title)
            if description.contains("<") {
                let html = CabinHTMLBlockView()
                html.setHTML(description)
                body.addArrangedSubview(html)
            } else {
                let label = UILabel()
                label.text = description
                label.font = .fdFont(ofSize: 14, weight: .regular)
                label.textColor = .fdText
                label.numberOfLines = 0
                body.addArrangedSubview(label)
            }
            hasContent = true
        }
        if let duration = detail.durationText {
            body.addArrangedSubview(infoRow("时长", duration, tappable: false))
            hasContent = true
        }
        let dict = DictionaryCacheService.shared
        if let text = dict.joinedLabels(parent: .serviceRestrictedPeople, raw: detail.restrictedPeople) {
            body.addArrangedSubview(infoRow("禁止人群", text, tappable: false))
            hasContent = true
        }
        if let text = dict.joinedLabels(parent: .serviceApplicablePeople, raw: detail.applicablePeople) {
            body.addArrangedSubview(infoRow("适用人群", text, tappable: false))
            hasContent = true
        }
        if let notice = detail.notice, !notice.isEmpty {
            body.addArrangedSubview(infoRow("预约须知", notice, tappable: false))
            hasContent = true
        }
        guard hasContent else { return nil }
        card.addSubview(body)
        body.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        return card
    }

    private func storeBlock(_ detail: CabinReservationDetailVO) -> UIView? {
        var rows: [(String, String, Bool)] = []
        if !detail.hospitalName.isEmpty { rows.append(("门店", detail.hospitalName, false)) }
        if !detail.address.isEmpty { rows.append(("地址", detail.address, false)) }
        if let openTime = detail.openTime, !openTime.isEmpty { rows.append(("营业时间", openTime, false)) }
        if let mobile = detail.mobile, !mobile.isEmpty { rows.append(("电话", mobile, true)) }
        guard !rows.isEmpty || detail.coordinate != nil else { return nil }
        let card = makeCard()
        let body = UIStackView()
        body.axis = .vertical
        body.spacing = 10
        body.addArrangedSubview(sectionTitle("门店信息"))
        for row in rows {
            body.addArrangedSubview(infoRow(row.0, row.1, tappable: row.2))
        }
        if detail.coordinate != nil {
            let button = UIButton(type: .system)
            button.setTitle("导航到门店", for: .normal)
            button.setTitleColor(.fdPrimary, for: .normal)
            button.titleLabel?.font = .fdFont(ofSize: 14, weight: .semibold)
            button.backgroundColor = .fdPrimarySoft
            button.layer.cornerRadius = 18
            button.addTarget(self, action: #selector(navigateTapped), for: .touchUpInside)
            body.addArrangedSubview(button)
            button.snp.makeConstraints { $0.height.equalTo(36) }
        }
        card.addSubview(body)
        body.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        return card
    }

    private func card(title: String, rows: [(String, String)]) -> UIView {
        let card = makeCard()
        let body = UIStackView()
        body.axis = .vertical
        body.spacing = 10
        body.addArrangedSubview(sectionTitle(title))
        for row in rows {
            body.addArrangedSubview(infoRow(row.0, row.1, tappable: false))
        }
        card.addSubview(body)
        body.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        return card
    }

    @objc private func copyCode() {
        let code = viewModel.detail?.cancellationCode ?? ""
        guard !code.isEmpty else { return }
        UIPasteboard.general.string = code
        showToastAlert("已复制核销码")
    }

    @objc private func actionTapped() {
        guard let detail = viewModel.detail else { return }
        if detail.canCancel {
            let alert = UIAlertController(
                title: "确认取消本次预约？",
                message: "取消仅作废本次预约时段，您下次可直接重新选择服务项目预约。\n\n注：此处不会办理退款；如需退款，请前往「订单」办理退单/售后。",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "再想想", style: .cancel))
            alert.addAction(UIAlertAction(title: "确认取消", style: .destructive) { [weak self] _ in
                self?.submitCancel()
            })
            present(alert, animated: true)
            return
        }
        bookAgain(detail)
    }

    private func submitCancel() {
        guard !viewModel.isCancelling else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.viewModel.cancel()
                await MainActor.run {
                    self.showToastAlert("已取消预约") { [weak self] in
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "取消失败，请重试"
                await MainActor.run { self.showToastAlert(message) }
            }
        }
    }

    private func bookAgain(_ detail: CabinReservationDetailVO) {
        let configId = detail.configId.isEmpty ? viewModel.configId : detail.configId
        if !configId.isEmpty {
            var params: [String: Any] = ["configId": configId]
            if !detail.hospitalId.isEmpty { params["hospitalId"] = detail.hospitalId }
            Router.shared.push("/wellness-cabins/book", params: params, from: self)
            return
        }
        guard !detail.hospitalId.isEmpty else {
            showToastAlert("暂无门店信息")
            return
        }
        Router.shared.push(
            "/wellness-cabins/detail",
            params: ["hospitalId": detail.hospitalId],
            from: self
        )
    }

    @objc private func navigateTapped() {
        guard let detail = viewModel.detail, let coordinate = detail.coordinate else {
            showToastAlert("暂无门店位置")
            return
        }
        guard AmapNavigation.isInstalled,
              let url = AmapNavigation.driveURL(
                longitude: coordinate.longitude,
                latitude: coordinate.latitude,
                name: detail.hospitalName
              ) else {
            presentAmapMissingAlert()
            return
        }
        UIApplication.shared.open(url)
    }

    private func presentAmapMissingAlert() {
        let alert = UIAlertController(
            title: "未安装高德地图",
            message: "请先安装高德地图后再导航到门店",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        present(alert, animated: true)
    }

    @objc private func phoneTapped() {
        let digits = (viewModel.detail?.mobile ?? "").filter { $0.isNumber }
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else {
            showToastAlert("暂无联系电话")
            return
        }
        UIApplication.shared.open(url)
    }

    private func setBar(visible: Bool) {
        barHeight?.update(offset: visible ? 64 + view.safeAreaInsets.bottom : 0)
        bottomBar.isHidden = !visible
        let inset = visible ? 80.0 : 0
        scrollView.contentInset.bottom = inset
        scrollView.verticalScrollIndicatorInsets.bottom = inset
    }

    private func style(_ card: UIView) {
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdBorder.cgColor
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 15, weight: .semibold)
        label.textColor = .fdText
        return label
    }

    private func infoRow(_ title: String, _ value: String, tappable: Bool) -> UIView {
        let name = UILabel()
        name.text = title
        name.font = .fdFont(ofSize: 13, weight: .regular)
        name.textColor = .fdMuted
        name.setContentHuggingPriority(.required, for: .horizontal)
        let body = UILabel()
        body.text = value
        body.font = .fdFont(ofSize: 14, weight: .regular)
        body.textColor = tappable ? .fdPrimary : .fdText
        body.numberOfLines = 0
        let row = UIStackView(arrangedSubviews: [name, body])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12
        if tappable {
            row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(phoneTapped)))
            row.isUserInteractionEnabled = true
        }
        return row
    }

    private func badge(_ text: String, status: Int?) -> UILabel {
        let label = UILabel()
        label.text = "  \(text)  "
        label.font = .fdFont(ofSize: 13, weight: .medium)
        label.textAlignment = .center
        label.layer.cornerRadius = 11
        label.clipsToBounds = true
        label.isHidden = text.isEmpty
        switch status {
        case 3:
            label.textColor = .fdInfo
            label.backgroundColor = .fdInfoSoft
        case 4:
            label.textColor = .fdPrimary
            label.backgroundColor = .fdPrimarySoft
        case 5:
            label.textColor = .fdSuccess
            label.backgroundColor = .fdSuccessSoft
        case 7:
            label.textColor = .fdWarning
            label.backgroundColor = .fdWarningSoft
        default:
            label.textColor = .fdMuted
            label.backgroundColor = .fdBg2
        }
        return label
    }

    private func makeCard() -> UIView {
        let card = UIView()
        style(card)
        return card
    }

    private static func qrImage(base64 raw: String?) -> UIImage? {
        guard var text = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        if let range = text.range(of: "base64,") {
            text = String(text[range.upperBound...])
        }
        guard let data = Data(base64Encoded: text) else { return nil }
        return UIImage(data: data)
    }

    private static func qrImage(from text: String) -> UIImage? {
        guard let data = text.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        let context = CIContext()
        guard let image = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: image)
    }
}

/// 项目介绍富文本。介绍图写在 `description` 的 HTML 里。
private final class CabinHTMLBlockView: UIView, WKNavigationDelegate {

    private let webView = WKWebView()
    private var heightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        addSubview(webView)
        webView.snp.makeConstraints { $0.edges.equalToSuperview() }
        snp.makeConstraints { heightConstraint = $0.height.equalTo(1).constraint }
    }

    required init?(coder: NSCoder) { fatalError() }

    func setHTML(_ html: String) {
        let page = """
        <!doctype html><html><head>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
        body{margin:0;font:14px -apple-system,PingFang SC;color:#1F2942;line-height:1.5;}
        img{max-width:100%;height:auto;border-radius:8px;}
        p{margin:0 0 8px;}
        </style></head><body>\(html)</body></html>
        """
        webView.loadHTMLString(page, baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] value, _ in
            let height = (value as? CGFloat) ?? (value as? Double).map { CGFloat($0) } ?? 0
            guard height > 0 else { return }
            self?.heightConstraint?.update(offset: height)
            self?.superview?.layoutIfNeeded()
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}
