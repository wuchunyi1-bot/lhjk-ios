import UIKit
import SnapKit

/// 知情同意确认弹窗 — 对齐 funde `LoginView` agreement sheet / PRD AUTH-06
final class AgreementConsentSheet: UIViewController {

    enum PendingAction {
        case smsLogin
        case passwordLogin
        case wechatLogin
    }

    var onAgreeAndContinue: (() -> Void)?
    var onLater: (() -> Void)?
    var onOpenUserAgreement: (() -> Void)?
    var onOpenPrivacyPolicy: (() -> Void)?
    var onOpenConsent: (() -> Void)?

    private let dimView = UIView()
    private let panel = UIView()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    private func buildUI() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        panel.backgroundColor = .fdSurface
        panel.layer.cornerRadius = 16
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(panel)
        panel.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }

        let title = UILabel()
        title.text = "请先阅读并同意相关协议"
        title.font = .fdMyH3
        title.textColor = .fdText
        title.numberOfLines = 0

        let desc = UILabel()
        desc.text = "请先阅读并同意用户协议、隐私政策与健康管理服务知情同意书"
        desc.font = .fdLoginMeta
        desc.textColor = .fdSubtext
        desc.numberOfLines = 0

        let links = UIStackView(arrangedSubviews: [
            makeLinkButton(title: "查看用户协议", action: #selector(tapUser)),
            makeLinkButton(title: "查看隐私政策", action: #selector(tapPrivacy)),
            makeLinkButton(title: "查看知情同意书", action: #selector(tapConsent)),
        ])
        links.axis = .vertical
        links.spacing = 4
        links.alignment = .leading

        let later = UIButton(type: .system)
        later.setTitle("稍后再看", for: .normal)
        later.titleLabel?.font = .fdLoginInput
        later.setTitleColor(.fdText, for: .normal)
        later.backgroundColor = .fdSurface
        later.layer.cornerRadius = 22
        later.layer.borderWidth = 1
        later.layer.borderColor = UIColor.fdBorder.cgColor
        later.addTarget(self, action: #selector(tapLater), for: .touchUpInside)

        let agree = UIButton(type: .system)
        agree.setTitle("同意并继续", for: .normal)
        agree.titleLabel?.font = .fdLoginInput
        agree.setTitleColor(.white, for: .normal)
        agree.backgroundColor = .fdPrimary
        agree.layer.cornerRadius = 22
        agree.addTarget(self, action: #selector(tapAgree), for: .touchUpInside)

        let actions = UIStackView(arrangedSubviews: [later, agree])
        actions.axis = .horizontal
        actions.spacing = 12
        actions.distribution = .fillEqually
        later.snp.makeConstraints { $0.height.equalTo(44) }
        agree.snp.makeConstraints { $0.height.equalTo(44) }

        let stack = UIStackView(arrangedSubviews: [title, desc, links, actions])
        stack.axis = .vertical
        stack.spacing = 14
        panel.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(panel.safeAreaLayoutGuide).offset(-12)
        }
    }

    private func makeLinkButton(title: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .fdLoginMeta
        btn.setTitleColor(.fdPrimary, for: .normal)
        btn.contentHorizontalAlignment = .leading
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }

    @objc private func tapUser() { onOpenUserAgreement?() }
    @objc private func tapPrivacy() { onOpenPrivacyPolicy?() }
    @objc private func tapConsent() { onOpenConsent?() }

    @objc private func tapLater() {
        dismiss(animated: true) { [weak self] in self?.onLater?() }
    }

    @objc private func tapAgree() {
        dismiss(animated: true) { [weak self] in self?.onAgreeAndContinue?() }
    }
}
