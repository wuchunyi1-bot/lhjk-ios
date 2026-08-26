import Foundation

/// 用户信息服务
///
/// 封装用户资料 / 档案机构相关接口
final class UserService: UserServiceProtocol {

    // MARK: - Singleton

    static let shared = UserService()

    private init() {}

    // MARK: - UserServiceProtocol

    func updateCurrentProfile(_ payload: SUsersOnboardingPayload) async throws -> SUsers? {
        print("[UserService] updateCurrentProfile → mobile=\(payload.mobile ?? "nil") name=\(payload.chineseName ?? "nil")")

        // 构建请求参数（只传非空字段）
        var params: [String: Any] = [:]
        if let mobile = payload.mobile { params["mobile"] = mobile }
        if let name = payload.chineseName { params["chineseName"] = name }
        if let sex = payload.sex { params["sex"] = sex }
        if let birthday = payload.birthday { params["birthday"] = birthday }
        if let imageUrl = payload.imageUrl { params["imageUrl"] = imageUrl }
        if let nickname = payload.nickname { params["nickname"] = nickname }
        if let email = payload.email { params["email"] = email }
        if let career = payload.career { params["career"] = career }
        if let education = payload.education { params["education"] = education }
        if let idType = payload.idType { params["idType"] = idType }
        if let idNumber = payload.idNumber { params["idNumber"] = idNumber }
        if let nationality = payload.nationality { params["nationality"] = nationality }
        if let ethnic = payload.ethnic { params["ethnic"] = ethnic }
        if let province = payload.province { params["province"] = province }
        if let cities = payload.cities { params["cities"] = cities }
        if let addressProvince = payload.addressProvince { params["addressProvince"] = addressProvince }
        if let addressCity = payload.addressCity { params["addressCity"] = addressCity }
        if let addressArea = payload.addressArea { params["addressArea"] = addressArea }
        if let address = payload.address { params["address"] = address }
        if let age = payload.age { params["age"] = age }

        print("[UserService] updateCurrentProfile → params: \(params)")

        let response: APIResponse<SUsers> = try await APIManager.shared
            .postAsync(path: "/v1/users/updateCurrentProfile", parameters: params, responseType: APIResponse<SUsers>.self)

        guard response.isSuccess else {
            print("[UserService] updateCurrentProfile ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw UserServiceError.saveFailed(response.msg ?? "")
        }

        print("[UserService] updateCurrentProfile ✓ id=\(response.data?.id ?? "-1")")
        return response.data
    }

    /// 完善资料：保存档案机构 + 基本信息
    /// `POST /v1/archive/saveArchiveHospital`
    func saveArchiveHospital(_ dto: SaveArchiveHospitalDTO) async throws {
        var params: [String: Any] = [
            "chineseName": dto.chineseName,
            "sex": dto.sex,
            "birthday": dto.birthday,
            "hospitalId": dto.hospitalId,
        ]
        if let managerId = dto.businessManagerId {
            params["businessManagerId"] = managerId
        }

        print("[UserService] saveArchiveHospital → name=\(dto.chineseName) hospitalId=\(dto.hospitalId) managerId=\(dto.businessManagerId.map(String.init) ?? "nil")")

        let response: APIResponse<EmptyResponse> = try await APIManager.shared
            .postAsync(path: "/v1/archive/saveArchiveHospital", parameters: params, responseType: APIResponse<EmptyResponse>.self)

        guard response.isSuccess else {
            print("[UserService] saveArchiveHospital ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw UserServiceError.saveFailed(response.msg ?? "")
        }
        print("[UserService] saveArchiveHospital ✓")
    }

    func getCurrentUserBaseInfo() async throws -> SUsers? {
        print("[UserService] getCurrentUserBaseInfo")

        let response: APIResponse<SUsers> = try await APIManager.shared
            .getAsync(path: "/v1/users/getCurrentUserBaseInfo", parameters: nil, responseType: APIResponse<SUsers>.self)

        guard response.isSuccess else {
            print("[UserService] getCurrentUserBaseInfo ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw UserServiceError.queryFailed(response.msg ?? "")
        }

        guard let user = response.data else {
            print("[UserService] getCurrentUserBaseInfo → data is null, returning nil")
            return nil
        }
        if user.id == nil && user.mobile == nil && user.account == nil {
            print("[UserService] getCurrentUserBaseInfo → empty data, returning nil")
            return nil
        }
        print("[UserService] getCurrentUserBaseInfo ✓ id=\(user.id ?? "nil") name=\(user.chineseName ?? "nil")")
        return user
    }

    /// `GET /v1/users/getUserCenterOverview`
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/503199941e0.md
    func getUserCenterOverview() async throws -> UserCenterOverviewVO {
        print("[UserService] getUserCenterOverview")

        let response: APIResponse<UserCenterOverviewVO> = try await APIManager.shared.getAsync(
            path: "/v1/users/getUserCenterOverview",
            parameters: nil,
            responseType: APIResponse<UserCenterOverviewVO>.self
        )

        guard response.isSuccess, let overview = response.data else {
            print("[UserService] getUserCenterOverview ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw UserServiceError.queryFailed(response.msg ?? "")
        }

        print(
            "[UserService] getUserCenterOverview ✓ grade=\(overview.gradeName.map(String.init) ?? "nil") "
                + "point=\(overview.accountPoint.map(String.init) ?? "nil") "
                + "fundeCoin=\(overview.fundeCoin.map(String.init) ?? "nil") "
                + "benefits=\(overview.availableBenefitsCount.map(String.init) ?? "nil")"
        )
        return overview
    }

    /// `GET /v1/archive/getOArchiveByUserId`
    /// Apifox: https://s.apifox.cn/e82b600d-da6a-4580-88cb-5f0660f85f9b/486441727e0.md
    func getOArchiveByUserId(_ userId: String) async throws -> OArchive? {
        let trimmed = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            print("[UserService] getOArchiveByUserId → empty userId")
            throw UserServiceError.queryFailed("用户 ID 无效")
        }

        print("[UserService] getOArchiveByUserId → userId=\(trimmed)")

        let response: APIResponse<OArchive> = try await APIManager.shared
            .getAsync(
                path: "/v1/archive/getOArchiveByUserId",
                parameters: ["userId": trimmed],
                responseType: APIResponse<OArchive>.self
            )

        guard response.isSuccess else {
            print("[UserService] getOArchiveByUserId ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw UserServiceError.queryFailed(response.msg ?? "")
        }

        guard let archive = response.data else {
            print("[UserService] getOArchiveByUserId → data is null")
            return nil
        }
        print("[UserService] getOArchiveByUserId ✓ id=\(archive.id ?? "nil") name=\(archive.chineseName ?? "nil") archiveComplete=\(archive.archiveComplete.map(String.init) ?? "nil") height=\(archive.height.map(String.init) ?? "nil")")
        return archive
    }

    /// `GET /v1/archive/calculateArchiveCompletion`
    /// Apifox: 机构/档案管理 — 计算档案完善进度
    func calculateArchiveCompletion(userId: String) async throws -> ArchiveCompletionVO {
        let trimmed = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            print("[UserService] calculateArchiveCompletion → empty userId")
            throw UserServiceError.queryFailed("用户 ID 无效")
        }

        print("[UserService] calculateArchiveCompletion → userId=\(trimmed)")

        let response: APIResponse<ArchiveCompletionVO> = try await APIManager.shared.getAsync(
            path: "/v1/archive/calculateArchiveCompletion",
            parameters: ["userId": trimmed],
            responseType: APIResponse<ArchiveCompletionVO>.self
        )

        guard response.isSuccess, let data = response.data else {
            print("[UserService] calculateArchiveCompletion ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw UserServiceError.queryFailed(response.msg ?? "")
        }

        print("[UserService] calculateArchiveCompletion ✓ completionPercentage="
                + "\(data.completionPercentage.map(String.init) ?? "nil")"
        )
        return data
    }

    /// `POST /v1/archive/saveOrUpdateArchiveByMobile` — 手机端修改档案（如是否孕妇）
    func saveOrUpdateArchiveByMobile(
        archive: OArchive,
        whetherPregnancy: Int? = nil
    ) async throws {
        guard let params = Self.mobileArchiveBody(from: archive, whetherPregnancy: whetherPregnancy) else {
            print("[UserService] saveOrUpdateArchiveByMobile → incomplete archive")
            throw UserServiceError.saveFailed("档案数据不完整，无法保存")
        }

        print("[UserService] saveOrUpdateArchiveByMobile → id=\(archive.id ?? "nil") whetherPregnancy=\(params["whetherPregnancy"] ?? "nil")")

        let response: APIResponse<EmptyResponse> = try await APIManager.shared.postAsync(
            path: "/v1/archive/saveOrUpdateArchiveByMobile",
            parameters: params,
            responseType: APIResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            print("[UserService] saveOrUpdateArchiveByMobile ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw UserServiceError.saveFailed(response.msg ?? "")
        }
        print("[UserService] saveOrUpdateArchiveByMobile ✓")
    }

    // MARK: - Private

    /// Apifox `OArchive` 必填：userId、hospitalId、status、height、weight
    private static func mobileArchiveBody(
        from archive: OArchive,
        whetherPregnancy: Int?
    ) -> [String: Any]? {
        guard
            let userId = intParam(archive.userId),
            let hospitalId = intParam(archive.hospitalId),
            let status = archive.status,
            let height = archive.height,
            let weight = archive.weight
        else { return nil }

        var params: [String: Any] = [
            "userId": userId,
            "hospitalId": hospitalId,
            "status": status,
            "height": height,
            "weight": weight,
        ]
        if let id = intParam(archive.id) { params["id"] = id }
        let pregnancy = whetherPregnancy ?? archive.whetherPregnancy ?? 0
        params["whetherPregnancy"] = pregnancy
        return params
    }

    private static func intParam(_ raw: String?) -> Int64? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return Int64(trimmed)
    }

    // MARK: - 密码/手机号管理

    func resetPasswordByMobile(mobile: String, newPwd: String, checkCode: String) async throws {
        print("[UserService] resetPasswordByMobile → mobile=\(mobile)")
        let dto = ResetPasswordByMobileDTO(mobile: mobile, newPwd: newPwd, checkCode: checkCode)

        let response: APIResponse<EmptyResponse> = try await APIManager.shared
            .publicPostAsync(
                path: "/v1/users/resetPasswordByMobile",
                parameters: dto.asDict(),
                responseType: APIResponse<EmptyResponse>.self
            )

        guard response.isSuccess else {
            print("[UserService] resetPasswordByMobile ✗ code=\(response.code)")
            throw UserServiceError.passwordResetFailed(response.msg ?? "")
        }
        print("[UserService] resetPasswordByMobile ✓")
    }

    func changeMobile(oldMobile: String?, newMobile: String, checkCode: String?) async throws {
        print("[UserService] changeMobile → newMobile=\(newMobile)")
        var params: [String: Any] = ["newMobile": newMobile]
        if let old = oldMobile { params["oldMobile"] = old }
        if let code = checkCode { params["checkCode"] = code }

        let response: APIResponse<EmptyResponse> = try await APIManager.shared
            .postFormURLEncodedAsync(path: "/v1/users/changeMobile", parameters: params, responseType: APIResponse<EmptyResponse>.self)

        guard response.isSuccess else {
            print("[UserService] changeMobile ✗ code=\(response.code)")
            throw UserServiceError.mobileChangeFailed(response.msg ?? "")
        }
        print("[UserService] changeMobile ✓")
    }

    // MARK: - 注销用户

    func cancelCurrentUser() async throws {
        print("[UserService] cancelCurrentUser")

        let response: APIResponse<EmptyResponse> = try await APIManager.shared
            .postAsync(path: "/v1/users/cancelCurrentUser", parameters: nil, responseType: APIResponse<EmptyResponse>.self)

        guard response.isSuccess else {
            print("[UserService] cancelCurrentUser ✗ code=\(response.code) msg=\(response.msg ?? "")")
            throw UserServiceError.cancelFailed(response.msg ?? "")
        }
        print("[UserService] cancelCurrentUser ✓")
    }

    func changeCurrentPassword(oldPwd: String, newPwd: String) async throws {
        print("[UserService] changeCurrentPassword")
        let dto = ChangeCurrentPasswordDTO(oldPwd: oldPwd, newPwd: newPwd)

        let response: APIResponse<EmptyResponse> = try await APIManager.shared
            .postAsync(path: "/v1/users/changeCurrentPassword", parameters: dto.asDict(), responseType: APIResponse<EmptyResponse>.self)

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
    case cancelFailed(String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let msg): return msg.isEmpty ? "保存用户信息失败" : msg
        case .queryFailed(let msg): return msg.isEmpty ? "查询用户信息失败" : msg
        case .passwordResetFailed(let msg): return msg.isEmpty ? "密码重置失败" : msg
        case .passwordChangeFailed(let msg): return msg.isEmpty ? "密码修改失败" : msg
        case .mobileChangeFailed(let msg): return msg.isEmpty ? "手机号修改失败" : msg
        case .cancelFailed(let msg): return msg.isEmpty ? "注销失败，请稍后重试" : msg
        }
    }
}
