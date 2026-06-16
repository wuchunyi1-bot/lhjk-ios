import UIKit
import SnapKit

/// 可选中 chip 按钮 — 支持单选/多选模式
/// 参考 funde-client: ob-chip
final class OptionChipView: UIView {

    // MARK: - Properties

    let label: String
    var isSelected: Bool = false {
        didSet { updateAppearance() }
    }
    var onTap: (() -> Void)?

    // MARK: - UI

    private let titleLabel = UILabel()
    private let tapGesture = UITapGestureRecognizer()

    // MARK: - Init

    init(label: String) {
        self.label = label
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        layer.cornerRadius = 20
        layer.borderWidth = 1.5
        clipsToBounds = true

        titleLabel.text = label
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textAlignment = .center
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)) }

        self.snp.makeConstraints { make in
            make.height.equalTo(38)
        }

        tapGesture.addTarget(self, action: #selector(didTap))
        addGestureRecognizer(tapGesture)

        updateAppearance()
    }

    private func updateAppearance() {
        if isSelected {
            backgroundColor = .fdPrimarySoft
            titleLabel.textColor = .fdPrimary
            titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
            layer.borderColor = UIColor.fdPrimary.cgColor
        } else {
            backgroundColor = .fdSurface
            titleLabel.textColor = .fdSubtext
            titleLabel.font = .systemFont(ofSize: 14)
            layer.borderColor = UIColor.fdBorder.cgColor
        }
    }

    @objc private func didTap() {
        isSelected.toggle()
        onTap?()
    }

    /// Programmatic selection (without calling onTap)
    func setSelected(_ selected: Bool, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.15) {
                self.isSelected = selected
            }
        } else {
            isSelected = selected
        }
    }
}

// MARK: - Option Chip Group (Helper for managing radio/multi-select groups)

/// Chip 组管理器 — 处理单选/多选逻辑
final class OptionChipGroup {

    let chips: [OptionChipView]
    let allowsMultipleSelection: Bool

    /// 当前选中的 chip 数组（单选模式下只有 1 个元素）
    var selectedChips: [OptionChipView] {
        chips.filter { $0.isSelected }
    }

    var selectedLabels: [String] {
        selectedChips.map { $0.label }
    }

    var onSelectionChanged: (([String]) -> Void)?

    init(chips: [OptionChipView], allowsMultipleSelection: Bool) {
        self.chips = chips
        self.allowsMultipleSelection = allowsMultipleSelection
        setupChips()
    }

    private func setupChips() {
        for chip in chips {
            chip.onTap = { [weak self] in
                self?.handleSelection(chip)
            }
        }
    }

    private func handleSelection(_ chip: OptionChipView) {
        if !allowsMultipleSelection {
            // Radio mode: deselect others
            for other in chips where other !== chip {
                other.setSelected(false)
            }
            // Ensure current stays selected
            chip.setSelected(true)
        } else {
            // Multi-select mode: special handling for "无" (none)
            if chip.label == "无" {
                if chip.isSelected {
                    // If "无" is selected, deselect all others
                    for other in chips where other.label != "无" {
                        other.setSelected(false)
                    }
                }
            } else {
                // If selecting a disease, deselect "无"
                for other in chips where other.label == "无" {
                    other.setSelected(false)
                }
            }
        }

        onSelectionChanged?(selectedLabels)
    }

    /// Reset all chips to deselected state
    func reset() {
        chips.forEach { $0.setSelected(false, animated: false) }
    }
}
