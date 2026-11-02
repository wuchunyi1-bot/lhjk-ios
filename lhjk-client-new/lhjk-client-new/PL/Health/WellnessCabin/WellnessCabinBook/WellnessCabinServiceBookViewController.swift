import Combine
import Kingfisher
import SnapKit
import UIKit

/// 康养小屋项目预约。门店详情「立即预约」进入，加载预约页详情。
final class WellnessCabinServiceBookViewController: BaseViewController {

    private let viewModel: WellnessCabinBookViewModel
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
    private let inlineButton = UIButton(type: .system)
    private let bottomBar = UIView()
    private let barInfoLabel = UILabel()
    private let barButton = UIButton(type: .system)
    private let pageSpinner = UIActivityIndicatorView(style: .large)
    private let missingView = FDEmptyStateView(style: .page, message: "未找到该项目")
    private let notice = CabinHealthNoticeView()
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
        internalOnly: Bool? = nil
    ) {
        viewModel = WellnessCabinBookViewModel(
            hospitalId: hospitalId,
            configId: configId,
            priceText: priceText,
            unitName: unitName,
            internalOnly: internalOnly
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
        title = "项目预约"
        setupScroll()
        setupCards()
        setupBottomBar()
        setupNotice()
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
        let height = show ? 64 + view.safeAreaInsets.bottom : 0
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
            aboutLabel.text = text
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
        let feeBody = UIStackView(arrangedSubviews: [feeHeading, feeRow])
        feeBody.axis = .vertical
        feeBody.spacing = 12
        pin(feeBody, in: feeCard)
        cardsStack.addArrangedSubview(feeCard)

        configureConfirm(inlineButton)
        cardsStack.addArrangedSubview(inlineButton)
        inlineButton.snp.makeConstraints { $0.height.equalTo(44) }
    }

    private func setupBottomBar() {
        bottomBar.backgroundColor = .fdSurface
        let line = UIView()
        line.backgroundColor = .fdBorder
        barInfoLabel.font = .fdFont(ofSize: 16, weight: .semibold)
        barInfoLabel.textColor = .fdPrimary
        configureConfirm(barButton)
        let row = UIStackView(arrangedSubviews: [barInfoLabel, barButton])
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
            $0.height.equalTo(44)
        }
        barButton.snp.makeConstraints { $0.width.equalTo(120) }
        bottomBar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            barHeight = $0.height.equalTo(0).constraint
        }
    }

    private func setupNotice() {
        notice.isHidden = true
        notice.onClose = { [weak self] in
            self?.notice.isHidden = true
        }
        notice.onProceed = { [weak self] in
            self?.proceedBook()
        }
        view.addSubview(notice)
        notice.snp.makeConstraints { $0.edges.equalToSuperview() }
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
        if let people = detail.applicablePeople, !people.isEmpty {
            metaStack.addArrangedSubview(metaRow(symbol: "person", text: "适用人群：\(people)", tint: .fdText))
        }
        if let restricted = detail.restrictedPeople, !restricted.isEmpty {
            metaStack.addArrangedSubview(
                metaRow(symbol: "exclamationmark.triangle", text: "禁止人群：\(restricted)", tint: .fdDanger)
            )
        }
        metaStack.isHidden = metaStack.arrangedSubviews.isEmpty
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
        switch viewModel.billingSource {
        case 2:
            feeCard.isHidden = false
            feeTitleLabel.text = detail.name
            feeValueLabel.text = viewModel.timesCardText
            feeValueLabel.textColor = .fdSuccess
        case 3 where viewModel.feeAmountText != nil:
            feeCard.isHidden = false
            feeTitleLabel.text = detail.name
            let unit = viewModel.feeUnitText
            feeValueLabel.text = "\(viewModel.feeAmountText ?? "")/\(unit)"
            feeValueLabel.textColor = .fdPrimary
        default:
            feeCard.isHidden = true
        }
    }

    private func proceedBook() {
        guard !didProceed, !viewModel.isSubmitting else { return }
        didProceed = true
        notice.isHidden = true
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
                    case .purchase(let packageId, let hospitalId, let context):
                        var params = ServiceRoutes.packageDetailParams(
                            packageId: packageId,
                            hospitalId: hospitalId
                        )
                        context.routeParams().forEach { params[$0.key] = $0.value }
                        Router.shared.push("/services/pkg", params: params, from: self)
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
        notice.configure(internalOnly: viewModel.isInternalStation)
        notice.isHidden = false
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

    private func configureConfirm(_ button: UIButton) {
        button.setTitle("确定预约", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .fdFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .fdPrimary
        button.layer.cornerRadius = 22
        button.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
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

private final class CabinBookGalleryView: UIView, UIScrollViewDelegate {

    private let scroll = UIScrollView()
    private let pageControl = UIPageControl()
    private var imageViews: [UIImageView] = []
    private var heightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdProductImageBg
        scroll.isPagingEnabled = true
        scroll.showsHorizontalScrollIndicator = false
        scroll.bounces = false
        scroll.delegate = self
        pageControl.currentPageIndicatorTintColor = .fdPrimary
        pageControl.pageIndicatorTintColor = .fdBorderStrong
        pageControl.isUserInteractionEnabled = false
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

    func setURLs(_ urls: [URL]) {
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews = urls.map { url in
            let image = UIImageView()
            image.contentMode = .scaleAspectFill
            image.clipsToBounds = true
            image.backgroundColor = .fdProductImageBg
            image.kf.setImage(with: url)
            scroll.addSubview(image)
            return image
        }
        pageControl.numberOfPages = urls.count
        pageControl.currentPage = 0
        pageControl.isHidden = urls.count <= 1
        isHidden = urls.isEmpty
        heightConstraint?.update(offset: urls.isEmpty ? 0 : 200)
        scroll.contentOffset = .zero
        setNeedsLayout()
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
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.width
        guard width > 0 else { return }
        pageControl.currentPage = Int(round(scrollView.contentOffset.x / width))
    }
}

private final class CabinHealthNoticeView: UIView {

    var onClose: (() -> Void)?
    var onProceed: (() -> Void)?

    private let card = UIView()
    private let listStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.45)
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        listStack.axis = .vertical
        listStack.spacing = 10

        let title = UILabel()
        title.text = "温馨提示"
        title.font = .fdFont(ofSize: 18, weight: .semibold)
        title.textColor = .fdText
        title.textAlignment = .center

        let standardTitle = UILabel()
        standardTitle.text = "健康筛查标准"
        standardTitle.font = .fdFont(ofSize: 13, weight: .semibold)
        standardTitle.textColor = .fdInfo
        let standardBody = UILabel()
        standardBody.text = "体温 ≥ 37.3℃ 或存在急性呼吸道感染症状者，请勿预约"
        standardBody.font = .fdFont(ofSize: 13, weight: .regular)
        standardBody.textColor = .fdText2
        standardBody.numberOfLines = 0
        let standardBox = UIStackView(arrangedSubviews: [standardTitle, standardBody])
        standardBox.axis = .vertical
        standardBox.spacing = 6
        standardBox.isLayoutMarginsRelativeArrangement = true
        standardBox.layoutMargins = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        let standardWrap = UIView()
        standardWrap.backgroundColor = .fdInfoSoft
        standardWrap.layer.cornerRadius = 8
        standardWrap.addSubview(standardBox)
        standardBox.snp.makeConstraints { $0.edges.equalToSuperview() }

        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
        close.tintColor = .fdSubtext
        close.accessibilityLabel = "关闭"
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let proceed = UIButton(type: .system)
        proceed.setTitle("仍要预约", for: .normal)
        proceed.setTitleColor(.white, for: .normal)
        proceed.titleLabel?.font = .fdFont(ofSize: 16, weight: .semibold)
        proceed.backgroundColor = .fdPrimary
        proceed.layer.cornerRadius = 22
        proceed.addTarget(self, action: #selector(proceedTapped), for: .touchUpInside)

        let body = UIStackView(arrangedSubviews: [title, listStack, standardWrap, proceed])
        body.axis = .vertical
        body.spacing = 16
        card.addSubview(close)
        card.addSubview(body)
        addSubview(card)
        close.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.trailing.equalToSuperview().offset(-8)
            $0.width.height.equalTo(36)
        }
        body.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 28, left: 20, bottom: 20, right: 20))
        }
        proceed.snp.makeConstraints { $0.height.equalTo(44) }
        card.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(28)
            $0.trailing.equalToSuperview().offset(-28)
            $0.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(internalOnly: Bool) {
        listStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if internalOnly {
            listStack.addArrangedSubview(
                line("此健康驿站服务仅限【红色工牌员工】预约；", color: .fdDanger)
            )
        }
        listStack.addArrangedSubview(
            line("为确保筛查结果准确，并保障您和他人的健康安全，如有发热（≥37.3℃）、感冒、咳嗽、咽痛等急性感染症状，请暂缓预约任何服务。", color: .fdText2)
        )
        listStack.addArrangedSubview(
            line("建议待症状消失、体温正常满24小时后再进行预约，感谢您的理解与配合。", color: .fdText2)
        )
    }

    private func line(_ text: String, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 14, weight: .regular)
        label.textColor = color
        label.numberOfLines = 0
        return label
    }

    @objc private func closeTapped() { onClose?() }

    @objc private func proceedTapped() { onProceed?() }
}
