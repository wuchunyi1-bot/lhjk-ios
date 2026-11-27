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
    private var currentPage = 1
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
        isLoadingMore = false
        fetch(pageNum: 1, append: false, token: token)
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
        fetch(pageNum: currentPage + 1, append: true, token: requestID)
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

    /// 预约记录只请求一次，不传 `businessType`。
    private func fetch(pageNum: Int, append: Bool, token: Int) {
        let status = tab.statusQuery
        let service = cabinService
        let pageSize = pageSize
        Task {
            do {
                let page = try await service.appointments(
                    status: status,
                    pageNum: pageNum,
                    pageSize: pageSize
                )
                apply(page, pageNum: pageNum, pageSize: pageSize, append: append, token: token)
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "获取预约失败"
                fail(message, token: token, append: append)
            }
        }
    }

    private func apply(
        _ page: PaginatedCabinAppointmentData,
        pageNum: Int,
        pageSize: Int,
        append: Bool,
        token: Int
    ) {
        guard token == requestID else { return }
        isLoading = false
        isLoadingMore = false
        let records = page.records ?? []
        let total = page.totalRecords ?? records.count
        currentPage = pageNum
        hasMore = !records.isEmpty && pageNum * pageSize < total
        items = append ? items + records : records
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


