import SnapKit
import UIKit

/// 设备空态插图。复用 `noData_default`，文案 12pt、行高 1.5。
final class DeviceEmptyIllustrationView: UIView {

    private let imageView = UIImageView(image: UIImage(named: FDEmptyStateView.imageName))
    private let textLabel = UILabel()

    init(text: String) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false

        imageView.contentMode = .scaleAspectFit

        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineSpacing = 6
        textLabel.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.fdFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor(hexString: "#6D7381"),
                .paragraphStyle: style
            ]
        )

        let stack = UIStackView(arrangedSubviews: [imageView, textLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        imageView.snp.makeConstraints { $0.size.equalTo(145) }
        textLabel.snp.makeConstraints { $0.width.lessThanOrEqualTo(187) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
