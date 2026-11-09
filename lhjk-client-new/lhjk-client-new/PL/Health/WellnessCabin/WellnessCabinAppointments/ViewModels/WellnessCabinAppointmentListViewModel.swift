import Combine
import Foundation

enum CabinAppointmentTab: Int, CaseIterable {
    case all = 0
    case pending = 3
    case serving = 4
    case finished = 5
    case cancelled = 6
    case expired = 7

    var title: String {
        switch self {
        case .all: return "全部"
        case .pending: return "待服务"
        case .serving: return "服务中"
        case .finished: return "已完成"
        case .cancelled: return "已取消"
        case .expired: return "已过期"
        }
    }

    /// 全部不传 status。
    var statusQuery: String? {
        self == .all ? nil : String(rawValue)
    }

    var emptyText: String {
        self == .all ? "暂无预约记录" : "暂无\(title)预约"
    }
}

@MainActor
final class WellnessCabinAppointmentListViewModel: ObservableObject {

    @Published private(set) var tab: CabinAppointmentTab = .all
    @Published private(set) var items: [CabinAppointmentVO] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = false
    @Published private(set) var errorMessage: String?

    private let pageSize = 20
    private var currentPage = 1
    private var requestID = 0
    private var isCancelling = false
    private let cabinService: CabinService

    init(cabinService: CabinService = AppContainer.shared.cabinService) {
        self.cabinService = cabinService
    }

    var emptyText: String { tab.emptyText }

    func reload() {
        requestID += 1
        let token = requestID
        currentPage = 1
        hasMore = false
        isLoading = true
        let status = tab.statusQuery
        let service = cabinService
        let pageSize = pageSize
        Task.detached {
            do {
                let page = try await service.appointments(status: status, pageNum: 1, pageSize: pageSize)
                await self.apply(page, pageNum: 1, append: false, token: token)
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "获取预约记录失败"
                await self.fail(message, token: token, append: false)
            }
        }
    }

    func select(_ tab: CabinAppointmentTab) {
        guard tab != self.tab else { return }
        self.tab = tab
        items = []
        reload()
    }

    func loadMore() {
        guard hasMore, !isLoading, !isLoadingMore else { return }
        isLoadingMore = true
        let token = requestID
        let next = currentPage + 1
        let status = tab.statusQuery
        let service = cabinService
        let pageSize = pageSize
        Task.detached {
            do {
                let page = try await service.appointments(status: status, pageNum: next, pageSize: pageSize)
                await self.apply(page, pageNum: next, append: true, token: token)
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "获取预约记录失败"
                await self.fail(message, token: token, append: true)
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }

    /// 只作废本次时段，不在这里退款。正在取消时返回 false。
    func cancel(_ item: CabinAppointmentVO) async throws -> Bool {
        guard !isCancelling else { return false }
        isCancelling = true
        defer { isCancelling = false }
        try await cabinService.cancelReservation(id: item.id)
        return true
    }

    private func apply(_ page: PaginatedCabinAppointmentData, pageNum: Int, append: Bool, token: Int) {
        guard token == requestID else { return }
        isLoading = false
        isLoadingMore = false
        let rows = page.records ?? []
        items = append ? items + rows : rows
        currentPage = pageNum
        let total = page.totalRecords ?? items.count
        hasMore = !rows.isEmpty && items.count < total
    }

    private func fail(_ message: String, token: Int, append: Bool) {
        guard token == requestID else { return }
        isLoading = false
        isLoadingMore = false
        if !append {
            items = []
            hasMore = false
        }
        errorMessage = message
    }
}
