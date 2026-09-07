import UIKit
import SnapKit

/// 支付结果卡片内部虚线分割线（对齐 Figma Vector 1791）
final class OrderPayResultDottedLine: UIView {
    private let shapeLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        shapeLayer.strokeColor = UIColor(hexString: "#E5E7EB").cgColor
        shapeLayer.lineWidth = 1
        shapeLayer.lineDashPattern = [4, 4]
        layer.addSublayer(shapeLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = CGMutablePath()
        path.addLines(between: [CGPoint(x: 0, y: bounds.midY), CGPoint(x: bounds.width, y: bounds.midY)])
        shapeLayer.path = path
    }
}

/// 支付信息卡 — 背景切图 `pay_info_bg`，字段来自 `getAppOrderDetail`，不展示支付时间
final class OrderPayResultInfoView: UIView {

    var onOrderNumberCopied: (() -> Void)?

    private let backgroundView = UIImageView(image: UIImage(named: "pay_info_bg"))
    private let titleLabel = UILabel()
    private let dottedLine = OrderPayResultDottedLine()
    private let rowsStack = UIStackView()
    private var orderNumberText: String?
    private var lastLayoutWidth: CGFloat = 0

    /// `pay_info_bg` @2x 732×783
    private static let artworkRatio: CGFloat = 783.0 / 732.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = false

        backgroundView.contentMode = .scaleToFill
        backgroundView.isUserInteractionEnabled = false
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { $0.edges.equalToSuperview() }

        titleLabel.text = "订单信息"
        titleLabel.font = .fdFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#1F2942")

        rowsStack.axis = .vertical
        rowsStack.spacing = 16

        addSubview(titleLabel)
        addSubview(dottedLine)
        addSubview(rowsStack)

        // 对应 Figma 中 front card top(34pt) + 16pt = 50pt
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(48)
            $0.leading.equalToSuperview().offset(26)
            $0.trailing.lessThanOrEqualToSuperview().offset(-26)
        }

        // 对应 Figma 中两侧缺口中心线 (y=80pt)
        dottedLine.snp.makeConstraints {
            $0.top.equalToSuperview().offset(80)
            $0.leading.trailing.equalToSuperview().inset(26)
            $0.height.equalTo(1)
        }

        // 字段从虚线下方 16pt 开始排布
        rowsStack.snp.makeConstraints {
            $0.top.equalTo(dottedLine.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(26)
            $0.bottom.lessThanOrEqualToSuperview().offset(-24)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize {
        let width = bounds.width > 1 ? bounds.width : UIScreen.main.bounds.width - 32
        let height = BannerImageAspectLayout.height(
            width: width,
            imageSize: backgroundView.image?.size,
            fallbackRatio: Self.artworkRatio
        )
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if abs(bounds.width - lastLayoutWidth) > 0.5 {
            lastLayoutWidth = bounds.width
            invalidateIntrinsicContentSize()
        }
    }

    func configure(rows: [OrderPayResultInfoRow]) {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        orderNumberText = rows.first(where: { $0.isOrderNumber })?.value
        rows.forEach { row in
            rowsStack.addArrangedSubview(makeRow(row))
        }
        setNeedsLayout()
    }

    private func makeRow(_ row: OrderPayResultInfoRow) -> UIView {
        let left = UILabel()
        left.text = row.title
        left.font = .fdFont(ofSize: 14, weight: .regular)
        left.textColor = UIColor(hexString: "#8591AB")
        left.setContentHuggingPriority(.required, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.text = row.value
        valueLabel.font = .fdFont(ofSize: 14, weight: .regular)
        valueLabel.textColor = UIColor(hexString: "#1F2942")
        valueLabel.textAlignment = .right
        valueLabel.lineBreakMode = .byTruncatingMiddle

        var arranged: [UIView] = [left]
        if row.isOrderNumber {
            valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            let copyButton = UIButton(type: .custom)
            copyButton.setImage(UIImage(named: "order_detail_copy")?.withRenderingMode(.alwaysOriginal), for: .normal)
            copyButton.accessibilityLabel = "复制订单号"
            copyButton.addAction(UIAction { [weak self] _ in
                guard let text = self?.orderNumberText, !text.isEmpty else { return }
                UIPasteboard.general.string = text
                self?.onOrderNumberCopied?()
            }, for: .touchUpInside)
            copyButton.snp.makeConstraints { $0.size.equalTo(14) }
            let right = UIStackView(arrangedSubviews: [valueLabel, copyButton])
            right.axis = .horizontal
            right.spacing = 4
            right.alignment = .center
            arranged.append(right)
        } else {
            arranged.append(valueLabel)
        }

        let line = UIStackView(arrangedSubviews: arranged)
        line.axis = .horizontal
        line.alignment = .center
        line.spacing = 12
        line.distribution = .fill
        return line
    }
}
