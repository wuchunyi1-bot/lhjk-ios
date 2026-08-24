import AVFoundation
import CoreMedia
import Foundation

#if canImport(opus)
import opus
#endif

enum OpusVoiceTranscoderError: LocalizedError {
    case opusLibraryUnavailable
    case noAudioTrack
    case readerFailed(String)
    case decodeFailed(String)
    case emptyPCM

    var errorDescription: String? {
        switch self {
        case .opusLibraryUnavailable:
            return "当前设备无法解码 Opus 语音，请升级系统或联系对方重发"
        case .noAudioTrack:
            return "语音文件无音轨"
        case .readerFailed(let detail):
            return "读取语音失败：\(detail)"
        case .decodeFailed(let detail):
            return "解码 Opus 失败：\(detail)"
        case .emptyPCM:
            return "语音解码结果为空"
        }
    }
}

/// 将 MP4/M4A 容器内的 Opus 音轨解码为 WAV，供 AVAudioPlayer 播放（iOS 16 跨端语音）
enum OpusVoiceTranscoder {

    static var isAvailable: Bool {
        #if canImport(opus)
        return true
        #else
        return false
        #endif
    }

    static func transcodedWAVURL(
        from sourceURL: URL,
        sampleRate: Int = 16_000,
        channels: Int = 1
    ) throws -> URL {
        #if canImport(opus)
        let pcm = try extractAndDecodePCM(from: sourceURL, sampleRate: sampleRate, channels: channels)
        let wavURL = URL(
            fileURLWithPath: NSTemporaryDirectory()
                + "voice_opus_\(Int(Date().timeIntervalSince1970)).wav"
        )
        try? FileManager.default.removeItem(at: wavURL)
        try writeWAV(pcm: pcm, to: wavURL, sampleRate: sampleRate, channels: channels)
        return wavURL
        #else
        throw OpusVoiceTranscoderError.opusLibraryUnavailable
        #endif
    }

    // MARK: - Private

    #if canImport(opus)
    private static func extractAndDecodePCM(
        from sourceURL: URL,
        sampleRate: Int,
        channels: Int
    ) throws -> Data {
        let asset = AVURLAsset(url: sourceURL)
        guard let track = asset.tracks(withMediaType: .audio).first else {
            throw OpusVoiceTranscoderError.noAudioTrack
        }

        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else {
            throw OpusVoiceTranscoderError.readerFailed("cannot add track output")
        }
        reader.add(output)
        guard reader.startReading() else {
            throw OpusVoiceTranscoderError.readerFailed(reader.error?.localizedDescription ?? "startReading failed")
        }

        var errorCode: Int32 = 0
        guard let decoder = opus_decoder_create(Int32(sampleRate), Int32(channels), &errorCode) else {
            throw OpusVoiceTranscoderError.decodeFailed("opus_decoder_create code=\(errorCode)")
        }
        defer { opus_decoder_destroy(decoder) }

        let maxFrameSamples = 960 * 6
        var pcm = Data()
        var packetCount = 0

        while reader.status == .reading {
            guard let sampleBuffer = output.copyNextSampleBuffer() else { break }
            defer { CMSampleBufferInvalidate(sampleBuffer) }

            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
            var totalLength = 0
            var dataPointer: UnsafeMutablePointer<Int8>?
            let status = CMBlockBufferGetDataPointer(
                blockBuffer,
                atOffset: 0,
                lengthAtOffsetOut: nil,
                totalLengthOut: &totalLength,
                dataPointerOut: &dataPointer
            )
            guard status == kCMBlockBufferNoErr, let dataPointer, totalLength > 0 else { continue }

            let packet = Data(bytes: dataPointer, count: totalLength)
            packetCount += 1

            var frameBuffer = [Int16](repeating: 0, count: maxFrameSamples * channels)
            let decodedSamples = packet.withUnsafeBytes { rawBuffer -> Int32 in
                guard let baseAddress = rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    return -1
                }
                return opus_decode(
                    decoder,
                    baseAddress,
                    Int32(packet.count),
                    &frameBuffer,
                    Int32(maxFrameSamples),
                    0
                )
            }

            guard decodedSamples > 0 else {
                print("[Voice] opus decode skip packet=\(packetCount) code=\(decodedSamples)")
                continue
            }

            let byteCount = Int(decodedSamples) * channels * MemoryLayout<Int16>.size
            frameBuffer.withUnsafeBytes { rawBuffer in
                if let base = rawBuffer.baseAddress {
                    pcm.append(base.assumingMemoryBound(to: UInt8.self), count: byteCount)
                }
            }
        }

        if reader.status == .failed {
            throw OpusVoiceTranscoderError.readerFailed(reader.error?.localizedDescription ?? "reader failed")
        }
        guard !pcm.isEmpty else {
            throw OpusVoiceTranscoderError.emptyPCM
        }

        print("[Voice] opus transcode ✓ packets=\(packetCount) pcmBytes=\(pcm.count)")
        return pcm
    }
    #endif

    private static func writeWAV(
        pcm: Data,
        to url: URL,
        sampleRate: Int,
        channels: Int,
        bitsPerSample: Int = 16
    ) throws {
        let byteRate = sampleRate * channels * bitsPerSample / 8
        let blockAlign = channels * bitsPerSample / 8
        var header = Data()

        func appendString(_ value: String) {
            header.append(value.data(using: .ascii) ?? Data())
        }
        func appendUInt32LE(_ value: UInt32) {
            var le = value.littleEndian
            header.append(Data(bytes: &le, count: 4))
        }
        func appendUInt16LE(_ value: UInt16) {
            var le = value.littleEndian
            header.append(Data(bytes: &le, count: 2))
        }

        let dataSize = UInt32(pcm.count)
        let riffSize = 36 + dataSize

        appendString("RIFF")
        appendUInt32LE(riffSize)
        appendString("WAVE")
        appendString("fmt ")
        appendUInt32LE(16)
        appendUInt16LE(1)
        appendUInt16LE(UInt16(channels))
        appendUInt32LE(UInt32(sampleRate))
        appendUInt32LE(UInt32(byteRate))
        appendUInt16LE(UInt16(blockAlign))
        appendUInt16LE(UInt16(bitsPerSample))
        appendString("data")
        appendUInt32LE(dataSize)

        var fileData = header
        fileData.append(pcm)
        try fileData.write(to: url, options: .atomic)
    }
}
