import Foundation

/// 康养小屋列表。`GET /v1/cabin/list`
///
/// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529266269e0
/// 开启定位时传高德 GCJ-02，服务端按距离排序。未开启定位时只传省市区，不传经纬度。从我的权益进入时另传 `projectId`。
final class CabinService {

    static let shared = CabinService()

    private init() {}

    func listStores(
        keyword: String? = nil,
        province: String? = nil,
        city: String? = nil,
        area: String? = nil,
        longitude: String? = nil,
        latitude: String? = nil,
        projectId: String? = nil,
        pageNum: Int = 1,
        pageSize: Int = 20
    ) async throws -> PaginatedCabinListData {
        var params: [String: Any] = [
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
        ]
        if let keyword = keyword?.trimmingCharacters(in: .whitespacesAndNewlines), !keyword.isEmpty {
            params["keyword"] = keyword
        }
        Self.put(province, for: "province", into: &params)
        Self.put(city, for: "city", into: &params)
        Self.put(area, for: "area", into: &params)
        if let longitude, !longitude.isEmpty, let latitude, !latitude.isEmpty {
            params["longitude"] = longitude
            params["latitude"] = latitude
        }
        Self.put(projectId, for: "projectId", into: &params)

        let response: APIResponse<PaginatedCabinListData> = try await APIManager.shared.getAsync(
            path: "/v1/cabin/list",
            parameters: params,
            responseType: APIResponse<PaginatedCabinListData>.self
        )
        guard response.isSuccess else {
            throw CabinServiceError.requestFailed(response.msg ?? "获取康养小屋失败")
        }
        return response.data ?? PaginatedCabinListData.empty(pageNum: pageNum, pageSize: pageSize)
    }

    private static func put(_ value: String?, for key: String, into params: inout [String: Any]) {
        guard let text = value?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        params[key] = text
    }

    /// 门店详情。`GET /v1/cabin/detail`
    ///
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529266267e0
    func storeDetail(hospitalId: String) async throws -> CabinStoreVO {
        let response: APIResponse<CabinStoreVO> = try await APIManager.shared.getAsync(
            path: "/v1/cabin/detail",
            parameters: ["hospitalId": hospitalId],
            responseType: APIResponse<CabinStoreVO>.self
        )
        guard response.isSuccess, let store = response.data, !store.id.isEmpty else {
            throw CabinServiceError.requestFailed(response.msg ?? "未找到该驿站")
        }
        return store
    }

    /// 服务分类。`GET /v1/cabin/categoryList`
    ///
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529785605e0
    func categories(hospitalId: String) async throws -> [CabinCategoryVO] {
        let response: APIResponse<[CabinCategoryVO]> = try await APIManager.shared.getAsync(
            path: "/v1/cabin/categoryList",
            parameters: ["hospitalId": hospitalId],
            responseType: APIResponse<[CabinCategoryVO]>.self
        )
        guard response.isSuccess else {
            throw CabinServiceError.requestFailed(response.msg ?? "获取服务分类失败")
        }
        return (response.data ?? []).sorted { lhs, rhs in
            if lhs.sortId != rhs.sortId { return lhs.sortId < rhs.sortId }
            return lhs.id < rhs.id
        }
    }

    /// 分类下的服务项目。`GET /v1/cabin/configList`
    ///
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529266270e0
    func serviceItems(hospitalId: String, parentId: String) async throws -> [CabinConfigItemVO] {
        let response: APIResponse<[CabinConfigItemVO]> = try await APIManager.shared.getAsync(
            path: "/v1/cabin/configList",
            parameters: ["hospitalId": hospitalId, "parentId": parentId],
            responseType: APIResponse<[CabinConfigItemVO]>.self
        )
        guard response.isSuccess else {
            throw CabinServiceError.requestFailed(response.msg ?? "获取服务项目失败")
        }
        return response.data ?? []
    }

