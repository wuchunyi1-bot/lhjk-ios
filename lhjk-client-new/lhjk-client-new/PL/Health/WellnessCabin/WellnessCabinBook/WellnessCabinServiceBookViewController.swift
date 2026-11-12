import Combine
import Kingfisher
import SnapKit
import UIKit

/// 康养小屋项目预约。门店详情「立即预约」进入，加载预约页详情。
final class WellnessCabinServiceBookViewController: BaseViewController {

    private let viewModel: WellnessCabinBookViewModel
    private let pageTitle: String
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let gallery = CabinBookGalleryView()
    private let introCard = UIView()
    private let titleLabel = UILabel()
    private let metaStack = UIStackView()
    private let dateCard = UIView()
    private let dateScroll = UIScrollView()
    private let dateStack = UIStackView()
    private let slotCard = UIView()
    private let slotStack = UIStackView()
    private let slotEmptyLabel = UILabel()
    private let slotSpinner = UIActivityIndicatorView(style: .medium)
    private let aboutCard = UIView()
    private let aboutLabel = UILabel()
    private let aboutHTML = CabinHTMLBlockView()
    private var aboutTextKey: String?
    private let noticeCard = UIView()
    private let noticeLabel = UILabel()
    private let feeCard = UIView()
    private let feeTitleLabel = UILabel()
    private let feeValueLabel = UILabel()
    private let feeHintLabel = UILabel()
    private let inlineButton = UIButton(type: .system)
    private let bottomBar = UIView()
    private let barInfoLabel = UILabel()
    private let barHintLabel = UILabel()
    private let barButton = UIButton(type: .system)
    private let pageSpinner = UIActivityIndicatorView(style: .large)
    private let missingView = FDEmptyStateView(style: .page, message: "未找到该项目")
    private let cardsStack = UIStackView()
    private var barHeight: Constraint?
    private var barVisible = false
    private var galleryKey = ""
    private var dateRenderKey = ""
    private var didProceed = false
    private var didAppear = false

