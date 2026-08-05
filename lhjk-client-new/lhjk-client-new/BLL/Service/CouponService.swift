import Foundation

// MARK: - 优惠券服务 (BLL)

/// 确认订单优惠券查询与绑定；卡包「我的优惠券」列表同源
final class CouponService {

    static let shared = CouponService()

    /// 待使用（status=1）缓存总数，供角标
    private(set) var cachedAvailableCouponCount: Int = 0

    private init() {}

    /// 查询优惠券领用列表
    /// `GET /v1/couponTake/getCouponTakeList`
    /// - Parameters:
    ///   - hospitalId: 订单场景可选机构筛选
    ///   - status: 卡包 Tab — 1 待使用 / 2 已领用 / 3 已过期；`nil` 表示全部
    @discardableResult
    func getCouponTakeList(
        hospitalId: String? = nil,
        status: Int? = nil,
        pageNum: Int = 1,
        pageSize: Int = 50
    ) async throws -> CouponTakeListResult {
        var params: [String: Any] = [
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
        ]
        let hospital = hospitalId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !hospital.isEmpty {
            params["hospitalId"] = hospital
        }
        if let status {
            params["status"] = String(status)
        }

        print("[CouponService] getCouponTakeList → hospitalId=\(hospital) status=\(status.map(String.init) ?? "nil") pageNum=\(pageNum) pageSize=\(pageSize)")

        let response: APIResponse<PaginatedCouponTakeData> = try await APIManager.shared.getAsync(
            path: "/v1/couponTake/getCouponTakeList",
            parameters: params,
            responseType: APIResponse<PaginatedCouponTakeData>.self
        )

        guard response.isSuccess else {
            print("[CouponService] getCouponTakeList ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw CouponServiceError.requestFailed(response.msg ?? "查询优惠券失败")
        }

        let items = response.data?.records ?? []
        let total = response.total
            ?? response.data?.totalRecords
            ?? items.count
        print("[CouponService] getCouponTakeList ✓ count=\(items.count) total=\(total)")

        if status == 1 {
            cachedAvailableCouponCount = total
        }

        return CouponTakeListResult(items: items, total: total)
    }

    /// 刷新待使用优惠券总数（角标）
    @discardableResult
    func refreshAvailableCouponCount() async throws -> Int {
        let result = try await getCouponTakeList(status: 1, pageNum: 1, pageSize: 1)
        cachedAvailableCouponCount = result.total
        return cachedAvailableCouponCount
    }

    /// 绑定 / 解绑优惠券与订单
    /// `POST /v1/couponTake/bindCouponTake`
    func bindCouponTake(orderId: Int64, couponTakeId: Int64?) async throws {
        var body: [String: Any] = ["orderId": orderId]
        if let couponTakeId { body["couponTakeId"] = couponTakeId }

        print("[CouponService] bindCouponTake → orderId=\(orderId) couponTakeId=\(couponTakeId?.description ?? "nil")")

        let response: APIResponse<EmptyResponse> = try await APIManager.shared.postAsync(
            path: "/v1/couponTake/bindCouponTake",
            parameters: body,
            responseType: APIResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            print("[CouponService] bindCouponTake ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw CouponServiceError.requestFailed(response.msg ?? "绑定优惠券失败")
        }
        print("[CouponService] bindCouponTake ✓")
    }
}

enum CouponServiceError: Error, LocalizedError {
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let msg): return msg.isEmpty ? "优惠券操作失败" : msg
        }
    }
}
