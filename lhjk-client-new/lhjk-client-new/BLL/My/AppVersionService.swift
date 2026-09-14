import Foundation

/// 移动端版本 — `GET /v1/version/getLatestVersionForApp`
///
/// Apifox：内容/版本管理，Query `type`、`versionCode`。
final class AppVersionService {

    static let shared = AppVersionService()

    private init() {}

    /// 当前 App 的 `CFBundleVersion`（递增编码）；解析失败时回退短版本去点号。
    var localVersionCode: Int {
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        if let value = Int(build.trimmingCharacters(in: .whitespacesAndNewlines)), value > 0 {
            return value
        }
        let short = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(short) ?? 0
    }

    /// 当前 App 的 `CFBundleShortVersionString`（例如 1.2.0）
    var localVersionName: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let trimmed = short.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "1.0.0" : trimmed
    }

    /// 查询是否有新版本。无更新或 `data` 为空时返回 `.upToDate`。
    func checkLatestVersion(
        type: AppVersionClientType = .ios
    ) async throws -> AppVersionCheckOutcome {
        let localCode = localVersionCode
        let params: [String: Any] = [
            "type": type.rawValue,
            "versionCode": localCode,
        ]
        print("[AppVersionService] getLatestVersionForApp → type=\(type.rawValue) versionCode=\(localCode)")

        let response: APIResponse<AppLatestVersionData>
        do {
            response = try await requestLatest(parameters: params)
        } catch {
            print("[AppVersionService] getLatestVersionForApp ✗ \(error.localizedDescription)")
            throw AppVersionServiceError.requestFailed(
                error.localizedDescription.isEmpty ? "检查更新失败" : error.localizedDescription
            )
        }

        guard response.isSuccess else {
            let message = response.msg?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            print("[AppVersionService] getLatestVersionForApp ✗ code=\(response.code) msg=\(message)")
            throw AppVersionServiceError.requestFailed(message.isEmpty ? "检查更新失败" : message)
        }

        let outcome = evaluate(data: response.data, localCode: localCode)
        switch outcome {
        case .upToDate:
            print("[AppVersionService] getLatestVersionForApp ✓ up to date local=\(localCode)")
        case .available(let info):
            print("[AppVersionService] getLatestVersionForApp ✓ update \(info.version.displayVersionName) force=\(info.isForce)")
        }
        return outcome
    }

    private func requestLatest(parameters: [String: Any]) async throws -> APIResponse<AppLatestVersionData> {
        let hasToken = UserDefaults.standard.string(forKey: "auth_access_token") != nil
        if hasToken {
            return try await APIManager.shared.getAsync(
                path: "/v1/version/getLatestVersionForApp",
                parameters: parameters,
                responseType: APIResponse<AppLatestVersionData>.self
            )
        }
        return try await APIManager.shared.publicGetAsync(
            path: "/v1/version/getLatestVersionForApp",
            parameters: parameters,
            responseType: APIResponse<AppLatestVersionData>.self
        )
    }

    private func evaluate(data: AppLatestVersionData?, localCode: Int) -> AppVersionCheckOutcome {
        guard let data else { return .upToDate }
        if data.isUpdate == false { return .upToDate }
        guard let version = data.version else { return .upToDate }

        if data.isUpdate != true {
            if let remoteCode = version.versionCode, remoteCode > 0, remoteCode <= localCode {
                return .upToDate
            }
            let name = version.versionName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if version.versionCode == nil, name.isEmpty {
                return .upToDate
            }
        }

        let isForce = data.isForceInstall == true || version.isForceInstall
        return .available(AppVersionCheckInfo(version: version, isForce: isForce, localVersionCode: localCode))
    }
}
