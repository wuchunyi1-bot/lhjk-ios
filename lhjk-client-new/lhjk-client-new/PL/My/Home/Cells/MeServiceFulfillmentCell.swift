import UIKit
import SnapKit

/// 服务履约卡片视图 — 对齐 Figma 3594:8634
final class MeServiceFulfillmentCardView: UIView {

    struct StatItem {
        let label: String
        let value: String
        let tabKey: String
    }

    var onAllOrdersTap: (() -> Void)?
    var onStatTap: ((Int) -> Void)?

    private let titleLabel = UILabel()
    private let allOrdersLabel = UILabel()
    private let allOrdersArrow = UIImageView()
    private let allOrdersButton = UIButton(type: .custom)
    private let statsStack = UIStackView()
    private var valueLabels: [UILabel] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 16
        clipsToBounds = true

        // Title: 服务履约
        titleLabel.text = "服务履约"
        titleLabel.font = .fdFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#1F2430")
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(16)
        }

        // Right "全部订单" + Arrow
        allOrdersArrow.image = UIImage(named: "me_list_more_arrow")
        allOrdersArrow.contentMode = .scaleAspectFit
        addSubview(allOrdersArrow)
        allOrdersArrow.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(titleLabel)
            $0.size.equalTo(12)
        }

        allOrdersLabel.text = "全部订单"
        allOrdersLabel.font = .fdFont(ofSize: 12, weight: .regular)
        allOrdersLabel.textColor = UIColor(hexString: "#717885")
        addSubview(allOrdersLabel)
        allOrdersLabel.snp.makeConstraints {
            $0.trailing.equalTo(allOrdersArrow.snp.leading).offset(-2)
            $0.centerY.equalTo(titleLabel)
        }

        allOrdersButton.addTarget(self, action: #selector(handleAllOrdersTap), for: .touchUpInside)
        addSubview(allOrdersButton)
        allOrdersButton.snp.makeConstraints {
            $0.trailing.top.equalToSuperview()
            $0.leading.equalTo(allOrdersLabel.snp.leading).offset(-8)
            $0.bottom.equalTo(titleLabel.snp.bottom).offset(8)
        }

        // Stats Stack (top 55pt)
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.alignment = .fill
        addSubview(statsStack)
        statsStack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalToSuperview().offset(55)
            $0.bottom.equalToSuperview().offset(-15)
        }

        snp.makeConstraints {
            $0.height.equalTo(110)
        }
    }

    func configure(stats: [StatItem]) {
        statsStack.arrangedSubviews.forEach {
            statsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        valueLabels.removeAll()

        for (index, stat) in stats.enumerated() {
            let col = UIView()
            let button = UIButton(type: .custom)
            button.tag = index
            button.addTarget(self, action: #selector(handleStatTap(_:)), for: .touchUpInside)
            col.addSubview(button)
            button.snp.makeConstraints { $0.edges.equalToSuperview() }

            let valLbl = UILabel()
            valLbl.text = stat.value
            valLbl.textColor = UIColor(hexString: "#1F2942")
            valLbl.font = .fdFont(ofSize: 18, weight: .medium)
            valLbl.textAlignment = .center
            valLbl.isUserInteractionEnabled = false

            let lblLbl = UILabel()
            lblLbl.text = stat.label
            lblLbl.font = .fdFont(ofSize: 12, weight: .regular)
            lblLbl.textColor = UIColor(hexString: "#1F2942")
            lblLbl.textAlignment = .center
            lblLbl.isUserInteractionEnabled = false

            button.addSubview(valLbl)
            button.addSubview(lblLbl)

            valLbl.snp.makeConstraints {
                $0.top.equalToSuperview()
                $0.centerX.equalToSuperview()
            }
            lblLbl.snp.makeConstraints {
                $0.top.equalTo(valLbl.snp.bottom).offset(4)
                $0.centerX.equalToSuperview()
                $0.bottom.equalToSuperview()
            }

            valueLabels.append(valLbl)
            statsStack.addArrangedSubview(col)
        }
    }

    func updateStatValue(at index: Int, value: String) {
        guard index < valueLabels.count else { return }
        valueLabels[index].text = value
    }

    @objc private func handleAllOrdersTap() {
        onAllOrdersTap?()
    }

    @objc private func handleStatTap(_ sender: UIButton) {
        onStatTap?(sender.tag)
    }
}

/// 服务履约 Cell 兼容包装
final class MeServiceFulfillmentCell: UITableViewCell {

    static let reuseIdentifier = "MeServiceFulfillmentCell"

    let cardView = MeServiceFulfillmentCardView()

    var onAllOrdersTap: (() -> Void)? {
        get { cardView.onAllOrdersTap }
        set { cardView.onAllOrdersTap = newValue }
    }

    var onStatTap: ((Int) -> Void)? {
        get { cardView.onStatTap }
        set { cardView.onStatTap = newValue }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(cardView)
        cardView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(stats: [MeServiceFulfillmentCardView.StatItem]) {
        cardView.configure(stats: stats)
    }
}
