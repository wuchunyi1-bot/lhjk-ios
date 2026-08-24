import AVFoundation
import CoreMedia

struct VoiceAssetProfile {
    let isPlayable: Bool
    let audioCodecs: [String]
    let duration: TimeInterval
    let sampleRate: Double
    let channelCount: Int

    var containsOpus: Bool {
        audioCodecs.contains { $0.caseInsensitiveCompare("Opus") == .orderedSame || $0 == "opus" }
    }

    /// iOS 16 及更早无法通过 AVFoundation 解码 MP4 内的 Opus 音轨
    var requiresOpusTranscode: Bool {
        containsOpus && !Self.systemSupportsOpusInMP4
    }

    private static var systemSupportsOpusInMP4: Bool {
        if #available(iOS 17.0, *) {
            return true
        }
        return false
    }
}

enum VoiceAssetInspector {

    static func inspect(url: URL) -> VoiceAssetProfile {
        let asset = AVURLAsset(url: url)
        let audioTracks = asset.tracks(withMediaType: .audio)
        var codecs: [String] = []
        var sampleRate: Double = 16_000
        var channelCount = 1

        for track in audioTracks {
            let descriptions = track.formatDescriptions as? [CMFormatDescription] ?? []
            for description in descriptions {
                codecs.append(fourCC(CMFormatDescriptionGetMediaSubType(description)))
                if let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(description)?.pointee {
                    if asbd.mSampleRate > 0 {
                        sampleRate = asbd.mSampleRate
                    }
                    if asbd.mChannelsPerFrame > 0 {
                        channelCount = Int(asbd.mChannelsPerFrame)
                    }
                }
            }
        }

        let duration = CMTimeGetSeconds(asset.duration)
        return VoiceAssetProfile(
            isPlayable: asset.isPlayable,
            audioCodecs: codecs,
            duration: duration.isFinite ? duration : 0,
            sampleRate: sampleRate,
            channelCount: max(channelCount, 1)
        )
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
