import UIKit
import SnapKit

/// 版本升级弹窗背景渐变视图（对齐 Figma：#FFF9EB → #FFFFFF）
final class AppUpdateGradientView: UIView {

    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    private var gradientLayer: CAGradientLayer {
        // swiftlint:disable:next force_cast
        layer as! CAGradientLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }

    private func setupGradient() {
        gradientLayer.colors = [
            UIColor(hexString: "#FFF9EB").cgColor,
            UIColor.white.cgColor,
            UIColor.white.cgColor,
        ]
        gradientLayer.locations = [0.0, 0.46, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    }
}

/// App 版本更新提示弹窗（对齐 Figma 设计稿 5704:4691 / 非强制更新）
final class AppUpdateDialogViewController: UIViewController {

    var onConfirmUpdate: (() -> Void)?
    var onDismiss: (() -> Void)?

    private let info: AppVersionCheckInfo

    private let dimView = UIView()
    private let cardBackgroundView = AppUpdateGradientView()
    private let illustrationView = UIImageView()
    private let closeButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let sectionTitleLabel = UILabel()
    private let contentTextView = UITextView()
    private let laterButton = UIButton(type: .custom)
    private let updateButton = UIButton(type: .custom)
    private let buttonStack = UIStackView()

    init(info: AppVersionCheckInfo) {
        self.info = info
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareAnimationState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playAppearAnimation()
    }

    private func buildUI() {
        view.backgroundColor = .clear

        // 1. 半透明遮罩
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        if !info.isForce {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleDimTap))
            dimView.addGestureRecognizer(tap)
        }

