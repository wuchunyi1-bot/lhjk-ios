import UIKit
import SnapKit

/// 手动记录 / 历史记录 双入口
final class BloodPressureRecordEntryCell: UITableViewCell {

    static let reuseID = "BloodPressureRecordEntryCell"

    var onManualTap: (() -> Void)?
    var onHistoryTap: (() -> Void)?

    private let manualCard = BloodPressureEntryCard(title: "手动记录", symbol: "square.and.pencil")
    private let historyCard = BloodPressureEntryCard(title: "历史记录", symbol: "clock.arrow.circlepath")

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        let stack = UIStackView(arrangedSubviews: [manualCard, historyCard])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 12, right: 16))
            make.height.equalTo(88)
        }

        manualCard.addTarget(self, action: #selector(manualTapped), for: .touchUpInside)
        historyCard.addTarget(self, action: #selector(historyTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func manualTapped() { onManualTap?() }
    @objc private func historyTapped() { onHistoryTap?() }
}

private final class BloodPressureEntryCard: UIControl {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    init(title: String, symbol: String) {
        super.init(frame: .zero)
        backgroundColor = .fdSurface
        layer.cornerRadius = 12

        iconView.image = UIImage(systemName: symbol)
        iconView.tintColor = .fdPrimary
        iconView.contentMode = .scaleAspectFit

        titleLabel.text = title
        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText
        titleLabel.textAlignment = .center

        addSubview(iconView)
        addSubview(titleLabel)
        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.size.equalTo(28)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
