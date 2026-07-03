import UIKit
import SnapKit
import Kingfisher
import AVFoundation

/// 语音气泡 Cell — 波形图标 + 时长，宽度随 duration 变化
final class VoiceBubbleCell: UITableViewCell {
    static let reuseID = "VoiceBubbleCell"

    weak var delegate: ChatCellDelegate?
    private var currentMessage: ChatMessage?

    // MARK: - UI

    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 13, weight: .bold)
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
        l.font = .fdMicro
        l.textColor = .fdMuted
        return l
    }()

    private let bubbleView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 15
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "waveform"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let durationLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14)
        return l
    }()

    private let unreadDot: UIView = {
        let v = UIView()
        v.backgroundColor = .red
        v.layer.cornerRadius = 4
        v.isHidden = true
        return v
    }()

    // MARK: - Playback

    private var player: AVAudioPlayer?
    private var currentAudioPath: String?
    private var currentMessageId: Int = 0
    private var isPlaying = false

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdBg

        [avatarLabel, avatarImageView, metaLabel, bubbleView].forEach(contentView.addSubview)
        [iconView, durationLabel, unreadDot].forEach(bubbleView.addSubview)

        let tap = UITapGestureRecognizer(target: self, action: #selector(togglePlay))
        bubbleView.addGestureRecognizer(tap)
        bubbleView.isUserInteractionEnabled = true

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        bubbleView.addGestureRecognizer(longPress)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopPlayback()
        currentAudioPath = nil
    }

    // MARK: - Configure

    func configure(_ msg: ChatMessage, tone: String, convRole: ConversationRole) {
        currentMessage = msg
        let isStaff = msg.isStaff
        let seconds = msg.thumbHeight ?? 0

        metaLabel.font = .fdMicro

        // 停止上一个播放
        stopPlayback()
        currentAudioPath = msg.imagePath
        currentMessageId = msg.messageId
        print("[VoiceBubble] configure → path=\(msg.imagePath ?? "nil") duration=\(seconds) msgId=\(currentMessageId)")
        updatePlayIcon(false)

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

        metaLabel.text = isStaff
            ? [msg.senderName, msg.senderRole, msg.time].compactMap { $0 }.joined(separator: " · ")
            : msg.time
        metaLabel.textAlignment = isStaff ? .left : .right

        durationLabel.text = "\(seconds)\""
        iconView.tintColor = isStaff ? .fdText : .white
        durationLabel.textColor = isStaff ? .fdText : .white
        bubbleView.backgroundColor = isStaff ? .fdSurface : UIColor(hexString: "#FF7A50")

        // staff 图标朝右，user 图标朝左（镜像）
        iconView.transform = isStaff ? .identity : CGAffineTransform(scaleX: -1, y: 1)

        layoutForStaff(isStaff, seconds: seconds)
    }

    // MARK: - Playback Actions

    @objc private func togglePlay() {
        print("[VoiceBubble] togglePlay called, isPlaying=\(isPlaying)")
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let msg = currentMessage else { return }
        delegate?.cellDidLongPress(self, message: msg)
    }

    private func startPlayback() {
        // 1. 本地文件存在 → 直接播放
        if let path = currentAudioPath, !path.isEmpty, path.hasPrefix("/") {
            playFile(URL(fileURLWithPath: path))
            return
        }

        // 2. messageId 有效 → 通过融云 SDK 下载
        if currentMessageId > 0 {
            print("[VoiceBubble] downloading via SDK msgId=\(currentMessageId)")
            updatePlayIcon(true)
            RongCloudManager.shared.downloadMediaMessage(currentMessageId) { [weak self] localPath in
                guard let self, let localPath else {
                    print("[VoiceBubble] ✗ SDK download failed msgId=\(self?.currentMessageId ?? 0)")
                    DispatchQueue.main.async { self?.updatePlayIcon(false) }
                    return
                }
                print("[VoiceBubble] ✓ SDK downloaded: \(localPath)")
                DispatchQueue.main.async {
                    self.currentAudioPath = localPath
                    self.playFile(URL(fileURLWithPath: localPath))
                }
            }
            return
        }

        // 3. messageId 不可用 → 尝试直接下载 remoteUrl
        if let urlStr = currentAudioPath, !urlStr.isEmpty,
           let remoteURL = URL(string: urlStr) {
            print("[VoiceBubble] downloading via URL: \(urlStr)")
            updatePlayIcon(true)
            URLSession.shared.downloadTask(with: remoteURL) { [weak self] tempURL, _, error in
                guard let self, let tempURL = tempURL, error == nil else {
                    print("[VoiceBubble] ✗ URL download failed: \(error?.localizedDescription ?? "nil")")
                    DispatchQueue.main.async { self?.updatePlayIcon(false) }
                    return
                }
                // 移动到持久位置
                let dest = URL(fileURLWithPath: NSTemporaryDirectory() + "voice_\(Int(Date().timeIntervalSince1970)).m4a")
                try? FileManager.default.removeItem(at: dest)
                do {
                    try FileManager.default.moveItem(at: tempURL, to: dest)
                    print("[VoiceBubble] ✓ URL downloaded: \(dest.path)")
                    DispatchQueue.main.async {
                        self.currentAudioPath = dest.path
                        self.playFile(dest)
                    }
                } catch {
                    print("[VoiceBubble] ✗ move file failed: \(error)")
                    DispatchQueue.main.async { self.updatePlayIcon(false) }
                }
            }.resume()
            return
        }

        print("[VoiceBubble] ✗ no local path, no messageId, no remote URL — cannot play")
    }

    private func playFile(_ url: URL) {
        let exists = FileManager.default.fileExists(atPath: url.path)
        print("[VoiceBubble] play: \(url.path), exists=\(exists)")
        guard exists else { updatePlayIcon(false); return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
            isPlaying = true
            updatePlayIcon(true)
            print("[VoiceBubble] ✓ playing, duration=\(player?.duration ?? 0)")
        } catch {
            print("[VoiceBubble] ✗ failed: \(error)")
            updatePlayIcon(false)
        }
    }

    private func stopPlayback() {
        print("[VoiceBubble] stopPlayback")
        player?.stop()
        player = nil
        isPlaying = false
        updatePlayIcon(false)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func updatePlayIcon(_ playing: Bool) {
        iconView.image = UIImage(systemName: playing ? "waveform.circle.fill" : "waveform")
    }

    // MARK: - Layout

    private func layoutForStaff(_ isStaff: Bool, seconds: Int) {
        let bubbleWidth = voiceBubbleWidth(seconds: seconds)

        avatarLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(8).priority(999)
            make.size.equalTo(34)
            if isStaff {
                make.leading.equalToSuperview().offset(16)
            } else {
                make.trailing.equalToSuperview().offset(-16)
            }
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

        bubbleView.snp.remakeConstraints { make in
            make.top.equalTo(metaLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-8).priority(999)
            make.width.equalTo(bubbleWidth)
            make.height.equalTo(40)
            if isStaff {
                make.leading.equalTo(metaLabel)
            } else {
                make.trailing.equalTo(metaLabel)
            }
        }

        if isStaff {
            iconView.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(12)
                make.centerY.equalToSuperview()
                make.size.equalTo(20)
            }
            durationLabel.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-10)
                make.centerY.equalToSuperview()
            }
            unreadDot.snp.remakeConstraints { make in
                make.leading.equalTo(durationLabel.snp.trailing).offset(4)
                make.centerY.equalTo(durationLabel)
                make.size.equalTo(8)
            }
        } else {
            durationLabel.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(10)
                make.centerY.equalToSuperview()
            }
            iconView.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-12)
                make.centerY.equalToSuperview()
                make.size.equalTo(20)
            }
        }
    }

    /// 气泡宽度随秒数变化：1s=60pt, 60s=160pt
    private func voiceBubbleWidth(seconds: Int) -> CGFloat {
        let minWidth: CGFloat = 60
        let maxWidth: CGFloat = 160
        let width = minWidth + CGFloat(min(seconds, 60)) * (maxWidth - minWidth) / 60.0
        return width
    }
}

// MARK: - AVAudioPlayerDelegate

extension VoiceBubbleCell: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        updatePlayIcon(false)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
