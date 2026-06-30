import AVFoundation

/// 语音录制 — AVAudioRecorder 封装
///
/// 录制格式：WAV (.wav)，单声道 8000Hz 16bit，兼容融云 RCHQVoiceMessage。
/// 录制路径由外部传入，与文件管理解耦。
///
/// 使用：
/// ```
/// let recorder = AudioRecorder()
/// await recorder.requestPermission()
/// let url = fileManager.audioFileURL()  // 外部生成路径
/// try recorder.startRecording(to: url)
/// ...
/// let recordedURL = recorder.stopRecording()
/// ```
final class AudioRecorder: NSObject {

    // MARK: - State

    private(set) var isRecording = false
    private(set) var isPaused = false

    /// 当前录制时长（秒），实时更新
    var currentDuration: TimeInterval {
        guard let recorder else { return 0 }
        return recorder.currentTime
    }

    // MARK: - Callbacks

    /// 录制完成回调 (文件路径, 时长秒数)
    var onDidFinish: ((_ url: URL, _ duration: TimeInterval) -> Void)?
    /// 录制失败回调
    var onDidFail: ((Error) -> Void)?

    // MARK: - Private

    private var recorder: AVAudioRecorder?
    private var recordURL: URL?

    // MARK: - Permission

    /// 请求麦克风权限，返回是否授权
    func requestPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        default:
            return false
        }
    }

    // MARK: - Recording Actions

    /// 开始录制到指定路径（由调用方传入）
    func startRecording(to url: URL) throws {
        guard !isRecording else { return }

        // 配置音频会话
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 8000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
        ]

        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.delegate = self
        recorder?.prepareToRecord()
        recorder?.record()

        recordURL = url
        isRecording = true
        isPaused = false
    }

    func pauseRecording() {
        guard isRecording, !isPaused else { return }
        recorder?.pause()
        isPaused = true
    }

    func resumeRecording() throws {
        guard isRecording, isPaused else { return }
        recorder?.record()
        isPaused = false
    }

    /// 停止录制，返回文件路径
    func stopRecording() -> URL? {
        guard isRecording else { return nil }
        let url = recordURL
        recorder?.stop()
        recorder = nil
        isRecording = false
        isPaused = false
        deactivateSession()
        return url
    }

    /// 放弃录制，删除临时文件
    func cancelRecording() {
        guard isRecording else { return }
        let url = recordURL
        recorder?.stop()
        recorder = nil
        isRecording = false
        isPaused = false
        deactivateSession()
        if let url { try? FileManager.default.removeItem(at: url) }
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        guard let url = recordURL else { return }
        let duration = recorder.currentTime
        if flag {
            onDidFinish?(url, duration)
        } else {
            onDidFail?(NSError(domain: "AudioRecorder", code: -1,
                               userInfo: [NSLocalizedDescriptionKey: "录制失败"]))
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error {
            onDidFail?(error)
        }
    }
}
