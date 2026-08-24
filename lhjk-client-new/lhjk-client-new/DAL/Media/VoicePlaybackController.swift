import AVFoundation
import CoreMedia

/// 语音播放：WAV/AAC 走 AVAudioPlayer；Opus（跨端 Android）在 iOS 16 转 WAV 后播放
final class VoicePlaybackController: NSObject {

    private var audioPlayer: AVAudioPlayer?
    private var avPlayer: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var endObserver: NSObjectProtocol?
    private var failObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?
    private var timeControlObserver: NSKeyValueObservation?
    private var onFinishedHandler: (() -> Void)?
    private var playbackVerificationWorkItem: DispatchWorkItem?
    private var avPlayerDidStart = false

    var isPlaying: Bool {
        (audioPlayer?.isPlaying == true) || ((avPlayer?.rate ?? 0) > 0)
    }

    func play(
        url: URL,
        messageId: Int,
        sampleRate: Int = 16_000,
        channels: Int = 1,
        onStarted: @escaping () -> Void,
        onFinished: @escaping () -> Void,
        onFailed: @escaping (Error) -> Void
    ) {
        stop(notifySession: false)
        onFinishedHandler = onFinished

        let profile = VoiceAssetInspector.inspect(url: url)
        VoicePlaybackLogger.logAssetProfile(messageId: messageId, profile: profile, url: url)

        if profile.requiresOpusTranscode {
            playOpusTranscoded(
                url: url,
                messageId: messageId,
                sampleRate: sampleRate,
                channels: channels,
                onStarted: onStarted,
                onFinished: onFinished,
                onFailed: onFailed
            )
            return
        }

        playWithSystemEngines(
            url: url,
            messageId: messageId,
            profile: profile,
            onStarted: onStarted,
            onFinished: onFinished,
            onFailed: onFailed
        )
    }

    func stop(notifySession: Bool = true) {
        playbackVerificationWorkItem?.cancel()
        playbackVerificationWorkItem = nil

        audioPlayer?.stop()
        audioPlayer = nil

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        if let failObserver {
            NotificationCenter.default.removeObserver(failObserver)
            self.failObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil
        timeControlObserver?.invalidate()
        timeControlObserver = nil

        avPlayer?.pause()
        avPlayer = nil
        playerItem = nil
        avPlayerDidStart = false
        onFinishedHandler = nil

        if notifySession {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    // MARK: - Opus

    private func playOpusTranscoded(
        url: URL,
        messageId: Int,
        sampleRate: Int,
        channels: Int,
        onStarted: @escaping () -> Void,
        onFinished: @escaping () -> Void,
        onFailed: @escaping (Error) -> Void
    ) {
        VoicePlaybackLogger.logFallback(engine: "OpusTranscoder", messageId: messageId, url: url)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let wavURL = try OpusVoiceTranscoder.transcodedWAVURL(
                    from: url,
                    sampleRate: sampleRate,
                    channels: channels
                )
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.playWithSystemEngines(
                        url: wavURL,
                        messageId: messageId,
                        profile: VoiceAssetInspector.inspect(url: wavURL),
                        onStarted: onStarted,
                        onFinished: onFinished,
                        onFailed: onFailed
                    )
                }
            } catch {
                DispatchQueue.main.async {
                    VoicePlaybackLogger.logPlayFailure(
                        url: url,
                        messageId: messageId,
                        error: error,
                        engine: "OpusTranscoder"
                    )
                    onFailed(error)
                }
            }
        }
    }

    // MARK: - System engines

