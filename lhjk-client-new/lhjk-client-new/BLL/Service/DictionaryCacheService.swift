import Foundation

// MARK: - 字典本地缓存 (BLL)

/// `getDictionaryByParentId2` 批量结果本地持久化。
///
/// - 成功拉取覆盖本地；失败保留旧数据
/// - 「清理缓存」不调用 `clear()`，与图片/Hub 缓存隔离
/// - 登录后一次 `sync()` 拉取全部 `DictionaryParent`（含德系 9 宫格 `packageSeries`）
final class DictionaryCacheService {

    static let shared = DictionaryCacheService()

    static let didUpdateNotification = Notification.Name("lhjk.dictionary.cache.didUpdate")

    private static let storageKey = "lhjk.dictionary.catalog.v1"

    private let lock = NSLock()
    private var rootsByParentId: [Int64: SDictionary] = [:]

    private init() {
        loadFromDisk()
    }

    // MARK: - Sync

    private var syncTask: Task<Void, Never>?

    /// 拉取并覆盖本地字典（全部父节点，单次 `getDictionaryByParentId2`）
    func sync() async {
        if let syncTask {
            await syncTask.value
            return
        }
        let task = Task {
            await performSync()
        }
        syncTask = task
        await task.value
        syncTask = nil
    }

    private func performSync() async {
        let parentIds = DictionaryParent.allCases.map(\.rawValue)
        do {
            let nodes = try await DictionaryService.shared.fetchNodes(parentIds: parentIds, allStatus: true)
            apply(nodes: nodes, persist: true)
            print("[DictionaryCache] sync ✓ parents=\(nodes.count)")
            await MainActor.run {
                NotificationCenter.default.post(name: Self.didUpdateNotification, object: nil)
            }
        } catch {
            print("[DictionaryCache] sync ✗ \(error.localizedDescription) — keep local cache")
        }
    }

    // MARK: - Lookup

    func label(parent: DictionaryParent, intValue: Int?) -> String? {
        guard let intValue else { return nil }
        return label(parent: parent, value: String(intValue))
    }

    func label(parent: DictionaryParent, value: String?) -> String? {
        let key = normalizedValue(value)
        guard !key.isEmpty else { return nil }
        return enabledChildren(for: parent).first { normalizedValue($0.value) == key }?
            .name?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
    }

    func intValue(parent: DictionaryParent, name: String?) -> Int? {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return nil }
        guard let child = enabledChildren(for: parent).first(where: {
            ($0.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") == trimmed
        }) else { return nil }
        guard let raw = child.value?.trimmingCharacters(in: .whitespacesAndNewlines),
              let int = Int(raw) else { return nil }
        return int
    }

    func optionNames(parent: DictionaryParent) -> [String] {
        enabledChildren(for: parent).compactMap { item in
            item.name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        }
    }

    func billingUnitLabel(_ billingType: Int?, default defaultLabel: String) -> String {
        label(parent: .packageUnit, intValue: billingType) ?? defaultLabel
    }

    func packageBadgeLabel(recommend: Int?) -> String? {
        label(parent: .packageBadge, intValue: recommend)
    }

    /// 德系 9 宫格产品线（字典 `packageSeries`）
    func productMatrix() -> [ProductMatrixItem] {
        ProductMatrixMapper.toMatrixItems(rootNodes(for: .packageSeries))
    }

    /// 推荐服务类目 → `packageMainCategory`（字典 `packageCategory`）
    func recommendCategories() -> [ServiceRecommendCategory] {
        guard let root = root(for: .packageCategory) else { return [] }
        return ServiceRecommendCategoryMapper.toCategories([root])
    }

    func rootNodes(for parent: DictionaryParent) -> [SDictionary] {
        guard let root = root(for: parent) else { return [] }
        return [root]
    }

    // MARK: - 健康监测任务（仅路由跳转使用字典，其它模块不变）

    func isNavigableMonitorTaskType(_ type: Int?) -> Bool {
        guard let type, let route = monitorTaskActionRoute(type) else { return false }
        return !route.isEmpty
    }

    func monitorTaskActionRoute(_ type: Int?) -> String? {
        guard let type else { return nil }
        guard enabledChildren(for: .monitorType).contains(where: {
            Int(normalizedValue($0.value)) == type
        }) else { return nil }
        return Self.monitorTaskRoutes[type]
    }

    func monitorTaskDisplayName(_ type: Int?) -> String? {
        label(parent: .monitorType, intValue: type)
    }

  // MARK: - Private

    private static let monitorTaskRoutes: [Int: String] = [
        2: "/health/metrics/blood-pressure/add",
        3: "/health/metrics/exercise/home",
        4: "/health/metrics/weight/add",
        5: "/health/metrics/blood-sugar/add",
        6: "/health/metrics/temperature/add",
        7: "/health/metrics/spo2/add",
    ]

    private func root(for parent: DictionaryParent) -> SDictionary? {
        lock.lock()
        defer { lock.unlock() }
        return rootsByParentId[parent.rawValue]
    }

    private func enabledChildren(for parent: DictionaryParent) -> [SDictionary] {
        lock.lock()
        let root = rootsByParentId[parent.rawValue]
        lock.unlock()
        guard let root else { return [] }
        let children = root.children ?? []
        let list = children.isEmpty ? [root] : children
        return list
            .filter { $0.status == nil || $0.status == 1 }
            .sorted { ($0.sortId ?? Int.max) < ($1.sortId ?? Int.max) }
    }

    private func apply(nodes: [SDictionary], persist: Bool) {
        var map: [Int64: SDictionary] = [:]
        for node in nodes {
            if let id = Int64(node.id.trimmingCharacters(in: .whitespacesAndNewlines)) {
                map[id] = node
            }
        }
        lock.lock()
        rootsByParentId = map
        lock.unlock()
        if persist {
            saveToDisk(nodes)
        }
    }

    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return }
        guard let nodes = try? JSONDecoder().decode([SDictionary].self, from: data) else { return }
        apply(nodes: nodes, persist: false)
        print("[DictionaryCache] loaded local parents=\(nodes.count)")
    }

    private func saveToDisk(_ nodes: [SDictionary]) {
        guard let data = try? JSONEncoder().encode(nodes) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func normalizedValue(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
