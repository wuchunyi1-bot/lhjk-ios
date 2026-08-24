import Foundation

/// 我的卡券 — 权益卡走 `/v1/benefitsTake/*`；优惠券走 `CouponService`
final class VoucherService {

    static let shared = VoucherService()

    /// 待使用权益卡数量（status=3）缓存，供角标
    private(set) var cachedAvailableBenefitCount: Int = 0

    private init() {}

    // MARK: - Badge

    var availableBenefitCount: Int { cachedAvailableBenefitCount }

    var availableCouponCount: Int {
        CouponService.shared.cachedAvailableCouponCount
    }

    var meBadgeCount: Int {
        availableBenefitCount + availableCouponCount
    }

    var meBadgeText: String? {
        let n = meBadgeCount
        if n <= 0 { return nil }
        if n > 99 { return "99+" }
        return "\(n)"
    }

    func refreshAvailableCouponCount() async {
        _ = try? await CouponService.shared.refreshAvailableCouponCount()
    }

    @discardableResult
    func refreshAvailableBenefitCount() async -> Int {
        do {
            let overview = try await getActivationOverview()
            cachedAvailableBenefitCount = overview.count
            return cachedAvailableBenefitCount
        } catch {
            print("[VoucherService] getActivationOverview ✗ \(error.localizedDescription)，回退状态计数")
        }
        do {
            let counts = try await getCustomerStatusCount()
            let available = counts.first {
                $0.value == String(BenefitAPIStatus.available.rawValue)
                    || ($0.name?.contains("待使用") ?? false)
            }?.count ?? 0
            cachedAvailableBenefitCount = max(0, available)
        } catch {
            print("[VoucherService] refreshAvailableBenefitCount ✗ \(error.localizedDescription)")
        }
        return cachedAvailableBenefitCount
    }

    func refreshVoucherBadges() async {
        _ = await refreshAvailableBenefitCount()
        await refreshAvailableCouponCount()
    }

    // MARK: - List

    /// `GET /v1/benefitsTake/getCustomerPage`
    func getCustomerPage(
        status: Int? = nil,
        pageNum: Int = 1,
        pageSize: Int = 50
    ) async throws -> (cards: [BenefitCard], pendingTransfers: [BenefitTransferRecord], total: Int) {
        var params: [String: Any] = [
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
        ]
        if let status {
            params["status"] = String(status)
        }

        print("[VoucherService] getCustomerPage → status=\(status.map(String.init) ?? "nil") page=\(pageNum)")

        let response: APIResponse<PaginatedBenefitsTakeData> = try await APIManager.shared.getAsync(
            path: "/v1/benefitsTake/getCustomerPage",
            parameters: params,
            responseType: APIResponse<PaginatedBenefitsTakeData>.self
        )
        guard response.isSuccess else {
            throw VoucherServiceError.requestFailed(response.msg ?? "查询权益卡失败")
        }

        let records = response.data?.records ?? []
        let total = response.total ?? response.data?.totalRecords ?? records.count
        var cards: [BenefitCard] = []
        var pending: [BenefitTransferRecord] = []
        for item in records {
            if let t = BenefitMapper.pendingTransfer(from: item) {
                pending.append(t)
            } else if let c = BenefitMapper.card(from: item) {
                cards.append(c)
            }
        }
        print("[VoucherService] getCustomerPage ✓ cards=\(cards.count) pending=\(pending.count) total=\(total)")
        return (cards, pending, total)
    }

    /// `GET /v1/benefitsTake/getGiftRecordPage`
    func getGiftRecordPage(
        pageNum: Int = 1,
        pageSize: Int = 50
    ) async throws -> [BenefitTransferRecord] {
        let params: [String: Any] = [
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
        ]
        print("[VoucherService] getGiftRecordPage → page=\(pageNum)")

        let response: APIResponse<PaginatedBenefitsGiftData> = try await APIManager.shared.getAsync(
            path: "/v1/benefitsTake/getGiftRecordPage",
            parameters: params,
            responseType: APIResponse<PaginatedBenefitsGiftData>.self
        )
        guard response.isSuccess else {
            throw VoucherServiceError.requestFailed(response.msg ?? "查询转赠记录失败")
        }
        let items = (response.data?.records ?? []).map(BenefitMapper.transfer(from:))
        print("[VoucherService] getGiftRecordPage ✓ count=\(items.count)")
        return items
    }

