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
    ///   - session: 当前的 Alamofire Session
    ///   - completion: 刷新完成后调用，传入新的 Credential 或错误
    func refresh(
        _ credential: Credential,
        for session: Session,
        completion: @escaping (Result<Credential, any Error>) -> Void
    ) {
        // TODO: 替换为实际的 Token 刷新请求
        // 示例请求：
        // let parameters = ["refresh_token": credential.refreshToken]
        // session.request(refreshURL, method: .post, parameters: parameters)
        //     .validate()
        //     .responseDecodable(of: TokenResponse.self) { response in
        //         switch response.result {
        //         case .success(let tokenResponse):
        //             let newCredential = OAuthCredential(
        //                 accessToken: tokenResponse.accessToken,
        //                 refreshToken: tokenResponse.refreshToken,
        //                 expiration: tokenResponse.expiration
        //             )
        //             // 持久化新 Token
        //             completion(.success(newCredential))
        //         case .failure(let error):
        //             completion(.failure(error))
        //         }
        //     }

        // 占位实现：刷新失败，触发 didRequestFailWithError 流程
        let error = NSError(
            domain: "com.lhjk.auth",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Token 刷新尚未接入实际接口"]
        )
        completion(.failure(error))
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
