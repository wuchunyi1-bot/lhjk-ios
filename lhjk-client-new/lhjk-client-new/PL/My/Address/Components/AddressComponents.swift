import UIKit
import SnapKit

// MARK: - Design tokens (Figma 4522:6020 / 6521 / 6675 / 6771)

enum AddressStyle {
    static let cardRadius: CGFloat = 16
    static let horizontalInset: CGFloat = 16
    static let cardHorizontalInset: CGFloat = 12
    static let rowHeight: CGFloat = 50
    /// 普通模式保持 74。长辈模式字号变大后，按「所在地区」四个字撑开，避免标题被截成「所在…」。
    static var labelWidth: CGFloat {
        let textWidth = ("所在地区" as NSString).size(withAttributes: [.font: fieldFont]).width
        return max(74, ceil(textWidth) + 4)
    }
    /// 输入区起点：左边距 + 标题栏宽。
    static var fieldLeading: CGFloat {
        cardHorizontalInset + labelWidth
    }
    static var fieldFont: UIFont { .fdFont(ofSize: 16, weight: .regular) }
    static var fieldMediumFont: UIFont { .fdFont(ofSize: 16, weight: .medium) }
    static var captionFont: UIFont { .fdFont(ofSize: 14, weight: .regular) }
    static var buttonFont: UIFont { .fdFont(ofSize: 18, weight: .medium) }
    static var sheetTitleFont: UIFont { .fdFont(ofSize: 20, weight: .medium) }
    static var pickerSelectedFont: UIFont { .fdFont(ofSize: 18, weight: .medium) }
    static var pickerNormalFont: UIFont { .fdFont(ofSize: 16, weight: .regular) }
    static var defaultBadgeFont: UIFont { .fdFont(ofSize: 14, weight: .semibold) }
    static let primaryButtonHeight: CGFloat = 51
    static let pickerSaveButtonHeight: CGFloat = 48
    static let primaryButtonRadius: CGFloat = 25.5
    static let modalDimAlpha: CGFloat = 0.35
    static let placeholderColor = UIColor.fdTabInactive
    static let tertiaryText = UIColor(hexString: "#A6ACB8")
}

// MARK: - List tip banner

/// 地址列表顶部提示 — Figma 4522:6344
final class AddressListTipBannerView: UIView {

    var onClose: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .fdPrimarySoft
        layer.cornerRadius = AddressStyle.cardRadius
        clipsToBounds = true

        let iconView = UIImageView(image: AddressIcons.note())
        iconView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = "默认地址可用于商城下单、服务资料邮寄等场景。"
        label.font = AddressStyle.captionFont
        label.textColor = .fdPrimary
        label.numberOfLines = 2

        let closeButton = UIButton(type: .custom)
        closeButton.setImage(AddressIcons.close(), for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        addSubview(iconView)
        addSubview(label)
        addSubview(closeButton)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }

        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.size.equalTo(28)
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(6)
            make.trailing.equalTo(closeButton.snp.leading).offset(-4)
            make.top.bottom.equalToSuperview().inset(8)
        }

        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(34)
        }
    }

    @objc private func closeTapped() {
        onClose?()
    }
}

// MARK: - Form helpers

extension MAddress {
    /// 省市区（不含详细地址）
    var regionSummary: String {
        [province, city, area]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined()
    }
}

enum AddressFormDivider {
    static func make() -> UIView {
        let line = UIView()
        line.backgroundColor = .fdBorder
        line.snp.makeConstraints { $0.height.equalTo(1.0 / UIScreen.main.scale) }
        return line
    }
}

enum AddressIcons {
    private static func scaledImage(named name: String, size: CGFloat) -> UIImage? {
        guard let image = UIImage(named: name) else { return nil }
        let target = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: target)
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return scaled.withRenderingMode(.alwaysOriginal)
    }

    /// 地址列表提示 icon — `address_note`
    static func note(size: CGFloat = 16) -> UIImage? {
        scaledImage(named: "address_note", size: size)
    }

    /// 所在地区展开 — `address_open`
    static func open(size: CGFloat = 12) -> UIImage? {
        scaledImage(named: "address_open", size: size)
    }

    /// 地区选择弹层关闭 — `address_close_big`
    static func closeBig(size: CGFloat = 24) -> UIImage? {
        scaledImage(named: "address_close_big", size: size)
    }

    /// 地址列表提示关闭 — `address_close`
    static func close(size: CGFloat = 16) -> UIImage? {
        scaledImage(named: "address_close", size: size)
    }
}