    init(
        hospitalId: String = "",
        configId: String = "",
        priceText: String? = nil,
        unitName: String? = nil,
        internalOnly: Bool? = nil,
        presentsCommerce: Bool = true
    ) {
        pageTitle = presentsCommerce ? "项目预约" : "活动详情"
        viewModel = WellnessCabinBookViewModel(
            hospitalId: hospitalId,
            configId: configId,
            priceText: priceText,
            unitName: unitName,
            internalOnly: internalOnly,
            presentsCommerce: presentsCommerce
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        if didAppear {
            didProceed = false
            viewModel.reloadSelectedDate()
        }
        didAppear = true
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        title = pageTitle
        setupScroll()
        setupCards()
        setupBottomBar()
        setupMissing()
        pageSpinner.color = .fdPrimary
        pageSpinner.hidesWhenStopped = true
        view.addSubview(pageSpinner)
        pageSpinner.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    override func bindViewModel() {
        viewModel.$detail
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)
        viewModel.$days
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)
        viewModel.$selectedDateId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)
        viewModel.$slots
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)
        viewModel.$selectedSlotKey
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)
        viewModel.$isLoading
            .combineLatest(viewModel.$isLoadingSlots, viewModel.$isMissing, viewModel.$isSubmitting)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
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

    override func refreshForSeniorMode() {
        super.refreshForSeniorMode()
        render()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateBarLayout()
    }

    private func updateBarLayout() {
        let show = viewModel.showsBottomBar && viewModel.detail != nil && !viewModel.isMissing
        let hintExtra: CGFloat = show && viewModel.timesCardHint != nil ? 18 : 0
        let height = show ? 66 + hintExtra + view.safeAreaInsets.bottom : 0
        barHeight?.update(offset: height)
        guard show != barVisible else { return }
        barVisible = show
        bottomBar.isHidden = !show
        scrollView.snp.remakeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            if show {
                $0.bottom.equalTo(bottomBar.snp.top)
            } else {
                $0.bottom.equalTo(view.safeAreaLayoutGuide)
            }
        }
    }

    private func render() {
        let ready = viewModel.detail != nil && !viewModel.isMissing
        scrollView.isHidden = !ready
        bottomBar.isHidden = !ready || !viewModel.showsBottomBar
        missingView.isHidden = !viewModel.isMissing
        if viewModel.isLoading || viewModel.isSubmitting {
            pageSpinner.startAnimating()
        } else {
            pageSpinner.stopAnimating()
        }
        guard let detail = viewModel.detail else { return }

        let urls = detail.galleryURLs
        let nextGalleryKey = urls.map(\.absoluteString).joined(separator: "|")
        if nextGalleryKey != galleryKey {
            galleryKey = nextGalleryKey
            gallery.setURLs(urls)
        }
        titleLabel.text = detail.name.isEmpty ? "项目预约" : detail.name
        refillMeta(detail)
        refillDates()
        refillSlots()
        if let text = detail.description, !text.isEmpty {
            aboutCard.isHidden = false
            if text != aboutTextKey {
                aboutTextKey = text
                setAboutText(text)
            }
        } else {
            aboutCard.isHidden = true
            aboutTextKey = nil
        }
        if let noticeText = detail.notice, !noticeText.isEmpty {
            noticeCard.isHidden = false
            noticeLabel.text = noticeText
        } else {
            noticeCard.isHidden = true
        }
        refillFee(detail)
        inlineButton.isHidden = viewModel.showsBottomBar
        updateConfirmStyle(inlineButton)
        updateConfirmStyle(barButton)
        barInfoLabel.text = viewModel.barText
        barInfoLabel.isHidden = viewModel.barText == nil
        switch viewModel.billingSource {
        case 2:
            barInfoLabel.textColor = .fdPrimary
        case 3:
            barInfoLabel.textColor = .fdPrimary
        default:
            barInfoLabel.textColor = .fdText
        }
        barHintLabel.text = viewModel.timesCardHint
        barHintLabel.isHidden = viewModel.timesCardHint == nil
        updateBarLayout()
    }

    private func setupScroll() {
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .fdBg
        view.addSubview(scrollView)
        contentStack.axis = .vertical
        contentStack.spacing = 0
        cardsStack.axis = .vertical
        cardsStack.spacing = 12
        cardsStack.isLayoutMarginsRelativeArrangement = true
        cardsStack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)
        scrollView.addSubview(contentStack)
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        contentStack.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }
    }

    private func setupCards() {
        contentStack.addArrangedSubview(gallery)
        contentStack.addArrangedSubview(cardsStack)

        styleCard(introCard)
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .fdText
        titleLabel.numberOfLines = 0
        metaStack.axis = .vertical
        metaStack.spacing = 10
        let introStack = UIStackView(arrangedSubviews: [titleLabel, metaStack])
        introStack.axis = .vertical
        introStack.spacing = 12
        pin(introStack, in: introCard)
        cardsStack.addArrangedSubview(introCard)

        styleCard(dateCard)
        let dateTitle = sectionTitle("选择预约日期")
        dateScroll.showsHorizontalScrollIndicator = false
        dateStack.axis = .horizontal
        dateStack.spacing = 10
        dateStack.alignment = .fill
        dateScroll.addSubview(dateStack)
        dateStack.snp.makeConstraints {
            $0.edges.equalTo(dateScroll.contentLayoutGuide)
            $0.height.equalTo(dateScroll.frameLayoutGuide)
        }
        dateScroll.snp.makeConstraints { $0.height.equalTo(64) }
        let dateBody = UIStackView(arrangedSubviews: [dateTitle, dateScroll])
        dateBody.axis = .vertical
        dateBody.spacing = 12
        pin(dateBody, in: dateCard)
        cardsStack.addArrangedSubview(dateCard)

        styleCard(slotCard)
        let slotTitle = sectionTitle("选择预约时段")
        slotStack.axis = .vertical
        slotStack.spacing = 10
        slotEmptyLabel.font = .fdFont(ofSize: 16, weight: .regular)
        slotEmptyLabel.textColor = .fdTabInactive
        slotEmptyLabel.textAlignment = .center
        slotEmptyLabel.text = "暂无可预约时段"
        slotSpinner.color = .fdPrimary
        slotSpinner.hidesWhenStopped = true
        let slotBody = UIStackView(arrangedSubviews: [slotTitle, slotStack, slotEmptyLabel, slotSpinner])
        slotBody.axis = .vertical
        slotBody.spacing = 12
        pin(slotBody, in: slotCard)
        cardsStack.addArrangedSubview(slotCard)

        styleCard(aboutCard)
        let aboutTitle = sectionTitle("项目介绍")
        aboutLabel.font = .fdFont(ofSize: 16, weight: .regular)
        aboutLabel.textColor = .fdTabInactive
        aboutLabel.numberOfLines = 0
        aboutHTML.isHidden = true
        let aboutBody = UIStackView(arrangedSubviews: [aboutTitle, aboutLabel, aboutHTML])
        aboutBody.axis = .vertical
        aboutBody.spacing = 12
        pin(aboutBody, in: aboutCard)
        cardsStack.addArrangedSubview(aboutCard)

        styleCard(noticeCard)
        let noticeTitle = sectionTitle("预约须知")
        noticeLabel.font = .fdFont(ofSize: 16, weight: .regular)
        noticeLabel.textColor = .fdTabInactive
        noticeLabel.numberOfLines = 0
        let noticeBody = UIStackView(arrangedSubviews: [noticeTitle, noticeLabel])
        noticeBody.axis = .vertical
        noticeBody.spacing = 12
        pin(noticeBody, in: noticeCard)
        cardsStack.addArrangedSubview(noticeCard)

        styleCard(feeCard)
        let feeHeading = sectionTitle("费用信息")
        feeTitleLabel.font = .fdFont(ofSize: 16, weight: .regular)
        feeTitleLabel.textColor = .fdTabInactive
        feeTitleLabel.numberOfLines = 2
        feeValueLabel.font = .fdFont(ofSize: 16, weight: .medium)
        feeValueLabel.textAlignment = .right
        feeValueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let feeRow = UIStackView(arrangedSubviews: [feeTitleLabel, feeValueLabel])
        feeRow.axis = .horizontal
        feeRow.alignment = .center
        feeRow.spacing = 12
        feeHintLabel.font = .fdFont(ofSize: 14, weight: .regular)
        feeHintLabel.textColor = .fdDanger
        feeHintLabel.numberOfLines = 0
        feeHintLabel.isHidden = true
        let feeBody = UIStackView(arrangedSubviews: [feeHeading, feeRow, feeHintLabel])
        feeBody.axis = .vertical
        feeBody.spacing = 12
        pin(feeBody, in: feeCard)
        cardsStack.addArrangedSubview(feeCard)

        configureConfirm(inlineButton)
        cardsStack.addArrangedSubview(inlineButton)
        inlineButton.snp.makeConstraints { $0.height.equalTo(40) }
    }

    private func setupBottomBar() {
        bottomBar.backgroundColor = .white
        bottomBar.layer.cornerRadius = 16
        bottomBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomBar.layer.shadowColor = UIColor.black.cgColor
        bottomBar.layer.shadowOpacity = 0.04
        bottomBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        bottomBar.layer.shadowRadius = 8
        barInfoLabel.font = .fdFont(ofSize: 16, weight: .medium)
        barInfoLabel.textColor = .fdPrimary
        barInfoLabel.numberOfLines = 1
        barHintLabel.font = .fdFont(ofSize: 12, weight: .regular)
        barHintLabel.textColor = .fdDanger
        barHintLabel.numberOfLines = 2
        barHintLabel.isHidden = true
        let infoStack = UIStackView(arrangedSubviews: [barInfoLabel, barHintLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2
        configureConfirm(barButton)
        let row = UIStackView(arrangedSubviews: [infoStack, barButton])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        bottomBar.addSubview(row)
        view.addSubview(bottomBar)
        row.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }
        barButton.snp.makeConstraints {
            $0.width.equalTo(120)
            $0.height.equalTo(40)
        }
        bottomBar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            barHeight = $0.height.equalTo(0).constraint
        }
    }

    private func setupMissing() {
        view.addSubview(missingView)
        missingView.snp.makeConstraints { $0.edges.equalToSuperview() }
        missingView.isHidden = true
    }

    private func refillMeta(_ detail: CabinBookDetailVO) {
        metaStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let text = detail.durationText {
            metaStack.addArrangedSubview(metaRow(symbol: "clock", text: text, tint: .fdTabInactive))
        }
        let dict = DictionaryCacheService.shared
        if let people = dict.joinedLabels(parent: .serviceApplicablePeople, raw: detail.applicablePeople) {
            metaStack.addArrangedSubview(
                audienceRow(symbol: "person", title: "适用人群", value: people, valueColor: .fdText)
            )
        }
        if let restricted = dict.joinedLabels(parent: .serviceRestrictedPeople, raw: detail.restrictedPeople) {
            metaStack.addArrangedSubview(
                audienceRow(
                    symbol: "exclamationmark.triangle",
                    title: "禁止人群",
                    value: restricted,
                    valueColor: .fdDanger
                )
            )
        }
        metaStack.isHidden = metaStack.arrangedSubviews.isEmpty
        ensureAudienceDictionary(detail)
    }

    private func refillDates() {
        let key = viewModel.days.map(\.id).joined(separator: ",") + "|" + (viewModel.selectedDateId ?? "")
        guard key != dateRenderKey else { return }
        dateRenderKey = key
        let offset = dateScroll.contentOffset
        dateStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for day in viewModel.days {
            let chip = CabinBookDateChip(day: day, selected: day.id == viewModel.selectedDateId)
            chip.addTarget(self, action: #selector(dateTapped(_:)), for: .touchUpInside)
            dateStack.addArrangedSubview(chip)
        }
        dateScroll.layoutIfNeeded()
        dateScroll.contentOffset = offset
    }

    private func refillSlots() {
        slotStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let loading = viewModel.isLoadingSlots
        if loading {
            slotSpinner.startAnimating()
        } else {
            slotSpinner.stopAnimating()
        }
        slotStack.isHidden = loading
        slotEmptyLabel.isHidden = loading || !viewModel.slots.isEmpty
        guard !loading else { return }

        var row: UIStackView?
        for (index, slot) in viewModel.slots.enumerated() {
            if index % 3 == 0 {
                row = UIStackView()
                row?.axis = .horizontal
                row?.spacing = 10
                row?.distribution = .fillEqually
                if let row { slotStack.addArrangedSubview(row) }
            }
            let chip = CabinBookSlotChip(
                slot: slot,
                selected: slot.key == viewModel.selectedSlotKey && slot.isBookable
            )
            chip.addTarget(self, action: #selector(slotTapped(_:)), for: .touchUpInside)
            row?.addArrangedSubview(chip)
        }
        if let row, row.arrangedSubviews.count < 3 {
            let missing = 3 - row.arrangedSubviews.count
            for _ in 0..<missing {
                let spacer = UIView()
                spacer.isUserInteractionEnabled = false
                row.addArrangedSubview(spacer)
            }
        }
    }

    private func refillFee(_ detail: CabinBookDetailVO) {
        guard viewModel.presentsCommerce else {
            feeCard.isHidden = true
            feeHintLabel.isHidden = true
            return
        }
        switch viewModel.billingSource {
        case 2:
            feeCard.isHidden = false
            feeTitleLabel.text = detail.name
            feeValueLabel.text = viewModel.timesCardText
            feeValueLabel.textColor = .fdPrimary
            feeHintLabel.isHidden = viewModel.timesCardHint == nil
            feeHintLabel.text = viewModel.timesCardHint
        case 3 where viewModel.feeAmountText != nil:
            feeCard.isHidden = false
            feeTitleLabel.text = detail.name
            feeValueLabel.text = viewModel.feeAmountText
            feeValueLabel.textColor = .fdPrimary
            feeHintLabel.isHidden = true
        default:
            feeCard.isHidden = true
            feeHintLabel.isHidden = true
        }
    }

    private func proceedBook() {
        guard !didProceed, !viewModel.isSubmitting else { return }
        didProceed = true
        Task { [weak self] in
            guard let self else { return }
            do {
                let outcome = try await self.viewModel.proceed()
                await MainActor.run {
                    switch outcome {
                    case .ignored:
                        self.didProceed = false
                    case .booked:
                        self.showToastAlert("已提交预约") { [weak self] in
                            guard let self else { return }
                            Router.shared.push("/wellness-cabins/appointments", from: self)
                        }
                    case .confirmOrder(let orderId, let context):
                        var params: [String: Any] = ["orderId": String(orderId)]
                        context.routeParams().forEach { params[$0.key] = $0.value }
                        self.didProceed = false
                        Router.shared.push("/orders/confirm", params: params, from: self)
                    }
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "提交失败，请重试"
                await MainActor.run {
                    self.didProceed = false
                    self.showToastAlert(message)
                }
            }
        }
    }

    private var isCheckingLimit = false

    private func confirmTapped() {
        guard viewModel.selectedSlot != nil else {
            showToastAlert("请选择可预约时段")
            return
        }
        guard !isCheckingLimit, !didProceed, !viewModel.isSubmitting else { return }
        isCheckingLimit = true
        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await self.viewModel.checkBookLimit()
                await MainActor.run {
                    self.isCheckingLimit = false
                    if result.blocksBooking {
                        self.presentBookLimit(result)
                        return
                    }
                    self.continueAfterLimitCheck()
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "预约校验失败，请重试"
                await MainActor.run {
                    self.isCheckingLimit = false
                    self.showToastAlert(message)
                }
            }
        }
    }

    /// 限流通过后，项目预约和活动预约都先弹温馨提示。
    private func continueAfterLimitCheck() {
        presentHealthNotice()
    }

    private func presentBookLimit(_ result: CabinBookLimitCheckVO) {
        let alert = CabinBookLimitAlertView()
        alert.configure(title: result.alertTitle, message: result.alertMessage)
        alert.onConfirm = { [weak alert] in
            alert?.dismiss()
        }
        alert.show(in: view)
    }

    private func presentHealthNotice() {
        let notice = CabinHealthNoticeView()
        notice.configure(isInternalStation: viewModel.isInternalStation)
        notice.onClose = { [weak notice] in
            notice?.dismiss()
        }
        notice.onContinue = { [weak self, weak notice] in
            notice?.dismiss()
            self?.proceedBook()
        }
        notice.show(in: view)
    }

    @objc private func dateTapped(_ sender: CabinBookDateChip) {
        viewModel.select(date: sender.dayId)
    }

    @objc private func slotTapped(_ sender: CabinBookSlotChip) {
        viewModel.select(slot: sender.slot)
    }

    private func styleCard(_ card: UIView) {
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 18, weight: .medium)
        label.textColor = .fdText
        return label
    }

    private func pin(_ stack: UIStackView, in card: UIView) {
        card.addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        }
    }

    private var didSyncAudienceDictionary = false

    private func ensureAudienceDictionary(_ detail: CabinBookDetailVO) {
        let dict = DictionaryCacheService.shared
        let missing = dict.hasUnresolvedValue(parent: .serviceApplicablePeople, raw: detail.applicablePeople)
            || dict.hasUnresolvedValue(parent: .serviceRestrictedPeople, raw: detail.restrictedPeople)
        guard missing, !didSyncAudienceDictionary else { return }
        didSyncAudienceDictionary = true
        Task { [weak self] in
            await DictionaryCacheService.shared.sync()
            await MainActor.run {
                guard let self, let detail = self.viewModel.detail else { return }
                self.refillMeta(detail)
            }
        }
    }

    /// 标题固定，字典名称换行跟在后面，避免长文案把图标挤变形。
    private func audienceRow(symbol name: String, title: String, value: String, valueColor: UIColor) -> UIStackView {
        let icon = UIImageView(image: UIImage(systemName: name))
        icon.tintColor = valueColor
        icon.contentMode = .scaleAspectFit
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.snp.makeConstraints { $0.width.height.equalTo(16) }

        let text = NSMutableAttributedString(
            string: "\(title)：",
            attributes: [
                .font: UIFont.fdFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor.fdSubtext,
            ]
        )
        text.append(NSAttributedString(
            string: value,
            attributes: [
                .font: UIFont.fdFont(ofSize: 16, weight: .medium),
                .foregroundColor: valueColor,
            ]
        ))
        let label = UILabel()
        label.attributedText = text
        label.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 6
        return row
    }

    private func metaRow(symbol name: String, text: String, tint: UIColor) -> UIStackView {
        let icon = UIImageView(image: UIImage(systemName: name))
        icon.tintColor = tint
        icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints { $0.width.height.equalTo(16) }
        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 16, weight: .regular)
        label.textColor = tint
        label.numberOfLines = 0
        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 8
        return row
    }

    private func configureConfirm(_ button: UIButton) {
        button.setTitle("确定预约", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .fdPrimary
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
    }

    private func setAboutText(_ text: String) {
        let markup = text.contains("<") || text.contains("&lt;")
        aboutLabel.isHidden = markup
        aboutHTML.isHidden = !markup
        if markup {
            aboutLabel.text = nil
            aboutHTML.setHTML(text)
            return
        }
        aboutLabel.attributedText = nil
        aboutLabel.text = text
    }

    private func updateConfirmStyle(_ button: UIButton) {
        let enabled = viewModel.selectedSlot != nil
        button.backgroundColor = enabled ? .fdPrimary : UIColor.fdPrimary.withAlphaComponent(0.45)
    }

    @objc private func confirmButtonTapped() {
        confirmTapped()
    }
}

