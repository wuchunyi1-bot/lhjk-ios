import UIKit
import SnapKit

private enum ComboBenefitRowMetrics {
    static let qtyColumnWidth: CGFloat = 52
    static let priceColumnWidth: CGFloat = 64
    /// 天数列与价格列间距；略大以便天数列整体左移
    static let columnGap: CGFloat = 18
}

/// 权益单行：名称 + 天数列 + 价格列（列宽固定，多行之间上下对齐）
private final class ComboBenefitRowView: UIView {

    private let nameLabel = UILabel()
    private let qtyLabel = UILabel()
    private let priceLabel = UILabel()

    init(item: ServicePackageComboItem, priceWeight: UIFont.Weight = .medium) {
        super.init(frame: .zero)

        nameLabel.text = item.name
        nameLabel.font = .fdFont(ofSize: 16, weight: .regular)
        nameLabel.textColor = UIColor(hexString: "#1F2942")
        nameLabel.numberOfLines = 0
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        qtyLabel.text = item.qtyLabel
        qtyLabel.font = .fdFont(ofSize: 16, weight: .regular)
        qtyLabel.textColor = UIColor(hexString: "#1F2942")
        qtyLabel.textAlignment = .right

        priceLabel.text = ServicePackageMoney.comboDisplayYen(item.priceValue)
        priceLabel.font = .fdFont(ofSize: 16, weight: priceWeight)
        priceLabel.textColor = UIColor(hexString: "#1F2942")
        priceLabel.textAlignment = .right

        addSubview(nameLabel)
        addSubview(qtyLabel)
        addSubview(priceLabel)

        priceLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.equalTo(ComboBenefitRowMetrics.priceColumnWidth)
        }

        qtyLabel.snp.makeConstraints {
            $0.trailing.equalTo(priceLabel.snp.leading).offset(-ComboBenefitRowMetrics.columnGap)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(ComboBenefitRowMetrics.qtyColumnWidth)
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(qtyLabel.snp.leading).offset(-8)
            $0.top.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func setTextColor(_ color: UIColor) {
        nameLabel.textColor = color
        qtyLabel.textColor = color
        priceLabel.textColor = color
    }
}

// MARK: - Selectable Unit Model

private struct SelectableUnit {
    let parentIndex: Int
    let parentItem: ServicePackageComboItem
    let childIndices: [Int]
    let childItems: [ServicePackageComboItem]
}

/// 套餐权益规则分组卡片 — 对齐 Figma 3805:20864 / 3805:20901 / 3805:20932 / 3805:21606
final class PackageComboGroupView: UIView {

    var onRadioSelect: ((Int) -> Void)?
    var onCheckToggle: ((Int) -> Void)?

    private let headerView = HeaderGradientView()
    private let titleLabel = UILabel()
    private let badgeContainer = UIView()
    private let badgeLabel = UILabel()
    private let contentStack = UIStackView()

    private var group: ServicePackageComboGroup?
    private var unitViews: [SelectableUnitView] = []
    private var currentRadioPick: Int?
    private var currentCheckPicks: Set<Int> = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor(hexString: "#FFEEDC").cgColor
        clipsToBounds = true

        addSubview(headerView)
        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(43)
        }

        titleLabel.font = .fdFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#A25300")

        badgeContainer.backgroundColor = .white
        badgeContainer.layer.cornerRadius = 10
        badgeContainer.clipsToBounds = true

        badgeLabel.font = .fdFont(ofSize: 12, weight: .medium)
        badgeLabel.textColor = UIColor(hexString: "#A25300")

