import UIKit
import SnapKit
import Kingfisher

/// 引用回复预览条 — 显示在输入栏上方
final class QuotePreviewBar: UIView {

    var onDismiss: (() -> Void)?
    var onTap: (() -> Void)?

    private var currentReply: ReplyMessage?

    // MARK: - UI

    private let barView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdPrimary
        v.layer.cornerRadius = 1
        return v
    }()

    private lazy var nameLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 11)
        l.textColor = .fdPrimary
        return l
    }()

    /// 文本预览（非媒体类型使用）
    private lazy var contentLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 12)
        l.textColor = .fdSubtext
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    /// 图片/视频缩略图（媒体类型使用）
    private lazy var thumbnailView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 4
        iv.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        iv.isHidden = true
        return iv
    }()

    /// 语音图标 + 时长（语音类型使用）
    private lazy var voiceContainer: UIView = {
        let v = UIView()
        v.isHidden = true
        return v
    }()
    private lazy var voiceIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "waveform"))
        iv.tintColor = .fdSubtext
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    private lazy var voiceDurationLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 12)
        l.textColor = .fdSubtext
        return l
    }()

    private lazy var closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "xmark"), for: .normal)
        b.tintColor = .fdMuted
        b.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white

        voiceContainer.addSubview(voiceIcon)
        voiceContainer.addSubview(voiceDurationLabel)

        [barView, nameLabel, contentLabel, thumbnailView, voiceContainer, closeButton].forEach(addSubview)

        barView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(2)
            make.height.equalTo(32)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(barView.snp.trailing).offset(8)
            make.top.equalTo(barView)
        }

        contentLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.equalTo(closeButton.snp.leading).offset(-8)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
        }

        thumbnailView.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.size.equalTo(32)
        }

        voiceIcon.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        voiceDurationLabel.snp.makeConstraints { make in
            make.leading.equalTo(voiceIcon.snp.trailing).offset(4)
            make.centerY.trailing.equalToSuperview()
        }
        voiceContainer.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.height.equalTo(20)
        }

        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(with reply: ReplyMessage) {
        currentReply = reply
        nameLabel.text = "回复 \(reply.senderName)"

        // 重置所有可见性
        contentLabel.isHidden = true
        thumbnailView.isHidden = true
        voiceContainer.isHidden = true

        if reply.isImage {
            // 图片：展示缩略图
            thumbnailView.isHidden = false
            if let url = URL(string: reply.text), url.scheme?.hasPrefix("http") == true {
                thumbnailView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
            }
        } else if reply.isVoice {
            // 语音：展示波形图标 + 时长
            voiceContainer.isHidden = false
            if let dur = reply.duration, dur > 0 {
                voiceDurationLabel.text = "\(dur)\""
            } else {
                voiceDurationLabel.text = ""
            }
        } else if reply.isVideo {
            // 视频：展示封面缩略图
            thumbnailView.isHidden = false
            if let url = URL(string: reply.text) {
                thumbnailView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
            }
        } else {
            // 文本 / 文件 / 套餐：展示文字
            contentLabel.isHidden = false
            if reply.isFile {
                contentLabel.text = "[文件] \(reply.fileName ?? reply.text)"
            } else {
                contentLabel.text = reply.text
            }
        }
    }

    func dismiss() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }

    @objc private func closeTapped() {
        onDismiss?()
    }

    @objc private func handleTap() {
        onTap?()
    }
}
