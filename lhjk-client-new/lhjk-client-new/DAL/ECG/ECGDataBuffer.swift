import Foundation

// MARK: - ECG Data Buffer (DAL)

/// 环形缓冲区 — 存储 ECG 波形数据，O(1) 追加，线程安全。
///
/// 替代原 `PointContainer` 单例的 C 数组方案，解决以下问题：
/// - 原实现每次插入 O(n) 位移所有元素
/// - 原实现 x 坐标在位移时不更新，导致绘制错位
/// - 原实现单例限制多导联场景
///
/// 使用方式：
/// ```swift
/// let buffer = ECGDataBuffer(capacity: 1024)
/// buffer.append(1.23)  // 追加一个数据点
/// let points = buffer.chronologicalPoints()  // 按时间顺序取出
/// ```
final class ECGDataBuffer {

    // MARK: - Properties

    /// 缓冲区最大容量
    let capacity: Int

    /// 当前已存储的数据点数量（≤ capacity）
    private(set) var count: Int = 0

    // MARK: - Private Storage

    private var _buffer: [Float]
    private var _head: Int = 0      // 下一次写入的索引
    private let _lock = NSLock()    // 线程安全锁

    // MARK: - Initialization

    /// 创建一个 ECG 数据缓冲区
    /// - Parameter capacity: 最大容量，默认 2048。
    ///   以 250Hz 采样率计算，2048 点 ≈ 8.2 秒数据。
    init(capacity: Int = 2048) {
        self.capacity = max(1, capacity)
        self._buffer = Array(repeating: 0, count: self.capacity)
    }

    // MARK: - Public API

    /// 追加一个数据点到缓冲区（O(1)）
    ///
    /// 当缓冲区满时，最旧的数据点被覆盖。
    /// - Parameter value: ECG 信号幅值
    func append(_ value: Float) {
        _lock.lock()
        defer { _lock.unlock() }

        _buffer[_head] = value
        _head = (_head + 1) % capacity
        if count < capacity {
            count += 1
        }
    }

    /// 批量追加数据点（O(k)，k 为追加数量）
    /// - Parameter values: ECG 信号幅值数组
    func append(contentsOf values: [Float]) {
        _lock.lock()
        defer { _lock.unlock() }

        for value in values {
            _buffer[_head] = value
            _head = (_head + 1) % capacity
            if count < capacity {
                count += 1
            }
        }
    }

    /// 清空缓冲区，回到初始状态
    func reset() {
        _lock.lock()
        defer { _lock.unlock() }

        _head = 0
        count = 0
        // 安全擦除旧数据（可选，调试时有助于识别未初始化数据）
        _buffer = Array(repeating: 0, count: capacity)
    }

    /// 以时间顺序（旧→新）返回当前缓冲区中的所有数据点
    ///
    /// 复杂度 O(n)，n = count。仅在渲染时调用一次，不在热路径上。
    /// - Returns: 按时间顺序排列的数据点数组
    func chronologicalPoints() -> [Float] {
        _lock.lock()
        defer { _lock.unlock() }

        guard count > 0 else { return [] }

        let start = (count < capacity) ? 0 : _head
        var result: [Float] = []
        result.reserveCapacity(count)
        for i in 0..<count {
            let idx = (start + i) % capacity
            result.append(_buffer[idx])
        }
        return result
    }

    /// 获取最新的数据点，不改变缓冲区状态
    /// - Returns: 最新的值，缓冲区为空时返回 nil
    func latest() -> Float? {
        _lock.lock()
        defer { _lock.unlock() }

        guard count > 0 else { return nil }
        let latestIdx = (_head - 1 + capacity) % capacity
        return _buffer[latestIdx]
    }

    /// 获取最近 N 个数据点（按时间顺序，旧→新）
    /// - Parameter n: 请求的数量，超过 count 时返回全部
    /// - Returns: 最近 n 个数据点
    func latest(_ n: Int) -> [Float] {
        _lock.lock()
        defer { _lock.unlock() }

        guard count > 0 else { return [] }
        let requestCount = min(n, count)
        var result: [Float] = []
        result.reserveCapacity(requestCount)

        // 从旧到新：先定位起始索引
        let latestIdx = (_head - 1 + capacity) % capacity
        let startIdx = (latestIdx - requestCount + 1 + capacity) % capacity

        for i in 0..<requestCount {
            let idx = (startIdx + i) % capacity
            result.append(_buffer[idx])
        }
        return result
    }
}
