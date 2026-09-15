import UIKit
import SnapKit

/// 列表无数据默认空态：插图 `noData_default` + 文案。
/// 全页 / 全列表空态统一使用；购物车等已有业务专属插图的页面除外。
final class FDEmptyStateView: UIView {

    static let imageName = "noData_default"
    static let pageImageSize: CGFloat = 145
    static let compactImageSize: CGFloat = 100

    enum Style {
        case page
        case compact
    }

    private let imageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: FDEmptyStateView.imageName))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .regular)
        l.textColor = .fdMuted
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdCaption
        l.textColor = .fdSubtext
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        return l
    }()

    private let stack = UIStackView()

    init(style: Style = .page, message: String = "", subtitle: String? = nil) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        // 贴四边或与列表抢高度时，把剩余空间让给列表，避免把提示行撑开
        setContentHuggingPriority(.defaultLow, for: .vertical)

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(messageLabel)
        stack.addArrangedSubview(subtitleLabel)
        stack.setCustomSpacing(8, after: messageLabel)

        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        let size = style == .page ? Self.pageImageSize : Self.compactImageSize
        imageView.snp.makeConstraints { $0.size.equalTo(size) }

        configure(message: message, subtitle: subtitle)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize {
        let fitted = stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGSize(width: UIView.noIntrinsicMetric, height: max(fitted.height, 160))
    }

    func configure(message: String, subtitle: String? = nil) {
        messageLabel.text = message
        let sub = subtitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        subtitleLabel.text = sub
        subtitleLabel.isHidden = sub.isEmpty
        invalidateIntrinsicContentSize()
    }
}
