import UIKit

// MARK: - ECG Chart View (DAL)

/// 实时心电图波形绘制视图。
///
/// 核心改进（对比原 HeartLive / PointContainer）：
/// - O(1) 环形缓冲区替代 O(n) 移位数组，修复 x 坐标不随平移更新的 bug
/// - 标准医学 ECG 网格（横线 + 竖线、大方格 + 小方格），网格缓存为 UIImage
/// - CADisplayLink 驱动 60fps 渲染，自动合并重复刷新
/// - 平滑滚动插值，避免数据突发导致画面跳跃
/// - 可配置走纸速度 / 增益 / 颜色 / 线宽
/// - 支持多实例（不再使用单例数据容器）
///
/// 使用方式：
/// ```swift
/// let view = ECGChartView(frame: ...)
/// view.paperSpeed = 25              // 25 mm/s 标准走纸速度
/// view.verticalRange = 0...240      // 数据范围映射到 view 高度
/// view.startRendering()
/// view.append(value: 120.5)         // 追加 ECG 数据点
/// ```
final class ECGChartView: UIView {

    // MARK: - Grid Configuration

    /// 小方格边长（point），对应标准 ECG 1mm 方格
    /// 默认 5pt ≈ 1mm（视网膜屏适配后可调整）
    var smallSquareSize: CGFloat = 5 {
        didSet { invalidateGridCache() }
    }

    /// 一个大方格包含的小方格数（标准 ECG 为 5，即 5mm 大方格）
    var squaresPerLargeSquare: Int = 5 {
        didSet { invalidateGridCache() }
    }

    /// 网格线颜色
    var gridLineColor: UIColor = UIColor.gray.withAlphaComponent(0.4) {
        didSet { invalidateGridCache() }
    }

    /// 小格线宽
    var gridThinLineWidth: CGFloat = 0.4 {
        didSet { invalidateGridCache() }
    }

    /// 大格线宽
    var gridBoldLineWidth: CGFloat = 0.8 {
        didSet { invalidateGridCache() }
    }

    // MARK: - Waveform Configuration

    /// 波形线颜色
    var waveformColor: UIColor = .systemOrange {
        didSet { markDirty() }
    }

    /// 波形线宽
    var waveformLineWidth: CGFloat = 1.0 {
        didSet { markDirty() }
    }

    /// 走纸速度（mm/s），标准 ECG 为 25 mm/s
    var paperSpeed: CGFloat = 25 {
        didSet { markDirty() }
    }

    /// 增益（pt/mV），标准 ECG 10mm/mV 在 5pt/mm 时为 50pt/mV
    /// 用于将 mV 值转换为 point 坐标
    var gain: CGFloat = 50 {
        didSet { markDirty() }
    }

    /// 数据值在视图垂直方向上的映射范围
    /// 例如心率 0...240 bpm 时，0 对应 view 底部，240 对应顶部
    var verticalRange: ClosedRange<Float> = 0...240 {
        didSet { markDirty() }
    }

    /// 波形右侧留白（point）
    var trailingMargin: CGFloat = 10 {
        didSet { markDirty() }
    }

    /// 每个数据样本的水平间距（point）
    ///
    /// 计算：paperSpeed (mm/s) × smallSquareSize (pt/mm) ÷ 采样率 (Hz)
    /// 例：25 mm/s × 5 pt/mm ÷ 250 Hz = 0.5 pt/样本
    var pointSpacing: CGFloat = 0.5 {
        didSet { markDirty() }
    }

    // MARK: - Data

    /// ECG 数据缓冲区（外部注入，支持多视图共享或独立使用）
    var buffer: ECGDataBuffer = ECGDataBuffer(capacity: 2048)

    /// 自上次 reset 以来接收的总样本数
    private var totalSamplesReceived: Int = 0

    // MARK: - Rendering State

    private var displayLink: CADisplayLink?
    private var cachedGridImage: UIImage?
    private var gridCacheInvalid = true
    private var needsRedraw = false
    private var lastFrameTime: CFTimeInterval = 0

