import SnapKit
import UIKit

/// 活动详情正文：活动信息、领取福利官、本场设备检测入口。
final class MyActivityDetailBodyView: UIView {

    var onClaim: (() -> Void)?
    var onDevice: ((MyActivityDeviceEntry) -> Void)?

    private let infoCard: UIView = {
        let view = UIView()
        view.backgroundColor = .fdSurface
        view.layer.cornerRadius = 16
        return view
    }()

    private let themeLabel: UILabel = {
        let label = UILabel()
        label.font = .fdH3
        label.textColor = .fdText
        label.numberOfLines = 0
        return label
    }()

    private let timeTitle = fieldTitle("活动时间")
    private let timeValue = fieldValue()
    private let ownerTitle = fieldTitle("活动负责人")
    private let ownerValue = fieldValue()

    private let divider: UIView = {
        let view = UIView()
        view.backgroundColor = .fdBorder
        return view
    }()

    private let welfareCard: UIView = {
        let view = UIView()
        view.backgroundColor = .fdPrimarySoft
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.fdPrimaryEdge.cgColor
        return view
    }()

    private let giftBadge: UIView = {
        let view = UIView()
        view.backgroundColor = .fdSurface
        view.layer.cornerRadius = 8
        return view
    }()

    private let giftIcon: UIImageView = {
        let image = UIImageView(image: UIImage(systemName: "gift.fill"))
        image.tintColor = .fdPrimary
        image.contentMode = .scaleAspectFit
        return image
    }()

    private let welfareTitle: UILabel = {
        let label = UILabel()
        label.font = .fdBodyBold
        label.textColor = .fdText
        label.text = "添加健康福利官"
        label.numberOfLines = 0
        return label
    }()

    private let welfareSubtitle: UILabel = {
        let label = UILabel()
        label.font = .fdBody
        label.textColor = .fdText2
        label.numberOfLines = 0
        label.text = "一键领取现场健康福利，享报告解读、健康咨询等专属权益。"
        return label
    }()

    private let claimButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("立即领取", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .fdBodyBold
        button.backgroundColor = .fdPrimary
        button.layer.cornerRadius = 24
        return button
    }()

    private let deviceTitle: UILabel = {
        let label = UILabel()
        label.font = .fdBodyBold
        label.textColor = .fdText
        label.text = "设备检测"
        return label
    }()

    private let deviceStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()

    private var devices: [MyActivityDeviceEntry] = []
    private var infoCardBottom: Constraint?
    private var deviceSectionBottom: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ content: MyActivityDetailContent) {
        themeLabel.text = content.theme
        timeValue.text = content.timeText
        ownerValue.text = content.owner
        devices = content.devices
        let showsDevices = !devices.isEmpty
        deviceTitle.isHidden = !showsDevices
        deviceStack.isHidden = !showsDevices
        infoCardBottom?.isActive = !showsDevices
        deviceSectionBottom?.isActive = showsDevices
        deviceStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, device) in devices.enumerated() {
            deviceStack.addArrangedSubview(deviceRow(device, tag: index))
        }
    }

    private func setup() {
        addSubview(infoCard)
        infoCard.addSubview(themeLabel)
        infoCard.addSubview(timeTitle)
        infoCard.addSubview(timeValue)
        infoCard.addSubview(ownerTitle)
        infoCard.addSubview(ownerValue)
        infoCard.addSubview(divider)
        infoCard.addSubview(welfareCard)
        welfareCard.addSubview(giftBadge)
        giftBadge.addSubview(giftIcon)
        welfareCard.addSubview(welfareTitle)
        welfareCard.addSubview(welfareSubtitle)
        welfareCard.addSubview(claimButton)
        addSubview(deviceTitle)
        addSubview(deviceStack)

        claimButton.addTarget(self, action: #selector(claimTapped), for: .touchUpInside)

        infoCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            infoCardBottom = make.bottom.equalToSuperview().offset(-24).constraint
        }
        infoCardBottom?.isActive = false
        themeLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        timeTitle.snp.makeConstraints { make in
            make.top.equalTo(themeLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.width.equalTo(88)
        }
        timeValue.snp.makeConstraints { make in
            make.top.equalTo(timeTitle)
            make.leading.equalTo(timeTitle.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
        }
        ownerTitle.snp.makeConstraints { make in
            make.top.equalTo(timeValue.snp.bottom).offset(12)
            make.leading.width.equalTo(timeTitle)
        }
        ownerValue.snp.makeConstraints { make in
            make.top.equalTo(ownerTitle)
            make.leading.equalTo(ownerTitle.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
        }
        divider.snp.makeConstraints { make in
            make.top.equalTo(ownerValue.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(1)
        }
        welfareCard.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
        giftBadge.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
            make.size.equalTo(48)
        }
        giftIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(26)
        }
        welfareTitle.snp.makeConstraints { make in
            make.top.equalTo(giftBadge)
            make.leading.equalTo(giftBadge.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
        }
        welfareSubtitle.snp.makeConstraints { make in
            make.top.equalTo(welfareTitle.snp.bottom).offset(8)
            make.leading.trailing.equalTo(welfareTitle)
        }
        claimButton.snp.makeConstraints { make in
            make.top.equalTo(welfareSubtitle.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-16)
        }
        deviceTitle.snp.makeConstraints { make in
            make.top.equalTo(infoCard.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        deviceStack.snp.makeConstraints { make in
            make.top.equalTo(deviceTitle.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            deviceSectionBottom = make.bottom.equalToSuperview().offset(-24).constraint
        }
    }

    private func deviceRow(_ device: MyActivityDeviceEntry, tag: Int) -> UIControl {
        let row = UIControl()
        row.tag = tag
        row.backgroundColor = .fdSurface
        row.layer.cornerRadius = 16
        row.addTarget(self, action: #selector(deviceTapped(_:)), for: .touchUpInside)

        let iconWrap = UIView()
        iconWrap.backgroundColor = .fdInfoSoft
        iconWrap.layer.cornerRadius = 12
        iconWrap.isUserInteractionEnabled = false
        let icon = UIImageView(image: UIImage(systemName: device.symbolName))
        icon.tintColor = .fdInfo
        icon.contentMode = .scaleAspectFit
        let name = UILabel()
        name.font = .fdBodyBold
        name.textColor = .fdText
        name.text = device.name
        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .fdSubtext
        arrow.contentMode = .scaleAspectFit

        row.addSubview(iconWrap)
        iconWrap.addSubview(icon)
        row.addSubview(name)
        row.addSubview(arrow)
        row.snp.makeConstraints { $0.height.greaterThanOrEqualTo(64) }
        iconWrap.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(22)
        }
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
        name.snp.makeConstraints { make in
            make.leading.equalTo(iconWrap.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(arrow.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        return row
    }

    @objc private func claimTapped() {
        onClaim?()
    }

    @objc private func deviceTapped(_ sender: UIControl) {
        guard devices.indices.contains(sender.tag) else { return }
        onDevice?(devices[sender.tag])
    }

    private static func fieldTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .fdBody
        label.textColor = .fdSubtext
        label.text = text
        return label
    }

    private static func fieldValue() -> UILabel {
        let label = UILabel()
        label.font = .fdBodyBold
        label.textColor = .fdText
        label.numberOfLines = 0
        return label
    }
}
