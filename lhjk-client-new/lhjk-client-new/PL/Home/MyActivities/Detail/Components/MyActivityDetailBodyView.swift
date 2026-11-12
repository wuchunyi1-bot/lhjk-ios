import Kingfisher
import SnapKit
import UIKit

/// 活动详情正文：活动信息、领取福利官、本场设备检测入口。
final class MyActivityDetailBodyView: UIView {

    var onClaim: (() -> Void)?
    var onDevice: ((MyActivityDeviceEntry) -> Void)?

    private let infoCard: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()

    private let watermark = UIImageView(image: UIImage(named: "event_detail_icon"))

    private let themeLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 18, weight: .medium)
        label.textColor = UIColor(hexString: "#522B0F")
        label.numberOfLines = 0
        return label
    }()

    private let timeIcon = UIImageView(image: UIImage(named: "event_live_time"))
    private let ownerIcon = UIImageView(image: UIImage(named: "event_live_leader"))
    private let timeLabel = metaLabel()
    private let ownerLabel = metaLabel()

    private let welfareCard = WelfareCardView()

    private let deviceCard: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()

    private let deviceTitle: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 18, weight: .medium)
        label.textColor = UIColor(hexString: "#1F2430")
        label.text = "设备检测"
        return label
    }()

    private let deviceGrid = UIStackView()

    private var devices: [MyActivityDeviceEntry] = []
    private var infoCardBottom: Constraint?
    private var deviceCardBottom: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ content: MyActivityDetailContent) {
        themeLabel.text = content.theme
        timeLabel.text = "活动时间：\(content.timeText)"
        ownerLabel.text = "活动负责人：\(content.owner)"
        devices = content.devices
        let showsDevices = !devices.isEmpty
        deviceCard.isHidden = !showsDevices
        infoCardBottom?.isActive = !showsDevices
        deviceCardBottom?.isActive = showsDevices
        rebuildDevices()
    }

    private func setup() {
        watermark.contentMode = .scaleAspectFit
        timeIcon.contentMode = .scaleAspectFit
        ownerIcon.contentMode = .scaleAspectFit
        deviceGrid.axis = .vertical
        deviceGrid.spacing = 12

        addSubview(infoCard)
        infoCard.addSubview(watermark)
        infoCard.addSubview(themeLabel)
        infoCard.addSubview(timeIcon)
        infoCard.addSubview(timeLabel)
        infoCard.addSubview(ownerIcon)
        infoCard.addSubview(ownerLabel)
        infoCard.addSubview(welfareCard)
        addSubview(deviceCard)
        deviceCard.addSubview(deviceTitle)
        deviceCard.addSubview(deviceGrid)
        welfareCard.claimButton.addTarget(self, action: #selector(claimTapped), for: .touchUpInside)

        infoCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            infoCardBottom = make.bottom.equalToSuperview().offset(-24).constraint
        }
        infoCardBottom?.isActive = false
        watermark.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.width.equalTo(160)
            make.height.equalTo(120)
        }
        themeLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(20)
            make.trailing.lessThanOrEqualTo(watermark.snp.leading).offset(24)
        }
        timeIcon.snp.makeConstraints { make in
            make.leading.equalTo(themeLabel)
            make.top.equalTo(themeLabel.snp.bottom).offset(8)
            make.size.equalTo(16)
        }
        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(timeIcon.snp.trailing).offset(3)
            make.centerY.equalTo(timeIcon)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        ownerIcon.snp.makeConstraints { make in
            make.leading.size.equalTo(timeIcon)
            make.top.equalTo(timeIcon.snp.bottom).offset(10)
        }
        ownerLabel.snp.makeConstraints { make in
            make.leading.equalTo(ownerIcon.snp.trailing).offset(3)
            make.centerY.equalTo(ownerIcon)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        welfareCard.snp.makeConstraints { make in
            make.top.equalTo(ownerIcon.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-16)
        }
        deviceCard.snp.makeConstraints { make in
            make.top.equalTo(infoCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            deviceCardBottom = make.bottom.equalToSuperview().offset(-24).constraint
        }
        deviceTitle.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(15)
            make.trailing.equalToSuperview().offset(-15)
        }
        deviceGrid.snp.makeConstraints { make in
            make.top.equalTo(deviceTitle.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(11)
            make.bottom.equalToSuperview().offset(-15)
        }
    }

    private func rebuildDevices() {
        deviceGrid.arrangedSubviews.forEach {
            deviceGrid.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        var index = 0
        while index < devices.count {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 9
            row.distribution = .fillEqually
            row.addArrangedSubview(deviceTile(devices[index], tag: index))
            if index + 1 < devices.count {
                row.addArrangedSubview(deviceTile(devices[index + 1], tag: index + 1))
            } else {
                let spacer = UIView()
                spacer.isUserInteractionEnabled = false
                row.addArrangedSubview(spacer)
            }
            deviceGrid.addArrangedSubview(row)
            index += 2
        }
    }

    private func deviceTile(_ device: MyActivityDeviceEntry, tag: Int) -> UIControl {
        let tile = UIControl()
        tile.tag = tag
        tile.backgroundColor = UIColor(hexString: "#FDF6F3")
        tile.layer.cornerRadius = 12
        tile.clipsToBounds = true
        tile.addTarget(self, action: #selector(deviceTapped(_:)), for: .touchUpInside)

        let name = UILabel()
        name.font = .fdFont(ofSize: 16, weight: .medium)
        name.textColor = UIColor(hexString: "#1F2942")
        name.numberOfLines = 2
        name.text = device.name
        name.isUserInteractionEnabled = false

        let action = UILabel()
        action.font = .fdFont(ofSize: 14, weight: .regular)
        action.textColor = UIColor(hexString: "#FF7A50")
        action.text = "去检测"
        action.isUserInteractionEnabled = false

        let chevron = UIImageView(image: UIImage(named: "event_arrow"))
        chevron.contentMode = .scaleAspectFit

        let photo = UIImageView()
        photo.contentMode = .scaleAspectFit
        photo.clipsToBounds = true
        photo.isUserInteractionEnabled = false
        if let imageUrl = device.imageUrl, let url = URL(string: imageUrl) {
            photo.kf.setImage(with: url)
        }

        tile.addSubview(name)
        tile.addSubview(action)
        tile.addSubview(chevron)
        tile.addSubview(photo)
        tile.snp.makeConstraints { $0.height.greaterThanOrEqualTo(81) }
        name.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        action.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(name.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-14)
        }
        chevron.snp.makeConstraints { make in
            make.leading.equalTo(action.snp.trailing)
            make.centerY.equalTo(action)
            make.size.equalTo(12)
        }
        photo.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-4)
            make.bottom.equalToSuperview().offset(-4)
            make.width.equalTo(72)
            make.height.equalTo(52)
        }
        return tile
    }

    @objc private func claimTapped() {
        onClaim?()
    }

    @objc private func deviceTapped(_ sender: UIControl) {
        guard devices.indices.contains(sender.tag) else { return }
        onDevice?(devices[sender.tag])
    }

    private static func metaLabel() -> UILabel {
        let label = UILabel()
        label.font = .fdFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor(hexString: "#8C714F")
        label.numberOfLines = 1
        return label
    }
}

