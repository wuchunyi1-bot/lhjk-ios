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
        view.backgroundColor = UIColor(hexString: "#FDF6F3")
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
        titleLabel.textColor = UIColor(hexString: "#1F2942")

        let subtitleLabel = UILabel()
        subtitleLabel.text = "先绑定企业发放的权益卡，再兑换健康服务套餐"
        subtitleLabel.font = .fdFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = UIColor(hexString: "#8591AB")
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }

    // MARK: - Steps

    private func buildStepsSection() -> UIView {
        let container = UIView()

        // 竖线自绘（浅橙色 1pt）
        let timelineLine = UIView()
        timelineLine.backgroundColor = UIColor(hexString: "#FFD9C7")

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
        redeemSubtitleLabel.textColor = UIColor(hexString: "#8591AB")
        redeemSubtitleLabel.numberOfLines = 1
        redeemSubtitleLabel.lineBreakMode = .byTruncatingTail

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
            $0.top.equalTo(step1Header.snp.bottom)
            $0.bottom.equalTo(step2Header.snp.top)
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
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        card.isUserInteractionEnabled = true

        // 1. 图标 44x44
        let iconView = UIImageView(image: UIImage(named: iconName))
        iconView.contentMode = .scaleAspectFit
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 22
        iconView.backgroundColor = UIColor(hexString: "#FFF2E6")
        card.addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.leading.top.equalToSuperview().offset(12)
            $0.size.equalTo(44)
        }

        // 2. 标题与副标题
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .fdFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#1F2942")

        let subLabel = subtitleView ?? UILabel()
        if let subtitle {
            subLabel.text = subtitle
            subLabel.font = .fdFont(ofSize: 12, weight: .regular)
            subLabel.textColor = UIColor(hexString: "#8591AB")
            subLabel.numberOfLines = 1
            subLabel.lineBreakMode = .byTruncatingTail
        }

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.isUserInteractionEnabled = false
        card.addSubview(textStack)
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(11)
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalTo(iconView)
        }

        // 3. 卡片内部自绘分割线 (top 72pt, 0.5pt)
        let divider = UIView()
        divider.backgroundColor = UIColor(hexString: "#F6ECE4")
        divider.isUserInteractionEnabled = false
        card.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(72)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(0.5)
        }

        // 4. 底部按钮与提示文案
        let ctaButton = UILabel()
        ctaButton.text = cta
        ctaButton.font = .fdFont(ofSize: 12, weight: .medium)
        ctaButton.textColor = .white
        ctaButton.textAlignment = .center
        ctaButton.backgroundColor = .fdPrimary
        ctaButton.layer.cornerRadius = 14
        ctaButton.clipsToBounds = true
        ctaButton.isUserInteractionEnabled = false
        card.addSubview(ctaButton)
        ctaButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-11)
            make.width.equalTo(70)
            make.height.equalTo(28)
        }

        let footerHintLabel = UILabel()
        footerHintLabel.text = footerHint
        footerHintLabel.font = .fdFont(ofSize: 12, weight: .regular)
        footerHintLabel.textColor = UIColor(hexString: "#8591AB")
        footerHintLabel.isUserInteractionEnabled = false
        card.addSubview(footerHintLabel)
        footerHintLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.lessThanOrEqualTo(ctaButton.snp.leading).offset(-8)
            make.centerY.equalTo(ctaButton)
        }

        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))
        return card
    }

    private func refreshCountUI() {
        if availableCount > 0 {
            redeemSubtitleLabel.text = "当前有\(availableCount)张权益卡可用"
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
