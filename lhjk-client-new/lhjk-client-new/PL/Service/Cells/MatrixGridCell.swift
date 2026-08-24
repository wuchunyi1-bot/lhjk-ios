import UIKit
import SnapKit

/// 德系产品矩阵 — 对齐 Figma 3444:5255
/// 白卡 343×424 / 圆角 16；标题 18 Medium；3×3 图标 52 + 主标题 14 + 副标题 10
final class MatrixGridCell: UITableViewCell {
    static let reuseID = "MatrixGridCell"
    static let cardHeight: CGFloat = 424

    var onTileTap: ((String) -> Void)?
    private var items: [ProductMatrixItem] = []

    /// Figma 主标题（API `description` 缺失或等于 code 时用）
    private static let figmaTitles: [String: String] = [
        "德康": "健康基础",
        "德好": "向好逆转",
        "德护": "专病管护",
        "德元": "生命元气",
        "德愈": "治愈疑难",
        "德医": "医路通达",
        "德甄": "甄选全球",
        "德际": "国际无界",
        "德尊": "臻享极致",
    ]

    /// Figma 副文案（API 缺字段时用）
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
            $0.height.equalTo(Self.cardHeight)
        }

        let title = UILabel()
        title.attributedText = NSAttributedString(
            string: "德系产品矩阵",
            attributes: [
                .font: UIFont.fdFont(ofSize: 20, weight: .medium),
                .foregroundColor: UIColor.fdText,
                .kern: 0.55,
            ]
        )
        card.addSubview(title)
        title.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
        }

        // 图标顶 y=61 / 184 / 307；行高 95；行距 28；底留 22
        let grid = UIStackView()
        grid.axis = .vertical
        grid.distribution = .fill
        grid.alignment = .fill
        grid.spacing = 28
        card.addSubview(grid)
        grid.snp.makeConstraints {
            $0.top.equalToSuperview().offset(61)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-22)
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
        let tile = UIButton(type: .custom)
        tile.backgroundColor = .clear
        tile.tag = index

        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.isUserInteractionEnabled = false
        if let name = Self.iconNames[m.code], let img = UIImage(named: name) {
            icon.image = img.withRenderingMode(.alwaysOriginal)
        } else {
            icon.backgroundColor = m.accent.withAlphaComponent(0.12)
            icon.layer.cornerRadius = 12
            icon.layer.borderWidth = 0.5
            icon.layer.borderColor = m.accent.withAlphaComponent(0.35).cgColor
            icon.clipsToBounds = true
            let fallback = UILabel()
            fallback.text = m.code
            fallback.font = .fdFont(ofSize: 16, weight: .medium)
            fallback.textColor = m.accent
            fallback.textAlignment = .center
            icon.addSubview(fallback)
            fallback.snp.makeConstraints { $0.center.equalToSuperview() }
        }
        icon.snp.makeConstraints { $0.size.equalTo(52) }

        let name = UILabel()
        name.text = Self.displayTitle(m)
        name.font = .fdFont(ofSize: 16, weight: .medium)
        name.textColor = .fdText
        name.textAlignment = .center
        name.snp.makeConstraints { $0.height.equalTo(21) }

        let subtitle = Self.displaySubtitle(m)
        let desc = UILabel()
        desc.text = subtitle
        desc.font = .fdFont(ofSize: 12, weight: .regular)
        desc.textColor = UIColor(hexString: "#6D7381")
        desc.textAlignment = .center
        desc.isHidden = subtitle.isEmpty
        desc.snp.makeConstraints { $0.height.equalTo(15) }

        let stack = UIStackView(arrangedSubviews: [icon, name, desc])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 0
        stack.setCustomSpacing(6, after: icon)
        stack.setCustomSpacing(1, after: name)
        stack.isUserInteractionEnabled = false
        tile.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(2)
            $0.trailing.lessThanOrEqualToSuperview().offset(-2)
            $0.bottom.equalToSuperview()
        }

        tile.addTarget(self, action: #selector(tileTapped(_:)), for: .touchUpInside)
        return tile
    }

    private static func displayTitle(_ m: ProductMatrixItem) -> String {
        let name = m.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty, name != m.code { return name }
        return figmaTitles[m.code] ?? name
    }

    private static func displaySubtitle(_ m: ProductMatrixItem) -> String {
        let desc = m.desc.trimmingCharacters(in: .whitespacesAndNewlines)
        if !desc.isEmpty { return desc }
        return figmaSubtitles[m.code] ?? ""
    }

    @objc private func tileTapped(_ sender: UIButton) {
        guard sender.tag < items.count else { return }
        onTileTap?(items[sender.tag].code)
    }
}