        // 2. 弹窗卡片背景（圆角 20 + 浅黄到白渐变）
        cardBackgroundView.layer.cornerRadius = 20
        cardBackgroundView.layer.masksToBounds = true
        view.addSubview(cardBackgroundView)
        cardBackgroundView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(319)
        }

        // 3. 顶部 3D 插画（使用本地已落盘的 version_check 切图，溢出卡片顶部 81pt）
        illustrationView.image = UIImage(named: "version_check")
        illustrationView.contentMode = .scaleAspectFit
        view.addSubview(illustrationView)
        illustrationView.snp.makeConstraints {
            $0.centerX.equalTo(cardBackgroundView)
            $0.top.equalTo(cardBackgroundView.snp.top).offset(-81)
            $0.size.equalTo(CGSize(width: 180, height: 180))
        }

        // 4. 关闭按钮（右上角 20pt 图标，扩大点击热区）
        let closeImg = UIImage(named: "address_close")?.withRenderingMode(.alwaysTemplate)
            ?? UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium))
        closeButton.setImage(closeImg, for: .normal)
        closeButton.tintColor = UIColor(hexString: "#A6ACB8")
        closeButton.addTarget(self, action: #selector(handleCloseTap), for: .touchUpInside)
        closeButton.isHidden = info.isForce
        cardBackgroundView.addSubview(closeButton)
        closeButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.trailing.equalToSuperview().offset(-10)
            $0.size.equalTo(CGSize(width: 36, height: 36))
        }

        // 5. 标题：发现新版本
        titleLabel.text = info.title
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#1F2942")
        titleLabel.textAlignment = .center
        cardBackgroundView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(86)
            $0.centerX.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(20)
            $0.trailing.lessThanOrEqualToSuperview().offset(-20)
        }

        // 6. 版本比对副标题：最新 V... ｜ 当前 V...
        subtitleLabel.text = info.versionSubtitle
        subtitleLabel.font = .fdFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = UIColor(hexString: "#A6ACB8")
        subtitleLabel.textAlignment = .center
        cardBackgroundView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.centerX.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(20)
            $0.trailing.lessThanOrEqualToSuperview().offset(-20)
        }

        // 7. 更新内容标题
        sectionTitleLabel.text = "更新内容："
        sectionTitleLabel.font = .fdFont(ofSize: 14, weight: .medium)
        sectionTitleLabel.textColor = UIColor(hexString: "#1F2942")
        cardBackgroundView.addSubview(sectionTitleLabel)
        sectionTitleLabel.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(18)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
        }

        // 8. 更新说明正文（支持多行展示与滚动，行距 4pt）
        contentTextView.backgroundColor = .clear
        contentTextView.isEditable = false
        contentTextView.isSelectable = false
        contentTextView.isScrollEnabled = true
        contentTextView.textContainerInset = .zero
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.showsVerticalScrollIndicator = false

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.paragraphSpacing = 2
        let rawMessage = info.updateContent
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.fdFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor(hexString: "#8591AB"),
            .paragraphStyle: paragraphStyle,
        ]
        contentTextView.attributedText = NSAttributedString(string: rawMessage, attributes: attributes)

        cardBackgroundView.addSubview(contentTextView)
        contentTextView.snp.makeConstraints {
            $0.top.equalTo(sectionTitleLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.height.greaterThanOrEqualTo(42)
            $0.height.lessThanOrEqualTo(140)
        }

        // 9. 底部操作按钮：稍后再说 / 去更新
        laterButton.setTitle("稍后再说", for: .normal)
        laterButton.setTitleColor(.fdPrimary, for: .normal)
        laterButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        laterButton.backgroundColor = .clear
        laterButton.layer.cornerRadius = 20
        laterButton.layer.borderColor = UIColor.fdPrimary.cgColor
        laterButton.layer.borderWidth = 1
        laterButton.layer.masksToBounds = true
        laterButton.addTarget(self, action: #selector(handleLaterTap), for: .touchUpInside)

        updateButton.setTitle("去更新", for: .normal)
        updateButton.setTitleColor(.white, for: .normal)
        updateButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        updateButton.backgroundColor = .fdPrimary
        updateButton.layer.cornerRadius = 20
        updateButton.layer.masksToBounds = true
        updateButton.addTarget(self, action: #selector(handleUpdateTap), for: .touchUpInside)

        buttonStack.axis = .horizontal
        buttonStack.spacing = 11
        buttonStack.distribution = .fillEqually

        if !info.isForce {
            buttonStack.addArrangedSubview(laterButton)
        }
        buttonStack.addArrangedSubview(updateButton)

        cardBackgroundView.addSubview(buttonStack)
        buttonStack.snp.makeConstraints {
            $0.top.equalTo(contentTextView.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-20)
            $0.height.equalTo(40)
        }
    }

    // MARK: - Animations

    private func prepareAnimationState() {
        dimView.alpha = 0
        cardBackgroundView.alpha = 0
        illustrationView.alpha = 0
        cardBackgroundView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        illustrationView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
    }

    private func playAppearAnimation() {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
            self.dimView.alpha = 1
            self.cardBackgroundView.alpha = 1
            self.illustrationView.alpha = 1
            self.cardBackgroundView.transform = .identity
            self.illustrationView.transform = .identity
        }
    }

    private func dismissWithAnimation(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn], animations: {
            self.dimView.alpha = 0
            self.cardBackgroundView.alpha = 0
            self.illustrationView.alpha = 0
            self.cardBackgroundView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            self.illustrationView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }, completion: { _ in
            self.dismiss(animated: false, completion: completion)
        })
    }

    // MARK: - Actions

    @objc private func handleDimTap() {
        guard !info.isForce else { return }
        dismissWithAnimation { [weak self] in
            self?.onDismiss?()
        }
    }

    @objc private func handleCloseTap() {
        dismissWithAnimation { [weak self] in
            self?.onDismiss?()
        }
    }

    @objc private func handleLaterTap() {
        dismissWithAnimation { [weak self] in
            self?.onDismiss?()
        }
    }

    @objc private func handleUpdateTap() {
        dismissWithAnimation { [weak self] in
            self?.onConfirmUpdate?()
        }
    }
}
