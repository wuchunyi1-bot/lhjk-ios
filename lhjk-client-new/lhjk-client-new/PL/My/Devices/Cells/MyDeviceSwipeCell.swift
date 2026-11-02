import Kingfisher
import SnapKit
import UIKit

/// 我的设备列表行。左滑露出红色删除按钮，卡片本身不可点。
final class MyDeviceSwipeCell: UITableViewCell {

    static let reuseID = "MyDeviceSwipeCell"
    static let cardHeight: CGFloat = 65
    static let rowSpacing: CGFloat = 12

    var onDelete: (() -> Void)?
    var onWillSwipe: (() -> Void)?

    private let cardView = UIView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let codeLabel = UILabel()
    private let deleteButton = UIControl()
    private let deleteIcon = UIImageView()
    private let revealOffset: CGFloat = 50
    private let panGate = HorizontalPanGate()
    private var panOrigin: CGFloat = 0
    private var currentOffset: CGFloat = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.kf.cancelDownloadTask()
        iconView.image = UIImage(named: "weight_ble_unbound_scale")
        onDelete = nil
        onWillSwipe = nil
        setOffset(0, animated: false)
    }

    func configure(_ item: ScaleDeviceCardItem) {
        nameLabel.text = item.name
        if item.code.isEmpty {
            codeLabel.isHidden = true
            codeLabel.text = nil
        } else {
            codeLabel.isHidden = false
            codeLabel.text = "设备编码｜\(item.code)"
        }

        let placeholder = UIImage(named: "weight_ble_unbound_scale")
        if let raw = item.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty,
           let url = URL(string: raw) {
            iconView.kf.setImage(with: url, placeholder: placeholder, options: [.transition(.fade(0.15))])
        } else {
            iconView.kf.cancelDownloadTask()
            iconView.image = placeholder
        }
    }

    func close(animated: Bool) {
        setOffset(0, animated: animated)
    }

    var isRevealed: Bool { currentOffset < -1 }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true
        selectionStyle = .none

        deleteButton.backgroundColor = UIColor(hexString: "#F93838")
        deleteButton.layer.cornerRadius = 19
        deleteButton.clipsToBounds = true
        deleteButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
        deleteButton.accessibilityLabel = "解除绑定"
        deleteIcon.image = UIImage(named: "my_device_unbind_trash")
        deleteIcon.contentMode = .scaleAspectFit
        deleteButton.addSubview(deleteIcon)

        cardView.backgroundColor = .fdSurface
        cardView.layer.cornerRadius = 12
        cardView.clipsToBounds = true

        iconView.contentMode = .scaleAspectFit
        iconView.image = UIImage(named: "weight_ble_unbound_scale")

        nameLabel.font = .fdFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 1

        codeLabel.font = .fdFont(ofSize: 12, weight: .regular)
        codeLabel.textColor = UIColor(hexString: "#6D7381")
        codeLabel.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [nameLabel, codeLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading

        contentView.addSubview(deleteButton)
        contentView.addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(textStack)

        deleteButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(cardView)
            make.size.equalTo(38)
        }
        deleteIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(24)
        }
        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(Self.cardHeight)
            make.bottom.equalToSuperview().offset(-Self.rowSpacing)
        }
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(11)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = panGate
        cardView.addGestureRecognizer(pan)
    }

    @objc private func handleDelete() {
        onDelete?()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: contentView).x
        switch gesture.state {
        case .began:
            onWillSwipe?()
            panOrigin = currentOffset
        case .changed:
            setOffset(panOrigin + translation, animated: false)
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: contentView).x
            let shouldOpen = currentOffset < -revealOffset / 2 || velocity < -400
            setOffset(shouldOpen ? -revealOffset : 0, animated: true)
        default:
            break
        }
    }

    private func setOffset(_ value: CGFloat, animated: Bool) {
        let clamped = min(0, max(-revealOffset, value))
        currentOffset = clamped
        let updates = {
            self.cardView.transform = CGAffineTransform(translationX: clamped, y: 0)
        }
        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseOut, animations: updates)
        } else {
            updates()
        }
    }
}

private final class HorizontalPanGate: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: pan.view)
        return abs(velocity.x) > abs(velocity.y)
    }
}