private final class CabinBookDateChip: UIControl {

    let dayId: String
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    init(day: CabinBookDay, selected: Bool) {
        dayId = day.id
        super.init(frame: .zero)
        titleLabel.text = day.title
        titleLabel.font = .fdFont(ofSize: 14, weight: .regular)
        titleLabel.textAlignment = .center
        subtitleLabel.text = day.subtitle
        subtitleLabel.font = .fdFont(ofSize: 16, weight: .semibold)
        subtitleLabel.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12))
        }
        snp.makeConstraints { $0.width.greaterThanOrEqualTo(72) }
        setContentHuggingPriority(.required, for: .horizontal)
        layer.cornerRadius = 12
        layer.borderWidth = 1
        apply(selected: selected)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func apply(selected: Bool) {
        if selected {
            backgroundColor = .fdPrimary
            layer.borderColor = UIColor.fdPrimary.cgColor
            titleLabel.textColor = .white
            subtitleLabel.textColor = .white
        } else {
            backgroundColor = .fdSurface
            layer.borderColor = UIColor.fdBorder.cgColor
            titleLabel.textColor = .fdSubtext
            subtitleLabel.textColor = .fdText
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 72, height: 64)
    }
}

private final class CabinBookSlotChip: UIControl {

    let slot: CabinSlotVO
    private let timeLabel = UILabel()
    private let statusLabel = UILabel()

