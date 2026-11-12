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

    private static let titleColor = UIColor(hexString: "#1F2942")
    private static let subtitleColor = UIColor(hexString: "#8591AB")
    private static let orange = UIColor(hexString: "#FF7A50")

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
        scrollView.backgroundColor = .fdBg

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

        bottomBar.backgroundColor = .white
        bottomBar.layer.cornerRadius = 16
        bottomBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomBar.layer.shadowColor = UIColor.black.cgColor
        bottomBar.layer.shadowOpacity = 0.04
        bottomBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        bottomBar.layer.shadowRadius = 8
        actionButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        actionButton.layer.cornerRadius = 20
        actionButton.clipsToBounds = true
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        bottomBar.addSubview(actionButton)
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            barHeight = $0.height.equalTo(0).constraint
        }
        actionButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16).priority(999)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(40).priority(999)
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
            applyOutlineAction()
            setBar(visible: true)
        } else if viewModel.canBookAgain {
            actionButton.setTitle("再次预约", for: .normal)
            applyFilledAction()
            setBar(visible: true)
        } else {
            setBar(visible: false)
        }
    }

    private func headerBlock(_ detail: CabinReservationDetailVO) -> UIView {
        let name = UILabel()
        name.font = .fdFont(ofSize: 18, weight: .medium)
        name.textColor = Self.titleColor
        name.numberOfLines = 0
        name.text = detail.name.isEmpty ? "预约项目" : detail.name

        let status = UILabel()
        status.font = .fdFont(ofSize: 16, weight: .medium)
        status.textColor = Self.orange
        status.textAlignment = .right
        status.text = detail.statusTitle
        status.isHidden = detail.statusTitle.isEmpty
        status.setContentHuggingPriority(.required, for: .horizontal)
        status.setContentCompressionResistancePriority(.required, for: .horizontal)

        let nameRow = UIStackView(arrangedSubviews: [name, status])
        nameRow.axis = .horizontal
        nameRow.alignment = .top
        nameRow.spacing = 8

        var summary = [String]()
        if let duration = detail.durationText { summary.append(duration) }
        if let parent = detail.parentName, !parent.isEmpty { summary.append(parent) }
        let meta = UILabel()
        meta.font = .fdFont(ofSize: 16, weight: .regular)
        meta.textColor = Self.subtitleColor
        meta.numberOfLines = 0
        meta.text = summary.joined(separator: " · ")
        meta.isHidden = summary.isEmpty

        let time = [detail.reserveDate, detail.timeText].filter { !$0.isEmpty }.joined(separator: " ")
        let timeRow = infoRow("预约时间", time)
        timeRow.isHidden = time.isEmpty

        let stack = UIStackView(arrangedSubviews: [nameRow, meta, timeRow])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        stack.setCustomSpacing(4, after: nameRow)

        let card = makeCard()
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        return card
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
        body.alignment = .fill
        body.spacing = 12
        if let notice = detail.overdueNotice {
            body.addArrangedSubview(noticeBanner("预约已超时，当日仍可核销\n\(notice)"))
        }
        body.addArrangedSubview(sectionTitle("到店核销"))
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = Self.qrImage(base64: detail.qrCode) ?? Self.qrImage(from: detail.cancellationCode ?? "")
        let qrWrap = UIView()
        qrWrap.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.top.bottom.centerX.equalToSuperview()
            $0.width.height.equalTo(160)
        }
        body.addArrangedSubview(qrWrap)
        if let code = detail.cancellationCode, !code.isEmpty {
            let codeButton = UIButton(type: .system)
            codeButton.setTitle(code, for: .normal)
            codeButton.setTitleColor(Self.titleColor, for: .normal)
            codeButton.titleLabel?.font = .fdFont(ofSize: 22, weight: .semibold)
            codeButton.addTarget(self, action: #selector(copyCode), for: .touchUpInside)
            body.addArrangedSubview(codeButton)
        }
        let hint = UILabel()
        hint.text = "向工作人员出示二维码，或报上方核销码"
        hint.font = .fdFont(ofSize: 16, weight: .regular)
        hint.textColor = Self.subtitleColor
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
        body.spacing = 12
        body.addArrangedSubview(sectionTitle(title))
        for row in visible {
            body.addArrangedSubview(infoRow(row.0, row.1))
        }
        if !noteText.isEmpty {
            let label = UILabel()
            label.text = noteText
            label.font = .fdFont(ofSize: 16, weight: .regular)
            label.textColor = Self.subtitleColor
            label.numberOfLines = 0
            body.addArrangedSubview(label)
        }
        card.addSubview(body)
        body.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        return card
    }

    private func infoBlock(_ detail: CabinReservationDetailVO) -> UIView? {
        let number = detail.reservationNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let created = detail.createTime?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let reminder = Self.appointmentReminder(for: detail.status)
        guard !number.isEmpty || !created.isEmpty || reminder != nil else { return nil }
        let card = makeCard()
        let body = UIStackView()
        body.axis = .vertical
        body.spacing = 12
        body.addArrangedSubview(sectionTitle("预约信息"))
        if !number.isEmpty {
            body.addArrangedSubview(infoRow("预约编号", number, copyable: true))
        }
        if !created.isEmpty {
            body.addArrangedSubview(infoRow("创建时间", created))
        }
        if let reminder {
            body.addArrangedSubview(reminderBar(reminder))
        }
        card.addSubview(body)
        body.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        return card
    }

    private func serviceBlock(_ detail: CabinReservationDetailVO) -> UIView? {
        let card = makeCard()
        let body = UIStackView()
        body.axis = .vertical
        body.spacing = 12
        body.addArrangedSubview(sectionTitle("服务信息"))
        var hasContent = false
        if !detail.name.isEmpty {
            body.addArrangedSubview(infoRow("名称", detail.name))
            hasContent = true
        }
        if let description = detail.description, !description.isEmpty {
            let title = UILabel()
            title.text = "项目介绍"
            title.font = .fdFont(ofSize: 16, weight: .regular)
            title.textColor = Self.subtitleColor
            body.addArrangedSubview(title)
            if description.contains("<") {
                let html = CabinHTMLBlockView()
                html.setHTML(description)
                body.addArrangedSubview(html)
            } else {
                let label = UILabel()
                label.text = description
                label.font = .fdFont(ofSize: 16, weight: .regular)
                label.textColor = Self.titleColor
                label.numberOfLines = 0
                body.addArrangedSubview(label)
            }
            hasContent = true
        }
        if let duration = detail.durationText {
            body.addArrangedSubview(infoRow("时长", duration))
            hasContent = true
        }
        let dict = DictionaryCacheService.shared
        if let text = dict.joinedLabels(parent: .serviceRestrictedPeople, raw: detail.restrictedPeople) {
            body.addArrangedSubview(infoRow("禁止人群", text))
            hasContent = true
        }
        if let text = dict.joinedLabels(parent: .serviceApplicablePeople, raw: detail.applicablePeople) {
            body.addArrangedSubview(infoRow("适用人群", text))
            hasContent = true
        }
        if let notice = detail.notice, !notice.isEmpty {
            body.addArrangedSubview(infoRow("预约须知", notice))
            hasContent = true
        }
        guard hasContent else { return nil }
        card.addSubview(body)
        body.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        return card
    }

    private func storeBlock(_ detail: CabinReservationDetailVO) -> UIView? {
        let hours = detail.businessHours?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let mobile = detail.mobile?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !detail.hospitalName.isEmpty || !detail.address.isEmpty || !hours.isEmpty || !mobile.isEmpty || detail.coordinate != nil else {
            return nil
        }
        let card = makeCard()
        let body = UIStackView()
        body.axis = .vertical
        body.spacing = 12
        body.addArrangedSubview(sectionTitle("门店信息"))

        if !detail.hospitalName.isEmpty {
            let iconContainer = UIView()
            iconContainer.backgroundColor = UIColor(hexString: "#FFF2E6")
            iconContainer.layer.cornerRadius = 6
            iconContainer.clipsToBounds = true
            let icon = UIImageView(image: UIImage(named: "order_detail_address_pin"))
            icon.contentMode = .scaleAspectFit
            iconContainer.addSubview(icon)
            icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(14) }
            iconContainer.snp.makeConstraints { $0.size.equalTo(24) }

            let name = UILabel()
            name.text = detail.hospitalName
            name.font = .fdFont(ofSize: 18, weight: .medium)
            name.textColor = Self.titleColor
            name.numberOfLines = 0
            let nameRow = UIStackView(arrangedSubviews: [iconContainer, name])
            nameRow.axis = .horizontal
            nameRow.spacing = 8
            nameRow.alignment = .top
            body.addArrangedSubview(nameRow)
        }
        if !detail.address.isEmpty {
            let address = UILabel()
            address.text = detail.address
            address.font = .fdFont(ofSize: 16, weight: .regular)
            address.textColor = Self.subtitleColor
            address.numberOfLines = 0
            body.addArrangedSubview(address)
        }
        if !hours.isEmpty {
            body.addArrangedSubview(infoRow("营业时间", hours))
        }
        if !mobile.isEmpty {
            body.addArrangedSubview(infoRow("电话", mobile, tappable: true))
        }
        if detail.coordinate != nil {
            let button = UIButton(type: .system)
            button.setTitle("导航到门店", for: .normal)
            button.setTitleColor(Self.orange, for: .normal)
            button.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
            button.backgroundColor = .white
            button.layer.cornerRadius = 20
            button.layer.borderWidth = 0.5
            button.layer.borderColor = Self.orange.cgColor
            button.addTarget(self, action: #selector(navigateTapped), for: .touchUpInside)
            body.addArrangedSubview(button)
            button.snp.makeConstraints { $0.height.equalTo(40) }
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
        barHeight?.update(offset: visible ? 66 + view.safeAreaInsets.bottom : 0)
        bottomBar.isHidden = !visible
        let inset = visible ? 76.0 : 0
        scrollView.contentInset.bottom = inset
        scrollView.verticalScrollIndicatorInsets.bottom = inset
    }

    private func applyFilledAction() {
        actionButton.backgroundColor = Self.orange
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.layer.borderWidth = 0
    }

    private func applyOutlineAction() {
        actionButton.backgroundColor = .white
        actionButton.setTitleColor(Self.orange, for: .normal)
        actionButton.layer.borderWidth = 0.5
        actionButton.layer.borderColor = Self.orange.cgColor
    }

    private func style(_ card: UIView) {
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        card.clipsToBounds = true
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 18, weight: .medium)
        label.textColor = Self.titleColor
        return label
    }

    private func infoRow(_ title: String, _ value: String, tappable: Bool = false, copyable: Bool = false) -> UIView {
        let name = UILabel()
        name.text = title
        name.font = .fdFont(ofSize: 16, weight: .regular)
        name.textColor = Self.subtitleColor
        name.setContentHuggingPriority(.required, for: .horizontal)
        name.setContentCompressionResistancePriority(.required, for: .horizontal)

        let body = UILabel()
        body.text = value
        body.font = .fdFont(ofSize: 16, weight: .regular)
        body.textColor = tappable ? Self.orange : Self.titleColor
        body.numberOfLines = 0
        body.textAlignment = .right
        body.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let right: UIView
        if copyable {
            let copyButton = UIButton(type: .custom)
            copyButton.setImage(UIImage(named: "order_detail_copy")?.withRenderingMode(.alwaysOriginal), for: .normal)
            copyButton.accessibilityLabel = value
            copyButton.addTarget(self, action: #selector(copyReservationNumber(_:)), for: .touchUpInside)
            copyButton.snp.makeConstraints { $0.size.equalTo(14) }
            let pair = UIStackView(arrangedSubviews: [body, copyButton])
            pair.axis = .horizontal
            pair.spacing = 6
            pair.alignment = .center
            right = pair
        } else {
            right = body
        }

        let row = UIStackView(arrangedSubviews: [name, right])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12
        if tappable {
            row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(phoneTapped)))
            row.isUserInteractionEnabled = true
        }
        return row
    }

    /// 预约信息底部的固定提醒。只覆盖待服务到已过期。
    private static func appointmentReminder(for status: Int?) -> String? {
        switch status {
        case 3: return "请提前15分钟到店"
        case 4: return "服务进行中，请留意设备使用时长"
        case 5: return "已完成核销"
        case 6: return "已按规则取消"
        case 7: return "订单已过期，如需使用请重新预约。"
        default: return nil
        }
    }

    private func reminderBar(_ text: String) -> UIView {
        let box = UIView()
        box.backgroundColor = .fdPrimarySoft
        box.layer.cornerRadius = 8
        box.clipsToBounds = true

        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 16, weight: .regular)
        label.textColor = .fdPrimary
        label.numberOfLines = 0
        box.addSubview(label)
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
        }
        return box
    }

    private func noticeBanner(_ text: String) -> UIView {
        let box = UIView()
        box.backgroundColor = UIColor(hexString: "#F93838").withAlphaComponent(0.05)
        box.layer.cornerRadius = 8
        box.clipsToBounds = true

        let icon = UIImageView(image: UIImage(named: "order_notice_alert_icon"))
        icon.contentMode = .scaleAspectFit
        box.addSubview(icon)
        icon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(14)
        }

        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(hexString: "#F93838")
        label.numberOfLines = 0
        box.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.equalTo(icon.snp.trailing).offset(6)
            $0.trailing.equalToSuperview().offset(-12)
            $0.top.equalToSuperview().offset(8)
            $0.bottom.equalToSuperview().offset(-8)
        }
        return box
    }

    @objc private func copyReservationNumber(_ sender: UIButton) {
        let text = sender.accessibilityLabel ?? ""
        guard !text.isEmpty else { return }
        UIPasteboard.general.string = text
        showToastAlert("预约编号已复制")
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

/// 项目介绍富文本。介绍图写在 `description` 的 HTML 里。Quill 的有序列表按数字展示。
final class CabinHTMLBlockView: UIView, WKNavigationDelegate {

    private let webView = WKWebView()
    private var heightConstraint: Constraint?
    private var measuredWidth: CGFloat = 0

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
        let body = Self.prepare(html)
        let bodySize = UIFont.isSeniorMode ? 20 : 16
        let page = """
        <!doctype html><html><head>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
        body{margin:0;font:\(Int(bodySize))px -apple-system,PingFang SC;color:#1F2942;line-height:1.6;}
        ol,ul{margin:0 0 8px;padding-left:1.4em;}
        li{margin:0 0 6px;}
        li[data-list="ordered"]{list-style-type:decimal;}
        li[data-list="bullet"]{list-style-type:disc;}
        .ql-ui{display:none;}
        strong{font-weight:600;}
        em{font-style:italic;}
        img{max-width:100%;height:auto;border-radius:8px;}
        p{margin:0 0 8px;}
        </style></head><body>\(body)</body></html>
        """
        measuredWidth = 0
        webView.loadHTMLString(page, baseURL: nil)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = webView.bounds.width
        guard width > 1, abs(width - measuredWidth) > 1 else { return }
        measuredWidth = width
        measureHeight()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        measureHeight()
    }

    private func measureHeight() {
        webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] value, _ in
            let height = (value as? CGFloat) ?? (value as? Double).map { CGFloat($0) } ?? 0
            guard let self, height > 0 else { return }
            self.heightConstraint?.update(offset: height)
            var root: UIView = self
            while let parent = root.superview { root = parent }
            root.layoutIfNeeded()
        }
    }

    /// Quill 片段里的空 `ql-ui` 不参与排版。实体转义过的标签先还原。
    private static func prepare(_ html: String) -> String {
        var text = html
        if !text.contains("<"), text.contains("&lt;") {
            text = text
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&#39;", with: "'")
                .replacingOccurrences(of: "&amp;", with: "&")
        }
        guard let regex = try? NSRegularExpression(
            pattern: "<span\\b[^>]*class=\"ql-ui\"[^>]*>\\s*</span>",
            options: .caseInsensitive
        ) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
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