        badgeContainer.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(8)
            $0.top.bottom.equalToSuperview().inset(2.5)
        }
        badgeContainer.snp.makeConstraints {
            $0.height.equalTo(20)
        }

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, badgeContainer])
        headerStack.axis = .horizontal
        headerStack.spacing = 6
        headerStack.alignment = .center

        headerView.addSubview(headerStack)
        headerStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.centerY.equalToSuperview()
        }

        contentStack.axis = .vertical
        contentStack.spacing = 8
        addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(10)
            $0.bottom.equalToSuperview().inset(10)
        }
    }

    func configure(
        group: ServicePackageComboGroup,
        radioPick: Int?,
        checkPicks: Set<Int>
    ) {
        self.group = group
        self.currentRadioPick = radioPick
        self.currentCheckPicks = checkPicks

        titleLabel.text = group.name

        let modeText: String
        switch group.selectMode {
        case .required: modeText = "必选"
        case .radio: modeText = "单选"
        case .checkbox: modeText = "多选"
        }
        badgeLabel.text = modeText

        if group.selectMode == .required {
            backgroundColor = UIColor(hexString: "#FFFCF8")
        } else {
            backgroundColor = .white
        }

        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        unitViews.removeAll()

        if group.selectMode == .required {
            contentStack.spacing = 0
            for (index, item) in group.items.enumerated() {
                let row = makeRequiredRow(
                    index: index,
                    item: item,
                    showDivider: index < group.items.count - 1
                )
                contentStack.addArrangedSubview(row)
            }
        } else {
            contentStack.spacing = 4
            let units = buildSelectableUnits(from: group)
            for (unitIndex, unit) in units.enumerated() {
                let isSelected: Bool
                switch group.selectMode {
                case .radio:
                    isSelected = radioPick == unit.parentIndex
                case .checkbox:
                    isSelected = checkPicks.contains(unit.parentIndex)
                case .required:
                    isSelected = true
                }

                let unitView = SelectableUnitView(
                    mode: group.selectMode,
                    unit: unit,
                    isSelected: isSelected
                )

                unitView.onTap = { [weak self, weak unitView] in
                    guard let self, let unitView else { return }
                    self.handleUnitTap(unitView)
                }

                unitViews.append(unitView)
                contentStack.addArrangedSubview(unitView)
            }
            updateDividers()
        }
    }

    private func handleUnitTap(_ tappedUnit: SelectableUnitView) {
        guard let group else { return }
        switch group.selectMode {
        case .radio:
            currentRadioPick = tappedUnit.unit.parentIndex
            for uv in unitViews {
                let sel = uv.unit.parentIndex == currentRadioPick
                uv.setSelectedState(sel, animated: true)
            }
            updateDividers()
            onRadioSelect?(tappedUnit.unit.parentIndex)
        case .checkbox:
            let pIndex = tappedUnit.unit.parentIndex
            if currentCheckPicks.contains(pIndex) {
                currentCheckPicks.remove(pIndex)
            } else {
                currentCheckPicks.insert(pIndex)
            }
            tappedUnit.setSelectedState(currentCheckPicks.contains(pIndex), animated: true)
            updateDividers()
            onCheckToggle?(pIndex)
        case .required:
            break
        }
    }

    private func updateDividers() {
        guard let group, group.selectMode != .required else { return }
        for (i, uv) in unitViews.enumerated() {
            let hasNext = i < unitViews.count - 1
            let showDivider = hasNext && !uv.isSelected && !unitViews[i + 1].isSelected
            uv.showBottomDivider(showDivider)
        }
    }

    // MARK: - Required Rows

    private func makeRequiredRow(
        index: Int,
        item: ServicePackageComboItem,
        showDivider: Bool
    ) -> UIView {
        let row = UIView()

        let leading: CGFloat = item.isChild ? 24 : 6
        let benefitRow = ComboBenefitRowView(item: item, priceWeight: .medium)
        row.addSubview(benefitRow)
        benefitRow.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(leading)
            $0.trailing.equalToSuperview().offset(-6)
            $0.top.bottom.equalToSuperview().inset(12)
        }

        if showDivider {
            let line = UIView()
            line.backgroundColor = UIColor(hexString: "#FFEEDC")
            row.addSubview(line)
            line.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(leading)
                $0.trailing.bottom.equalToSuperview()
                $0.height.equalTo(0.5)
            }
        }

        return row
    }

    // MARK: - Selectable Units Builder

    private func buildSelectableUnits(from group: ServicePackageComboGroup) -> [SelectableUnit] {
        var units: [SelectableUnit] = []
        var i = 0
        while i < group.items.count {
            if !group.items[i].isChild {
                let parentIndex = i
                let parentItem = group.items[i]
                var childIndices: [Int] = []
                var childItems: [ServicePackageComboItem] = []
                i += 1
                while i < group.items.count && group.items[i].isChild {
                    childIndices.append(i)
                    childItems.append(group.items[i])
                    i += 1
                }
                units.append(SelectableUnit(
                    parentIndex: parentIndex,
                    parentItem: parentItem,
                    childIndices: childIndices,
                    childItems: childItems
                ))
            } else {
                i += 1
            }
        }
        return units
    }
}