    init(slot: CabinSlotVO, selected: Bool) {
        self.slot = slot
        super.init(frame: .zero)
        timeLabel.text = slot.timeText
        timeLabel.font = .fdFont(ofSize: 14, weight: .semibold)
        timeLabel.textAlignment = .center
        statusLabel.text = slot.statusText
        statusLabel.font = .fdFont(ofSize: 12, weight: .regular)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        let stack = UIStackView(arrangedSubviews: [timeLabel, statusLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4))
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(56) }
        layer.cornerRadius = 12
        layer.borderWidth = 1
        isUserInteractionEnabled = slot.isBookable
        apply(selected: selected, bookable: slot.isBookable)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func apply(selected: Bool, bookable: Bool) {
        if !bookable {
            backgroundColor = .fdBg2
            layer.borderColor = UIColor.fdBorder.cgColor
            timeLabel.textColor = .fdMuted
            statusLabel.textColor = .fdMuted
            return
        }
        if selected {
            backgroundColor = .fdPrimarySoft
            layer.borderColor = UIColor.fdPrimary.cgColor
            timeLabel.textColor = .fdPrimary
        } else {
            backgroundColor = .fdSurface
            layer.borderColor = UIColor.fdBorder.cgColor
            timeLabel.textColor = .fdText
        }
        statusLabel.textColor = .fdSuccess
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }
}

