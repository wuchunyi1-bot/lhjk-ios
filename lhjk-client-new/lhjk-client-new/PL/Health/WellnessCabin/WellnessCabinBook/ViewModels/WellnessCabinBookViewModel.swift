import Combine
import Foundation

enum CabinBookProceed {
    case ignored
    case booked
    case confirmOrder(orderId: Int64, context: CabinPaidBookContext)
}

@MainActor
final class WellnessCabinBookViewModel: ObservableObject {

    let hospitalId: String
    let configId: String
    /// 项目列表带入的金额。预约详情没返回价格时兜底。
    let priceText: String?
    let unitName: String?
    /// 活动页不展示金额、单位和次卡说明。
    let presentsCommerce: Bool

    @Published private(set) var detail: CabinBookDetailVO?
    @Published private(set) var days: [CabinBookDay] = []
    @Published private(set) var selectedDateId: String?
    @Published private(set) var slots: [CabinSlotVO] = []
    @Published private(set) var selectedSlotKey: String?
    @Published private(set) var isInternalStation = false
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingSlots = false
    @Published private(set) var isSubmitting = false
    @Published private(set) var isMissing = false
    @Published private(set) var errorMessage: String?

    private let cabinService: CabinService
    private let knownInternalOnly: Bool?
    private var didStart = false
    private var slotRequest = 0

    init(
        hospitalId: String,
        configId: String,
        priceText: String? = nil,
        unitName: String? = nil,
        internalOnly: Bool? = nil,
        presentsCommerce: Bool = true,
        cabinService: CabinService = AppContainer.shared.cabinService
    ) {
        self.hospitalId = hospitalId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.configId = configId.trimmingCharacters(in: .whitespacesAndNewlines)
        let price = priceText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.priceText = price.isEmpty ? nil : price
        let unit = unitName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.unitName = unit.isEmpty ? nil : unit
        self.presentsCommerce = presentsCommerce
        self.knownInternalOnly = internalOnly
        self.isInternalStation = internalOnly == true
        self.cabinService = cabinService
        load()
    }

    var selectedSlot: CabinSlotVO? {
        guard let selectedSlotKey else { return nil }
        return slots.first { $0.key == selectedSlotKey && $0.isBookable }
    }

    /// 1 免费。2 次卡。3 付费。免费和付费都走底栏。
    var billingSource: Int { detail?.billingSource ?? 1 }

    var showsBottomBar: Bool { presentsCommerce }

    var feeAmountText: String? {
        guard presentsCommerce, billingSource == 3 else { return nil }
        if let plain = detail?.plainPrice { return "¥\(plain)" }
        if let priceText { return "¥\(priceText)" }
        return nil
    }

    var feeUnitText: String {
        unitName ?? "次"
    }

    var timesCardText: String? {
        guard presentsCommerce, billingSource == 2 else { return nil }
        if let count = detail?.availableQuantity {
            return "可用次卡：\(count) 次"
        }
        return "可用次卡"
    }

    /// 原型固定文案，不是接口字段。有可用次数时展示。
    var timesCardHint: String? {
        guard presentsCommerce, billingSource == 2 else { return nil }
        if let count = detail?.availableQuantity, count <= 0 { return nil }
        return "优先使用次卡，本次预约将扣减 1 次"
    }

    var barText: String? {
        if let timesCardText { return timesCardText }
        if let feeAmountText { return "\(feeAmountText)/\(feeUnitText)" }
        if presentsCommerce, billingSource == 1 { return "免费" }
        return nil
    }

    func load() {
        guard !didStart else { return }
        didStart = true
        let id = configId
        guard !id.isEmpty else {
            isMissing = true
            return
        }
        isLoading = true
        isMissing = false
        let service = cabinService
        let storeId = hospitalId
        let shouldFetchStore = knownInternalOnly == nil && !storeId.isEmpty
        Task.detached {
            async let detailCall = service.bookDetail(configId: id, date: nil)
            let store: CabinStoreVO?
            if shouldFetchStore {
                store = try? await service.storeDetail(hospitalId: storeId)
            } else {
                store = nil
            }
            let loaded = try? await detailCall
            await self.finishLoad(detail: loaded, failed: loaded == nil, store: store)
        }
    }