    /// 预约页详情。`GET /v1/cabin/bookDetail`
    ///
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529785607e0
    /// `date` 不传时服务端按当天返回。换日期时传 `yyyy-MM-dd`。
    func bookDetail(configId: String, date: String? = nil) async throws -> CabinBookDetailVO {
        var params: [String: Any] = ["configId": configId]
        if let date, !date.isEmpty {
            params["date"] = date
        }
        let response: APIResponse<CabinBookDetailVO> = try await APIManager.shared.getAsync(
            path: "/v1/cabin/bookDetail",
            parameters: params,
            responseType: APIResponse<CabinBookDetailVO>.self
        )
        guard response.isSuccess, let detail = response.data, detail.hasContent else {
            throw CabinServiceError.requestFailed(response.msg ?? "未找到该项目")
        }
        return detail
    }

    /// 提交预约前的限流校验。`GET /v1/cabin/bookLimitCheck`
    ///
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/534863042e0
    /// `limitType`：0 可预约，1 当日名额已满，2 超每人每日，3 超每人每月。
    func bookLimitCheck(configId: String, reserveDate: String) async throws -> CabinBookLimitCheckVO {
        let response: APIResponse<CabinBookLimitCheckVO> = try await APIManager.shared.getAsync(
            path: "/v1/cabin/bookLimitCheck",
            parameters: ["configId": configId, "reserveDate": reserveDate],
            responseType: APIResponse<CabinBookLimitCheckVO>.self
        )
        guard response.isSuccess, let result = response.data else {
            throw CabinServiceError.requestFailed(response.msg ?? "预约校验失败，请重试")
        }
        return result
    }

    /// 创建预约订单。`POST /v1/cabin/createReservationOrder`
    ///
    /// 只传 `configId`。`data` 为订单 id，日期和时段留到支付成功后再提交预约。
    func createReservationOrder(configId: String) async throws -> Int64 {
        guard let config = Int64(configId) else {
            throw CabinServiceError.requestFailed("未找到该项目")
        }
        let response: APIResponse<CabinBookID> = try await APIManager.shared.postAsync(
            path: "/v1/cabin/createReservationOrder",
            parameters: ["configId": NSNumber(value: config)],
            responseType: APIResponse<CabinBookID>.self
        )
        guard response.isSuccess, let orderId = response.data?.value, orderId > 0 else {
            throw CabinServiceError.requestFailed(response.msg ?? "创建订单失败，请重试")
        }
        return orderId
    }

    /// 提交预约。`POST /v1/cabin/book`
    ///
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/530062590e0
    /// `sourceType = 3` 时必须带支付成功后的 `orderId`。
    @discardableResult
    func book(
        configId: String,
        reserveDate: String,
        sourceType: Int,
        startTime: String,
        endTime: String,
        quantity: Int = 1,
        orderId: Int64? = nil
    ) async throws -> Int64? {
        guard let config = Int64(configId) else {
            throw CabinServiceError.requestFailed("未找到该项目")
        }
        var body: [String: Any] = [
            "configId": NSNumber(value: config),
            "reserveDate": reserveDate,
            "sourceType": sourceType,
            "startTime": startTime,
            "endTime": endTime,
            "quantity": quantity,
        ]
        if let orderId, orderId > 0 {
            body["orderId"] = NSNumber(value: orderId)
        }
        let response: APIResponse<CabinBookID> = try await APIManager.shared.postAsync(
            path: "/v1/cabin/book",
            parameters: body,
            responseType: APIResponse<CabinBookID>.self
        )
        guard response.isSuccess else {
            throw CabinServiceError.requestFailed(response.msg ?? "提交失败，请重试")
        }
        return response.data?.value
    }

    /// 体检、就医协助确认消耗。`POST /v1/cabin/book`
    ///
    /// 只传 `configId`、`sourceType = 2`、`quantity = 1`。不传日期和时段。
    /// 弹窗里的姓名、电话和二维码用本次返回。
    func consumeBenefit(configId: String) async throws -> CabinConsumeContact {
        guard let config = Int64(configId) else {
            throw CabinServiceError.requestFailed("未找到该项目")
        }
        let body: [String: Any] = [
            "configId": NSNumber(value: config),
            "sourceType": 2,
            "quantity": 1,
        ]
        let response: APIResponse<CabinConsumeContact> = try await APIManager.shared.postAsync(
            path: "/v1/cabin/book",
            parameters: body,
            responseType: APIResponse<CabinConsumeContact>.self
        )
        guard response.isSuccess else {
            throw CabinServiceError.requestFailed(response.msg ?? "预约失败，请重试")
        }
        return response.data ?? .empty
    }
}

