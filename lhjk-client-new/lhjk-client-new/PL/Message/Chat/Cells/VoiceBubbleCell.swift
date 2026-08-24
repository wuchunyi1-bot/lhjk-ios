import UIKit
import SnapKit
import Kingfisher
import AVFoundation

/// 语音气泡 Cell — 波形图标 + 时长（Figma 3876:35332）
final class VoiceBubbleCell: UITableViewCell {
    static let reuseID = "VoiceBubbleCell"

    weak var delegate: ChatCellDelegate?
    private var currentMessage: ChatMessage?

    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 15, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.clipsToBounds = true
        return l
    }()
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isHidden = true
        return iv
    }()

    private let metaLabel = UILabel()

    private let bubbleBackground = ChatBubbleBackgroundView()
    private let bubbleView = UIView()

    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "waveform"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let durationLabel = UILabel()

    private let unreadDot: UIView = {
        let v = UIView()
        v.backgroundColor = .red
        v.layer.cornerRadius = 4
        v.isHidden = true
        return v
    }()

    private var playbackController = VoicePlaybackController()
    private var currentAudioPath: String?
    private var currentMessageId: Int = 0
    private var isPlaying = false
    private var didRetryVoiceDownload = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdBg

        ChatBubbleStyle.configureAvatar(avatarLabel, imageView: avatarImageView)
        metaLabel.font = ChatBubbleStyle.metaFont
        metaLabel.textColor = ChatBubbleStyle.metaColor
        durationLabel.font = ChatBubbleStyle.textFont

        [avatarLabel, avatarImageView, metaLabel, bubbleBackground, bubbleView].forEach(contentView.addSubview)
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

    func configure(_ msg: ChatMessage, tone: String, convRole: ConversationRole) {
        currentMessage = msg
        let isStaff = msg.isStaff
        let seconds = msg.thumbHeight ?? 0

        stopPlayback()
        currentAudioPath = msg.imagePath
        currentMessageId = msg.messageId
        didRetryVoiceDownload = false
        updatePlayIcon(false)

        ChatBubbleStyle.applyAvatar(portraitUrl: msg.portraitUrl, label: avatarLabel, imageView: avatarImageView)

        if isStaff {
            metaLabel.text = ChatBubbleStyle.staffMetaText(name: msg.senderName)
            metaLabel.textAlignment = .left
            bubbleBackground.tail = .left
            bubbleBackground.fill = .staffGradient
            iconView.tintColor = ChatBubbleStyle.primaryText
            durationLabel.textColor = ChatBubbleStyle.primaryText
            iconView.transform = .identity
        } else {
            metaLabel.text = msg.time
            metaLabel.textAlignment = .right
            bubbleBackground.tail = .right
            bubbleBackground.fill = .userSolid
            iconView.tintColor = .white
            durationLabel.textColor = .white
            iconView.transform = CGAffineTransform(scaleX: -1, y: 1)
        }

        durationLabel.text = "\(seconds)\""
        layoutForStaff(isStaff, seconds: seconds)
    }

    @objc private func togglePlay() {
        if isPlaying {
            stopPlayback()
        } else {
            VoicePlaybackLogger.logTap(
                messageId: currentMessageId,
                duration: currentMessage?.thumbHeight,
                audioRef: currentAudioPath
            )
            startPlayback()
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let msg = currentMessage else { return }
        delegate?.cellDidLongPress(self, message: msg)
    }

    private func startPlayback() {
        if currentMessageId > 0 {
            RongCloudManager.shared.logVoiceMessageMeta(messageId: currentMessageId)
        }

        if let path = currentAudioPath, !path.isEmpty, path.hasPrefix("/") {
            VoicePlaybackLogger.logSource("localPath", messageId: currentMessageId, detail: path)
            playFile(URL(fileURLWithPath: path))
            return
        }

        if currentMessageId > 0 {
            VoicePlaybackLogger.logSource("rongCloudDownload", messageId: currentMessageId)
            updatePlayIcon(true)
            RongCloudManager.shared.downloadMediaMessage(currentMessageId) { [weak self] localPath in
                guard let self else { return }
                guard let localPath else {
                    DispatchQueue.main.async {
                        VoicePlaybackLogger.logDownloadResult(
                            messageId: self.currentMessageId,
                            success: false,
                            localPath: nil,
                            error: "sdk returned nil"
                        )
                        self.updatePlayIcon(false)
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.currentAudioPath = localPath
                    self.playFile(URL(fileURLWithPath: localPath))
                }
            }
            return
        }

        if let urlStr = currentAudioPath, !urlStr.isEmpty,
           let remoteURL = URL(string: urlStr) {
            VoicePlaybackLogger.logSource(
                "urlSession",
                messageId: currentMessageId,
                detail: "url=\(urlStr)"
            )
            updatePlayIcon(true)
            URLSession.shared.downloadTask(with: remoteURL) { [weak self] tempURL, _, error in
                guard let self else { return }
                if let error {
                    VoicePlaybackLogger.logRemoteDownload(
                        url: remoteURL,
                        tempPath: tempURL?.path,
                        destPath: nil,
                        error: error
                    )
                    DispatchQueue.main.async { self.updatePlayIcon(false) }
                    return
                }
                guard let tempURL else {
                    VoicePlaybackLogger.logRemoteDownload(
                        url: remoteURL,
                        tempPath: nil,
                        destPath: nil,
                        error: NSError(
                            domain: "VoicePlayback",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "empty temp file"]
                        )
                    )
                    DispatchQueue.main.async { self.updatePlayIcon(false) }
                    return
                }
                let ext = remoteURL.pathExtension.isEmpty ? "m4a" : remoteURL.pathExtension
                let dest = URL(
                    fileURLWithPath: NSTemporaryDirectory()
                        + "voice_\(Int(Date().timeIntervalSince1970)).\(ext)"
                )
                try? FileManager.default.removeItem(at: dest)
                do {
                    try FileManager.default.moveItem(at: tempURL, to: dest)
                    VoicePlaybackLogger.logRemoteDownload(
                        url: remoteURL,
                        tempPath: tempURL.path,
                        destPath: dest.path,
                        error: nil
                    )
                    DispatchQueue.main.async {
                        self.currentAudioPath = dest.path
                        self.playFile(dest)
                    }
                } catch {
                    VoicePlaybackLogger.logRemoteDownload(
                        url: remoteURL,
                        tempPath: tempURL.path,
                        destPath: dest.path,
                        error: error
                    )
                    DispatchQueue.main.async { self.updatePlayIcon(false) }
                }
            }.resume()
            return
        }

        print("[Voice] play ✗ no playable source messageId=\(currentMessageId) ref=\(currentAudioPath ?? "nil")")
    }

    private func playFile(_ url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            VoicePlaybackLogger.logMissingFile(path: url.path, messageId: currentMessageId)
            updatePlayIcon(false)
            return
        }

        playbackController.play(
            url: url,
            messageId: currentMessageId,
            onStarted: { [weak self] in
                self?.isPlaying = true
                self?.updatePlayIcon(true)
            },
            onFinished: { [weak self] in
                self?.isPlaying = false
                self?.updatePlayIcon(false)
            },
            onFailed: { [weak self] error in
                guard let self else { return }
                self.isPlaying = false
                self.updatePlayIcon(false)
                let message = (error as? LocalizedError)?.errorDescription ?? "语音播放失败"
                self.delegate?.cellVoicePlaybackFailed(self, message: message)
                self.retryPlaybackAfterFailure(originalURL: url)
            }
        )
    }

    /// AVAudioPlayer / AVPlayer 均失败后，尝试重新从融云拉取媒体文件（仅一次）
    private func retryPlaybackAfterFailure(originalURL: URL) {
        guard currentMessageId > 0, !didRetryVoiceDownload else { return }
        didRetryVoiceDownload = true
        print("[Voice] retry download messageId=\(currentMessageId)")
        RongCloudManager.shared.downloadMediaMessage(currentMessageId) { [weak self] localPath in
            guard let self else { return }
            DispatchQueue.main.async {
                guard let localPath, localPath != originalURL.path else {
                    VoicePlaybackLogger.logDownloadResult(
                        messageId: self.currentMessageId,
                        success: false,
                        localPath: localPath,
                        error: "retry returned same or nil path"
                    )
                    return
                }
                self.currentAudioPath = localPath
                self.playFile(URL(fileURLWithPath: localPath))
            }
        }
    }

    private func stopPlayback() {
        playbackController.stop()
        isPlaying = false
        updatePlayIcon(false)
    }

    private func updatePlayIcon(_ playing: Bool) {
        iconView.image = UIImage(systemName: playing ? "waveform.circle.fill" : "waveform")
    }

    private func layoutForStaff(_ isStaff: Bool, seconds: Int) {
        let maxBubbleW = ChatBubbleStyle.maxContentBubbleWidth()
        let bubbleWidth = voiceBubbleWidth(seconds: seconds, maxWidth: maxBubbleW)

        avatarLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(8).priority(999)
            make.size.equalTo(ChatBubbleStyle.avatarSize)
            if isStaff {
                make.leading.equalToSuperview().offset(ChatBubbleStyle.horizontalInset)
            } else {
                make.trailing.equalToSuperview().offset(-ChatBubbleStyle.horizontalInset)
            }
        }
        avatarImageView.snp.remakeConstraints { make in
            make.edges.equalTo(avatarLabel)
        }

        metaLabel.snp.remakeConstraints { make in
            make.top.equalTo(avatarLabel)
            if isStaff {
                make.leading.equalTo(avatarLabel.snp.trailing).offset(ChatBubbleStyle.avatarToContentGap)
            } else {
                make.trailing.equalTo(avatarLabel.snp.leading).offset(-ChatBubbleStyle.avatarToContentGap)
            }
        }

        bubbleBackground.snp.remakeConstraints { make in
            make.edges.equalTo(bubbleView)
        }

        bubbleView.snp.remakeConstraints { make in
            make.top.equalTo(isStaff ? metaLabel.snp.bottom : avatarLabel.snp.top)
                .offset(isStaff ? ChatBubbleStyle.nameToBubbleGap : 0)
            make.bottom.equalToSuperview().offset(-8).priority(999)
            make.width.equalTo(bubbleWidth)
            make.height.equalTo(40)
            if isStaff {
                make.leading.equalTo(metaLabel)
            } else {
                make.trailing.equalTo(avatarLabel.snp.leading).offset(-ChatBubbleStyle.avatarToContentGap)
            }
        }

        if isStaff {
            iconView.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(ChatBubbleStyle.bubbleInset)
                make.centerY.equalToSuperview()
                make.size.equalTo(20)
            }
            durationLabel.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-ChatBubbleStyle.bubbleInset)
                make.centerY.equalToSuperview()
            }
            unreadDot.snp.remakeConstraints { make in
                make.leading.equalTo(durationLabel.snp.trailing).offset(4)
                make.centerY.equalTo(durationLabel)
                make.size.equalTo(8)
            }
        } else {
            durationLabel.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(ChatBubbleStyle.bubbleInset)
                make.centerY.equalToSuperview()
            }
            iconView.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-ChatBubbleStyle.bubbleInset)
                make.centerY.equalToSuperview()
                make.size.equalTo(20)
            }
        }
    }

    private func voiceBubbleWidth(seconds: Int, maxWidth: CGFloat) -> CGFloat {
        let minWidth: CGFloat = 72
        return minWidth + CGFloat(min(seconds, 60)) * (maxWidth - minWidth) / 60.0
    }
}
