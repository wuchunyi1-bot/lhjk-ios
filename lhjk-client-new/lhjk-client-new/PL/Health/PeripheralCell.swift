import UIKit

/// 蓝牙设备列表 Cell
final class PeripheralCell: UITableViewCell {

    static let reuseIdentifier = "PeripheralCell"

    // MARK: - UI Components

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let rssiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupUI() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(rssiLabel)
        contentView.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),

            rssiLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            rssiLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            rssiLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            statusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Configuration

    func configure(with peripheral: Peripheral) {
        nameLabel.text = peripheral.name ?? "未知设备"
        rssiLabel.text = "信号强度: \(peripheral.rssi) dBm"
        statusLabel.text = peripheral.isConnected ? "已连接" : "未连接"
        statusLabel.textColor = peripheral.isConnected ? .systemGreen : .secondaryLabel
    }
}
