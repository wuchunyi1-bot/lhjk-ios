import Foundation
import Combine

/// 编辑卡片 ViewModel — 对齐 funde-client MetricCardEditView（最多 6 张 / 排序 / 保存）
final class MetricCardEditViewModel: ObservableObject {

    struct EditCard: Equatable, Identifiable {
        var id: Int { cardType }
        let cardType: Int
        var cardName: String
        var iconUrl: String?
        var sortId: Int
    }

    @Published private(set) var displayed: [EditCard] = []
    @Published private(set) var hidden: [EditCard] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?
    @Published var toastMessage: String?

    private let healthPageService: HealthPageService
    private var hospitalId: String?
    private var snapshotDisplayed: [EditCard] = []

    init(healthPageService: HealthPageService = AppContainer.shared.healthPageService) {
        self.healthPageService = healthPageService
    }

    var hasChanges: Bool {
        let current = displayed.map(\.cardType)
        let snap = snapshotDisplayed.map(\.cardType)
        guard current.count == snap.count else { return true }
        return current != snap
    }

    func load() {
        Task { @MainActor in
            await fetch()
        }
    }

    @MainActor
    private func fetch() async {
        guard let hospitalId = HealthPageService.resolveHospitalId() else {
            errorMessage = "缺少机构信息"
            return
        }
        self.hospitalId = hospitalId
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let cfg = try await healthPageService.getUserMonitorCardConfig(hospitalId: hospitalId)
            var shown = (cfg.displayedCard ?? []).compactMap(Self.mapItem)
                .sorted { $0.sortId < $1.sortId }
            var hide = (cfg.hiddenCard ?? []).compactMap(Self.mapItem)
                .sorted { $0.sortId < $1.sortId }

            if shown.count > MonitorCardDisplayMapper.maxVisibleCards {
                let overflow = Array(shown[MonitorCardDisplayMapper.maxVisibleCards...])
                shown = Array(shown.prefix(MonitorCardDisplayMapper.maxVisibleCards))
                hide.append(contentsOf: overflow)
            }

            displayed = shown
            hidden = hide
            snapshotDisplayed = shown
        } catch {
            errorMessage = error.localizedDescription
            print("[MetricCardEditViewModel] load ✗ \(error.localizedDescription)")
        }
    }

    @MainActor
    func hideCard(_ cardType: Int) {
        guard let idx = displayed.firstIndex(where: { $0.cardType == cardType }) else { return }
        var card = displayed.remove(at: idx)
        card.sortId = (hidden.map(\.sortId).max() ?? -1) + 1
        hidden.append(card)
        renumberDisplayed()
    }

    @MainActor
    func showCard(_ cardType: Int) {
        guard displayed.count < MonitorCardDisplayMapper.maxVisibleCards else {
            toastMessage = "不能超过六张，请重新编辑"
            return
        }
        guard let idx = hidden.firstIndex(where: { $0.cardType == cardType }) else { return }
        var card = hidden.remove(at: idx)
        card.sortId = displayed.count
        displayed.append(card)
        renumberDisplayed()
    }

    @MainActor
    func moveDisplayed(from source: Int, to destination: Int) {
        guard source != destination,
              displayed.indices.contains(source),
              destination >= 0, destination <= displayed.count else { return }
        let item = displayed.remove(at: source)
        let dest = destination > source ? destination - 1 : destination
        let clamped = min(max(dest, 0), displayed.count)
        displayed.insert(item, at: clamped)
        renumberDisplayed()
    }

    @MainActor
    func reorderDisplayed(to order: [Int]) {
        let map = Dictionary(uniqueKeysWithValues: displayed.map { ($0.cardType, $0) })
        var next: [EditCard] = []
        for type in order {
            if let c = map[type] { next.append(c) }
        }
        for c in displayed where !order.contains(c.cardType) {
            next.append(c)
        }
        displayed = next
        renumberDisplayed()
    }

    @MainActor
    func save() async -> Bool {
        guard let hospitalId else {
            errorMessage = "缺少机构信息"
            return false
        }
        isSaving = true
        defer { isSaving = false }

        let list = displayed.enumerated().map { idx, card in
            MonitorCardConfigItemDTO(
                cardName: card.cardName,
                cardType: card.cardType,
                sortId: idx
            )
        }

        do {
            try await healthPageService.saveUserMonitorCardConfig(
                hospitalId: hospitalId,
                addCardVOList: list
            )
            await HealthPageCacheService.shared.invalidate()
            _ = await HealthPageCacheService.shared.refresh()
            snapshotDisplayed = displayed
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("[MetricCardEditViewModel] save ✗ \(error.localizedDescription)")
            return false
        }
    }

    @MainActor
    func revertToSnapshot() {
        let snapTypes = Set(snapshotDisplayed.map(\.cardType))
        let all = displayed + hidden
        displayed = snapshotDisplayed
        hidden = all.filter { !snapTypes.contains($0.cardType) }
        renumberDisplayed()
    }

    private func renumberDisplayed() {
        for i in displayed.indices {
            displayed[i].sortId = i
        }
    }

    private static func mapItem(_ item: MonitorCardItemVO) -> EditCard? {
        guard let type = item.cardType else { return nil }
        let name = (item.cardName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let key = MonitorCardDisplayMapper.metricKey(for: type)
        return EditCard(
            cardType: type,
            cardName: name.isEmpty ? H5Config.metricTitle(for: key) : name,
            iconUrl: {
                let t = (item.iconUrl ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                return t.isEmpty ? nil : t
            }(),
            sortId: item.sortId ?? 0
        )
    }
}
