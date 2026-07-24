import Foundation

// MARK: - 优惠券服务 (BLL)

/// 确认订单优惠券查询与绑定
final class CouponService {

    static let shared = CouponService()

    private init() {}

    /// 查询当前用户可用优惠券领用列表
    /// `GET /v1/couponTake/getCouponTakeList`
    func getCouponTakeList(
        hospitalId: String?,
        pageNum: Int = 1,
        pageSize: Int = 50
    ) async throws -> [CouponTakeItem] {
        var params: [String: Any] = [
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
        ]
        let hospital = hospitalId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !hospital.isEmpty {
            params["hospitalId"] = hospital
        }

        print("[CouponService] getCouponTakeList → hospitalId=\(hospital) pageNum=\(pageNum) pageSize=\(pageSize)")

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
        print("[CouponService] getCouponTakeList ✓ count=\(items.count)")
        return items
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
