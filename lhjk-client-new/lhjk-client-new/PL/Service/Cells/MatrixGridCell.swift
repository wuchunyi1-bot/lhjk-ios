import UIKit
import SnapKit

/// 德系产品矩阵 — 严格对齐 Figma 3021:1639
/// 白卡内含标题「德系产品矩阵」+ 3×3（图标 52 / 等级装饰 /「使用中」角标）
final class MatrixGridCell: UITableViewCell {
    static let reuseID = "MatrixGridCell"

    var onTileTap: ((String) -> Void)?
    private var items: [ProductMatrixItem] = []

    /// Figma 副文案 / 等级（API 缺字段时用，仅展示层）
    private static let figmaSubtitles: [String: String] = [
        "德康": "亚健康｜六高干预",
        "德好": "慢病逆转｜达标",
        "德护": "全病程专项管护",
        "德元": "肿瘤｜前沿疗法",
        "德愈": "疑难重症｜MDT",
        "德医": "三甲就医｜全程协助",
        "德甄": "全球特药甄选",
        "德际": "境外就医服务",
        "德尊": "长寿｜精准医学",
    ]

    private static let figmaTiers: [String: String] = [
        "德康": "基础",
        "德好": "主推",
        "德护": "专项",
        "德元": "高端",
        "德愈": "高端",
        "德医": "专项",
        "德甄": "高端",
        "德际": "旗舰",
        "德尊": "旗舰",
    ]

    private static let iconNames: [String: String] = [
        "德康": "matrix_icon_dekang",
        "德好": "matrix_icon_dehao",
        "德护": "matrix_icon_dehu",
        "德元": "matrix_icon_deyuan",
        "德愈": "matrix_icon_deyu",
        "德医": "matrix_icon_deyi",
        "德甄": "matrix_icon_dezhen",
        "德际": "matrix_icon_deji",
        "德尊": "matrix_icon_dezun",
    ]

    private static let tierColors: [String: UIColor] = [
        "德康": UIColor(hexString: "#6AC13E"),
        "德好": UIColor(hexString: "#FF6839"),
        "德护": UIColor(hexString: "#237BF1"),
        "德元": UIColor(hexString: "#985BCA"),
        "德愈": UIColor(hexString: "#F55A5D"),
        "德医": UIColor(hexString: "#059EA6"),
        "德甄": UIColor(hexString: "#189749"),
        "德际": UIColor(hexString: "#4E6BC9"),
        "德尊": UIColor(hexString: "#DD8E21"),
    ]