    /// `GET /v1/benefitsTake/getCustomerStatusCount`
    func getCustomerStatusCount() async throws -> [BenefitsTakeStatusCountItem] {
        let response: APIResponse<[BenefitsTakeStatusCountItem]> = try await APIManager.shared.getAsync(
            path: "/v1/benefitsTake/getCustomerStatusCount",
            parameters: nil,
            responseType: APIResponse<[BenefitsTakeStatusCountItem]>.self
        )
        guard response.isSuccess else {
            throw VoucherServiceError.requestFailed(response.msg ?? "查询状态数量失败")
        }
        return response.data ?? []
    }

    /// 按 Tab 拉取列表条目
    func loadBenefitEntries(filter: BenefitStatusFilter) async throws -> [BenefitListEntry] {
        switch filter {
        case .transferRecords:
            let records = try await getGiftRecordPage()
            return VoucherListQuery.benefitEntries(cards: [], transfers: records, filter: filter)
        case .all:
            let page = try await getCustomerPage(status: nil)
            // 全部 Tab 还需已转赠？原型：已转赠仅在转赠记录。全部只含等待领取 + 卡
            return VoucherListQuery.benefitEntries(
                cards: page.cards,
                transfers: page.pendingTransfers,
                filter: .all
            )
        case .pendingBind, .pendingReceive, .available, .redeemed, .expired:
            let page = try await getCustomerPage(status: filter.apiStatus)
            if filter == .available {
                cachedAvailableBenefitCount = page.total
            }
            return VoucherListQuery.benefitEntries(
                cards: page.cards,
                transfers: filter == .pendingReceive ? page.pendingTransfers : [],
                filter: filter
            )
        }
    }

    // MARK: - Bind

    /// `POST /v1/benefitsTake/preCheckByKey`
    func preCheckByKey(_ benefitsKey: String) async throws -> BenefitsBindPreCheckVO {
        guard !benefitsKey.isEmpty else { throw VoucherServiceError.requestFailed("请输入卡密") }

        let response: APIResponse<BenefitsBindPreCheckVO> = try await APIManager.shared.postAsync(
            path: "/v1/benefitsTake/preCheckByKey",
            parameters: ["benefitsKey": benefitsKey],
            responseType: APIResponse<BenefitsBindPreCheckVO>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw VoucherServiceError.requestFailed(response.msg ?? "卡密校验失败")
        }
        return data
    }

    /// `POST /v1/benefitsTake/bindByKey`
    func bindByKey(_ benefitsKey: String) async throws {
        guard !benefitsKey.isEmpty else { throw VoucherServiceError.requestFailed("请输入卡密") }

        let response: APIResponse<EmptyResponse> = try await APIManager.shared.postAsync(
            path: "/v1/benefitsTake/bindByKey",
            parameters: ["benefitsKey": benefitsKey],
            responseType: APIResponse<EmptyResponse>.self
        )
        guard response.isSuccess else {
            throw VoucherServiceError.requestFailed(response.msg ?? "绑定失败")
        }
        _ = await refreshAvailableBenefitCount()
    }

    // MARK: - Gift

    /// `POST /v1/benefitsTake/giftBenefit`
    @discardableResult
    func giftBenefit(benefitsTakeId: Int64, message: String?) async throws -> BenefitsIssueVO {
        let operationNo = Self.newOperationNo()
        var body: [String: Any] = [
            "benefitsTakeId": benefitsTakeId,
            "operationNo": operationNo,
        ]
        let msg = message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !msg.isEmpty {
            body["message"] = String(msg.prefix(50))
        }

        print("[VoucherService] giftBenefit → id=\(benefitsTakeId) operationNo=\(operationNo)")

        let response: APIResponse<BenefitsIssueVO> = try await APIManager.shared.postAsync(
            path: "/v1/benefitsTake/giftBenefit",
            parameters: body,
            responseType: APIResponse<BenefitsIssueVO>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw VoucherServiceError.requestFailed(response.msg ?? "转赠失败")
        }
        _ = await refreshAvailableBenefitCount()

        let serverNo = data.operationNo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !serverNo.isEmpty {
            return data
        }
        // 服务端未回显时，用请求幂等号组装分享凭证
        return BenefitsIssueVO(
            operationNo: operationNo,
            pageStatus: data.pageStatus,
            expireTime: data.expireTime,
            giftMessage: data.giftMessage ?? (msg.isEmpty ? nil : msg),
            giverName: data.giverName,
            appId: data.appId,
            path: data.path,
            cards: data.cards
        )
    }

    static func newOperationNo() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    // MARK: - 激活兑换 / 兑换套餐 / 订单绑卡

