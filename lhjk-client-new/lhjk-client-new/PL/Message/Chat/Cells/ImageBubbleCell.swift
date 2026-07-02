import UIKit
import SnapKit
import Kingfisher

/// 图片气泡 Cell — 按缩略图尺寸展示，点击放大看原图
final class ImageBubbleCell: UITableViewCell {

    static let reuseID = "ImageBubbleCell"

    // MARK: - Properties

    weak var delegate: ChatCellDelegate?
    private var currentMessage: ChatMessage?
    private var imagePath: String?
    var onTapImage: ((String?) -> Void)?

    // MARK: - UI

    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 13, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        l.layer.cornerRadius = 17
        l.clipsToBounds = true
        return l
    }()
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 17
        iv.clipsToBounds = true
        iv.isHidden = true
        return iv
    }()

    private let metaLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 10)
        l.textColor = .fdMuted
        return l
    }()

    private let photoView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        iv.isUserInteractionEnabled = true
        return iv
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdBg

        [avatarLabel, avatarImageView, metaLabel, photoView].forEach(contentView.addSubview)

        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        photoView.addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        photoView.addGestureRecognizer(longPress)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(_ msg: ChatMessage, tone: String, convRole: ConversationRole) {
        currentMessage = msg
        let isStaff = msg.isStaff
        imagePath = msg.imagePath

        if let urlStr = msg.portraitUrl, !urlStr.isEmpty, let url = URL(string: urlStr) {
            avatarImageView.isHidden = false
            avatarLabel.isHidden = true
            avatarImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            avatarImageView.isHidden = true
            avatarLabel.isHidden = false
            avatarLabel.text = isStaff ? (msg.avatar ?? msg.senderName?.prefix(1).description ?? "?") : "我"
        }
        avatarLabel.backgroundColor = isStaff
            ? UIColor(hexString: tone)
            : UIColor(hexString: "#FF7A50")

        metaLabel.text = isStaff ? "\(msg.senderName ?? "") · \(msg.senderRole ?? "") · \(msg.time)" : msg.time
        metaLabel.textAlignment = isStaff ? .left : .right

        // 加载缩略图（Kingfisher 自动缓存到内存+磁盘）
        photoView.image = nil
        if let path = msg.imagePath {
            print("[ImageBubbleCell] loading image path=\(path)")
            if path.hasPrefix("/") {
                photoView.image = UIImage(contentsOfFile: path)
            } else if let url = URL(string: path) {
                photoView.kf.setImage(with: url, options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ])
            }
        } else {
            print("[ImageBubbleCell] imagePath is nil!")
        }

        layoutForStaff(isStaff, thumbWidth: msg.thumbWidth, thumbHeight: msg.thumbHeight)
    }

    private func layoutForStaff(_ isStaff: Bool, thumbWidth: Int?, thumbHeight: Int?) {
        // 按缩略图尺寸计算展示宽高，最大 200，最小 80
        let maxSize: CGFloat = 200
        let minSize: CGFloat = 80
        var displayW: CGFloat = maxSize
        var displayH: CGFloat = maxSize

        if let w = thumbWidth, let h = thumbHeight, w > 0, h > 0 {
            let ratio = CGFloat(w) / CGFloat(h)
            if ratio >= 1 {
                displayW = min(maxSize, max(minSize, CGFloat(w)))
                displayH = displayW / ratio
            } else {
                displayH = min(maxSize, max(minSize, CGFloat(h)))
                displayW = displayH * ratio
            }
        }

        avatarLabel.snp.remakeConstraints { make in
            if isStaff {
                make.leading.equalToSuperview().offset(16)
            } else {
                make.trailing.equalToSuperview().offset(-16)
            }
            make.top.equalToSuperview().offset(8).priority(999)
            make.size.equalTo(34)
        }
        avatarImageView.snp.remakeConstraints { make in
            make.edges.equalTo(avatarLabel)
        }

        metaLabel.snp.remakeConstraints { make in
            make.top.equalTo(avatarLabel)
            if isStaff {
                make.leading.equalTo(avatarLabel.snp.trailing).offset(8)
            } else {
                make.trailing.equalTo(avatarLabel.snp.leading).offset(-8)
            }
        }

        photoView.snp.remakeConstraints { make in
            make.top.equalTo(metaLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-8).priority(999)
            make.width.equalTo(displayW)
            make.height.equalTo(displayH).priority(750)
            if isStaff {
                make.leading.equalTo(metaLabel)
            } else {
                make.trailing.equalTo(metaLabel)
            }
        }
    }

    // MARK: - Actions

    @objc private func imageTapped() {
        onTapImage?(imagePath)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let msg = currentMessage else { return }
        delegate?.cellDidLongPress(self, message: msg)
    }
}