    /// 设计稿默认顺序（API 乱序时按此重排）
    private static let figmaOrder = ["德康", "德好", "德护", "德元", "德愈", "德医", "德甄", "德际", "德尊"]

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.clipsToBounds = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ items: [ProductMatrixItem]) {
        // 按 Figma 九宫格顺序排列；未知 code 追加在后
        var ordered: [ProductMatrixItem] = []
        for code in Self.figmaOrder {
            if let item = items.first(where: { $0.code == code }) {
                ordered.append(item)
            }
        }
        for item in items where !Self.figmaOrder.contains(item.code) {
            ordered.append(item)
        }
        self.items = ordered
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.height.equalTo(462)
        }

        let title = UILabel()
        title.text = "德系产品矩阵"
        title.font = .fdFont(ofSize: 18, weight: .medium)
        title.textColor = .fdText
        card.addSubview(title)
        title.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
        }

        // 3 行 × 3 列；图标顶部分别对齐稿 y=61 / 192 / 323
        let grid = UIStackView()
        grid.axis = .vertical
        grid.distribution = .fillEqually
        grid.alignment = .fill
        card.addSubview(grid)
        grid.snp.makeConstraints {
            $0.top.equalToSuperview().offset(61)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-28)
        }

        for row in 0..<3 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.alignment = .top
            for col in 0..<3 {
                let index = row * 3 + col
                if index < self.items.count {
                    rowStack.addArrangedSubview(buildTile(self.items[index], index: index))
                } else {
                    rowStack.addArrangedSubview(UIView())
                }
            }
            grid.addArrangedSubview(rowStack)
        }
    }

    private func buildTile(_ m: ProductMatrixItem, index: Int) -> UIView {
        let tile = UIButton(type: .system)
        tile.backgroundColor = .clear
        tile.tag = index

        let iconWrap = UIView()
        iconWrap.isUserInteractionEnabled = false

        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        if let name = Self.iconNames[m.code], let img = UIImage(named: name) {
            icon.image = img
        } else {
            icon.backgroundColor = m.accent.withAlphaComponent(0.12)
            icon.layer.cornerRadius = 12
            icon.layer.borderWidth = 0.5
            icon.layer.borderColor = m.accent.withAlphaComponent(0.35).cgColor
            icon.clipsToBounds = true
            let fallback = UILabel()
            fallback.text = m.code
            fallback.font = .fdFont(ofSize: 12, weight: .medium)
            fallback.textColor = m.accent
            fallback.textAlignment = .center
            icon.addSubview(fallback)
            fallback.snp.makeConstraints { $0.center.equalToSuperview() }
        }
        iconWrap.addSubview(icon)
        icon.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
            $0.size.equalTo(52)
            $0.bottom.equalToSuperview()
        }

        let name = UILabel()
        name.text = m.name
        name.font = .fdFont(ofSize: 14, weight: .medium)
        name.textColor = .fdText
        name.textAlignment = .center

        let desc = UILabel()
        let subtitle = m.desc.isEmpty ? (Self.figmaSubtitles[m.code] ?? "") : m.desc
        desc.text = subtitle
        desc.font = .fdFont(ofSize: 10, weight: .regular)
        desc.textColor = UIColor(hexString: "#6D7381")
        desc.textAlignment = .center
        desc.isHidden = subtitle.isEmpty

        let tierColor = Self.tierColors[m.code] ?? m.accent
        let tierText = {
            let fromAPI = Self.normalizedTier(m.tier)
            return fromAPI.isEmpty ? (Self.figmaTiers[m.code] ?? "") : fromAPI
        }()
        let tierRow = makeTierRow(text: tierText, color: tierColor)
        tierRow.isHidden = tierText.isEmpty

        let stack = UIStackView(arrangedSubviews: [iconWrap, name, desc, tierRow])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 0
        stack.setCustomSpacing(4, after: iconWrap)
        stack.setCustomSpacing(0, after: name)
        stack.setCustomSpacing(5, after: desc)
        stack.isUserInteractionEnabled = false
        tile.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(2)
            $0.trailing.lessThanOrEqualToSuperview().offset(-2)
            $0.bottom.lessThanOrEqualToSuperview()
        }

        if m.current {
            let badge = makeUsingBadge()
            tile.addSubview(badge)
            badge.snp.makeConstraints {
                $0.top.equalTo(icon).offset(-2)
                $0.trailing.equalTo(icon).offset(14)
                $0.height.equalTo(19)
                $0.width.equalTo(45)
            }
        }

        tile.addTarget(self, action: #selector(tileTapped(_:)), for: .touchUpInside)
        return tile
    }

    private func makeTierRow(text: String, color: UIColor) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 2

        let left = TierBracketView(color: color, mirrored: false)
        let right = TierBracketView(color: color, mirrored: true)
        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 10, weight: .regular)
        label.textColor = color
        label.textAlignment = .center

        row.addArrangedSubview(left)
        row.addArrangedSubview(label)
        row.addArrangedSubview(right)
        left.snp.makeConstraints { $0.width.equalTo(6); $0.height.equalTo(9) }
        right.snp.makeConstraints { $0.width.equalTo(6); $0.height.equalTo(9) }
        return row
    }

    private func makeUsingBadge() -> UILabel {
        let badge = UILabel()
        badge.text = "使用中"
        badge.font = .fdFont(ofSize: 10, weight: .medium)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.clipsToBounds = true
        badge.backgroundColor = UIColor(hexString: "#F93838")
        badge.layer.cornerRadius = 12
        badge.layer.maskedCorners = [
            .layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner,
        ]
        return badge
    }

    private static func normalizedTier(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "（", with: "")
            .replacingOccurrences(of: "）", with: "")
    }

    @objc private func tileTapped(_ sender: UIButton) {
        guard sender.tag < items.count else { return }
        onTileTap?(items[sender.tag].code)
    }
}

// MARK: - 等级两侧装饰（对齐 Figma Union）

private final class TierBracketView: UIView {
    private let color: UIColor
    private let mirrored: Bool

    init(color: UIColor, mirrored: Bool) {
        self.color = color
        self.mirrored = mirrored
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()
        if mirrored {
            ctx.translateBy(x: bounds.width, y: 0)
            ctx.scaleBy(x: -1, y: 1)
        }
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 5.2, y: 0.5))
        path.addQuadCurve(to: CGPoint(x: 0.8, y: 4.5), controlPoint: CGPoint(x: 1.2, y: 1.2))
        path.addQuadCurve(to: CGPoint(x: 5.2, y: 8.5), controlPoint: CGPoint(x: 1.2, y: 7.8))
        path.addQuadCurve(to: CGPoint(x: 5.2, y: 0.5), controlPoint: CGPoint(x: 3.8, y: 4.5))
        color.setFill()
        path.fill()
        ctx.restoreGState()
    }
}
