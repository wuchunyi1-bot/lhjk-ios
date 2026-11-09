import Combine
import Kingfisher
import SnapKit
import UIKit

/// 体检项目预约详情。`GET /v1/serviceItem/detail`，不含日期和时段。
final class ExamPackageDetailViewController: BaseViewController {

    private let viewModel: ExamPackageDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let galleryStack = UIStackView()
    private let nameLabel = UILabel()
    private let metaStack = UIStackView()
    private let introTitle = UILabel()
    private let introLabel = UILabel()
    private let noticeTitle = UILabel()
    private let noticeStack = UIStackView()
    private let feeTitle = UILabel()
    private let feeNameLabel = UILabel()
    private let feePriceLabel = UILabel()
    private let missingLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let bottomBar = UIView()
    private let bottomPriceLabel = UILabel()
    private let bookButton = UIButton(type: .system)

    init(configId: String, listPriceText: String?) {
        viewModel = ExamPackageDetailViewModel(configId: configId, listPriceText: listPriceText)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "项目预约"
        view.backgroundColor = .fdBg

        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        view.addSubview(bottomBar)
        scrollView.addSubview(contentView)

        bottomBar.backgroundColor = .fdSurface
        bottomPriceLabel.font = .fdFont(ofSize: 20, weight: .semibold)
        bottomPriceLabel.textColor = .fdPrimary
        bookButton.setTitle("去预约", for: .normal)
        bookButton.setTitleColor(.white, for: .normal)
        bookButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .semibold)
        bookButton.backgroundColor = .fdPrimary
        bookButton.layer.cornerRadius = 22
        bookButton.addTarget(self, action: #selector(bookTapped), for: .touchUpInside)
        bottomBar.addSubview(bottomPriceLabel)
        bottomBar.addSubview(bookButton)

        nameLabel.font = .fdH2
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 0
        introLabel.font = .fdBody
        introLabel.textColor = .fdText
        introLabel.numberOfLines = 0
        feeNameLabel.font = .fdBody
        feeNameLabel.textColor = .fdText
        feeNameLabel.numberOfLines = 0
        feePriceLabel.font = .fdFont(ofSize: 16, weight: .semibold)
        feePriceLabel.textColor = .fdPrimary
        missingLabel.font = .fdBody
        missingLabel.textColor = .fdSubtext
        missingLabel.textAlignment = .center
        missingLabel.text = "未找到该项目"
        spinner.color = .fdPrimary
        spinner.hidesWhenStopped = true

        galleryStack.axis = .vertical
        galleryStack.spacing = 0
        metaStack.axis = .vertical
        metaStack.spacing = 8
        metaStack.alignment = .leading
        noticeStack.axis = .vertical
        noticeStack.spacing = 8
        noticeStack.alignment = .leading

        introTitle.text = "项目介绍"
        noticeTitle.text = "预约须知"
        feeTitle.text = "费用信息"
        [introTitle, noticeTitle, feeTitle].forEach {
            $0.font = .fdFont(ofSize: 16, weight: .semibold)
            $0.textColor = .fdText
        }

        let introCard = card(introTitle, introLabel)
        let noticeCard = card(noticeTitle, noticeStack)
        let feeRow = UIStackView(arrangedSubviews: [feeNameLabel, feePriceLabel])
        feeRow.axis = .horizontal
        feeRow.alignment = .firstBaseline
        feeRow.spacing = 12
        feePriceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let feeCard = card(feeTitle, feeRow)
        introCard.tag = 1
        noticeCard.tag = 2
        feeCard.tag = 3

        let sectionStack = UIStackView(arrangedSubviews: [introCard, noticeCard, feeCard])
        sectionStack.axis = .vertical
        sectionStack.spacing = 12

        contentView.addSubview(galleryStack)
        contentView.addSubview(nameLabel)
        contentView.addSubview(metaStack)
        contentView.addSubview(sectionStack)
        contentView.addSubview(missingLabel)
        view.addSubview(spinner)

        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(bottomBar.snp.top)
        }
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }
        galleryStack.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(galleryStack.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        metaStack.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalTo(nameLabel)
        }
        sectionStack.snp.makeConstraints {
            $0.top.equalTo(metaStack.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-16)
        }
        missingLabel.snp.makeConstraints {
            $0.center.equalTo(scrollView)
        }
        spinner.snp.makeConstraints { $0.center.equalTo(scrollView) }
        bottomBar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }
        bottomPriceLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
        }
        bookButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(bottomPriceLabel)
            $0.width.equalTo(120)
            $0.height.equalTo(44)
        }

    }

    override func bindViewModel() {
        viewModel.$detail
            .combineLatest(viewModel.$isLoading, viewModel.$isMissing)
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
        let detail = viewModel.detail
        let showMissing = viewModel.isMissing && !viewModel.isLoading
        missingLabel.isHidden = !showMissing
        scrollView.isHidden = detail == nil
        bottomBar.isHidden = detail == nil
        if viewModel.isLoading, detail == nil {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
        guard let detail else { return }

        nameLabel.text = detail.name
        rebuildGallery(detail.galleryURLs)
        rebuildMeta(detail)
        introLabel.text = detail.descriptionText
        contentView.viewWithTag(1)?.isHidden = (detail.descriptionText ?? "").isEmpty
        rebuildNotices(detail.noticeLines)
        contentView.viewWithTag(2)?.isHidden = detail.noticeLines.isEmpty
        feeNameLabel.text = detail.name
        feePriceLabel.text = viewModel.priceText
        contentView.viewWithTag(3)?.isHidden = viewModel.priceText == nil
        bottomPriceLabel.text = viewModel.priceText
        bottomPriceLabel.isHidden = viewModel.priceText == nil
        bookButton.setTitle(detail.needsPurchase ? "去购买" : "去预约", for: .normal)
    }

    private func rebuildGallery(_ urls: [URL]) {
        galleryStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        galleryStack.isHidden = urls.isEmpty
        for url in urls {
            let image = UIImageView()
            image.contentMode = .scaleAspectFill
            image.clipsToBounds = true
            image.backgroundColor = .fdSurface
            image.kf.setImage(with: url)
            galleryStack.addArrangedSubview(image)
            image.snp.makeConstraints { $0.height.equalTo(200) }
        }
    }

    private func rebuildMeta(_ detail: ServiceItemDetailVO) {
        metaStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let duration = detail.durationText {
            metaStack.addArrangedSubview(metaLine("单次时长：\(duration)", color: .fdText))
        }
        let dict = DictionaryCacheService.shared
        if let people = dict.joinedLabels(parent: .serviceApplicablePeople, raw: detail.applicablePeople) {
            metaStack.addArrangedSubview(metaLine("适用人群：\(people)", color: .fdText))
        }
        if let restricted = dict.joinedLabels(parent: .serviceRestrictedPeople, raw: detail.restrictedPeople) {
            metaStack.addArrangedSubview(metaLine("禁止人群：\(restricted)", color: .fdDanger))
        }
    }

    private func rebuildNotices(_ lines: [String]) {
        noticeStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for line in lines {
            noticeStack.addArrangedSubview(metaLine(line, color: .fdText))
        }
    }

    private func metaLine(_ text: String, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .fdBody
        label.textColor = color
        label.numberOfLines = 0
        return label
    }

    private func card(_ title: UILabel, _ body: UIView) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        let stack = UIStackView(arrangedSubviews: [title, body])
        stack.axis = .vertical
        stack.spacing = 10
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
        return card
    }

    @objc private func bookTapped() {
        guard let detail = viewModel.detail else { return }
        if let target = viewModel.purchaseTarget() {
            confirmPurchase(name: detail.name, packageId: target.packageId, hospitalId: target.hospitalId)
            return
        }
        showToastAlert("当前暂无法直接提交预约")
    }

    private func confirmPurchase(name: String, packageId: String, hospitalId: String) {
        let alert = UIAlertController(
            title: "确认预约",
            message: "「\(name)」需要购买后才能预约。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "再想想", style: .cancel))
        alert.addAction(UIAlertAction(title: "去购买", style: .default) { [weak self] _ in
            guard let self else { return }
            let params = ServiceRoutes.packageDetailParams(
                packageId: packageId,
                hospitalId: hospitalId.isEmpty ? nil : hospitalId
            )
            Router.shared.push("/services/pkg", params: params, from: self)
        })
        present(alert, animated: true)
    }
}
