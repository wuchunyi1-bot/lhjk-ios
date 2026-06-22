import Foundation

// MARK: - ECG Waveform Simulator (DAL)

/// 合成 ECG 波形生成器 — 用于 Demo / 无真实设备时的波形模拟。
///
/// 基于高斯函数叠加生成逼真的 P-QRS-T 复合波：
/// - P 波：心房除极
/// - QRS 复合波：心室除极（R 波为主峰，Q/S 为负向波）
/// - T 波：心室复极
///
/// 使用方式：
/// ```swift
/// let sim = ECGSimulator(heartRate: 75, sampleRate: 250)
/// // 在 Timer 中：
/// let value = sim.nextSample()
/// chartView.append(value: value)
/// ```
final class ECGSimulator {

    /// 心率（bpm）
    var heartRate: Double {
        didSet { period = 60.0 / heartRate }
    }

    /// 采样率（Hz）
    let sampleRate: Double

    /// 每个心动周期的秒数
    private var period: Double

    /// 自生成起的累计时间（秒）
    private var elapsed: Double = 0

    /// 采样间隔（秒）
    private var dt: Double { 1.0 / sampleRate }

    // MARK: - Init

    /// - Parameters:
    ///   - heartRate: 模拟心率（bpm），默认 75
    ///   - sampleRate: 采样率（Hz），默认 250
    init(heartRate: Double = 75, sampleRate: Double = 250) {
        self.heartRate = heartRate
        self.sampleRate = sampleRate
        self.period = 60.0 / heartRate
    }

    // MARK: - Public

    /// 获取下一个采样点的 ECG 幅值（mV）
    func nextSample() -> Float {
        defer { elapsed += dt }
        return ecgAmplitude(at: elapsed)
    }

    /// 批量获取 n 个采样点
    func nextSamples(_ n: Int) -> [Float] {
        return (0..<n).map { _ in nextSample() }
    }

    /// 重置计时器
    func reset() {
        elapsed = 0
    }

    // MARK: - ECG Model

    /// 计算给定时刻的 ECG 幅值
    ///
    /// 数学模型：以心动周期为单位，叠加 P / Q / R / S / T 五个高斯分量。
    /// - P 波中心 ≈ 0.10 周期
    /// - Q 波中心 ≈ 0.28
    /// - R 波中心 ≈ 0.30（主峰，幅值最高）
    /// - S 波中心 ≈ 0.32
    /// - T 波中心 ≈ 0.60
    private func ecgAmplitude(at t: Double) -> Float {
        let phase = t.truncatingRemainder(dividingBy: period) / period // 0…1

        // R 波 — 心室除极主峰
        let r = gaussian(phase, center: 0.30, sigma: 0.018) * 1.5
        // Q 波 — 负向，R 之前
        let q = -gaussian(phase, center: 0.275, sigma: 0.008) * 0.35
        // S 波 — 负向，R 之后
        let s = -gaussian(phase, center: 0.325, sigma: 0.008) * 0.5
        // P 波 — 心房除极
        let p = gaussian(phase, center: 0.10, sigma: 0.025) * 0.18
        // T 波 — 心室复极
        let tWave = gaussian(phase, center: 0.62, sigma: 0.045) * 0.35

        return Float(r + q + s + p + tWave)
    }

    /// 高斯函数：exp(-(x - center)² / (2 * sigma²))
    private func gaussian(_ x: Double, center: Double, sigma: Double) -> Double {
        let z = (x - center) / sigma
        return exp(-0.5 * z * z)
    }
}
