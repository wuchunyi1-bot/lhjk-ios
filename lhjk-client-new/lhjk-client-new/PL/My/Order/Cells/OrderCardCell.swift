import UIKit
import SnapKit

/// 订单卡片 Cell — 服务名 + 状态标签 + 套餐描述 + 日期 + 价格
/// 参考 funde-client: order-card
/// 对接后端 AppOrderListBO 模型
final class OrderCardCell: UITableViewCell {

    static let reuseIdentifier = "OrderCardCell"

    // MARK: - UI

    private let cardView = UIView()
    private let nameLabel = UILabel()
    private let statusContainer = UIView()
    private let statusLabel = UILabel()
    private let tagLabel = UILabel()
    private let dateLabel = UILabel()
    private let priceLabel = UILabel()

    // MARK: - Status Color Map (API status 1-9)

    struct StatusStyle {
        let bg: UIColor; let text: UIColor
    }

    private let statusColors: [Int: StatusStyle] = [
        1: StatusStyle(bg: UIColor(hexString: "#FFF8E8"), text: UIColor(hexString: "#B47300")), // 待付款
        2: StatusStyle(bg: UIColor(hexString: "#FFF3EE"), text: UIColor(hexString: "#FF7A50")), // 待发货
        3: StatusStyle(bg: UIColor(hexString: "#FFF3EE"), text: UIColor(hexString: "#FF7A50")), // 待收货
        4: StatusStyle(bg: UIColor(hexString: "#EEF6FF"), text: UIColor(hexString: "#3D6FB8")), // 使用中
        5: StatusStyle(bg: UIColor(hexString: "#F0FAF4"), text: UIColor(hexString: "#52B96A")), // 已完成
        6: StatusStyle(bg: UIColor(hexString: "#FFF0F0"), text: UIColor(hexString: "#D6602B")), // 退款/售后
        7: StatusStyle(bg: UIColor(hexString: "#F0F0F0"), text: UIColor(hexString: "#999999")), // 已逾期
        8: StatusStyle(bg: UIColor(hexString: "#F0F0F0"), text: UIColor(hexString: "#999999")), // 已取消
        9: StatusStyle(bg: UIColor(hexString: "#FFF8E8"), text: UIColor(hexString: "#B47300")), // 退款审核中
    ]

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupCard()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCard() {
        cardView.backgroundColor = .fdSurface
        cardView.layer.cornerRadius = 24
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 1)
        cardView.layer.shadowRadius = 6
        cardView.layer.shadowOpacity = 0.03
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)) }

        // Status badge
        statusContainer.layer.cornerRadius = 999
        statusLabel.font = .fdMicroSemibold
        statusContainer.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }

        // Header row: name + status
        nameLabel.font = .fdBodyBold
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 1

        cardView.addSubview(nameLabel)
        cardView.addSubview(statusContainer)

        nameLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualTo(statusContainer.snp.leading).offset(-12)
        }
        statusContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        // Package description / hospital name
        tagLabel.font = .fdCaption
        tagLabel.textColor = .fdSubtext
        tagLabel.numberOfLines = 1
        cardView.addSubview(tagLabel)
        tagLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        // Date
        dateLabel.font = .fdCaption
        dateLabel.textColor = .fdSubtext
        cardView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(tagLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        // Price
        priceLabel.font = .fdBodyBold
        priceLabel.textColor = .fdPrimary
        cardView.addSubview(priceLabel)
        priceLabel.snp.makeConstraints { make in
            make.centerY.equalTo(dateLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
    }

    // MARK: - Configure

    func configure(order: MOrder) {
        nameLabel.text = order.orderName ?? "未命名订单"
        statusLabel.text = order.statusLabel
        tagLabel.text = order.packageDescription ?? order.hospitalName
        dateLabel.text = order.dateRangeText
        priceLabel.text = order.priceText

        // Status style
        if let status = order.status, let style = statusColors[status] {
            statusContainer.backgroundColor = style.bg
            statusLabel.textColor = style.text
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        statusLabel.text = nil
        tagLabel.text = nil
        dateLabel.text = nil
        priceLabel.text = nil
    }
}