    /// `GET /v1/benefitsTake/getActivationOverview`
    func getActivationOverview() async throws -> BenefitsActivationOverviewVO {
        let response: APIResponse<BenefitsActivationOverviewVO> = try await APIManager.shared.getAsync(
            path: "/v1/benefitsTake/getActivationOverview",
            parameters: nil,
            responseType: APIResponse<BenefitsActivationOverviewVO>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw VoucherServiceError.requestFailed(response.msg ?? "查询激活兑换数据失败")
        }
        cachedAvailableBenefitCount = data.count
        return data
    }

    /// `GET /v1/benefitsTake/getRedeemPageInfo`
    func getRedeemPageInfo() async throws -> BenefitsRedeemPageInfoVO {
        let response: APIResponse<BenefitsRedeemPageInfoVO> = try await APIManager.shared.getAsync(
            path: "/v1/benefitsTake/getRedeemPageInfo",
            parameters: nil,
            responseType: APIResponse<BenefitsRedeemPageInfoVO>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw VoucherServiceError.requestFailed(response.msg ?? "查询兑换页数据失败")
        }
        if data.availableCount > 0 {
            cachedAvailableBenefitCount = data.availableCount
        }
        return data
    }

    /// `GET /v1/benefitsTake/getRedeemPackagePage`
    func getRedeemPackagePage(
        categoryServiceId: String? = nil,
        pageNum: Int = 1,
        pageSize: Int = 10
    ) async throws -> (items: [BenefitsRedeemPackageItem], total: Int, hasMore: Bool) {
        var params: [String: Any] = [
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
        ]
        let category = categoryServiceId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !category.isEmpty {
            params["categoryServiceId"] = category
        }

        print("[VoucherService] getRedeemPackagePage → category=\(category.isEmpty ? "全部" : category) page=\(pageNum)")

        let response: APIResponse<PaginatedBenefitsRedeemPackageData> = try await APIManager.shared.getAsync(
            path: "/v1/benefitsTake/getRedeemPackagePage",
            parameters: params,
            responseType: APIResponse<PaginatedBenefitsRedeemPackageData>.self
        )
        guard response.isSuccess else {
            throw VoucherServiceError.requestFailed(response.msg ?? "查询可兑换套餐失败")
        }
        let records = (response.data?.records ?? []).filter { !$0.packageId.isEmpty }
        let total = response.total
            ?? response.data?.totalRecords
            ?? records.count
        let current = response.data?.currentPage ?? pageNum
        let pages = response.data?.totalPages
        let hasMore: Bool
        if let pages {
            hasMore = current < pages
        } else {
            hasMore = records.count >= pageSize && (pageNum * pageSize) < total
        }
        print("[VoucherService] getRedeemPackagePage ✓ count=\(records.count) total=\(total)")
        return (records, total, hasMore)
    }

    /// `GET /v1/benefitsTake/getOrderBenefitsList`
    func getOrderBenefitsList(orderId: Int64) async throws -> [BenefitsRedeemCardVO] {
        let response: APIResponse<[BenefitsRedeemCardVO]> = try await APIManager.shared.getAsync(
            path: "/v1/benefitsTake/getOrderBenefitsList",
            parameters: ["orderId": orderId],
            responseType: APIResponse<[BenefitsRedeemCardVO]>.self
        )
        guard response.isSuccess else {
            throw VoucherServiceError.requestFailed(response.msg ?? "查询订单权益卡失败")
        }
        return response.data ?? []
    }

    /// `POST /v1/benefitsTake/updateOrderBenefits`（query：orderId、benefitsTakeIds）
    func updateOrderBenefits(orderId: Int64, benefitsTakeIds: [Int64]) async throws {
        var params: [String: Any] = ["orderId": orderId]
        params["benefitsTakeIds"] = benefitsTakeIds

        print("[VoucherService] updateOrderBenefits → orderId=\(orderId) ids=\(benefitsTakeIds)")

        let response: APIResponse<EmptyResponse> = try await APIManager.shared.postQueryAsync(
            path: "/v1/benefitsTake/updateOrderBenefits",
            parameters: params,
            responseType: APIResponse<EmptyResponse>.self
        )
        guard response.isSuccess else {
            throw VoucherServiceError.requestFailed(response.msg ?? "保存权益卡失败")
        }
    }
}

enum VoucherServiceError: Error, LocalizedError {
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let msg):
            return msg.isEmpty ? "权益卡操作失败" : msg
        }
    }
}
