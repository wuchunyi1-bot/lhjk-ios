import Foundation
import AVFoundation
import CoreMedia

/// 语音播放调试日志 — 排查跨端编码 / iOS 16 解码兼容问题
enum VoicePlaybackLogger {

    // MARK: - Public

    static func logTap(messageId: Int, duration: Int?, audioRef: String?) {
        print(
            "[Voice] tap messageId=\(messageId) duration=\(duration.map(String.init) ?? "nil") "
            + "ref=\(sanitize(audioRef))"
        )
    }

    static func logSource(_ source: String, messageId: Int, detail: String? = nil) {
        var line = "[Voice] source=\(source) messageId=\(messageId)"
        if let detail, !detail.isEmpty {
            line += " \(detail)"
        }
        print(line)
    }

    static func logDownloadResult(messageId: Int, success: Bool, localPath: String?, error: String? = nil) {
        if success, let localPath {
            print("[Voice] download ✓ messageId=\(messageId) \(fileSummary(path: localPath))")
        } else {
            print(
                "[Voice] download ✗ messageId=\(messageId) "
                + "error=\(error ?? "unknown") path=\(sanitize(localPath))"
            )
        }
    }

    static func logRemoteDownload(url: URL, tempPath: String?, destPath: String?, error: Error?) {
        if let error {
            print("[Voice] urlDownload ✗ url=\(url.absoluteString) error=\(error.localizedDescription)")
            return
        }
        if let tempPath {
            print("[Voice] urlDownload temp=\(fileSummary(path: tempPath))")
        }
        if let destPath {
            print("[Voice] urlDownload dest=\(fileSummary(path: destPath))")
        }
    }

    static func logPlayStart(url: URL, messageId: Int) {
        print("[Voice] play ▶ messageId=\(messageId) \(fileSummary(url: url))")
    }

    static func logPlaySuccess(
        url: URL,
        messageId: Int,
        player: AVAudioPlayer,
        engine: String = "AVAudioPlayer"
    ) {
        print(
            "[Voice] play ✓ messageId=\(messageId) engine=\(engine) "
            + "duration=\(String(format: "%.2f", player.duration))s "
            + "channels=\(player.numberOfChannels) "
            + "format=\(player.format.description)"
        )
    }

    static func logPlaySuccessAVPlayer(url: URL, messageId: Int, duration: Double) {
        let durationText = duration.isFinite ? String(format: "%.2f", duration) : "unknown"
        print(
            "[Voice] play ✓ messageId=\(messageId) engine=AVPlayer "
            + "duration=\(durationText)s"
        )
    }

    static func logPlayFailure(
        url: URL,
        messageId: Int,
        error: Error,
        engine: String = "AVAudioPlayer"
    ) {
        let nsError = error as NSError
        print(
            "[Voice] play ✗ messageId=\(messageId) engine=\(engine) "
            + "\(fileSummary(url: url)) "
            + "error=\(error.localizedDescription) "
            + "domain=\(nsError.domain) code=\(nsError.code)"
        )
    }

    static func logFallback(engine: String, messageId: Int, url: URL) {
        print(
            "[Voice] fallback engine=\(engine) messageId=\(messageId) "
            + "\(fileSummary(url: url))"
        )
    }

    static func logAssetDiagnostics(url: URL, messageId: Int) {
        let profile = VoiceAssetInspector.inspect(url: url)
        logAssetProfile(messageId: messageId, profile: profile, url: url)
    }

    static func logAssetProfile(messageId: Int, profile: VoiceAssetProfile, url: URL) {
        let durationText = profile.duration > 0 ? String(format: "%.2f", profile.duration) : "unknown"
        print(
            "[Voice] asset messageId=\(messageId) playable=\(profile.isPlayable) "
            + "duration=\(durationText)s audioTracks=\(profile.audioCodecs.count) "
            + "codecs=\(profile.audioCodecs.isEmpty ? "none" : profile.audioCodecs.joined(separator: "; ")) "
            + "requiresOpusTranscode=\(profile.requiresOpusTranscode) opusLib=\(OpusVoiceTranscoder.isAvailable)"
        )
    }

    static func logMissingFile(path: String, messageId: Int) {
        print("[Voice] play ✗ file missing messageId=\(messageId) path=\(sanitize(path))")
    }

    static func logRongCloudVoiceMeta(
        messageId: Int,
        objectName: String?,
        duration: Int,
        format: String?,
        sampleRate: UInt,
        channels: UInt,
        remoteUrl: String?,
        localPath: String?
    ) {
        print(
            "[Voice] meta messageId=\(messageId) objectName=\(objectName ?? "nil") "
            + "duration=\(duration)s format=\(format ?? "nil") "
            + "sampleRate=\(sampleRate) channels=\(channels) "
            + "remote=\(sanitize(remoteUrl)) local=\(sanitize(localPath))"
        )
    }

    // MARK: - File inspection

    static func fileSummary(url: URL) -> String {
        fileSummary(path: url.path)
    }

    static func fileSummary(path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let fm = FileManager.default
        guard fm.fileExists(atPath: path) else {
            return "path=\(sanitize(path)) exists=false"
        }

        let attrs = (try? fm.attributesOfItem(atPath: path)) ?? [:]
        let size = (attrs[.size] as? NSNumber)?.intValue ?? 0
        let ext = url.pathExtension.isEmpty ? "none" : url.pathExtension
        let magic = readMagicHex(path: path, length: 12)
        let guessed = guessFormat(magicHex: magic, pathExtension: ext)

        return "path=\(sanitize(path)) size=\(size)B ext=.\(ext) magic=\(magic) guessed=\(guessed)"
    }

    // MARK: - Private

    private static func sanitize(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "nil" }
        if value.count > 160 {
            return String(value.prefix(160)) + "…"
        }
        return value
    }

    private static func readMagicHex(path: String, length: Int) -> String {
        guard let handle = FileHandle(forReadingAtPath: path) else { return "unreadable" }
        defer { try? handle.close() }
        let data = handle.readData(ofLength: length)
        guard !data.isEmpty else { return "empty" }
        return data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    private static func guessFormat(magicHex: String, pathExtension: String) -> String {
        let upper = magicHex.uppercased()
        if upper.hasPrefix("52 49 46 46") { return "wav" }
        if upper.contains("23 21 41 4D 52") || upper.hasPrefix("23 21 41 4D 52") { return "amr" }
        if upper.count >= 11 {
            let bytes = upper.split(separator: " ")
            if bytes.count >= 8,
               bytes[4] == "66", bytes[5] == "74", bytes[6] == "79", bytes[7] == "70" {
                return "m4a/mp4"
            }
        }
        if upper.hasPrefix("FF F1") || upper.hasPrefix("FF F9") { return "aac-adts" }
        if upper.hasPrefix("49 44 33") { return "mp3-id3" }
        if !pathExtension.isEmpty { return ".\(pathExtension)" }
        return "unknown"
    }

    private static func fourCC(_ value: FourCharCode) -> String {
        let bytes: [UInt8] = [
            UInt8((value >> 24) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF),
        ]
        let printable = bytes.allSatisfy { $0 >= 32 && $0 < 127 }
        if printable {
            return String(bytes: bytes, encoding: .ascii) ?? String(format: "0x%08X", value)
        }
        return String(format: "0x%08X", value)
    }
}
