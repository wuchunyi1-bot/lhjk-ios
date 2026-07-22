import UIKit
import SnapKit

final class PackageComboGroupView: UIView {

    var onRadioSelect: ((Int) -> Void)?
    var onCheckToggle: ((Int) -> Void)?

    /// 子项相对父项的左侧缩进（对齐 funde `--fd-s-6` ≈ 24pt）
    private let childLeadingInset: CGFloat = 24

    func configure(
        group: ServicePackageComboGroup,
        radioPick: Int?,
        checkPicks: Set<Int>
    ) {
        subviews.forEach { $0.removeFromSuperview() }

        let box = DashedBorderView()
        let isRequired = group.selectMode == .required
        box.backgroundColor = isRequired ? UIColor(hexString: "#FFF7F8") : .fdSurface
        box.layer.cornerRadius = 12
        box.clipsToBounds = true
        box.borderColor = isRequired ? UIColor(hexString: "#F0708C") : .fdBorder
        box.dashed = true
        box.solidBorder = false
        addSubview(box)
        box.snp.makeConstraints { $0.edges.equalToSuperview() }

        // 角标必须用「容器 + 固定高度」，UILabel 直接进 UIStackView 会被压成 0 高导致不显示
        let badge = makeRuleBadge(mode: group.selectMode)

        let divider = UIView()
        divider.backgroundColor = .fdBorder

        let header = UIView()
        header.addSubview(badge)
        header.addSubview(divider)
        badge.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.height.equalTo(20)
        }
        divider.snp.makeConstraints {
            $0.top.equalTo(badge.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
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

        let stack = UIStackView(arrangedSubviews: [header, rows])
        stack.axis = .vertical
        stack.spacing = 0
        box.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
    }

    /// checkType → 必选 / 单选 / 可选
    private func makeRuleBadge(mode: ServicePackageSelectMode) -> UIView {
        let text: String
        switch mode {
        case .required: text = "必选"
        case .radio: text = "单选"
        case .checkbox: text = "可选"
        }

        let container = UIView()
        container.layer.cornerRadius = 10
        container.clipsToBounds = true

        let label = UILabel()
        label.text = text
        label.font = .fdMicroSemibold
        label.textAlignment = .center
        label.numberOfLines = 1

        switch mode {
        case .required:
            container.backgroundColor = UIColor(hexString: "#FDE3E9")
            label.textColor = UIColor(hexString: "#E0436B")
        case .radio, .checkbox:
            container.backgroundColor = .fdBg2
            label.textColor = .fdText2
        }

        container.addSubview(label)
        label.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(2)
            $0.leading.trailing.equalToSuperview().inset(8)
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
        // 子项无独立选中态（跟随父项，且不展示控件）
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
        name.font = .fdBody
        name.textColor = .fdText
        name.numberOfLines = 2
        let qty = UILabel()
        qty.text = item.qtyLabel
        qty.font = .fdCaption
        qty.textColor = .fdSubtext
        qty.setContentHuggingPriority(.required, for: .horizontal)
        let price = UILabel()
        price.text = item.priceLabel
        price.font = .fdMonoFont(ofSize: 13, weight: .semibold)
        price.textColor = .fdText
        price.setContentHuggingPriority(.required, for: .horizontal)
        price.snp.makeConstraints { $0.width.greaterThanOrEqualTo(44) }

        // 子项：不展示选择控件，不可点选
        let arranged: [UIView]
        if item.isChild {
            arranged = [name, qty, price]
            row.isEnabled = false
        } else {
            let ctrl = makeControl(group: group, selected: selected)
            arranged = [ctrl, name, qty, price]
            row.isEnabled = group.selectMode != .required
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
            line.backgroundColor = .fdBorder
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
        let onColor = UIColor(hexString: "#EE4D6F")
        let box = UIView()
        box.snp.makeConstraints { $0.size.equalTo(20) }

        let isRadio = group.selectMode == .radio
        box.layer.cornerRadius = isRadio ? 10 : 6
        box.layer.borderWidth = 1.5

        if selected {
            if isRadio {
                box.backgroundColor = .white
                box.layer.borderColor = onColor.cgColor
                let dot = UIView()
                dot.backgroundColor = onColor
                dot.layer.cornerRadius = 5
                box.addSubview(dot)
                dot.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(10) }
            } else {
                box.backgroundColor = onColor
                box.layer.borderColor = onColor.cgColor
                let iv = UIImageView(image: UIImage(systemName: "checkmark"))
                iv.tintColor = .white
                iv.contentMode = .scaleAspectFit
                box.addSubview(iv)
                iv.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(12) }
            }
        } else {
            box.backgroundColor = .clear
            box.layer.borderColor = UIColor.fdBorder.cgColor
        }

        if group.selectMode == .required {
            box.alpha = 0.85
        }
        return box
    }
}
