import Foundation

// MARK: - 收货地址服务 (BLL)

/// 收货地址管理服务 — 提供地址的增删改查能力
///
/// 封装三个后端接口：
/// - `GET  /mobile/v1/address/getAddressList` — 分页查询地址列表
/// - `POST /mobile/v1/address/saveOrUpdateAddress` — 新增/修改地址
/// - `DELETE /mobile/v1/address/deleteAddressById` — 根据 ID 删除地址
final class AddressService {

    // MARK: - Singleton

    static let shared = AddressService()

    private init() {}

    // MARK: - 查询地址列表

    /// 查询当前用户的收货地址列表（分页）
    /// - Parameters:
    ///   - userId: 用户 ID（可选，不传则查当前登录用户）
    ///   - pageNum: 当前页码，默认 1
    ///   - pageSize: 每页记录数，默认 20
    /// - Returns: 分页地址数据
    func getAddressList(
        userId: String? = nil,
        pageNum: Int = 1,
        pageSize: Int = 20
    ) async throws -> PaginatedAddressData {
        var params: [String: Any] = [
            "pageNum": String(pageNum),
            "pageSize": String(pageSize),
        ]
        if let userId = userId {
            params["userId"] = userId
        }

        print("[AddressService] getAddressList → userId=\(userId ?? "nil") page=\(pageNum) size=\(pageSize)")

        let response: APIResponse<PaginatedAddressData> = try await APIManager.shared
            .getAsync(
                path: "/mobile/v1/address/getAddressList",
                parameters: params,
                responseType: APIResponse<PaginatedAddressData>.self
            )

        guard response.isSuccess else {
            print("[AddressService] getAddressList ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw AddressServiceError.queryFailed(response.msg ?? "查询地址列表失败")
        }

        let data = response.data ?? PaginatedAddressData(totalRecords: 0, pageSize: pageSize, totalPages: 0, currentPage: pageNum, records: [])
        print("[AddressService] getAddressList ✓ total=\(data.totalRecords ?? 0) count=\(data.records?.count ?? 0)")
        return data
    }

    // MARK: - 新增/修改地址

    /// 新增或修改收货地址
    /// - Parameter payload: 地址保存请求体（有 `id` 则修改，无 `id` 则新增）
    func saveOrUpdateAddress(_ payload: AddressSavePayload) async throws {
        let isUpdate = payload.id != nil
        print("[AddressService] saveOrUpdateAddress → id=\(payload.id?.description ?? "nil") name=\(payload.name)")

        let params: [String: Any] = [
            "id": payload.id.map(String.init) as Any,
            "name": payload.name,
            "mobile": payload.mobile,
            "isDefault": payload.isDefault,
            "province": payload.province,
            "city": payload.city,
            "area": payload.area,
            "address": payload.address,
            "code": payload.code as Any,
        ]

        let response: APIResponse<EmptyResponse> = try await APIManager.shared
            .postAsync(
                path: "/mobile/v1/address/saveOrUpdateAddress",
                parameters: params,
                responseType: APIResponse<EmptyResponse>.self
            )

        guard response.isSuccess else {
            print("[AddressService] saveOrUpdateAddress ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw AddressServiceError.saveFailed(response.msg ?? "保存地址失败")
        }

        print("[AddressService] saveOrUpdateAddress ✓ (\(isUpdate ? "update" : "create"))")
    }

    // MARK: - 删除地址

    /// 根据 ID 删除收货地址
    /// - Parameter id: 地址主键 ID
    func deleteAddress(id: Int64) async throws {
        print("[AddressService] deleteAddress → id=\(id)")

        let response: APIResponse<EmptyResponse> = try await APIManager.shared
            .deleteAsync(
                path: "/mobile/v1/address/deleteAddressById",
                parameters: ["id": String(id)],
                responseType: APIResponse<EmptyResponse>.self
            )

        guard response.isSuccess else {
            print("[AddressService] deleteAddress ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw AddressServiceError.deleteFailed(response.msg ?? "删除地址失败")
        }

        print("[AddressService] deleteAddress ✓")
    }
}

// MARK: - Error

enum AddressServiceError: Error, LocalizedError {
    case queryFailed(String)
    case saveFailed(String)
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .queryFailed(let msg): return msg.isEmpty ? "查询地址列表失败" : msg
        case .saveFailed(let msg): return msg.isEmpty ? "保存地址失败" : msg
        case .deleteFailed(let msg): return msg.isEmpty ? "删除地址失败" : msg
        }
    }
}