    func select(date id: String) {
        guard id != selectedDateId, !configId.isEmpty, !isLoadingSlots else { return }
        slotRequest += 1
        let token = slotRequest
        let previousDateId = selectedDateId
        selectedDateId = id
        isLoadingSlots = true
        let service = cabinService
        let configId = configId
        Task.detached {
            do {
                let detail = try await service.bookDetail(configId: configId, date: id)
                await self.applySlots(detail.slots, date: id, token: token)
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "获取可预约时段失败"
                await self.failSlots(previousDateId: previousDateId, message: message, token: token)
            }
        }
    }

    func select(slot: CabinSlotVO) {
        guard slot.isBookable else { return }
        selectedSlotKey = slot.key
    }

    /// 免费、次卡直接预约。付费或没有可用次数时创建预约订单，确认页支付成功后再预约。
    func proceed() async throws -> CabinBookProceed {
        guard !isSubmitting else { return .ignored }
        guard let slot = selectedSlot, let date = selectedDateId else {
            throw CabinServiceError.requestFailed("请选择可预约时段")
        }
        if needsPurchase {
            isSubmitting = true
            defer { isSubmitting = false }
            let orderId = try await cabinService.createReservationOrder(configId: configId)
            let context = CabinPaidBookContext(
                configId: configId,
                reserveDate: date,
                startTime: slot.startTime,
                endTime: slot.endTime
            )
            return .confirmOrder(orderId: orderId, context: context)
        }
        isSubmitting = true
        defer { isSubmitting = false }
        try await cabinService.book(
            configId: configId,
            reserveDate: date,
            sourceType: billingSource,
            startTime: slot.startTime,
            endTime: slot.endTime,
            quantity: 1
        )
        return .booked
    }

    private var needsPurchase: Bool {
        if billingSource == 3 { return true }
        if billingSource == 2, let count = detail?.availableQuantity, count <= 0 { return true }
        return false
    }

    func clearError() {
        errorMessage = nil
    }

    private func finishLoad(detail: CabinBookDetailVO?, failed: Bool, store: CabinStoreVO?) {
        isLoading = false
        if let store {
            isInternalStation = store.internalOnly == 1
        }
        guard let detail, !failed else {
            isMissing = true
            self.detail = nil
            return
        }
        isMissing = false
        self.detail = detail
        days = Self.makeDays(ahead: Self.span(bookDaysAhead: detail.bookDaysAhead, returnedDate: detail.date))
        let returned = detail.date
        let selected = days.first { $0.id == returned }?.id ?? days.first?.id
        selectedDateId = selected
        slots = detail.slots
        selectedSlotKey = detail.slots.first { $0.isBookable }?.key
    }

    private func applySlots(_ slots: [CabinSlotVO], date: String, token: Int) {
        guard token == slotRequest else { return }
        isLoadingSlots = false
        selectedDateId = date
        self.slots = slots
        selectedSlotKey = slots.first { $0.isBookable }?.key
    }

    private func failSlots(previousDateId: String?, message: String, token: Int) {
        guard token == slotRequest else { return }
        isLoadingSlots = false
        selectedDateId = previousDateId
        errorMessage = message
    }

    private static func span(bookDaysAhead: Int?, returnedDate: String?, today: Date = Date()) -> Int {
        let ahead = max(bookDaysAhead ?? 0, 0)
        guard let returnedDate, let offset = dayOffset(from: today, to: returnedDate) else { return ahead }
        return max(ahead, offset)
    }

    private static func dayOffset(from today: Date, to id: String) -> Int? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: id) else { return nil }
        let startToday = calendar.startOfDay(for: today)
        let startDate = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: startToday, to: startDate).day
    }

    private static func makeDays(ahead: Int, today: Date = Date()) -> [CabinBookDay] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        let start = calendar.startOfDay(for: today)
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let idFormatter = DateFormatter()
        idFormatter.calendar = calendar
        idFormatter.locale = Locale(identifier: "zh_CN")
        idFormatter.timeZone = calendar.timeZone
        idFormatter.dateFormat = "yyyy-MM-dd"
        let subtitleFormatter = DateFormatter()
        subtitleFormatter.calendar = calendar
        subtitleFormatter.locale = Locale(identifier: "zh_CN")
        subtitleFormatter.timeZone = calendar.timeZone
        subtitleFormatter.dateFormat = "M/d"

        return (0...ahead).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let title: String
            if offset == 0 {
                title = "今天"
            } else if offset == 1 {
                title = "明天"
            } else {
                let weekday = calendar.component(.weekday, from: date)
                title = weekdays[max(0, min(weekdays.count - 1, weekday - 1))]
            }
            return CabinBookDay(
                id: idFormatter.string(from: date),
                title: title,
                subtitle: subtitleFormatter.string(from: date)
            )
        }
    }
}
