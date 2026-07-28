import UIKit
import SnapKit

/// 协议勾选 — 《用户协议》《隐私政策》《健康管理服务知情同意书》
/// 对齐 funde `LoginView` / PRD AUTH-06
final class AgreementCheckboxView: UIView {

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

    var isChecked: Bool {
        get { checkboxButton.isSelected }
        set { checkboxButton.isSelected = newValue }
    }

    var onUserAgreementTap: (() -> Void)?
    var onPrivacyPolicyTap: (() -> Void)?
    var onConsentTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

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

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleLabelTap(_:)))
        agreementLabel.addGestureRecognizer(tap)
    }

    private func buildAgreementText() {
        let fullText = "我已阅读并同意《用户协议》《隐私政策》与《健康管理服务知情同意书》"
        let attributed = NSMutableAttributedString(string: fullText)
        attributed.setAttributes([
            .font: UIFont.fdCaption,
            .foregroundColor: UIColor.fdSubtext,
        ], range: NSRange(location: 0, length: fullText.count))

        for link in ["《用户协议》", "《隐私政策》", "《健康管理服务知情同意书》"] {
            if let range = fullText.range(of: link) {
                attributed.addAttributes([
                    .foregroundColor: UIColor.fdPrimary,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                ], range: NSRange(range, in: fullText))
            }
        }
        agreementLabel.attributedText = attributed
    }

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
        guard glyphIndex != NSNotFound else { return }

        let charRange = layoutManager.characterRange(
            forGlyphRange: NSRange(location: glyphIndex, length: 1),
            actualGlyphRange: nil
        )
        let text = (label.text ?? "") as NSString

        let links: [(String, () -> Void)] = [
            ("《用户协议》", { [weak self] in self?.onUserAgreementTap?() }),
            ("《隐私政策》", { [weak self] in self?.onPrivacyPolicyTap?() }),
            ("《健康管理服务知情同意书》", { [weak self] in self?.onConsentTap?() }),
        ]
        for (title, action) in links {
            let range = text.range(of: title)
            if range.location != NSNotFound, NSIntersectionRange(charRange, range).length > 0 {
                action()
                return
            }
        }
    }
}
