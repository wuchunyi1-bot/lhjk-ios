import UIKit
import SnapKit

protocol PackageDetailTierPickerViewDelegate: AnyObject {
    func tierPickerView(_ view: PackageDetailTierPickerView, didSelect index: Int)
}

final class PackageDetailTierPickerView: UIView {

    weak var delegate: PackageDetailTierPickerViewDelegate?

    private let titleLabel = UILabel()
    private let chipRow = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "选择档次"
        titleLabel.font = .fdFont(ofSize: 15, weight: .heavy)
        titleLabel.textColor = .fdText
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        chipRow.axis = .horizontal
        chipRow.spacing = 8
        chipRow.distribution = .fillEqually
        addSubview(chipRow)
        chipRow.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(tiers: [ServicePackageTier], selectedIndex: Int, accent: UIColor) {
        chipRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, tier) in tiers.enumerated() {
            chipRow.addArrangedSubview(makeChip(tier: tier, index: index, selected: index == selectedIndex, accent: accent))
        }
    }

    private func makeChip(tier: ServicePackageTier, index: Int, selected: Bool, accent: UIColor) -> UIView {
        let chip = UIControl()
        chip.tag = index
        chip.layer.cornerRadius = 12
        chip.layer.borderWidth = 1.5
        chip.backgroundColor = selected ? accent.withAlphaComponent(0.06) : .fdSurface
        chip.layer.borderColor = (selected ? accent : UIColor.fdBorder).cgColor
        chip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)

        let name = UILabel()
        name.text = tier.name
        name.font = .fdCaptionSemibold
        name.textColor = selected ? accent : .fdText
        name.textAlignment = .center
        let price = UILabel()
        price.text = tier.priceLabel
        price.font = .fdMicro
        price.textColor = selected ? accent : .fdSubtext
        price.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [name, price])
        stack.axis = .vertical
        stack.spacing = 3
        stack.isUserInteractionEnabled = false
        chip.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(10) }
        return chip
    }

    @objc private func chipTapped(_ sender: UIControl) {
        delegate?.tierPickerView(self, didSelect: sender.tag)
    }
}
