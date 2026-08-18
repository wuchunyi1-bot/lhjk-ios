import UIKit
import SnapKit

/// 套餐权益规则分组卡片 — 对齐 Figma 3449:7828 / 3449:7872 / 3449:7913
final class PackageComboGroupView: UIView {

    var onRadioSelect: ((Int) -> Void)?
    var onCheckToggle: ((Int) -> Void)?

    /// 子项相对父项的左侧缩进
    private let childLeadingInset: CGFloat = 24

    func configure(
        group: ServicePackageComboGroup,
        radioPick: Int?,
        checkPicks: Set<Int>
    ) {
        subviews.forEach { $0.removeFromSuperview() }

        backgroundColor = UIColor(hexString: "#FFFCF8")
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor(hexString: "#FFEEDC").cgColor
        clipsToBounds = true

        let header = makeHeaderView(mode: group.selectMode)
        addSubview(header)
        header.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(42)
        }

        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 0

        for (index, item) in group.items.enumerated() {
            rows.addArrangedSubview(
                makeRow(
                    group: group,
                    index: index,
                    item: item,
                    selected: isSelected(group: group, index: index, radioPick: radioPick, checkPicks: checkPicks),
                    showDivider: index < group.items.count - 1
                )
            )
        }

        addSubview(rows)
        rows.snp.makeConstraints {
            $0.top.equalTo(header.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(12)
        }
    }

    /// 顶部渐变标题条（—— 必选 / 单选 / 可选 ——）
    private func makeHeaderView(mode: ServicePackageSelectMode) -> UIView {
        let container = HeaderGradientView()

        let leftWing = UIImageView(image: UIImage(named: "package_detail_wing_left"))
        leftWing.contentMode = .scaleAspectFit

        let rightWing = UIImageView(image: UIImage(named: "package_detail_wing_right"))
        rightWing.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        let modeText: String
        switch mode {
        case .required: modeText = "必选"
        case .radio: modeText = "单选"
        case .checkbox: modeText = "可选"
        }
        titleLabel.text = modeText
        titleLabel.font = .fdFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#A25300")
        titleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [leftWing, titleLabel, rightWing])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center

        leftWing.snp.makeConstraints {
            $0.width.equalTo(62.5)
            $0.height.equalTo(3)
        }
        rightWing.snp.makeConstraints {
            $0.width.equalTo(62.5)
            $0.height.equalTo(3)
        }

        container.addSubview(stack)
        stack.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        return container
    }

    private func isSelected(
        group: ServicePackageComboGroup,
        index: Int,
        radioPick: Int?,
        checkPicks: Set<Int>
    ) -> Bool {
        let item = group.items[index]
        if item.isChild { return false }
        switch group.selectMode {
        case .required:
            return true
        case .radio:
            return radioPick == index
        case .checkbox:
            return checkPicks.contains(index)
        }
    }

    private func makeRow(
        group: ServicePackageComboGroup,
        index: Int,
        item: ServicePackageComboItem,
        selected: Bool,
        showDivider: Bool
    ) -> UIView {
        let row = UIControl()
        row.tag = index

        let name = UILabel()
        name.text = item.name
        name.font = .fdFont(ofSize: 14, weight: .regular)
        name.textColor = .fdText
        name.numberOfLines = 0
        name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let qty = UILabel()
        qty.text = item.qtyLabel
        qty.font = .fdFont(ofSize: 14, weight: .regular)
        qty.textColor = .fdText
        qty.setContentHuggingPriority(.required, for: .horizontal)
        qty.setContentCompressionResistancePriority(.required, for: .horizontal)

        let price = UILabel()
        price.text = item.priceLabel
        price.font = .fdMonoFont(ofSize: 14, weight: .medium)
        price.textColor = .fdText
        price.setContentHuggingPriority(.required, for: .horizontal)
        price.setContentCompressionResistancePriority(.required, for: .horizontal)

        let arranged: [UIView]
        if item.isChild {
            arranged = [name, qty, price]
            row.isEnabled = false
        } else if group.selectMode == .required {
            // 必选：无选择框，直接左对齐展示
            arranged = [name, qty, price]
            row.isEnabled = false
        } else {
            let ctrl = makeControl(group: group, selected: selected)
            arranged = [ctrl, name, qty, price]
            row.isEnabled = true
        }

        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        row.addSubview(stack)

        let leading = item.isChild ? childLeadingInset : 0
        stack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(leading)
            $0.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(10)
        }

        if showDivider {
            let line = UIView()
            line.backgroundColor = UIColor(hexString: "#FFEEDC")
            row.addSubview(line)
            line.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(leading)
                $0.trailing.bottom.equalToSuperview()
                $0.height.equalTo(1)
            }
        }

        guard !item.isChild else { return row }

        switch group.selectMode {
        case .required:
            break
        case .radio:
            row.addAction(UIAction { [weak self] _ in
                self?.onRadioSelect?(index)
            }, for: .touchUpInside)
        case .checkbox:
            row.addAction(UIAction { [weak self] _ in
                self?.onCheckToggle?(index)
            }, for: .touchUpInside)
        }
        return row
    }

    private func makeControl(group: ServicePackageComboGroup, selected: Bool) -> UIView {
        let isRadio = group.selectMode == .radio
        let container = UIView()
        container.snp.makeConstraints { $0.size.equalTo(14) }

        if selected {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFit
            if isRadio {
                iv.image = UIImage(named: "package_detail_radio_checked")
            } else {
                iv.image = UIImage(named: "package_detail_checkbox_checked")
            }
            container.addSubview(iv)
            iv.snp.makeConstraints { $0.edges.equalToSuperview() }
        } else {
            let box = UIView()
            box.layer.cornerRadius = isRadio ? 7 : 3.5
            box.layer.borderWidth = 0.7
            box.layer.borderColor = UIColor(hexString: "#535D72").cgColor
            box.backgroundColor = .clear
            container.addSubview(box)
            box.snp.makeConstraints { $0.edges.equalToSuperview() }
        }

        return container
    }
}

// MARK: - 渐变标题条容器

private final class HeaderGradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.colors = [
            UIColor(hexString: "#FFF7F0").cgColor,
            UIColor(hexString: "#FFEDDB").cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