extension Notification.Name {
    static let cabinBenefitConsumed = Notification.Name("lhjk.cabinBenefitConsumed")
}

extension CabinService {
    /// 我的权益列表。`GET /v1/cabin/entitlementList`
    ///
    /// Apifox：`entitlementList`。无 Query。`data` 为权益数组。
    func entitlements() async throws -> [CabinEntitlementVO] {
        let response: APIResponse<[CabinEntitlementVO]> = try await APIManager.shared.getAsync(
            path: "/v1/cabin/entitlementList",
            responseType: APIResponse<[CabinEntitlementVO]>.self
        )
        guard response.isSuccess else {
            throw CabinServiceError.requestFailed(response.msg ?? "获取权益失败")
        }
        return response.data ?? []
    }

    /// 小屋预约。体检和就医协助的使用记录不是这一类。
    static let cabinBusinessType = 1

    /// 当前登录人的预约记录。`GET /v1/cabin/appointments`
    ///
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/529785606e0
    /// `businessType`：1 小屋，2 体检，3 就医协助。预约记录页不传。小屋列表和首页待服务传 1。
    /// `status` 空为全部：1 待安排，2 待确认，3 待服务，4 服务中，5 已完成，6 已取消，7 已过期。
    func appointments(
        status: String? = nil,
        businessType: Int? = nil,
        pageNum: Int = 1,
        pageSize: Int = 20
    ) async throws -> PaginatedCabinAppointmentData {
        var params: [String: Any] = [
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
        ]
        if let status, !status.isEmpty {
            params["status"] = status
        }
        if let businessType {
            params["businessType"] = String(businessType)
        }
        let response: APIResponse<PaginatedCabinAppointmentData> = try await APIManager.shared.getAsync(
            path: "/v1/cabin/appointments",
            parameters: params,
            responseType: APIResponse<PaginatedCabinAppointmentData>.self
        )
        guard response.isSuccess else {
            throw CabinServiceError.requestFailed(response.msg ?? "获取预约记录失败")
        }
        return response.data ?? PaginatedCabinAppointmentData(
            totalRecords: 0,
            pageSize: pageSize,
            totalPages: 0,
            currentPage: pageNum,
            records: []
        )
    }

    /// 当前登录人的预约详情。`GET /v1/cabin/reservationDetail`
    ///
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/531651137e0
    func reservationDetail(id: String) async throws -> CabinReservationDetailVO {
        guard let reservationId = Int64(id) else {
            throw CabinServiceError.requestFailed("未找到该预约")
        }
        let response: APIResponse<CabinReservationDetailVO> = try await APIManager.shared.getAsync(
            path: "/v1/cabin/reservationDetail",
            parameters: ["id": String(reservationId)],
            responseType: APIResponse<CabinReservationDetailVO>.self
        )
        guard response.isSuccess, let detail = response.data, !detail.id.isEmpty else {
            throw CabinServiceError.requestFailed(response.msg ?? "未找到该预约")
        }
        return detail
    }

    /// 用户确认预约。`POST /v1/cabin/confirm`
    ///
    /// 待确认详情点「确认安排」。只传预约 id。
    func confirmReservation(id: String) async throws {
        guard let reservationId = Int64(id) else {
            throw CabinServiceError.requestFailed("未找到该预约")
        }
        let response: APIResponse<CabinIgnoredPayload> = try await APIManager.shared.postAsync(
            path: "/v1/cabin/confirm",
            parameters: ["id": NSNumber(value: reservationId)],
            responseType: APIResponse<CabinIgnoredPayload>.self
        )
        guard response.isSuccess else {
            throw CabinServiceError.requestFailed(response.msg ?? "确认失败，请重试")
        }
    }

