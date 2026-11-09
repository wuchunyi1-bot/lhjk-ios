import SnapKit
import UIKit

/// 我的设备绑定成功。对齐 Figma 6751:10774。健康页体重绑定不进入此页。
final class DeviceBindSuccessViewController: BaseViewController {

    private let deviceName: String
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let actionButton = UIButton(type: .custom)

    init(deviceName: String) {
        let trimmed = deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.deviceName = trimmed.isEmpty ? "设备" : trimmed
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        title = "设备绑定"
        view.backgroundColor = .fdBg
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: .fdNavBack,
            style: .plain,
            target: self,
            action: #selector(backToMyDevices)
        )
        navigationItem.leftBarButtonItem?.tintColor = .fdText

        iconView.image = UIImage(named: "device_bind_success")
        iconView.contentMode = .scaleAspectFit

        titleLabel.text = "绑定成功"
        titleLabel.font = .fdFont(ofSize: 18, weight: .regular)
        titleLabel.textColor = .fdText
        titleLabel.textAlignment = .center

        subtitleLabel.text = "\(deviceName) 已添加到我的设备"
        subtitleLabel.font = .fdFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .fdTabInactive
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        actionButton.setTitle("查看我的设备", for: .normal)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        actionButton.backgroundColor = .fdPrimary
        actionButton.layer.cornerRadius = 20
        actionButton.addTarget(self, action: #selector(backToMyDevices), for: .touchUpInside)

        view.addSubview(iconView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(actionButton)

        iconView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(168)
            make.centerX.equalToSuperview()
            make.width.equalTo(74)
            make.height.equalTo(84)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        actionButton.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
            make.width.equalTo(167)
            make.height.equalTo(40)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @objc private func backToMyDevices() {
        guard let nav = navigationController else { return }
        if let devices = nav.viewControllers.last(where: { $0 is DevicesViewController }) {
            nav.popToViewController(devices, animated: true)
        } else {
            nav.popViewController(animated: true)
        }
    }
}