/// 预约详情图集：高度固定 200，多于一张时每 4 秒向前循环。
private final class CabinBookGalleryView: UIView, UIScrollViewDelegate {

    private static let galleryHeight: CGFloat = 200
    private static let loopMultiplier = 40

    private let scroll = UIScrollView()
    private let pageControl = UIPageControl()
    private var urls: [URL] = []
    private var imageViews: [UIImageView] = []
    private var heightConstraint: Constraint?
    private var logicalIndex = 0
    private var placedInitialPage = false
    private var timer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = .fdProductImageBg
        scroll.isPagingEnabled = true
        scroll.showsHorizontalScrollIndicator = false
        scroll.bounces = false
        scroll.delegate = self
        pageControl.currentPageIndicatorTintColor = .fdPrimary
        pageControl.pageIndicatorTintColor = UIColor.fdPrimary.withAlphaComponent(0.25)
        pageControl.isUserInteractionEnabled = false
        pageControl.hidesForSinglePage = true
        addSubview(scroll)
        addSubview(pageControl)
        scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        pageControl.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-6)
        }
        snp.makeConstraints { heightConstraint = $0.height.equalTo(0).constraint }
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit { timer?.invalidate() }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            startTimer()
        } else {
            stopTimer()
        }
    }

    func setURLs(_ urls: [URL]) {
        guard self.urls != urls else { return }
        self.urls = urls
        placedInitialPage = false
        logicalIndex = urls.count > 1 ? urls.count * (Self.loopMultiplier / 2) : 0
        pageControl.numberOfPages = urls.count
        pageControl.currentPage = 0
        isHidden = urls.isEmpty
        heightConstraint?.update(offset: urls.isEmpty ? 0 : Self.galleryHeight)
        rebuildSlides()
        setNeedsLayout()
        if window != nil {
            startTimer()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        let height = bounds.height
        guard width > 0, height > 0 else { return }
        scroll.contentSize = CGSize(width: width * CGFloat(max(imageViews.count, 1)), height: height)
        for (index, image) in imageViews.enumerated() {
            image.frame = CGRect(x: width * CGFloat(index), y: 0, width: width, height: height)
        }
        guard !placedInitialPage else { return }
        placedInitialPage = true
        scroll.contentOffset = CGPoint(x: width * CGFloat(logicalIndex), y: 0)
        pageControl.currentPage = realIndex(for: logicalIndex)
    }

    private var slideCount: Int {
        guard urls.count > 1 else { return urls.count }
        return urls.count * Self.loopMultiplier
    }

    private func realIndex(for logical: Int) -> Int {
        guard !urls.isEmpty else { return 0 }
        let count = urls.count
        let mod = logical % count
        return mod >= 0 ? mod : mod + count
    }

    private func rebuildSlides() {
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews = (0..<slideCount).map { index in
            let image = UIImageView()
            image.contentMode = .scaleAspectFill
            image.clipsToBounds = true
            image.backgroundColor = .fdProductImageBg
            image.kf.setImage(with: urls[realIndex(for: index)])
            scroll.addSubview(image)
            return image
        }
    }

    private func normalizePositionIfNeeded() {
        guard urls.count > 1 else { return }
        let width = scroll.bounds.width
        guard width > 0 else { return }
        let count = urls.count
        let middle = count * (Self.loopMultiplier / 2)
        let real = realIndex(for: logicalIndex)
        if logicalIndex < count || logicalIndex >= slideCount - count {
            logicalIndex = middle + real
            scroll.contentOffset = CGPoint(x: width * CGFloat(logicalIndex), y: 0)
        }
    }

    private func syncPageFromOffset() {
        let width = scroll.bounds.width
        guard width > 0, !urls.isEmpty else { return }
        logicalIndex = Int(round(scroll.contentOffset.x / width))
        pageControl.currentPage = realIndex(for: logicalIndex)
    }

    private func startTimer() {
        stopTimer()
        guard window != nil, urls.count > 1 else { return }
        let timer = Timer(timeInterval: 4, repeats: true) { [weak self] _ in
            self?.advancePage()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func advancePage() {
        let width = scroll.bounds.width
        guard urls.count > 1, width > 0 else { return }
        normalizePositionIfNeeded()
        logicalIndex += 1
        pageControl.currentPage = realIndex(for: logicalIndex)
        scroll.setContentOffset(CGPoint(x: width * CGFloat(logicalIndex), y: 0), animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.width
        guard width > 0, !urls.isEmpty else { return }
        let index = Int(round(scrollView.contentOffset.x / width))
        pageControl.currentPage = realIndex(for: index)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopTimer()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            syncPageFromOffset()
            normalizePositionIfNeeded()
            startTimer()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        syncPageFromOffset()
        normalizePositionIfNeeded()
        startTimer()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        syncPageFromOffset()
        normalizePositionIfNeeded()
    }
}

/// 预约次数或名额已满。只有「我知道了」，关闭后不继续预约。
private final class CabinBookLimitAlertView: UIView {

    var onConfirm: (() -> Void)?

    private let card = UIView()
    private let iconHost = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let confirmButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, message: String) {
        titleLabel.text = title
        messageLabel.text = message
    }

    func show(in host: UIView) {
        host.addSubview(self)
        snp.makeConstraints { $0.edges.equalToSuperview() }
        alpha = 0
        card.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1
            self.card.transform = .identity
        }
    }

    func dismiss() {
        UIView.animate(withDuration: 0.18, animations: {
            self.alpha = 0
            self.card.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }

    private func setup() {
        backgroundColor = UIColor.black.withAlphaComponent(0.45)

        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.clipsToBounds = true

        iconHost.backgroundColor = .fdWarningSoft
        iconHost.layer.cornerRadius = 28
        iconView.image = UIImage(systemName: "exclamationmark.triangle.fill")
        iconView.tintColor = .fdWarning
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .fdFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .fdText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        messageLabel.font = .fdFont(ofSize: 14, weight: .regular)
        messageLabel.textColor = .fdSubtext
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        confirmButton.setTitle("我知道了", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        confirmButton.backgroundColor = .fdPrimary
        confirmButton.layer.cornerRadius = 22
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        addSubview(card)
        card.addSubview(iconHost)
        iconHost.addSubview(iconView)
        card.addSubview(titleLabel)
        card.addSubview(messageLabel)
        card.addSubview(confirmButton)

        card.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(40)
            $0.width.lessThanOrEqualTo(300)
        }
        iconHost.snp.makeConstraints {
            $0.top.equalToSuperview().offset(28)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(56)
        }
        iconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(26)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(iconHost.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        messageLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        confirmButton.snp.makeConstraints {
            $0.top.equalTo(messageLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }
    }

    @objc private func confirmTapped() {
        onConfirm?()
    }
}

/// 项目预约温馨提示。关闭不提交；「仍要预约」才继续。
private final class CabinHealthNoticeView: UIView {

    var onClose: (() -> Void)?
    var onContinue: (() -> Void)?

    private let card = UIView()
    private let closeButton = UIButton(type: .system)
    private let iconHost = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let listStack = UIStackView()
    private let standardCard = UIView()
    private let standardTitle = UILabel()
    private let standardText = UILabel()
    private let continueButton = UIButton(type: .system)
    private let internalItem = CabinHealthNoticeBullet(
        text: "此健康驿站服务仅限【红色工牌员工】预约；",
        emphasized: true
    )
    private let feverItem = CabinHealthNoticeBullet(
        text: "为确保筛查结果准确，并保障您和他人的健康安全，如有发热（≥37.3℃）、感冒、咳嗽、咽痛等急性感染症状，请暂缓预约任何服务。",
        emphasized: false
    )
    private let recoverItem = CabinHealthNoticeBullet(
        text: "建议待症状消失、体温正常满24小时后再进行预约，感谢您的理解与配合。",
        emphasized: false
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(isInternalStation: Bool) {
        internalItem.isHidden = !isInternalStation
    }

    func show(in host: UIView) {
        host.addSubview(self)
        snp.makeConstraints { $0.edges.equalToSuperview() }
        alpha = 0
        card.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1
            self.card.transform = .identity
        }
    }

    func dismiss() {
        UIView.animate(withDuration: 0.18, animations: {
            self.alpha = 0
            self.card.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }

    private func setup() {
        backgroundColor = UIColor.black.withAlphaComponent(0.45)

        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.clipsToBounds = true

        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .fdMuted
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        iconHost.backgroundColor = .fdWarningSoft
        iconHost.layer.cornerRadius = 32
        iconView.image = UIImage(systemName: "exclamationmark.triangle.fill")
        iconView.tintColor = .fdWarning
        iconView.contentMode = .scaleAspectFit

        titleLabel.text = "温馨提示"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .fdText
        titleLabel.textAlignment = .center

        listStack.axis = .vertical
        listStack.spacing = 12
        listStack.addArrangedSubview(internalItem)
        listStack.addArrangedSubview(feverItem)
        listStack.addArrangedSubview(recoverItem)

        standardCard.backgroundColor = .fdWarningSoft
        standardCard.layer.cornerRadius = 12
        standardCard.layer.borderWidth = 0
        standardCard.layer.borderColor = UIColor.clear.cgColor

        let infoIcon = UIImageView(image: UIImage(systemName: "info.circle.fill"))
        infoIcon.tintColor = .fdWarning
        infoIcon.contentMode = .scaleAspectFit
        standardTitle.text = "健康筛查标准"
        standardTitle.font = .fdFont(ofSize: 14, weight: .medium)
        standardTitle.textColor = .fdWarning
        let standardTitleRow = UIStackView(arrangedSubviews: [infoIcon, standardTitle])
        standardTitleRow.axis = .horizontal
        standardTitleRow.spacing = 6
        standardTitleRow.alignment = .center

        standardText.text = "体温 ≥ 37.3℃ 或存在急性呼吸道感染症状者，请勿预约"
        standardText.font = .fdFont(ofSize: 14, weight: .regular)
        standardText.textColor = .fdText
        standardText.numberOfLines = 0

        continueButton.setTitle("仍要预约", for: .normal)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        continueButton.backgroundColor = .fdPrimary
        continueButton.layer.cornerRadius = 20
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        addSubview(card)
        card.addSubview(closeButton)
        card.addSubview(iconHost)
        iconHost.addSubview(iconView)
        card.addSubview(titleLabel)
        card.addSubview(listStack)
        card.addSubview(standardCard)
        standardCard.addSubview(standardTitleRow)
        standardCard.addSubview(standardText)
        card.addSubview(continueButton)

        card.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.width.lessThanOrEqualTo(340)
        }
        closeButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().offset(-12)
            $0.size.equalTo(32)
        }
        iconHost.snp.makeConstraints {
            $0.top.equalToSuperview().offset(22)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(64)
        }
        iconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(28)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(iconHost.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        listStack.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        standardCard.snp.makeConstraints {
            $0.top.equalTo(listStack.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        infoIcon.snp.makeConstraints { $0.size.equalTo(16) }
        standardTitleRow.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(12)
        }
        standardText.snp.makeConstraints {
            $0.top.equalTo(standardTitleRow.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(34)
            $0.trailing.bottom.equalToSuperview().inset(12)
        }
        continueButton.snp.makeConstraints {
            $0.top.equalTo(standardCard.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
            $0.height.equalTo(40)
        }
    }

    @objc private func closeTapped() {
        onClose?()
    }

    @objc private func continueTapped() {
        onContinue?()
    }
}

private final class CabinHealthNoticeBullet: UIView {

    private let dot = UIView()
    private let label = UILabel()

    init(text: String, emphasized: Bool) {
        super.init(frame: .zero)
        dot.backgroundColor = .fdWarning
        dot.layer.cornerRadius = 3
        label.text = text
        label.font = .fdFont(ofSize: 14, weight: emphasized ? .bold : .regular)
        label.textColor = .fdText
        label.numberOfLines = 0
        addSubview(dot)
        addSubview(label)
        dot.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalToSuperview().offset(8)
            $0.size.equalTo(6)
        }
        label.snp.makeConstraints {
            $0.leading.equalTo(dot.snp.trailing).offset(8)
            $0.top.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}