    /// 用户取消预约。`POST /v1/cabin/cancel`
    ///
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/531651134e0
    func cancelReservation(id: String, reason: String? = nil) async throws {
        guard let reservationId = Int64(id) else {
            throw CabinServiceError.requestFailed("未找到该预约")
        }
        var body: [String: Any] = ["id": NSNumber(value: reservationId)]
        let note = reason?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !note.isEmpty {
            body["reason"] = note
        }
        let response: APIResponse<EmptyResponse> = try await APIManager.shared.postAsync(
            path: "/v1/cabin/cancel",
            parameters: body,
            responseType: APIResponse<EmptyResponse>.self
        )
        guard response.isSuccess else {
            throw CabinServiceError.requestFailed(response.msg ?? "取消失败，请重试")
        }
    }
}

/// 消耗权益后 `data` 里的工作人员信息。文档里的 `data` 也可能只是预约单 id。
struct CabinConsumeContact: Decodable, Equatable {
    let name: String?
    let phone: String?
    let qrCode: String?

    static let empty = CabinConsumeContact(name: nil, phone: nil, qrCode: nil)

    var qrURL: URL? {
        guard let qrCode else { return nil }
        return CabinMedia.urls(from: qrCode).first
    }

    private enum CodingKeys: String, CodingKey {
        case chineseName, contactName, staffName, name
        case mobile, contactPhone, phone
        case qrCode, qrUrl, manualAccess
    }

    init(name: String?, phone: String?, qrCode: String?) {
        self.name = name
        self.phone = phone
        self.qrCode = qrCode
    }

    init(from decoder: Decoder) throws {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            self = .empty
            return
        }
        var manual: CabinManualAccessVO?
        if let decoded = try? container.decodeIfPresent(CabinManualAccessVO.self, forKey: .manualAccess) {
            manual = decoded
        }
        name = Self.first(
            CabinJSON.string(container, .chineseName),
            CabinJSON.string(container, .contactName),
            CabinJSON.string(container, .staffName),
            manual?.chineseName,
            CabinJSON.string(container, .name)
        )
        phone = Self.first(
            CabinJSON.string(container, .mobile),
            CabinJSON.string(container, .contactPhone),
            CabinJSON.string(container, .phone),
            manual?.mobile
        )
        qrCode = Self.first(
            CabinJSON.string(container, .qrCode),
            CabinJSON.string(container, .qrUrl),
            manual?.qrCode
        )
    }

    private static func first(_ values: String?...) -> String? {
        for value in values {
            guard let value else { continue }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }
}

/// 确认预约的 `data` 不使用。数字、对象或空都能解码。
private struct CabinIgnoredPayload: Decodable {
    init(from decoder: Decoder) throws {}
}

/// 预约接口 `data` 可能是预约单 id，也可能是 `{ id, manualAccess }`。
private struct CabinBookID: Decodable {
    let value: Int64

    private enum CodingKeys: String, CodingKey {
        case id
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           let text = CabinJSON.string(container, .id),
           let number = Int64(text) {
            value = number
            return
        }
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Int64.self) {
            value = number
            return
        }
        if let number = try? container.decode(Int.self) {
            value = Int64(number)
            return
        }
        if let text = try? container.decode(String.self), let number = Int64(text) {
            value = number
            return
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "预约单 id 无效")
    }
}

extension PaginatedCabinListData {
    static func empty(pageNum: Int, pageSize: Int) -> PaginatedCabinListData {
        PaginatedCabinListData(
            totalRecords: 0,
            pageSize: pageSize,
            totalPages: 0,
            currentPage: pageNum,
            records: []
        )
    }

    fileprivate init(
        totalRecords: Int?,
        pageSize: Int?,
        totalPages: Int?,
        currentPage: Int?,
        records: [CabinStoreVO]?
    ) {
        self.totalRecords = totalRecords
        self.pageSize = pageSize
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.records = records
    }
}

enum CabinServiceError: Error, LocalizedError {
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let message): return message
        }
    }
}
