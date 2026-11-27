import Combine
import SnapKit
import UIKit

/// 详情接口返回后，按 `businessType` 换成对应模板。1 小屋，2 体检，3 就医协助。
enum ReservationDetailPresentation {

    static func redirect(
        from current: UIViewController,
        detail: CabinReservationDetailVO,
        reservationId: String,
        configId: String
    ) -> Bool {
        guard let type = detail.businessType else { return false }
        let wantsBenefit = type == ServiceItemService.examBusinessType || type == ServiceItemService.assistBusinessType
        let isBenefit = current is BenefitUsageDetailViewController
        guard wantsBenefit != isBenefit else { return false }
        let next: UIViewController
        if wantsBenefit {
            next = BenefitUsageDetailViewController(reservationId: reservationId, preloaded: detail)
        } else {
            let resolvedConfig = detail.configId.isEmpty ? configId : detail.configId
            next = WellnessCabinAppointmentDetailViewController(
                reservationId: reservationId,
                configId: resolvedConfig,
                preloaded: detail
            )
        }
        guard let navigation = current.navigationController,
              let index = navigation.viewControllers.firstIndex(where: { $0 === current }) else {
            return false
        }
        var controllers = navigation.viewControllers
        controllers[index] = next
        navigation.setViewControllers(controllers, animated: false)
        return true
    }
}

/// 体检、就医协助的使用详情。待确认可确认安排，待服务可取消服务。
final class BenefitUsageDetailViewController: BaseViewController {

    private let viewModel: BenefitUsageDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let bottomBar = UIView()
    private var barHeight: Constraint?

    private static let titleColor = UIColor(hexString: "#1F2942")
    private static let subtitleColor = UIColor(hexString: "#8591AB")
    private static let orange = UIColor(hexString: "#FF7A50")

    init(reservationId: String, preloaded: CabinReservationDetailVO? = nil) {
        viewModel = BenefitUsageDetailViewModel(reservationId: reservationId, preloaded: preloaded)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func setupUI() {
        title = viewModel.pageTitle
        view.backgroundColor = .fdBg
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .fdBg
        stack.axis = .vertical
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)

        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        stack.snp.makeConstraints {
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
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            barHeight = $0.height.equalTo(0).constraint
        }

        spinner.color = .fdPrimary
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        spinner.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        if !bottomBar.isHidden {
            setBar(visible: true, tall: viewModel.showsConfirmButton)
        }
    }

    override func bindViewModel() {
        viewModel.$detail
            .combineLatest(viewModel.$isLoading, viewModel.$isSubmitting)
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
        viewModel.load()
    }

