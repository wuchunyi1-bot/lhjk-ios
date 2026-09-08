import UIKit
import SnapKit

/// 聊天详情「服务已过期」底栏 — 对齐 Figma `4565:9670`，背景用 `chat_expired_bg`
final class ChatExpiredBannerView: UIControl {

    static let contentHeight: CGFloat = 66

    var onTap: (() -> Void)?

    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.isUserInteractionEnabled = false
        iv.contentMode = .scaleToFill
        let insets = UIEdgeInsets(top: 20, left: 20, bottom: 8, right: 20)
        iv.image = UIImage(named: "chat_expired_bg")?.resizableImage(
            withCapInsets: insets,
            resizingMode: .stretch
        )
        return iv
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "chat_expired_warning"))
        iv.isUserInteractionEnabled = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.isUserInteractionEnabled = false
        l.numberOfLines = 2
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 24
        paragraph.maximumLineHeight = 24
        paragraph.lineBreakMode = .byWordWrapping
        l.attributedText = NSAttributedString(
            string: "您的服务已过期，可前往商城重新购买健康管理服务！",
            attributes: [
                .font: UIFont.fdFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor(hexString: "#C36E20"),
                .paragraphStyle: paragraph,
            ]
        )
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(backgroundImageView)
        addSubview(iconView)
        addSubview(messageLabel)

        backgroundImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(13)
            make.size.equalTo(40)
        }
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(14)
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-16)
        }

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        accessibilityTraits = .button
        accessibilityLabel = "您的服务已过期，可前往商城重新购买健康管理服务！"
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func handleTap() {
        onTap?()
    }
}
