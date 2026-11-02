import SnapKit
import UIKit

/// 解除绑定确认。对齐 Figma 6778:11071。
final class DeviceUnbindDialogViewController: UIViewController {

    var onConfirm: (() -> Void)?

    private let dimView = UIView()
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let cancelButton = UIButton(type: .custom)
    private let confirmButton = UIButton(type: .custom)

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        dimView.backgroundColor = UIColor(red: 2 / 255, green: 1 / 255, blue: 0, alpha: 0.9)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissSelf)))
        view.addSubview(dimView)

        cardView.backgroundColor = .fdSurface
        cardView.layer.cornerRadius = 20
        cardView.clipsToBounds = true
        view.addSubview(cardView)

        titleLabel.text = "确认解除绑定？"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .fdText
        titleLabel.textAlignment = .center

        messageLabel.text = "解除绑定后将无法同步该设备的数据"
        messageLabel.font = .fdFont(ofSize: 14, weight: .regular)
        messageLabel.textColor = UIColor(hexString: "#A6ACB8")
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(.fdPrimary, for: .normal)
        cancelButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        cancelButton.layer.cornerRadius = 20
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor.fdPrimary.cgColor
        cancelButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        confirmButton.setTitle("解除绑定", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        confirmButton.backgroundColor = .fdPrimary
        confirmButton.layer.cornerRadius = 20
        confirmButton.addTarget(self, action: #selector(handleConfirm), for: .touchUpInside)

        let buttonRow = UIStackView(arrangedSubviews: [cancelButton, confirmButton])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 7
        buttonRow.distribution = .fillEqually

        cardView.addSubview(titleLabel)
        cardView.addSubview(messageLabel)
        cardView.addSubview(buttonRow)

        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }
        cardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(319)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        buttonRow.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-24)
        }
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

    @objc private func handleConfirm() {
        let confirm = onConfirm
        dismiss(animated: true) {
            confirm?()
        }
    }
}
