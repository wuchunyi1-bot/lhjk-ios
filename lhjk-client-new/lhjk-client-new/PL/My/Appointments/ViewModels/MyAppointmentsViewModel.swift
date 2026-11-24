import Combine
import Foundation

enum MyAppointmentTab: Int, CaseIterable {
    case all = 0
    case arranging = 1
    case confirming = 2
    case pending = 3
    case serving = 4
    case finished = 5
    case cancelled = 6
    case expired = 7

    var title: String {
        switch self {
        case .all: return "全部"
        case .arranging: return "待安排"
        case .confirming: return "待确认"
        case .pending: return "待服务"
        case .serving: return "服务中"
        case .finished: return "已完成"
        case .cancelled: return "已取消"
        case .expired: return "已过期"
        }
    }

    /// 待安排、待确认只有体检和就医协助。其余状态小屋、体检、就医协助都查。
    var businessTypes: [Int] {
        switch self {
        case .arranging, .confirming:
            return [ServiceItemService.examBusinessType, ServiceItemService.assistBusinessType]
        default:
            return [
                CabinService.cabinBusinessType,
                ServiceItemService.examBusinessType,
                ServiceItemService.assistBusinessType,
            ]
        }
    }

    /// 全部不传 status。
    var statusQuery: String? {
        self == .all ? nil : String(rawValue)
    }

    var emptyText: String {
        self == .all ? "暂无预约" : "暂无\(title)预约"
    }
}

struct MyCabinAppointmentDetail {
    let name: String
    let status: Int?
    let statusTitle: String
    let durationText: String?
    let reserveDate: String
    let timeText: String
    let hospitalId: String
    let hospitalName: String
    let address: String
    let notice: String?
    let canBookAgain: Bool

    init(_ item: CabinAppointmentVO) {
        name = item.name
        status = item.status
        statusTitle = item.statusTitle
        durationText = item.durationText
        reserveDate = item.reserveDate
        timeText = item.timeText
        hospitalId = item.hospitalId
        hospitalName = item.hospitalName
        address = item.address
        notice = item.overdueNotice
        canBookAgain = item.canBookAgain
    }

    init?(routeParams: [String: Any]) {
        let name = Self.string(routeParams["name"])
        let statusTitle = Self.string(routeParams["statusTitle"])
        guard !name.isEmpty || !statusTitle.isEmpty else { return nil }
        self.name = name
        status = Int(Self.string(routeParams["status"]))
        self.statusTitle = statusTitle
        let duration = Self.string(routeParams["durationText"])
        durationText = duration.isEmpty ? nil : duration
        reserveDate = Self.string(routeParams["reserveDate"])
        timeText = Self.string(routeParams["timeText"])
        hospitalId = Self.string(routeParams["hospitalId"])
        hospitalName = Self.string(routeParams["hospitalName"])
        address = Self.string(routeParams["address"])
        let notice = Self.string(routeParams["notice"])
        self.notice = notice.isEmpty ? nil : notice
        canBookAgain = Self.string(routeParams["canBookAgain"]) == "1"
    }

    func routeParams() -> [String: Any] {
        var params: [String: Any] = [
            "name": name,
            "statusTitle": statusTitle,
            "reserveDate": reserveDate,
            "timeText": timeText,
            "hospitalId": hospitalId,
            "hospitalName": hospitalName,
            "address": address,
            "canBookAgain": canBookAgain ? "1" : "0",
        ]
        if let status { params["status"] = String(status) }
        if let durationText { params["durationText"] = durationText }
        if let notice { params["notice"] = notice }
        return params
    }

    var scheduleText: String {
        if reserveDate.isEmpty { return timeText }
        if timeText.isEmpty { return reserveDate }
        return "\(reserveDate) \(timeText)"
    }

    var placeText: String {
        [hospitalName, address].filter { !$0.isEmpty }.joined(separator: " ")
    }

