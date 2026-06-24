import Foundation

/// 用户信息服务
///
/// 封装 `POST /mobile/v1/users/saveUser` 和 `GET /mobile/v1/users/getUserByParam`
final class UserService: UserServiceProtocol {

    // MARK: - Singleton

    static let shared = UserService()

    private init() {}

    // MARK: - UserServiceProtocol

    func saveUser(_ payload: SUsersOnboardingPayload) async throws {
        print("[UserService] saveUser → mobile=\(payload.mobile ?? "nil") name=\(payload.chineseName ?? "nil")")

        // 构建请求参数（只传非空字段）
        var params: [String: Any] = [:]
        if let mobile = payload.mobile { params["mobile"] = mobile }
        if let name = payload.chineseName { params["chineseName"] = name }
        if let sex = payload.sex { params["sex"] = sex }
        if let birthday = payload.birthday { params["birthday"] = birthday }

        // 扩展字段
        if let history = payload.medicalHistory { params["medicalHistory"] = history }
        if let smoking = payload.smokingStatus { params["smokingStatus"] = smoking }
        if let exercise = payload.exerciseFrequency { params["exerciseFrequency"] = exercise }

        print("[UserService] saveUser → params: \(params)")

        let response: APIResponse<EmptyResponse> = try await APIManager.shared
            .postAsync(path: "/mobile/v1/users/saveUser", parameters: params, responseType: APIResponse<EmptyResponse>.self)

        guard response.isSuccess else {
            print("[UserService] saveUser ✗ code=\(response.code) msg=\(response.msg)")
            throw UserServiceError.saveFailed(response.msg ?? "")
        }

        print("[UserService] saveUser ✓")
    }

    func getUserByParam(mobile: String) async throws -> SUsers? {
        print("[UserService] getUserByParam → mobile=\(mobile)")

        let params: [String: Any] = ["mobile": mobile]

        let response: APIResponse<SUsers> = try await APIManager.shared
            .getAsync(path: "/mobile/v1/users/getUserByParam", parameters: params, responseType: APIResponse<SUsers>.self)

        guard response.isSuccess else {
            if response.code == "404" || (response.msg ?? "").contains("不存在") {
                print("[UserService] getUserByParam → user not found (code=\(response.code))")
                return nil
            }
            print("[UserService] getUserByParam ✗ code=\(response.code) msg=\(response.msg)")
            throw UserServiceError.queryFailed(response.msg ?? "")
        }

        guard let user = response.data else {
            print("[UserService] getUserByParam → data is null, returning nil")
            return nil
        }
        if user.id == nil && user.mobile == nil && user.account == nil {
            print("[UserService] getUserByParam → empty data, returning nil")
            return nil
        }
        print("[UserService] getUserByParam ✓ id=\(user.id ?? "nil") name=\(user.chineseName ?? "nil")")
        return user
    }

    // MARK: - 密码/手机号管理

    func resetPasswordByMobile(mobile: String, newPwd: String, checkCode: String) async throws {
        print("[UserService] resetPasswordByMobile → mobile=\(mobile)")
        let dto = ResetPasswordByMobileDTO(mobile: mobile, newPwd: newPwd, checkCode: checkCode)

        let response: APIResponse<EmptyResponse> = try await APIManager.shared
            .postAsync(path: "/mobile/v1/users/resetPasswordByMobile", parameters: dto.asDict(), responseType: APIResponse<EmptyResponse>.self)

        guard response.isSuccess else {
            print("[UserService] resetPasswordByMobile ✗ code=\(response.code)")
            throw UserServiceError.passwordResetFailed(response.msg ?? "")
        }
        print("[UserService] resetPasswordByMobile ✓")
    }

    func changePassword(mobile: String, oldPwd: String?, newPwd: String, checkCode: String?) async throws {
        print("[UserService] changePassword → mobile=\(mobile)")
        var params: [String: Any] = ["mobile": mobile, "newPwd": newPwd]
        if let old = oldPwd { params["oldPwd"] = old }
        if let code = checkCode { params["checkCode"] = code }

        let response: APIResponse<EmptyResponse> = try await APIManager.shared
            .postFormURLEncodedAsync(path: "/mobile/v1/users/changePassword", parameters: params, responseType: APIResponse<EmptyResponse>.self)

        guard response.isSuccess else {
            print("[UserService] changePassword ✗ code=\(response.code)")
            throw UserServiceError.passwordChangeFailed(response.msg ?? "")
        }
        print("[UserService] changePassword ✓")
    }

    func changeMobile(oldMobile: String?, newMobile: String, checkCode: String?) async throws {
        print("[UserService] changeMobile → newMobile=\(newMobile)")
        var params: [String: Any] = ["newMobile": newMobile]
        if let old = oldMobile { params["oldMobile"] = old }
        if let code = checkCode { params["checkCode"] = code }

        let response: APIResponse<EmptyResponse> = try await APIManager.shared
            .postFormURLEncodedAsync(path: "/mobile/v1/users/changeMobile", parameters: params, responseType: APIResponse<EmptyResponse>.self)

        guard response.isSuccess else {
            print("[UserService] changeMobile ✗ code=\(response.code)")
            throw UserServiceError.mobileChangeFailed(response.msg ?? "")
        }
        print("[UserService] changeMobile ✓")
    }

    func changeCurrentPassword(oldPwd: String, newPwd: String) async throws {
        print("[UserService] changeCurrentPassword")
        let dto = ChangeCurrentPasswordDTO(oldPwd: oldPwd, newPwd: newPwd)

        let response: APIResponse<EmptyResponse> = try await APIManager.shared
            .postAsync(path: "/mobile/v1/users/changeCurrentPassword", parameters: dto.asDict(), responseType: APIResponse<EmptyResponse>.self)

        guard response.isSuccess else {
            print("[UserService] changeCurrentPassword ✗ code=\(response.code)")
            throw UserServiceError.passwordChangeFailed(response.msg ?? "")
        }
        print("[UserService] changeCurrentPassword ✓")
    }
}

// MARK: - Error

// MARK: - Encodable → [String: Any]

private extension Encodable {
    func asDict() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return dict
    }
}

// MARK: - Error

enum UserServiceError: Error, LocalizedError {
    case saveFailed(String)
    case queryFailed(String)
    case passwordResetFailed(String)
    case passwordChangeFailed(String)
    case mobileChangeFailed(String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let msg): return msg.isEmpty ? "保存用户信息失败" : msg
        case .queryFailed(let msg): return msg.isEmpty ? "查询用户信息失败" : msg
        case .passwordResetFailed(let msg): return msg.isEmpty ? "密码重置失败" : msg
        case .passwordChangeFailed(let msg): return msg.isEmpty ? "密码修改失败" : msg
        case .mobileChangeFailed(let msg): return msg.isEmpty ? "手机号修改失败" : msg
        }
    }
}
