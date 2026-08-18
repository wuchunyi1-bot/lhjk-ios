import Foundation
import Combine

/// 健康 Hub ViewModel — 体征监测卡片 + 快捷入口（CMS / 卡片列表）
final class HealthViewModel: ObservableObject {

    @Published private(set) var metrics: [HealthMetricDisplayItem] = []
    @Published private(set) var quickEntries: [HealthQuickEntryDisplayItem] = MonitorCardDisplayMapper.defaultQuickEntries()
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: String?

    private let cacheService: HealthPageCacheService
    private var loadTask: Task<Void, Never>?

    init(cacheService: HealthPageCacheService = AppContainer.shared.healthPageCacheService) {
        self.cacheService = cacheService
    }

    deinit { loadTask?.cancel() }

    func load() {
        loadTask?.cancel()
        loadTask = Task { @MainActor [weak self] in
            await self?.fetch()
        }
    }

    @MainActor
    private func fetch() async {
        if let cached = await cacheService.getCached() {
            applyHubCache(cached)
        }

        guard HealthPageService.resolveHospitalId() != nil else {
            metrics = []
            quickEntries = []
            loadError = "缺少机构信息"
            return
        }

        let showLoading = await cacheService.getCached() == nil
        if showLoading {
            isLoading = true
            loadError = nil
        }

        let hub: HealthPageHubCache?
        if await cacheService.hasLoaded {
            hub = await cacheService.refresh()
        } else {
            hub = await cacheService.preload()
        }

        guard !Task.isCancelled else {
            if showLoading { isLoading = false }
            return
        }

        if let hub {
            applyHubCache(hub)
        } else if await cacheService.getCached() == nil {
            metrics = []
            quickEntries = []
            if loadError == nil {
                loadError = "加载失败"
            }
        }

        if showLoading { isLoading = false }
    }

    @MainActor
    private func applyHubCache(_ hub: HealthPageHubCache) {
        quickEntries = MonitorCardDisplayMapper.quickEntries(from: hub.cms.quickEntryList)

        if !hub.monitorCards.isEmpty {
            metrics = MonitorCardDisplayMapper.fromMonitorCards(hub.monitorCards)
            loadError = nil
        } else {
            metrics = MonitorCardDisplayMapper.fromCmsMeta(hub.cms.monitorCardMeta ?? [])
            loadError = nil
        }
    }

    func route(for metric: HealthMetricDisplayItem) -> String {
        MonitorCardDisplayMapper.route(for: metric.cardType)
    }
}
