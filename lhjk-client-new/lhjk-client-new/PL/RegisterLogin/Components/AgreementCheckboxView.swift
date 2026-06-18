import UIKit

/// 协议勾选组件 — 复选框 + 富文本协议链接
/// 参考 funde-client PRD: 获取验证码和任何登录/绑定提交前必须勾选
final class AgreementCheckboxView: UIView {

    // MARK: - UI

    private let checkboxButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "square"), for: .normal)
        btn.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        btn.tintColor = .fdPrimary
        btn.contentHorizontalAlignment = .fill
        btn.contentVerticalAlignment = .fill
        return btn
    }()

    private let agreementLabel: UILabel = {
        let label = UILabel()
        label.font = .fdCaption
        label.textColor = .fdSubtext
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        return label
    }()

    // MARK: - State

    var isChecked: Bool {
        get { checkboxButton.isSelected }
        set { checkboxButton.isSelected = newValue }
    }

    /// 用户协议点击回调
    var onUserAgreementTap: (() -> Void)?
    /// 隐私政策点击回调
    var onPrivacyPolicyTap: (() -> Void)?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(checkboxButton)
        addSubview(agreementLabel)

        checkboxButton.addTarget(self, action: #selector(toggleCheck), for: .touchUpInside)
        checkboxButton.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.size.equalTo(22)
        }

        buildAgreementText()

        agreementLabel.snp.makeConstraints { make in
            make.leading.equalTo(checkboxButton.snp.trailing).offset(8)
            make.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        // Tap gesture for link detection
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleLabelTap(_:)))
        agreementLabel.addGestureRecognizer(tap)
    }

    private func buildAgreementText() {
        let fullText = "我已阅读并同意《用户协议》与《隐私政策》"
        let attributed = NSMutableAttributedString(string: fullText)

        // Default style
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.fdCaption,
            .foregroundColor: UIColor.fdSubtext
        ]
        attributed.setAttributes(defaultAttributes, range: NSRange(location: 0, length: fullText.count))

        // Link style for 《用户协议》
        if let range = fullText.range(of: "《用户协议》") {
            let nsRange = NSRange(range, in: fullText)
            attributed.addAttributes([
                .foregroundColor: UIColor.fdPrimary,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ], range: nsRange)
        }

        // Link style for 《隐私政策》
        if let range = fullText.range(of: "《隐私政策》") {
            let nsRange = NSRange(range, in: fullText)
            attributed.addAttributes([
                .foregroundColor: UIColor.fdPrimary,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ], range: nsRange)
        }

        agreementLabel.attributedText = attributed
    }

    // MARK: - Actions

    @objc private func toggleCheck() {
        checkboxButton.isSelected.toggle()
    }

    @objc private func handleLabelTap(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel else { return }
        let point = gesture.location(in: label)

        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText ?? NSAttributedString(string: ""))

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.size = label.bounds.size

        let boundingBox = layoutManager.usedRect(for: textContainer)
        let textOffset = CGPoint(
            x: (label.bounds.width - boundingBox.width) * 0.5 - boundingBox.minX,
            y: (label.bounds.height - boundingBox.height) * 0.5 - boundingBox.minY
        )
        let textPoint = CGPoint(x: point.x - textOffset.x, y: point.y - textOffset.y)
        let glyphIndex = layoutManager.glyphIndex(for: textPoint, in: textContainer)

        if glyphIndex != NSNotFound {
            let charRange = layoutManager.characterRange(forGlyphRange: NSRange(location: glyphIndex, length: 1), actualGlyphRange: nil)
            let text = (label.text ?? "") as NSString

            let userAgreementRange = text.range(of: "《用户协议》")
            let privacyPolicyRange = text.range(of: "《隐私政策》")

            if userAgreementRange.location != NSNotFound,
               NSIntersectionRange(charRange, userAgreementRange).length > 0 {
                onUserAgreementTap?()
            } else if privacyPolicyRange.location != NSNotFound,
                      NSIntersectionRange(charRange, privacyPolicyRange).length > 0 {
                onPrivacyPolicyTap?()
            }
        }
    }
}
