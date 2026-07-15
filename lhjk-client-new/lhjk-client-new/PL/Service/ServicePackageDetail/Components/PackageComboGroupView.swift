import UIKit
import SnapKit

final class PackageComboGroupView: UIView {

    var onRadioSelect: ((Int) -> Void)?
    var onCheckToggle: ((Int) -> Void)?

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
        box.dashed = isRequired
        box.solidBorder = !isRequired
        addSubview(box)
        box.snp.makeConstraints { $0.edges.equalToSuperview() }

        let head = UIStackView()
        head.axis = .horizontal
        head.spacing = 8
        head.alignment = .center

        let badge = UILabel()
        if isRequired {
            badge.text = " 必选 "
            badge.backgroundColor = UIColor(hexString: "#FDE3E9")
            badge.textColor = UIColor(hexString: "#E0436B")
        } else {
            badge.text = " \(group.selectMode.rawValue) "
            badge.backgroundColor = .fdBg2
            badge.textColor = .fdText2
        }
        badge.font = .fdMicroSemibold
        badge.layer.cornerRadius = 999
        badge.clipsToBounds = true
        head.addArrangedSubview(badge)

        let gName = UILabel()
        gName.text = "\(group.emoji) \(group.name)"
        gName.font = .fdCaptionSemibold
        gName.textColor = .fdText
        head.addArrangedSubview(gName)

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

        let stack = UIStackView(arrangedSubviews: [head, rows])
        stack.axis = .vertical
        stack.spacing = 8
        box.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
    }

    private func isSelected(
        group: ServicePackageComboGroup,
        index: Int,
        radioPick: Int?,
        checkPicks: Set<Int>
    ) -> Bool {
        switch group.selectMode {
        case .required:
            return true
        case .radio:
            if index == 0 { return true }
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

        let ctrl = makeControl(group: group, index: index, selected: selected)
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

        let stack = UIStackView(arrangedSubviews: [ctrl, name, qty, price])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        row.addSubview(stack)
        stack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(10)
        }

        if showDivider {
            let divider = UIView()
            divider.backgroundColor = .fdBorder
            row.addSubview(divider)
            divider.snp.makeConstraints {
                $0.leading.trailing.bottom.equalToSuperview()
                $0.height.equalTo(1)
            }
        }

        switch group.selectMode {
        case .required:
            break
        case .radio where index > 0:
            row.addAction(UIAction { [weak self] _ in
                self?.onRadioSelect?(index)
            }, for: .touchUpInside)
        case .checkbox:
            row.addAction(UIAction { [weak self] _ in
                self?.onCheckToggle?(index)
            }, for: .touchUpInside)
        default:
            break
        }
        return row
    }

    private func makeControl(group: ServicePackageComboGroup, index: Int, selected: Bool) -> UIView {
        let onColor = UIColor(hexString: "#EE4D6F")
        let box = UIView()
        box.snp.makeConstraints { $0.size.equalTo(20) }

        let isRadio = group.selectMode == .radio && index > 0
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
        return box
    }
}