private final class WelfareCardView: UIView {

    let claimButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("立即领取", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor(hexString: "#FF7950")
        button.layer.cornerRadius = 14
        return button
    }()

    private let gift = UIImageView(image: UIImage(named: "event_detail_gift"))

    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 16
        layer.borderWidth = 0.5
        layer.borderColor = UIColor(hexString: "#FFECD2").cgColor
        clipsToBounds = true
        if let gradient = layer as? CAGradientLayer {
            gradient.colors = [
                UIColor(hexString: "#FFF7EB").cgColor,
                UIColor(hexString: "#FFFAF3").cgColor,
            ]
            gradient.startPoint = CGPoint(x: 0, y: 0)
            gradient.endPoint = CGPoint(x: 1, y: 1)
        }

        let title = UILabel()
        title.font = .fdFont(ofSize: 18, weight: .medium)
        title.textColor = UIColor(hexString: "#522B0F")
        title.text = "添加健康福利官"
        title.numberOfLines = 1

        let subtitle = UILabel()
        subtitle.font = .fdFont(ofSize: 14, weight: .regular)
        subtitle.textColor = UIColor(hexString: "#8C714F")
        subtitle.numberOfLines = 0
        subtitle.text = "一键领取现场健康福利，享报告解读、健康咨询等专属权益"

        gift.contentMode = .scaleAspectFit
        addSubview(gift)
        addSubview(title)
        addSubview(subtitle)
        addSubview(claimButton)

        gift.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.top.equalToSuperview().offset(8)
            make.size.equalTo(89)
        }
        title.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(22)
            make.leading.equalTo(gift.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-12)
        }
        subtitle.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(6)
            make.leading.equalTo(title)
            make.trailing.equalToSuperview().offset(-12)
        }
        claimButton.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(subtitle.snp.bottom).offset(12)
            make.top.greaterThanOrEqualTo(gift.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.greaterThanOrEqualTo(28)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