// MARK: - 可选项单元视图（严格对齐与平滑切换）

private final class SelectableUnitView: UIControl {

    let mode: ServicePackageSelectMode
    let unit: SelectableUnit

    var onTap: (() -> Void)?

    private let bgBox = UIView()
    private let controlImageView = UIImageView()
    private let parentRowView: ComboBenefitRowView

    private var childRows: [ComboBenefitRowView] = []
    private let bottomDividerLine = UIView()

    private enum Metrics {
        /// 选中/未选中统一垂直 inset，避免切换时高度变化导致闪动
        static let contentVerticalInset: CGFloat = 14
    }

    init(
        mode: ServicePackageSelectMode,
        unit: SelectableUnit,
        isSelected: Bool
    ) {
        self.mode = mode
        self.unit = unit
        self.parentRowView = ComboBenefitRowView(item: unit.parentItem, priceWeight: .medium)
        super.init(frame: .zero)
        self.isSelected = isSelected
        setupUI()
        applySelectionState()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear

        bgBox.isUserInteractionEnabled = false
        bgBox.layer.cornerRadius = 12
        bgBox.backgroundColor = .white
        addSubview(bgBox)
        bgBox.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        controlImageView.contentMode = .scaleAspectFit
        controlImageView.clipsToBounds = true
        if mode == .radio {
            controlImageView.layer.cornerRadius = 7
        } else {
            controlImageView.layer.cornerRadius = 3.5
        }
        addSubview(controlImageView)
        controlImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(10)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(14)
        }

        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.isUserInteractionEnabled = false
        addSubview(mainStack)
        mainStack.snp.makeConstraints {
            $0.leading.equalTo(controlImageView.snp.trailing).offset(10)
            $0.trailing.equalToSuperview().inset(10)
            $0.top.bottom.equalToSuperview().inset(Metrics.contentVerticalInset)
        }

        mainStack.addArrangedSubview(parentRowView)

        for childItem in unit.childItems {
            let childRow = ComboBenefitRowView(item: childItem, priceWeight: .regular)
            childRows.append(childRow)
            mainStack.addArrangedSubview(childRow)
        }

        bottomDividerLine.backgroundColor = UIColor(hexString: "#FFEEDC")
        bottomDividerLine.isHidden = true
        addSubview(bottomDividerLine)
        bottomDividerLine.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(10)
            $0.trailing.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    @objc private func didTap() {
        onTap?()
    }

    func setSelectedState(_ selected: Bool, animated: Bool = false) {
        guard self.isSelected != selected else { return }
        self.isSelected = selected
        applySelectionState()
    }

    func showBottomDivider(_ show: Bool) {
        bottomDividerLine.isHidden = !show
    }

    private func applySelectionState() {
        let selected = self.isSelected

        if selected {
            bgBox.backgroundColor = UIColor(hexString: "#FFFCF8")
            bgBox.layer.borderWidth = 0.5
            bgBox.layer.borderColor = UIColor(hexString: "#FF9F40").cgColor

            controlImageView.layer.borderWidth = 0
            controlImageView.layer.borderColor = nil
            controlImageView.image = mode == .radio
                ? UIImage(named: "package_detail_radio_checked")
                : UIImage(named: "package_detail_checkbox_checked")
        } else {
            bgBox.backgroundColor = .white
            bgBox.layer.borderWidth = 0

            controlImageView.image = nil
            controlImageView.layer.borderWidth = 0.7
            controlImageView.layer.borderColor = UIColor(hexString: "#535D72").cgColor
        }

        let textColor = selected ? UIColor(hexString: "#A25300") : UIColor(hexString: "#535D72")
        parentRowView.setTextColor(textColor)
        for cr in childRows {
            cr.setTextColor(textColor)
        }
    }
}

// MARK: - 分组卡片标题背景渐变

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