    private func render() {
        title = viewModel.pageTitle
        if viewModel.isLoading || viewModel.isSubmitting {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        guard let detail = viewModel.detail else {
            setBar(visible: false, tall: false)
            return
        }
        if ReservationDetailPresentation.redirect(
            from: self,
            detail: detail,
            reservationId: viewModel.reservationId,
            configId: detail.configId
        ) {
            return
        }

        if let hint = viewModel.hintText {
            stack.addArrangedSubview(reminderBar(hint))
        }
        if viewModel.showsConsumeWarning {
            stack.addArrangedSubview(noticeBanner("取消服务将消耗本次服务权益，后续如有需要需重新购买相关服务权益。"))
        }
        stack.addArrangedSubview(headerCard(detail))
        stack.addArrangedSubview(serviceCard(detail))
        stack.addArrangedSubview(descriptionCard(detail.description))
        updateBar()
    }

    private func updateBar() {
        bottomBar.subviews.forEach { $0.removeFromSuperview() }
        if viewModel.showsConfirmButton {
            let tip = UILabel()
            tip.text = "如有疑问，可先联系健管师再确认"
            tip.font = .fdFont(ofSize: 13, weight: .regular)
            tip.textColor = Self.subtitleColor
            tip.textAlignment = .center
            tip.numberOfLines = 0
            let button = actionButton("确认安排", filled: true, action: #selector(confirmTapped))
            let column = UIStackView(arrangedSubviews: [tip, button])
            column.axis = .vertical
            column.spacing = 8
            column.alignment = .fill
            bottomBar.addSubview(column)
            column.snp.makeConstraints {
                $0.top.equalToSuperview().offset(12)
                $0.leading.trailing.equalToSuperview().inset(16)
            }
            button.snp.makeConstraints { $0.height.equalTo(40) }
            setBar(visible: true, tall: true)
            return
        }
        if viewModel.showsCancelButton {
            let button = actionButton("取消服务", filled: false, action: #selector(cancelTapped))
            bottomBar.addSubview(button)
            button.snp.makeConstraints {
                $0.top.equalToSuperview().offset(16)
                $0.leading.trailing.equalToSuperview().inset(16)
                $0.height.equalTo(40)
            }
            setBar(visible: true, tall: false)
            return
        }
        setBar(visible: false, tall: false)
    }

    private func setBar(visible: Bool, tall: Bool) {
        let content: CGFloat = visible ? (tall ? 90 : 66) : 0
        barHeight?.update(offset: content + (visible ? view.safeAreaInsets.bottom : 0))
        bottomBar.isHidden = !visible
        let inset: CGFloat = visible ? (tall ? 100 : 76) : 0
        scrollView.contentInset.bottom = inset
        scrollView.verticalScrollIndicatorInsets.bottom = inset
    }

    @objc private func confirmTapped() {
        guard !viewModel.isSubmitting else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.viewModel.confirm()
                await MainActor.run {
                    self.showToastAlert("已确认服务安排") { [weak self] in
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "确认失败，请重试"
                await MainActor.run { self.showToastAlert(message) }
            }
        }
    }

    @objc private func cancelTapped() {
        let alert = UIAlertController(
            title: "取消服务？",
            message: "取消后，本次服务安排将不再保留。\n\n且将消耗本次服务权益；若后续仍有需要，需重新购买相关服务权益。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "暂不取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认取消", style: .destructive) { [weak self] _ in
            self?.submitCancel()
        })
        present(alert, animated: true)
    }

    private func submitCancel() {
        guard !viewModel.isSubmitting else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.viewModel.cancel()
                await MainActor.run {
                    self.showToastAlert("已取消服务，本次权益已消耗") { [weak self] in
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "取消失败，请重试"
                await MainActor.run { self.showToastAlert(message) }
            }
        }
    }

    @objc private func navigateTapped() {
        guard let detail = viewModel.detail, let coordinate = detail.coordinate else {
            showToastAlert(viewModel.missingAddressText)
            return
        }
        let opened = AppleMapsNavigation.openDriving(
            longitude: coordinate.longitude,
            latitude: coordinate.latitude,
            name: detail.hospitalName
        )
        if !opened {
            showToastAlert("无法打开地图")
        }
    }

    @objc private func callTapped() {
        let digits = (viewModel.detail?.contactPhone ?? "").filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty, let url = URL(string: "tel:\(digits)") else {
            showToastAlert("暂无服务人员电话")
            return
        }
        UIApplication.shared.open(url)
    }

    private func headerCard(_ detail: CabinReservationDetailVO) -> UIView {
        let column = UIStackView()
        column.axis = .vertical
        column.spacing = 8
        if !detail.statusTitle.isEmpty {
            let row = UIStackView(arrangedSubviews: [statusPill(detail.statusTitle, status: detail.status), UIView()])
            row.axis = .horizontal
            row.alignment = .center
            column.addArrangedSubview(row)
        }
        let name = UILabel()
        name.text = detail.name.isEmpty ? "预约项目" : detail.name
        name.font = .fdFont(ofSize: 18, weight: .medium)
        name.textColor = Self.titleColor
        name.numberOfLines = 0
        column.addArrangedSubview(name)
        column.addArrangedSubview(timeBar(viewModel.scheduleText))
        column.setCustomSpacing(12, after: name)
        return card(column)
    }

    private func serviceCard(_ detail: CabinReservationDetailVO) -> UIView {
        let body = UIStackView()
        body.axis = .vertical
        body.spacing = 12
        body.addArrangedSubview(sectionTitle("服务信息"))
        var rows: [UIView] = [
            infoRow(viewModel.institutionTitle, display(detail.hospitalName)),
            infoRow(viewModel.addressTitle, display(detail.address)),
            outlineAction(viewModel.navigationTitle, action: #selector(navigateTapped)),
        ]
        if viewModel.isAssist {
            rows.append(infoRow("科室", display(detail.department)))
            rows.append(infoRow("医生", display(detail.doctor)))
        }
        if let name = nonempty(detail.contactName) {
            rows.append(infoRow("服务人员", name))
        }
        if let phone = nonempty(detail.contactPhone) {
            rows.append(infoRow("联系电话", phone))
            rows.append(outlineAction("拨打电话", action: #selector(callTapped)))
        }
        rows.append(infoRow("时间", viewModel.scheduleText, emphasized: true))
        if let time = nonempty(detail.finishTime) {
            rows.append(infoRow("完成时间", time))
        }
        if let time = nonempty(detail.cancelTime) {
            rows.append(infoRow("取消时间", time))
        }
        if let time = nonempty(detail.expireTime) {
            rows.append(infoRow("过期时间", time))
        }
        appendSeparated(rows, to: body)
        return card(body)
    }

    private func descriptionCard(_ raw: String?) -> UIView {
        let body = UIStackView()
        body.axis = .vertical
        body.spacing = 12
        body.addArrangedSubview(sectionTitle("服务说明"))
        let text = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if text.contains("<") || text.contains("&lt;") {
            let html = CabinHTMLBlockView()
            html.setHTML(text)
            body.addArrangedSubview(html)
        } else {
            let label = UILabel()
            label.text = text.isEmpty ? "—" : text
            label.font = .fdFont(ofSize: 16, weight: .regular)
            label.textColor = Self.titleColor
            label.numberOfLines = 0
            body.addArrangedSubview(label)
        }
        return card(body)
    }

    private func card(_ body: UIView) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        card.addSubview(body)
        body.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        return card
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 18, weight: .medium)
        label.textColor = Self.titleColor
        return label
    }

    private func statusPill(_ text: String, status: Int?) -> UIView {
        let pending = status == 1 || status == 2 || status == 3 || status == 4
        let positive = status == 5
        let textColor: UIColor = positive ? .fdSuccess : (pending ? Self.orange : UIColor(hexString: "#8C93A3"))
        let fill: UIColor = positive ? .fdSuccessSoft : (pending ? UIColor(hexString: "#FFF3EE") : UIColor(hexString: "#F2F3F5"))
        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 12, weight: .regular)
        label.textColor = textColor
        let box = UIView()
        box.backgroundColor = fill
        box.layer.cornerRadius = 4
        box.clipsToBounds = true
        box.addSubview(label)
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
        }
        box.setContentHuggingPriority(.required, for: .horizontal)
        return box
    }

    private func timeBar(_ time: String) -> UIView {
        let box = UIView()
        box.backgroundColor = UIColor(hexString: "#FFF3EE")
        box.layer.cornerRadius = 8
        let name = UILabel()
        name.text = "预约时间"
        name.font = .fdFont(ofSize: 16, weight: .regular)
        name.textColor = Self.subtitleColor
        name.setContentHuggingPriority(.required, for: .horizontal)
        let value = UILabel()
        value.text = time
        value.font = .fdFont(ofSize: 16, weight: .semibold)
        value.textColor = Self.orange
        value.textAlignment = .right
        value.numberOfLines = 0
        let row = UIStackView(arrangedSubviews: [name, value])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        box.addSubview(row)
        row.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
        }
        return box
    }