    /// 视觉滚动偏移（平滑插值），避免数据突发导致画面跳跃
    private var visualScrollOffset: CGFloat = 0

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
        lastFrameTime = CACurrentMediaTime()
    }

    deinit {
        stopRendering()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        if cachedGridImage?.size != bounds.size {
            invalidateGridCache()
        }
    }

    // MARK: - Public API

    /// 追加一个数据点到波形末尾（线程安全）
    /// - Parameter value: 数据值（由 verticalRange 映射到屏幕坐标）
    func append(value: Float) {
        buffer.append(value)
        totalSamplesReceived += 1
        markDirty()
    }

    /// 批量追加数据点（线程安全）
    /// - Parameter values: 数据值数组
    func append(contentsOf values: [Float]) {
        buffer.append(contentsOf: values)
        totalSamplesReceived += values.count
        markDirty()
    }

    /// 开始渲染（启动 CADisplayLink，60fps）
    func startRendering() {
        guard displayLink == nil else { return }
        lastFrameTime = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    /// 停止渲染（暂停 CADisplayLink，省电）
    func stopRendering() {
        displayLink?.invalidate()
        displayLink = nil
    }

    /// 清空所有数据和滚动位置
    func reset() {
        buffer.reset()
        totalSamplesReceived = 0
        visualScrollOffset = 0
        markDirty()
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        // 1. 网格背景（缓存，O(1) 开销）
        drawGrid(in: context)

        // 2. 波形曲线
        drawWaveform(in: context)
    }

    // MARK: - Grid (Cached as UIImage)

    private func drawGrid(in context: CGContext) {
        if gridCacheInvalid || cachedGridImage == nil {
            cachedGridImage = renderGridToImage()
            gridCacheInvalid = false
        }
        cachedGridImage?.draw(in: bounds)
    }

    /// 将网格渲染为 UIImage（仅在尺寸或样式变化时调用一次）
    private func renderGridToImage() -> UIImage? {
        let size = bounds.size
        guard size.width > 0, size.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { ctx in
            let c = ctx.cgContext
            let thinWidth = gridThinLineWidth
            let boldWidth = gridBoldLineWidth
            let color = gridLineColor.cgColor
            let largeStep = smallSquareSize * CGFloat(squaresPerLargeSquare)

            // ---- 竖线：批量构建后一次性 stroke ----
            c.setStrokeColor(color)
            c.beginPath()
            var x: CGFloat = 0
            var col = 0
            while x <= size.width {
                c.setLineWidth((col % squaresPerLargeSquare == 0) ? boldWidth : thinWidth)
                c.move(to: CGPoint(x: x, y: 0))
                c.addLine(to: CGPoint(x: x, y: size.height))
                c.strokePath()
                x += smallSquareSize
                col += 1
            }

            // ---- 横线：批量构建后一次性 stroke ----
            c.beginPath()
            var y: CGFloat = 0
            var row = 0
            while y <= size.height {
                c.setLineWidth((row % squaresPerLargeSquare == 0) ? boldWidth : thinWidth)
                c.move(to: CGPoint(x: 0, y: y))
                c.addLine(to: CGPoint(x: size.width, y: y))
                c.strokePath()
                y += smallSquareSize
                row += 1
            }
        }
    }

    private func invalidateGridCache() {
        gridCacheInvalid = true
        markDirty()
    }

    // MARK: - Waveform Drawing

    private func drawWaveform(in context: CGContext) {
        let points = buffer.chronologicalPoints()
        guard points.count >= 1 else { return }

        let viewWidth = bounds.width
        let viewHeight = bounds.height
        let count = points.count

        let rangeMin = CGFloat(verticalRange.lowerBound)
        let rangeMax = CGFloat(verticalRange.upperBound)
        let rangeSpan = rangeMax - rangeMin
        guard rangeSpan > 0 else { return }

        context.setLineWidth(waveformLineWidth)
        context.setStrokeColor(waveformColor.cgColor)
        context.setLineJoin(.round)
        context.setLineCap(.round)

        var firstPointDrawn = false

        // 以最新点固定在右侧留白处为基准，老点依次向左排列
        // x(i) = viewWidth - trailingMargin - (count - 1 - i) * pointSpacing
        let baseX = viewWidth - trailingMargin - CGFloat(count - 1) * pointSpacing
        let clipMinX: CGFloat = -pointSpacing
        let clipMaxX: CGFloat = viewWidth + pointSpacing

        for i in 0..<count {
            let x = baseX + CGFloat(i) * pointSpacing

            // 跳过完全不可见的点
            if x < clipMinX { continue }
            if x > clipMaxX { continue }

            // 值 → 纵坐标：值域 [rangeMin, rangeMax] 映射到 [viewHeight, 0]
            let rawValue = CGFloat(points[i])
            let normalized = (rawValue - rangeMin) / rangeSpan
            let clamped = max(0, min(1, normalized))
            let y = viewHeight - clamped * viewHeight

            if !firstPointDrawn {
                context.move(to: CGPoint(x: x, y: y))
                firstPointDrawn = true
            } else {
                context.addLine(to: CGPoint(x: x, y: y))
            }
        }

        context.strokePath()
    }

    // MARK: - CADisplayLink

    @objc private func displayLinkFired() {
        // 无新数据时跳过绘制，减少 GPU 开销
        guard needsRedraw else { return }
        needsRedraw = false

        // 视觉滚动平滑插值
        let now = CACurrentMediaTime()
        let dt = now - lastFrameTime
        lastFrameTime = now

        let targetOffset = CGFloat(totalSamplesReceived) * pointSpacing
        // 指数平滑，dt 越小趋近越慢 → 帧率自适应
        let smoothFactor = min(CGFloat(dt * 10.0), 1.0)
        visualScrollOffset += (targetOffset - visualScrollOffset) * smoothFactor

        setNeedsDisplay()
    }

    private func markDirty() {
        needsRedraw = true
    }
}