    private static func string(_ value: Any?) -> String {
        if let text = value as? String { return text.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let number = value as? NSNumber { return number.stringValue }
        return ""
    }
}

@MainActor
final class MyAppointmentsViewModel: ObservableObject {

    @Published private(set) var tab: MyAppointmentTab = .all
    @Published private(set) var items: [CabinAppointmentVO] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = false
    @Published private(set) var errorMessage: String?

    private let pageSize = 20
    private var requestID = 0
    private var isCancelling = false
    private var sources: [AppointmentPageSource] = []
    private let cabinService: CabinService

    init(cabinService: CabinService = AppContainer.shared.cabinService) {
        self.cabinService = cabinService
    }

    var emptyText: String { tab.emptyText }

    func reload() {
        requestID += 1
        let token = requestID
        sources = tab.businessTypes.map { AppointmentPageSource(businessType: $0) }
        hasMore = !sources.isEmpty
        isLoading = true
        isLoadingMore = false
        fetch(append: false, token: token)
    }

    func select(_ tab: MyAppointmentTab) {
        guard tab != self.tab else { return }
        self.tab = tab
        items = []
        reload()
    }

    func loadMore() {
        guard hasMore, !isLoading, !isLoadingMore else { return }
        isLoadingMore = true
        fetch(append: true, token: requestID)
    }

    func clearError() {
        errorMessage = nil
    }

    /// 只作废本次时段。正在取消时返回 false。
    func cancel(_ item: CabinAppointmentVO) async throws -> Bool {
        guard !isCancelling else { return false }
        isCancelling = true
        defer { isCancelling = false }
        try await cabinService.cancelReservation(id: item.id)
        return true
    }

    private func fetch(append: Bool, token: Int) {
        let pending = sources.enumerated().filter(\.element.hasMore)
        guard !pending.isEmpty else {
            isLoading = false
            isLoadingMore = false
            hasMore = false
            return
        }
        let status = tab.statusQuery
        let service = cabinService
        let pageSize = pageSize
        Task {
            do {
                var fetched: [(offset: Int, page: PaginatedCabinAppointmentData, pageNum: Int)] = []
                try await withThrowingTaskGroup(
                    of: (offset: Int, page: PaginatedCabinAppointmentData, pageNum: Int).self
                ) { group in
                    for (offset, source) in pending {
                        let pageNum = source.nextPage
                        let businessType = source.businessType
                        group.addTask {
                            let page = try await service.appointments(
                                status: status,
                                businessType: businessType,
                                pageNum: pageNum,
                                pageSize: pageSize
                            )
                            return (offset, page, pageNum)
                        }
                    }
                    for try await item in group {
                        fetched.append(item)
                    }
                }
                apply(fetched, pageSize: pageSize, append: append, token: token)
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "获取预约失败"
                fail(message, token: token, append: append)
            }
        }
    }

    private func apply(
        _ fetched: [(offset: Int, page: PaginatedCabinAppointmentData, pageNum: Int)],
        pageSize: Int,
        append: Bool,
        token: Int
    ) {
        guard token == requestID else { return }
        isLoading = false
        isLoadingMore = false
        var rows: [CabinAppointmentVO] = []
        for item in fetched {
            guard sources.indices.contains(item.offset) else { continue }
            let records = (item.page.records ?? []).map { record -> CabinAppointmentVO in
                var copy = record
                copy.businessType = sources[item.offset].businessType
                return copy
            }
            let total = item.page.totalRecords ?? records.count
            sources[item.offset].nextPage = item.pageNum + 1
            sources[item.offset].hasMore = !records.isEmpty && item.pageNum * pageSize < total
            rows.append(contentsOf: records)
        }
        items = append ? items + rows : rows
        items.sort { lhs, rhs in
            (lhs.reserveDate, lhs.startTime, lhs.id) > (rhs.reserveDate, rhs.startTime, rhs.id)
        }
        hasMore = sources.contains { $0.hasMore }
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

private struct AppointmentPageSource {
    let businessType: Int
    var nextPage = 1
    var hasMore = true
}
