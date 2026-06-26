import UIKit
import SnapKit

/// 注销账户页
/// PRD: 02_用户_我的设置_v1.0 §5.6
/// 原型: funde-client prototype/src/views/me/settings/CancelAccountView.vue
///
/// 布局:
///   警告头部（⚠️ 注销后，您将放弃以下资产和权益）
///   5 个影响说明卡片（账户信息 / 服务权益 / 交易记录 / 服务记录 / 健康数据）
///   底部红色"申请注销"按钮
///
/// 流程:
///   点击申请注销 → 检查未完成订单 → 拦截/确认弹窗 → 清除登录态 → 结果页
final class CancelAccountViewController: BaseViewController {

    // MARK: - Step

    private enum Step {
        case notice, result
    }

    private var step: Step = .notice
    private var isSubmitting = false

    // MARK: - Cancel impact items

    private let cancelItems: [(title: String, desc: String)] = [
        ("账户信息", "身份信息、账户信息、会员积分等将被清空，且无法恢复。"),
        ("服务权益", "您已购买的服务将全部失效（包括活动积分、卡券、服务、未激活的权益等）将全部清空。"),
        ("交易记录", "交易记录将被清空，请确保所有交易已完结且无纠纷。注销后，历史订单可能产生的退款等资金退回权益将视为自动放弃。"),
        ("服务记录", "与三好服务团队的交流记录将被清空，无法恢复。"),
        ("健康数据", "各项身体数据将被清空，无法恢复。"),
    ]

    /// 拦截注销的订单状态
    private let unfinishedOrderStatuses: Set<String> = ["pending_use", "in_progress", "pending_review"]

    // MARK: - UI (notice)

    private let scrollView = UIScrollView()
    private var submitBtn: UIButton!
    private var noticeContainer: UIView!
    private var resultContainer: UIView!

    // MARK: - Lifecycle

    override func setupUI() {
        title = "注销账户"
        view.backgroundColor = .fdBg

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let contentView = UIView()
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        // MARK: Notice Step

        noticeContainer = UIView()
        contentView.addSubview(noticeContainer)
        noticeContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        // Warning header
        let warningView = UIView()
        noticeContainer.addSubview(warningView)
        warningView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        let warningCircle = UIView()
        warningCircle.backgroundColor = UIColor(hexString: "#FCE9E6")
        warningCircle.layer.cornerRadius = 18
        warningView.addSubview(warningCircle)
        warningCircle.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(36)
        }

        let warningIcon = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))
        warningIcon.tintColor = UIColor(hexString: "#D93025")
        warningIcon.contentMode = .scaleAspectFit
        warningCircle.addSubview(warningIcon)
        warningIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }

        let warningLabel = UILabel()
        warningLabel.text = "注销后，您将放弃以下资产和权益："
        warningLabel.font = .fdBodyBold
        warningLabel.textColor = .fdText
        warningLabel.numberOfLines = 0
        warningView.addSubview(warningLabel)
        warningLabel.snp.makeConstraints { make in
            make.leading.equalTo(warningCircle.snp.trailing).offset(10)
            make.trailing.centerY.equalToSuperview()
        }

        // Impact cards
        var previousCard: UIView?
        for item in cancelItems {
            let card = makeImpactCard(title: item.title, desc: item.desc)
            noticeContainer.addSubview(card)
            card.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                if let prev = previousCard {
                    make.top.equalTo(prev.snp.bottom).offset(10)
                } else {
                    make.top.equalTo(warningView.snp.bottom).offset(16)
                }
            }
            previousCard = card
        }

        // Submit button area (fixed at bottom)
        let bottomArea = UIView()
        noticeContainer.addSubview(bottomArea)
        bottomArea.snp.makeConstraints { make in
            make.top.equalTo((previousCard ?? warningView).snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-32)
            make.height.equalTo(54)
        }

        submitBtn = UIButton(type: .system)
        submitBtn.setTitle("申请注销", for: .normal)
        submitBtn.titleLabel?.font = .fdBodyBold
        submitBtn.setTitleColor(.white, for: .normal)
        submitBtn.backgroundColor = UIColor(hexString: "#D93025")
        submitBtn.layer.cornerRadius = 27
        submitBtn.addTarget(self, action: #selector(handleCancelAccount), for: .touchUpInside)
        bottomArea.addSubview(submitBtn)
        submitBtn.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // MARK: Result Step

        resultContainer = UIView()
        resultContainer.isHidden = true
        contentView.addSubview(resultContainer)
        resultContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        let checkIcon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkIcon.tintColor = UIColor(hexString: "#2DB983")
        checkIcon.contentMode = .scaleAspectFit
        resultContainer.addSubview(checkIcon)
        checkIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(100)
            make.size.equalTo(64)
        }

        let resultTitle = UILabel()
        resultTitle.text = "注销成功"
        resultTitle.font = .fdH2
        resultTitle.textColor = .fdText
        resultTitle.textAlignment = .center
        resultContainer.addSubview(resultTitle)
        resultTitle.snp.makeConstraints { make in
            make.top.equalTo(checkIcon.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }

        let resultDesc = UILabel()
        resultDesc.text = "您的账户已成功注销，即将跳转至注册页面。"
        resultDesc.font = .fdBody
        resultDesc.textColor = .fdSubtext
        resultDesc.textAlignment = .center
        resultDesc.numberOfLines = 0
        resultContainer.addSubview(resultDesc)
        resultDesc.snp.makeConstraints { make in
            make.top.equalTo(resultTitle.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
        }
    }

    // MARK: - Card Builder

    private func makeImpactCard(title: String, desc: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .fdBodyBold
        titleLabel.textColor = .fdText
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        let descLabel = UILabel()
        descLabel.text = desc
        descLabel.font = .fdCaption
        descLabel.textColor = .fdSubtext
        descLabel.numberOfLines = 0
        card.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
        }

        return card
    }

    // MARK: - Cancel Flow

    @objc private func handleCancelAccount() {
        guard !isSubmitting else { return }

        // Check for unfinished orders (V1.0: default allow if no order service available)
        if hasUnfinishedOrders() {
            showUnfinishedOrdersAlert()
        } else {
            showCancelConfirmation()
        }
    }

    private func hasUnfinishedOrders() -> Bool {
        // V1.0: 当前无订单服务，默认无未完成订单，允许进入注销确认
        // 后续接入订单服务后，检查 status ∈ {pending_use, in_progress, pending_review}
        return false
    }

    private func showUnfinishedOrdersAlert() {
        let alert = UIAlertController(
            title: "暂无法注销账户",
            message: "您当前还有未完成的订单或服务，请处理完成后再申请注销。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "我知道了", style: .cancel))
        alert.addAction(UIAlertAction(title: "查看订单", style: .default) { [weak self] _ in
            Router.shared.push("/orders")
        })
        present(alert, animated: true)
    }

    private func showCancelConfirmation() {
        let alert = UIAlertController(
            title: "注销确认",
            message: "注销后您将失去本账户的所有信息，请谨慎操作",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定注销", style: .destructive) { [weak self] _ in
            self?.performCancellation()
        })
        present(alert, animated: true)
    }

    private func performCancellation() {
        isSubmitting = true
        submitBtn.isEnabled = false
        submitBtn.setTitle("处理中...", for: .normal)
        submitBtn.alpha = 0.6

        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self else { return }

            // Clear auth state
            LoginService.shared.clearSession()
            UserManager.shared.clear()

            // Show result
            self.noticeContainer.isHidden = true
            self.resultContainer.isHidden = false
            self.step = .result
            self.title = ""

            // Redirect after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                Router.shared.setRoot("/login")
            }
        }
    }
}
