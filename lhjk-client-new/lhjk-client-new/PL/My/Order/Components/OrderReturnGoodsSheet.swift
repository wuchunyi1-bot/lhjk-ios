import UIKit
import SnapKit

/// 去退货客服指引底部弹窗 — 对齐 Figma 5607:21157 设计稿
/// 引导用户联系客服办理实物商品退货
final class OrderReturnGoodsSheet: UIViewController {

    /// 默认客服电话
    static let defaultPhoneNumber = "0755-61909838"

    var onClose: (() -> Void)?
    var onCall: (() -> Void)?

    private let phoneNumber: String

    private let dimView = UIView()
    private let panel = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .custom)

    private let noticeBar = UIView()
    private let noticeIconView = UIImageView()
    private let noticeLabel = UILabel()

    private let contactCard = UIView()
    private let phoneTitleLabel = UILabel()
    private let phoneNumberLabel = UILabel()
    private let csAvatarImageView = UIImageView()

    private let callButton = UIButton(type: .system)

    private var panelBottomConstraint: Constraint?

    init(phoneNumber: String = defaultPhoneNumber) {
        let trimmed = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        self.phoneNumber = trimmed.isEmpty ? Self.defaultPhoneNumber : trimmed
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        buildUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    // MARK: - UI Construction

    private func buildUI() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        dimView.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleDismiss))
        dimView.addGestureRecognizer(tap)
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        panel.backgroundColor = .fdSurface
        panel.layer.cornerRadius = 16
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(panel)
        panel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            panelBottomConstraint = $0.bottom.equalToSuperview().offset(360).constraint
        }

        // Title
        titleLabel.text = "去退货"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .fdText
        titleLabel.textAlignment = .center
        panel.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(25)
        }

        // Close Button
        closeButton.setImage(UIImage(named: "order_return_close"), for: .normal)
        closeButton.contentMode = .center
        closeButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        panel.addSubview(closeButton)
        closeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-8)
            $0.centerY.equalTo(titleLabel)
            $0.size.equalTo(44)
        }

        // Notice Bar
        let noticeBgColor = UIColor(hexString: "#FFF9F6")
        noticeBar.backgroundColor = noticeBgColor
        noticeBar.layer.cornerRadius = 8
        noticeBar.layer.masksToBounds = true
        panel.addSubview(noticeBar)
        noticeBar.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(33)
        }

        noticeIconView.image = UIImage(named: "order_return_notice_speaker")
        noticeIconView.contentMode = .scaleAspectFit
        noticeBar.addSubview(noticeIconView)
        noticeIconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(10)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(18)
        }

        noticeLabel.text = "实物商品需要寄回，请联系客服办理退货"
        noticeLabel.font = .fdFont(ofSize: 12, weight: .regular)
        noticeLabel.textColor = .fdPrimary
        noticeBar.addSubview(noticeLabel)
        noticeLabel.snp.makeConstraints {
            $0.leading.equalTo(noticeIconView.snp.trailing).offset(6)
            $0.trailing.lessThanOrEqualToSuperview().offset(-10)
            $0.centerY.equalToSuperview()
        }

        // Contact Card
        contactCard.backgroundColor = noticeBgColor
        contactCard.layer.cornerRadius = 12
        contactCard.layer.masksToBounds = false
        panel.addSubview(contactCard)
        contactCard.snp.makeConstraints {
            $0.top.equalTo(noticeBar.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(87)
        }

        phoneTitleLabel.text = "客服电话"
        phoneTitleLabel.font = .fdFont(ofSize: 16, weight: .medium)
        phoneTitleLabel.textColor = .fdText
        contactCard.addSubview(phoneTitleLabel)
        phoneTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.leading.equalToSuperview().offset(20)
        }

        phoneNumberLabel.text = phoneNumber
        phoneNumberLabel.font = .fdFont(ofSize: 18, weight: .medium)
        phoneNumberLabel.textColor = .fdText
        contactCard.addSubview(phoneNumberLabel)
        phoneNumberLabel.snp.makeConstraints {
            $0.top.equalTo(phoneTitleLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(20)
        }

        csAvatarImageView.image = UIImage(named: "order_return_cs_avatar")
        csAvatarImageView.contentMode = .scaleAspectFit
        contactCard.addSubview(csAvatarImageView)
        csAvatarImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-8)
            $0.bottom.equalToSuperview()
            $0.width.equalTo(122)
            $0.height.equalTo(105)
        }

        // Call Button
        callButton.setTitle("点击拨打客服电话", for: .normal)
        callButton.setTitleColor(.white, for: .normal)
        callButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        callButton.backgroundColor = .fdPrimary
        callButton.layer.cornerRadius = 22
        callButton.layer.masksToBounds = true
        callButton.addTarget(self, action: #selector(handleCall), for: .touchUpInside)
        panel.addSubview(callButton)
        callButton.snp.makeConstraints {
            $0.top.equalTo(contactCard.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
            $0.bottom.equalTo(panel.safeAreaLayoutGuide).offset(-12)
        }
    }

    // MARK: - Animations

    private func animateIn() {
        panelBottomConstraint?.update(offset: 0)
        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut]) {
            self.dimView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        panelBottomConstraint?.update(offset: 360)
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseIn]) {
            self.dimView.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            completion()
        }
    }

    // MARK: - Actions

    @objc private func handleDismiss() {
        animateOut { [weak self] in
            self?.dismiss(animated: false) {
                self?.onClose?()
            }
        }
    }

    @objc private func handleCall() {
        onCall?()
        callCustomerService()
    }

    private func callCustomerService() {
        let rawPhone = phoneNumber
        let sanitized = rawPhone.filter { $0.isNumber }
        guard !sanitized.isEmpty, let url = URL(string: "tel://\(sanitized)") else {
            copyPhoneAndToast(rawPhone)
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { [weak self] success in
                if !success {
                    self?.copyPhoneAndToast(rawPhone)
                }
            }
        } else {
            copyPhoneAndToast(rawPhone)
        }
    }

    private func copyPhoneAndToast(_ phone: String) {
        UIPasteboard.general.string = phone
        FDToast.show("客服电话已复制：\(phone)", duration: 1.5)
    }
}

// MARK: - Flow Coordinator

enum OrderReturnGoodsFlow {

    /// 订单列表点击「去退货」统一入口
    static func present(
        from presenter: UIViewController,
        order: MOrder,
        onSuccess: (() -> Void)? = nil
    ) {
        let sheet = OrderReturnGoodsSheet()
        sheet.onCall = {
            onSuccess?()
        }
        presenter.present(sheet, animated: false)
    }

    /// 订单详情点击「去退货」统一入口
    static func present(
        from presenter: UIViewController,
        detail: AppOrderDetailBO,
        onSuccess: (() -> Void)? = nil
    ) {
        let sheet = OrderReturnGoodsSheet()
        sheet.onCall = {
            onSuccess?()
        }
        presenter.present(sheet, animated: false)
    }
}