    private func playWithSystemEngines(
        url: URL,
        messageId: Int,
        profile: VoiceAssetProfile,
        onStarted: @escaping () -> Void,
        onFinished: @escaping () -> Void,
        onFailed: @escaping (Error) -> Void
    ) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            onFailed(error)
            return
        }

        VoicePlaybackLogger.logPlayStart(url: url, messageId: messageId)

        if tryPlayWithAudioPlayer(
            url: url,
            messageId: messageId,
            onStarted: onStarted,
            onFinished: onFinished
        ) {
            return
        }

        if profile.containsOpus {
            onFailed(OpusVoiceTranscoderError.opusLibraryUnavailable)
            return
        }

        playWithAVPlayer(
            url: url,
            messageId: messageId,
            onStarted: onStarted,
            onFinished: onFinished,
            onFailed: onFailed
        )
    }

    private func tryPlayWithAudioPlayer(
        url: URL,
        messageId: Int,
        onStarted: @escaping () -> Void,
        onFinished: @escaping () -> Void
    ) -> Bool {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            guard player.play() else {
                throw NSError(
                    domain: "VoicePlayback",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "AVAudioPlayer.play() returned false"]
                )
            }
            audioPlayer = player
            VoicePlaybackLogger.logPlaySuccess(
                url: url,
                messageId: messageId,
                player: player,
                engine: "AVAudioPlayer"
            )
            onStarted()
            return true
        } catch {
            VoicePlaybackLogger.logPlayFailure(
                url: url,
                messageId: messageId,
                error: error,
                engine: "AVAudioPlayer"
            )
            return false
        }
    }

    private func playWithAVPlayer(
        url: URL,
        messageId: Int,
        onStarted: @escaping () -> Void,
        onFinished: @escaping () -> Void,
        onFailed: @escaping (Error) -> Void
    ) {
        VoicePlaybackLogger.logFallback(engine: "AVPlayer", messageId: messageId, url: url)

        let item = AVPlayerItem(url: url)
        playerItem = item
        let player = AVPlayer(playerItem: item)
        player.volume = 1
        avPlayer = player
        avPlayerDidStart = false

        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    guard !self.avPlayerDidStart else { return }
                    player.play()
                    self.schedulePlaybackVerification(
                        player: player,
                        url: url,
                        messageId: messageId,
                        onStarted: onStarted,
                        onFinished: onFinished,
                        onFailed: onFailed
                    )
                case .failed:
                    let error = item.error ?? NSError(
                        domain: "VoicePlayback",
                        code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "AVPlayerItem failed"]
                    )
                    VoicePlaybackLogger.logPlayFailure(
                        url: url,
                        messageId: messageId,
                        error: error,
                        engine: "AVPlayer"
                    )
                    self.stop(notifySession: true)
                    onFailed(error)
                default:
                    break
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.stop(notifySession: true)
            onFinished()
        }

        failObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] note in
            let error = (note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)
                ?? NSError(
                    domain: "VoicePlayback",
                    code: -4,
                    userInfo: [NSLocalizedDescriptionKey: "AVPlayer playback failed"]
                )
            VoicePlaybackLogger.logPlayFailure(
                url: url,
                messageId: messageId,
                error: error,
                engine: "AVPlayer"
            )
            self?.stop(notifySession: true)
            onFailed(error)
        }
    }

    private func schedulePlaybackVerification(
        player: AVPlayer,
        url: URL,
        messageId: Int,
        onStarted: @escaping () -> Void,
        onFinished: @escaping () -> Void,
        onFailed: @escaping (Error) -> Void
    ) {
        playbackVerificationWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let isActuallyPlaying = player.timeControlStatus == .playing && player.rate > 0
            let currentSeconds = CMTimeGetSeconds(player.currentTime())

            if isActuallyPlaying || currentSeconds > 0.01 {
                guard !self.avPlayerDidStart else { return }
                self.avPlayerDidStart = true
                VoicePlaybackLogger.logPlaySuccessAVPlayer(
                    url: url,
                    messageId: messageId,
                    duration: CMTimeGetSeconds(self.playerItem?.duration ?? .zero)
                )
                onStarted()
                return
            }

            let error = NSError(
                domain: "VoicePlayback",
                code: -5,
                userInfo: [NSLocalizedDescriptionKey: "AVPlayer started without audible output"]
            )
            VoicePlaybackLogger.logPlayFailure(
                url: url,
                messageId: messageId,
                error: error,
                engine: "AVPlayer"
            )
            self.stop(notifySession: true)
            onFailed(error)
        }
        playbackVerificationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }
}

// MARK: - AVAudioPlayerDelegate

extension VoicePlaybackController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let handler = onFinishedHandler
        stop(notifySession: true)
        handler?()
    }
}
