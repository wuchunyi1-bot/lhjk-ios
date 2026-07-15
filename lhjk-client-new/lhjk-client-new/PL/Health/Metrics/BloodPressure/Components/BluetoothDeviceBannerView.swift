import UIKit
import SnapKit
import Kingfisher

/// 蓝牙设备状态 Banner
final class BluetoothDeviceBannerView: UIView {

    enum State {
        case unbound
        case connecting
        case connected
        case disconnected
        case poweredOff
    }

    var onTap: (() -> Void)?

    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    private let container = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface

        container.backgroundColor = .fdBg2
        container.layer.cornerRadius = 12
        addSubview(container)

        iconView.contentMode = .scaleAspectFit
        iconView.layer.cornerRadius = 8
        iconView.clipsToBounds = true
        iconView.backgroundColor = .fdSurface

        nameLabel.font = .fdBodySemibold
        nameLabel.textColor = .fdText

        statusLabel.font = .fdCaption
        statusLabel.textColor = .fdSubtext

        container.addSubview(iconView)
        container.addSubview(nameLabel)
        container.addSubview(statusLabel)

        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 12, right: 16))
            make.height.equalTo(72)
        }
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(16)
        }
        statusLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        container.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(equipment: BloodPressureEquipment?, state: State) {
        if let equipment {
            nameLabel.text = equipment.name ?? "血压计"
            if let urlString = equipment.imgUrl, let url = URL(string: urlString) {
                iconView.kf.setImage(with: url, placeholder: UIImage(systemName: "heart.text.square"))
            } else {
                iconView.image = UIImage(systemName: "heart.text.square")
            }
        } else {
            nameLabel.text = "未绑定血压计"
            iconView.image = UIImage(systemName: "heart.text.square")
        }

        switch state {
        case .unbound: statusLabel.text = "点击管理蓝牙设备"
        case .connecting: statusLabel.text = "正在连接..."
        case .connected: statusLabel.text = "已连接，等待测量"
        case .disconnected: statusLabel.text = "设备已断开"
        case .poweredOff: statusLabel.text = "请打开蓝牙"
        }
    }

    @objc private func handleTap() { onTap?() }
}
