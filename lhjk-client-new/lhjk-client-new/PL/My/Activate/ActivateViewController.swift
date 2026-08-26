import SnapKit
import UIKit

/// 激活兑换 Hub — 对齐 Figma 4086:3885 / funde `ActivateView`
final class ActivateViewController: BaseViewController {

    private let voucherService: VoucherService
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var loadTask: Task<Void, Never>?
    private var availableCount = 0

    private let redeemSubtitleLabel = UILabel()

    init(voucherService: VoucherService = AppContainer.shared.voucherService) {
        self.voucherService = voucherService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit { loadTask?.cancel() }

    override func setupUI() {
        title = "激活兑换"
        view.backgroundColor = .fdBg
        hidesBottomBarWhenPushed = true

        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }

        contentStack.axis = .vertical
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.width.equalTo(scrollView).offset(-32)
        }

        contentStack.addArrangedSubview(buildHeroSection())
        contentStack.setCustomSpacing(24, after: contentStack.arrangedSubviews.last!)
        contentStack.addArrangedSubview(buildStepsSection())

        refreshCountUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            let count = await self.voucherService.refreshAvailableBenefitCount()
            await MainActor.run {
                self.availableCount = count
                self.refreshCountUI()
            }
        }
    }

    // MARK: - Hero

    private func buildHeroSection() -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = "权益卡服务"
        titleLabel.font = .fdFont(ofSize: 22, weight: .medium)
        titleLabel.textColor = .fdText

        let subtitleLabel = UILabel()
        subtitleLabel.text = "先绑定企业发放的权益卡，再兑换健康服务套餐"
        subtitleLabel.font = .fdFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .fdTabInactive
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }

    // MARK: - Steps

    private func buildStepsSection() -> UIView {
        let container = UIView()

        let timelineLine = UIImageView(image: UIImage(named: "activate_step_line"))
        timelineLine.contentMode = .scaleToFill

        let step1Header = makeStepHeader(title: "步骤一")
        let bindCard = makeActionCard(
            iconName: "activate_bind_icon",
            title: "绑定权益卡",
            subtitle: "输入卡密或扫码，将权益卡放入我的卡券",
            footerHint: "绑定后可兑换服务套餐",
            cta: "去绑定",
            action: #selector(tapBind)
        )

        let step2Header = makeStepHeader(title: "步骤二")
        redeemSubtitleLabel.font = .fdFont(ofSize: 12, weight: .regular)
        redeemSubtitleLabel.textColor = .fdTabInactive
        redeemSubtitleLabel.numberOfLines = 0

        let redeemCard = makeActionCard(
            iconName: "activate_redeem_icon",
            title: "兑换健康服务套餐",
            subtitleView: redeemSubtitleLabel,
            footerHint: "选择专属健康服务套餐",
            cta: "去兑换",
            action: #selector(tapRedeem)
        )

        container.addSubview(timelineLine)
        container.addSubview(step1Header)
        container.addSubview(bindCard)
        container.addSubview(step2Header)
        container.addSubview(redeemCard)

        step1Header.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        bindCard.snp.makeConstraints {
            $0.top.equalTo(step1Header.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(22)
            $0.trailing.equalToSuperview()
            $0.height.equalTo(122)
        }

        step2Header.snp.makeConstraints {
            $0.top.equalTo(bindCard.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
        }

        redeemCard.snp.makeConstraints {
            $0.top.equalTo(step2Header.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(22)
            $0.trailing.bottom.equalToSuperview()
            $0.height.equalTo(122)
        }

        timelineLine.snp.makeConstraints {
            $0.width.equalTo(1)
            $0.centerX.equalTo(step1Header.snp.leading).offset(8)
            $0.top.equalTo(step1Header.snp.centerY)
            $0.bottom.equalTo(step2Header.snp.centerY)
        }

        return container
    }

    private func makeStepHeader(title: String) -> UIView {
        let dot = UIImageView(image: UIImage(named: "activate_step_dot"))
        dot.contentMode = .scaleAspectFit
        dot.snp.makeConstraints { $0.size.equalTo(16) }

        let label = UILabel()
        label.text = title
        label.font = .fdFont(ofSize: 14, weight: .medium)
        label.textColor = .fdPrimary

        let row = UIStackView(arrangedSubviews: [dot, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 6
        return row
    }

    private func makeActionCard(
        iconName: String,
        title: String,
        subtitle: String? = nil,
        subtitleView: UILabel? = nil,
        footerHint: String,
        cta: String,
        action: Selector
    ) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        card.isUserInteractionEnabled = true

        let iconView = UIImageView(image: UIImage(named: iconName))
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { $0.size.equalTo(44) }

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .fdFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .fdText

        let subLabel = subtitleView ?? UILabel()
        if let subtitle {
            subLabel.text = subtitle
            subLabel.font = .fdFont(ofSize: 12, weight: .regular)
            subLabel.textColor = .fdTabInactive
            subLabel.numberOfLines = 0
        }

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading

        let topRow = UIStackView(arrangedSubviews: [iconView, textStack])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 11

        let footerHintLabel = UILabel()
        footerHintLabel.text = footerHint
        footerHintLabel.font = .fdFont(ofSize: 12, weight: .regular)
        footerHintLabel.textColor = .fdTabInactive
        footerHintLabel.numberOfLines = 2

        let ctaLabel = UILabel()
        ctaLabel.text = cta
        ctaLabel.font = .fdFont(ofSize: 12, weight: .medium)
        ctaLabel.textColor = .white
        ctaLabel.textAlignment = .center
        ctaLabel.backgroundColor = .fdPrimary
        ctaLabel.layer.cornerRadius = 14
        ctaLabel.clipsToBounds = true
        ctaLabel.snp.makeConstraints {
            $0.width.equalTo(70)
            $0.height.equalTo(28)
        }

        let footerRow = UIStackView(arrangedSubviews: [footerHintLabel, ctaLabel])
        footerRow.axis = .horizontal
        footerRow.alignment = .center
        footerRow.spacing = 8

        let inner = UIStackView(arrangedSubviews: [topRow, footerRow])
        inner.axis = .vertical
        inner.spacing = 12
        inner.isUserInteractionEnabled = false

        card.addSubview(inner)
        inner.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }

        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))
        return card
    }

    private func refreshCountUI() {
        if availableCount > 0 {
            redeemSubtitleLabel.text = "当前有 \(availableCount) 张权益卡可用"
        } else {
            redeemSubtitleLabel.text = "暂无可用权益卡，先去绑定"
        }
    }

    @objc private func tapBind() {
        Router.shared.push("/activate/bind", from: self)
    }

    @objc private func tapRedeem() {
        Router.shared.push("/activate/redeem", from: self)
    }
}
