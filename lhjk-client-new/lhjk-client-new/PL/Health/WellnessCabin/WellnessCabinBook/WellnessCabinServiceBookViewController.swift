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
        let height = show ? 64 + hintExtra + view.safeAreaInsets.bottom : 0
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
            setAboutText(text)
        } else {
            aboutCard.isHidden = true
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
        barHintLabel.text = viewModel.timesCardHint
        barHintLabel.isHidden = viewModel.timesCardHint == nil
        updateBarLayout()
    }

    private func setupScroll() {
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
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
        titleLabel.font = .fdFont(ofSize: 20, weight: .semibold)
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
        slotEmptyLabel.font = .fdFont(ofSize: 13, weight: .regular)
        slotEmptyLabel.textColor = .fdMuted
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
        aboutLabel.font = .fdFont(ofSize: 14, weight: .regular)
        aboutLabel.textColor = .fdSubtext
        aboutLabel.numberOfLines = 0
        let aboutBody = UIStackView(arrangedSubviews: [aboutTitle, aboutLabel])
        aboutBody.axis = .vertical
        aboutBody.spacing = 12
        pin(aboutBody, in: aboutCard)
        cardsStack.addArrangedSubview(aboutCard)

        styleCard(noticeCard)
        let noticeTitle = sectionTitle("预约须知")
        noticeLabel.font = .fdFont(ofSize: 13, weight: .regular)
        noticeLabel.textColor = .fdSubtext
        noticeLabel.numberOfLines = 0
        let noticeBody = UIStackView(arrangedSubviews: [noticeTitle, noticeLabel])
        noticeBody.axis = .vertical
        noticeBody.spacing = 12
        pin(noticeBody, in: noticeCard)
        cardsStack.addArrangedSubview(noticeCard)

        styleCard(feeCard)
        let feeHeading = sectionTitle("费用信息")
        feeTitleLabel.font = .fdFont(ofSize: 14, weight: .regular)
        feeTitleLabel.textColor = .fdText
        feeTitleLabel.numberOfLines = 2
        feeValueLabel.font = .fdFont(ofSize: 14, weight: .semibold)
        feeValueLabel.textAlignment = .right
        feeValueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let feeRow = UIStackView(arrangedSubviews: [feeTitleLabel, feeValueLabel])
        feeRow.axis = .horizontal
        feeRow.alignment = .center
        feeRow.spacing = 12
        feeHintLabel.font = .fdFont(ofSize: 12, weight: .regular)
        feeHintLabel.textColor = .fdDanger
        feeHintLabel.numberOfLines = 0
        feeHintLabel.isHidden = true
        let feeBody = UIStackView(arrangedSubviews: [feeHeading, feeRow, feeHintLabel])
        feeBody.axis = .vertical
        feeBody.spacing = 12
        pin(feeBody, in: feeCard)
        cardsStack.addArrangedSubview(feeCard)

        configureConfirm(inlineButton, cornerRadius: 18)
        cardsStack.addArrangedSubview(inlineButton)
        inlineButton.snp.makeConstraints { $0.height.equalTo(44) }
    }

    private func setupBottomBar() {
        bottomBar.backgroundColor = .fdSurface
        let line = UIView()
        line.backgroundColor = .fdBorder
        barInfoLabel.font = .fdFont(ofSize: 16, weight: .semibold)
        barInfoLabel.textColor = .fdPrimary
        barInfoLabel.numberOfLines = 1
        barHintLabel.font = .fdFont(ofSize: 11, weight: .regular)
        barHintLabel.textColor = .fdDanger
        barHintLabel.numberOfLines = 2
        barHintLabel.isHidden = true
        let infoStack = UIStackView(arrangedSubviews: [barInfoLabel, barHintLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2
        configureConfirm(barButton, cornerRadius: 12)
        let row = UIStackView(arrangedSubviews: [infoStack, barButton])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        bottomBar.addSubview(line)
        bottomBar.addSubview(row)
        view.addSubview(bottomBar)
        line.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
        row.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }
        barButton.snp.makeConstraints {
            $0.width.equalTo(120)
            $0.height.equalTo(44)
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
            metaStack.addArrangedSubview(metaRow(symbol: "clock", text: text, tint: .fdText))
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
            feeValueLabel.textColor = .fdSuccess
            feeHintLabel.isHidden = viewModel.timesCardHint == nil
            feeHintLabel.text = viewModel.timesCardHint
        case 3 where viewModel.feeAmountText != nil:
            feeCard.isHidden = false
            feeTitleLabel.text = detail.name
            let unit = viewModel.feeUnitText
            feeValueLabel.text = "\(viewModel.feeAmountText ?? "")/\(unit)"
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

    private func confirmTapped() {
        guard viewModel.selectedSlot != nil else {
            showToastAlert("请选择可预约时段")
            return
        }
        proceedBook()
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
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdBorder.cgColor
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 16, weight: .semibold)
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
                .font: UIFont.fdFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor.fdSubtext,
            ]
        )
        text.append(NSAttributedString(
            string: value,
            attributes: [
                .font: UIFont.fdFont(ofSize: 13, weight: .medium),
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
        label.font = .fdFont(ofSize: 13, weight: .regular)
        label.textColor = tint
        label.numberOfLines = 0
        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 8
        return row
    }

    private func configureConfirm(_ button: UIButton, cornerRadius: CGFloat) {
        button.setTitle("确定预约", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .fdFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .fdPrimary
        button.layer.cornerRadius = cornerRadius
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
    }

    private func setAboutText(_ text: String) {
        guard text.contains("<"),
              let data = text.data(using: .utf8),
              let parsed = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue,
                ],
                documentAttributes: nil
              ) else {
            aboutLabel.attributedText = nil
            aboutLabel.text = text
            return
        }
        let styled = NSMutableAttributedString(attributedString: parsed)
        let range = NSRange(location: 0, length: styled.length)
        if range.length > 0 {
            styled.addAttributes(
                [
                    .font: UIFont.fdFont(ofSize: 14, weight: .regular),
                    .foregroundColor: UIColor.fdSubtext,
                ],
                range: range
            )
        }
        aboutLabel.attributedText = styled
    }

    private func updateConfirmStyle(_ button: UIButton) {
        let enabled = viewModel.selectedSlot != nil
        button.backgroundColor = enabled ? .fdPrimary : .fdPrimary.withAlphaComponent(0.4)
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
        titleLabel.font = .fdFont(ofSize: 13, weight: .regular)
        titleLabel.textAlignment = .center
        subtitleLabel.text = day.subtitle
        subtitleLabel.font = .fdFont(ofSize: 15, weight: .semibold)
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
        layer.cornerRadius = 8
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
        timeLabel.font = .fdFont(ofSize: 13, weight: .semibold)
        timeLabel.textAlignment = .center
        statusLabel.text = slot.statusText
        statusLabel.font = .fdFont(ofSize: 11, weight: .regular)
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
        layer.cornerRadius = 8
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
        pageControl.pageIndicatorTintColor = .fdBorderStrong
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

