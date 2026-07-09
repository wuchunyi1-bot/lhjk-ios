import Alamofire
import Foundation

// MARK: - OAuth Authenticator

/// OAuth 2.0 认证器，遵循 Alamofire 的 Authenticator 协议
///
/// 配合 `AuthenticationInterceptor` 使用，由 Alamofire 内部协调所有并发控制。
/// 无需手动管理锁、队列或刷新状态 — Alamofire 自动保证：
/// - 多个请求同时触发刷新时，仅第一个请求执行实际刷新，其余排队等待
/// - 刷新期间到达的新请求自动挂起，等待刷新完成后重放
final class OAuthAuthenticator: Authenticator {

    typealias Credential = OAuthCredential

    private let clientId = "funde-app"
    private let clientSecret = "funde-app"

    // MARK: - Authenticator: Apply

    /// 将 Token 注入请求头
    func apply(_ credential: Credential, to urlRequest: inout URLRequest) {
        urlRequest.headers.add(.authorization(bearerToken: credential.accessToken))
    }

    // MARK: - Authenticator: Refresh

    /// Token 过期或收到 401 时，Alamofire 自动调用此方法刷新 Token
    ///
    /// - Parameters:
    ///   - credential: 当前的凭证
    ///   - session: 当前的 Alamofire Session（含拦截器，不可用于刷新请求本身）
    ///   - completion: 刷新完成后调用，传入新的 Credential 或错误
    func refresh(
        _ credential: Credential,
        for session: Session,
        completion: @escaping (Result<Credential, any Error>) -> Void
    ) {
        DebugLogger.logCall(
            module: "OAuthAuthenticator",
            function: "refresh",
            params: [
                "expiration": credential.expiration,
                "requiresRefresh": credential.requiresRefresh,
            ]
        )

        let params: [String: Any] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "grant_type": "refresh_token",
            "refresh_token": credential.refreshToken,
        ]

        let url = APIManager.shared.makeURL(for: "/auth/oauth2/token", useGatewayRoot: true)

        // 必须使用无认证 Session，避免刷新请求再次触发拦截器
        APIManager.shared.publicSession
            .request(url, method: .post, parameters: params, encoding: URLEncoding.httpBody)
            .validate()
            .responseDecodable(of: APIResponse<OAuthTokenResponse>.self, decoder: APIManager.shared.jsonDecoder) { response in
                switch response.result {
                case .success(let apiResponse):
                    guard apiResponse.isSuccess, let token = apiResponse.data else {
                        let msg = apiResponse.msg ?? "Token 刷新失败"
                        DebugLogger.logReturn(
                            module: "OAuthAuthenticator",
                            function: "refresh",
                            value: "failed: code=\(apiResponse.code) msg=\(msg)"
                        )
                        completion(.failure(OAuthRefreshError.serverRejected(code: apiResponse.code, message: msg)))
                        return
                    }

                    let expiresIn = max(token.expiresIn, 60)
                    let newCredential = OAuthCredential(
                        accessToken: token.accessToken,
                        refreshToken: token.refreshToken,
                        expiration: Date().addingTimeInterval(TimeInterval(expiresIn))
                    )
                    APIManager.shared.persistRefreshedCredential(newCredential)
                    DebugLogger.logReturn(
                        module: "OAuthAuthenticator",
                        function: "refresh",
                        value: "success, expiresIn=\(expiresIn)s"
                    )
                    completion(.success(newCredential))

                case .failure(let error):
                    DebugLogger.logReturn(
                        module: "OAuthAuthenticator",
                        function: "refresh",
                        value: "failed: \(error.localizedDescription)"
                    )
                    completion(.failure(error))
                }
            }
    }

    // MARK: - Authenticator: 判断 401

    /// 判断请求失败是否因为认证错误（HTTP 401）
    func didRequest(
        _ urlRequest: URLRequest,
        with response: HTTPURLResponse,
        failDueToAuthenticationError error: any Error
    ) -> Bool {
        response.statusCode == 401
    }

    // MARK: - Authenticator: 判断是否已认证

    /// 判断请求是否已携带当前有效的 Bearer Token
    func isRequest(
        _ urlRequest: URLRequest,
        authenticatedWith credential: Credential
    ) -> Bool {
        let bearerValue = HTTPHeader.authorization(bearerToken: credential.accessToken).value
        return urlRequest.headers.value(for: "Authorization") == bearerValue
    }
}

// MARK: - Error

enum OAuthRefreshError: LocalizedError {
    case serverRejected(code: String, message: String)

    var errorDescription: String? {
        switch self {
        case .serverRejected(_, let message):
            return message
        }
    }
}