    private func infoRow(_ title: String, _ value: String, emphasized: Bool = false) -> UIView {
        let name = UILabel()
        name.text = title
        name.font = .fdFont(ofSize: 16, weight: .regular)
        name.textColor = Self.subtitleColor
        name.setContentHuggingPriority(.required, for: .horizontal)
        name.setContentCompressionResistancePriority(.required, for: .horizontal)
        let body = UILabel()
        body.text = value
        body.font = .fdFont(ofSize: 16, weight: emphasized ? .semibold : .regular)
        body.textColor = emphasized ? Self.orange : Self.titleColor
        body.textAlignment = .right
        body.numberOfLines = 0
        let row = UIStackView(arrangedSubviews: [name, body])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12
        return row
    }

    private func outlineAction(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(Self.orange, for: .normal)
        button.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 0.5
        button.layer.borderColor = Self.orange.cgColor
        button.addTarget(self, action: action, for: .touchUpInside)
        button.snp.makeConstraints { $0.height.equalTo(40) }
        return button
    }

    private func actionButton(_ title: String, filled: Bool, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        if filled {
            button.backgroundColor = Self.orange
            button.setTitleColor(.white, for: .normal)
        } else {
            button.backgroundColor = .white
            button.setTitleColor(Self.orange, for: .normal)
            button.layer.borderWidth = 0.5
            button.layer.borderColor = Self.orange.cgColor
        }
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func reminderBar(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 16, weight: .regular)
        label.textColor = .fdPrimary
        label.numberOfLines = 0
        let box = UIView()
        box.backgroundColor = .fdPrimarySoft
        box.layer.cornerRadius = 8
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
        let icon = UIImageView(image: UIImage(named: "order_notice_alert_icon"))
        icon.contentMode = .scaleAspectFit
        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(hexString: "#F93838")
        label.numberOfLines = 0
        box.addSubview(icon)
        box.addSubview(label)
        icon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(14)
        }
        label.snp.makeConstraints {
            $0.leading.equalTo(icon.snp.trailing).offset(6)
            $0.trailing.equalToSuperview().offset(-12)
            $0.top.equalToSuperview().offset(8)
            $0.bottom.equalToSuperview().offset(-8)
        }
        return box
    }

    private func appendSeparated(_ rows: [UIView], to body: UIStackView) {
        for (index, row) in rows.enumerated() {
            body.addArrangedSubview(row)
            guard index < rows.count - 1 else { continue }
            let line = UIView()
            line.backgroundColor = .fdBorder
            body.addArrangedSubview(line)
            line.snp.makeConstraints { $0.height.equalTo(1.0 / UIScreen.main.scale) }
        }
    }

    private func display(_ text: String?) -> String {
        nonempty(text) ?? "—"
    }

    private func nonempty(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}
