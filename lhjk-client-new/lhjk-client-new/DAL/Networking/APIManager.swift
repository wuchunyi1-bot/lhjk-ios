import Alamofire
import Combine
import Foundation

// MARK: - API 环境配置

enum APIEnvironment: String {
    case development
    case staging
    case production

    var baseURL: URL {
        switch self {
        case .development:
            return URL(string: "http://gateway-dev.lianhaojiankang.com")!
        case .staging:
            return URL(string: "https://staging-api.lhjk.com")!
        case .production:
            return URL(string: "https://api.lhjk.com")!
        }
    }
}

// MARK: - API Manager (DAL)

/// 统一网络请求管理器 — 纯 Alamofire，基于 AuthenticationInterceptor 管理 Token
///
/// Token 刷新并发控制由 Alamofire 的 `AuthenticationInterceptor` 内部处理：
/// - 多个请求同时触发刷新时，仅第一个执行实际刷新，其余排队等待
/// - 刷新期间到达的新请求自动挂起
/// - 无需手动管理锁 / 队列 / 刷新状态
final class APIManager {

    // MARK: - Singleton

    static let shared = APIManager()

    // MARK: - Properties

    /// 当前 API 环境
    var environment: APIEnvironment = .development

    /// Alamofire Session（含 AuthenticationInterceptor，用于需认证的请求）
    var session: Session!

    /// 无认证 Session（用于登录、发送验证码等公开接口）
    var publicSession: Session!

    /// JSONDecoder 配置：后端使用 snake_case 字段名
    let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    /// 底层 URLSession 配置（保持复用）
    private let configuration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return config
    }()

    // MARK: - Initialization

    private init() {
        let savedCredential = Self.loadCredentialFromStorage()
        configureSession(with: savedCredential)
        // 无认证 Session — 公开接口不需 Token
        publicSession = Session(
            configuration: configuration,
            eventMonitors: [LogMonitor()]
        )
    }

    /// 使用指定 Credential 重建 Session
    private func configureSession(with credential: OAuthCredential?) {
        let authenticator = OAuthAuthenticator()
        let interceptor = AuthenticationInterceptor(
            authenticator: authenticator,
            credential: credential
        )

        session = Session(
            configuration: configuration,
            interceptor: interceptor,
            eventMonitors: [LogMonitor()]
        )
    }

    // MARK: - Credential 管理

    /// 登录成功后调用：持久化 Credential 并重建 Session
    ///
    /// 重建 Session 确保 `AuthenticationInterceptor` 持有最新的 Token，
    /// 后续请求自动携带有效的 Bearer Token。
    func setCredential(_ credential: OAuthCredential) {
        persistCredential(credential)
        configureSession(with: credential)
    }

    /// 登出时调用：清除 Credential 并重建无认证 Session
    func clearCredential() {
        UserDefaults.standard.removeObject(forKey: .authAccessTokenKey)
        UserDefaults.standard.removeObject(forKey: .authRefreshTokenKey)
        UserDefaults.standard.removeObject(forKey: .authExpirationKey)
        configureSession(with: nil)
    }

    // MARK: - Private: 持久化

    private func persistCredential(_ credential: OAuthCredential) {
        UserDefaults.standard.set(credential.accessToken, forKey: .authAccessTokenKey)
        UserDefaults.standard.set(credential.refreshToken, forKey: .authRefreshTokenKey)
        UserDefaults.standard.set(credential.expiration, forKey: .authExpirationKey)
    }

    private static func loadCredentialFromStorage() -> OAuthCredential? {
        guard
            let accessToken = UserDefaults.standard.string(forKey: .authAccessTokenKey),
            let refreshToken = UserDefaults.standard.string(forKey: .authRefreshTokenKey)
        else { return nil }

        let expiration = UserDefaults.standard.object(forKey: .authExpirationKey) as? Date ?? Date()
        return OAuthCredential(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiration: expiration
        )
    }

    // MARK: - GET

    /// 发起 GET 请求并解析响应为指定 Decodable 类型
    func get<T: Decodable>(
        path: String,
        parameters: [String: Any]? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, APIError> {
        return request(method: .get, path: path, parameters: parameters, responseType: responseType)
    }

    // MARK: - POST

    /// 发起 POST 请求并解析响应为指定 Decodable 类型
    func post<T: Decodable>(
        path: String,
        parameters: [String: Any]? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, APIError> {
        return request(method: .post, path: path, parameters: parameters, responseType: responseType)
    }

    // MARK: - PUT

    /// 发起 PUT 请求并解析响应为指定 Decodable 类型
    func put<T: Decodable>(
        path: String,
        parameters: [String: Any]? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, APIError> {
        return request(method: .put, path: path, parameters: parameters, responseType: responseType)
    }

    // MARK: - DELETE

    /// 发起 DELETE 请求并解析响应为指定 Decodable 类型
    func delete<T: Decodable>(
        path: String,
        parameters: [String: Any]? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, APIError> {
        return request(method: .delete, path: path, parameters: parameters, responseType: responseType)
    }

    // MARK: - PATCH

    /// 发起 PATCH 请求并解析响应为指定 Decodable 类型
    func patch<T: Decodable>(
        path: String,
        parameters: [String: Any]? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, APIError> {
        return request(method: .patch, path: path, parameters: parameters, responseType: responseType)
    }

    // MARK: - Upload (Multipart)

    /// 文件上传（multipart/form-data），支持进度回调
    func upload<T: Decodable>(
        path: String,
        multipartItems: [MultipartFormData],
        responseType: T.Type,
        progressHandler: ((Double) -> Void)? = nil
    ) -> AnyPublisher<T, APIError> {
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = environment.baseURL.appendingPathComponent(cleanPath)

        return session.upload(
            multipartFormData: { formData in
                for item in multipartItems {
                    if let fileName = item.fileName, let mimeType = item.mimeType {
                        formData.append(item.data, withName: item.name, fileName: fileName, mimeType: mimeType)
                    } else {
                        formData.append(item.data, withName: item.name)
                    }
                }
            },
            to: url,
            method: .post
        )
        .uploadProgress { progress in
            progressHandler?(progress.fractionCompleted)
        }
        .validate()
        .publishDecodable(type: T.self, decoder: jsonDecoder)
        .tryMap { response in
            switch response.result {
            case .success(let value):
                return value
            case .failure(let afError):
                throw APIError(from: afError, data: response.data)
            }
        }
        .mapError { error in
            (error as? APIError) ?? .unknown(error)
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Private: 通用请求

    private func request<T: Decodable>(
        method: HTTPMethod,
        path: String,
        parameters: [String: Any]?,
        responseType: T.Type
    ) -> AnyPublisher<T, APIError> {
        // 去除 path 前导 `/`，防止 appendingPathComponent 吞掉 baseURL 的路径前缀
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = environment.baseURL.appendingPathComponent(cleanPath)

        let encoding: ParameterEncoding = {
            switch method {
            case .get, .delete:
                return URLEncoding.default
            default:
                return JSONEncoding.default
            }
        }()

        return session.request(
            url,
            method: method,
            parameters: parameters,
            encoding: encoding
        )
        .validate()
        .publishDecodable(type: T.self, decoder: jsonDecoder)
        .tryMap { response in
            switch response.result {
            case .success(let value):
                return value
            case .failure(let afError):
                throw APIError(from: afError, data: response.data)
            }
        }
        .mapError { error in
            (error as? APIError) ?? .unknown(error)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - JSONDecoder Extension

extension APIManager {
    /// 获取配置了 snake_case 转换的 JSONDecoder，供 DAL 层其他地方复用
    var snakeCaseDecoder: JSONDecoder { jsonDecoder }
}

// MARK: - HTTPMethod（简化版，直接使用 Alamofire）

typealias HTTPMethod = Alamofire.HTTPMethod

// MARK: - Multipart Form Data

struct MultipartFormData {
    let data: Data
    let name: String
    let fileName: String?
    let mimeType: String?
}

// MARK: - APIError 转换

extension APIError {
    init(from afError: AFError, data: Data?) {
        // 解码失败 → 优先处理，打印原始响应用于调试
        if case .responseSerializationFailed(let reason) = afError {
            if let data = data, let raw = String(data: data, encoding: .utf8) {
                print("[APIManager] Decode failed — reason: \(reason) — raw: \(raw.prefix(2000))")
            }
            self = .decodingError(afError)
            return
        }

        if let underlying = afError.underlyingError {
            let nsError = underlying as NSError
            if nsError.code == NSURLErrorTimedOut {
                self = .timeout
            } else if nsError.code == NSURLErrorNotConnectedToInternet {
                self = .networkUnreachable
            } else {
                self = .unknown(underlying)
            }
            return
        }

        switch afError {
        case .responseValidationFailed(let reason):
            if case .unacceptableStatusCode(let code) = reason {
                switch code {
                case 401:
                    self = .unauthorized
                case 500...599:
                    self = .serverError(statusCode: code, message: nil)
                default:
                    self = .businessError(code: code, message: String(data: data ?? Data(), encoding: .utf8))
                }
            } else {
                self = .unknown(afError)
            }
        default:
            self = .unknown(afError)
        }
    }
}

/// 空响应体（用于不需要解析返回值的请求）
struct EmptyResponse: Decodable {}

// MARK: - 日志监控

/// 请求/响应日志事件监控
final class LogMonitor: EventMonitor {

    func request(_ request: Request, didCreateURLRequest urlRequest: URLRequest) {
        print("[API] → \(urlRequest.httpMethod ?? "?") \(urlRequest.url?.absoluteString ?? "")")
        if let headers = urlRequest.allHTTPHeaderFields, !headers.isEmpty {
            print("[API] Headers: \(headers)")
        }
        if let body = urlRequest.httpBody {
            if let str = String(data: body, encoding: .utf8) {
                print("[API] Body(raw): \(str)")
            } else {
                print("[API] Body: \(body.count) bytes")
            }
        }
    }

    func request(_ request: Request, didParseResponse response: AFDataResponse<some Sendable>) {
        if let httpResponse = response.response {
            print("[API] ← \(httpResponse.statusCode) \(httpResponse.url?.absoluteString ?? "")")
        }
        if let data = response.data {
            if let str = String(data: data, encoding: .utf8) {
                print("[API] Response(raw): \(str.prefix(2000))")
            } else {
                print("[API] Response: \(data.count) bytes")
            }
        }
        if let error = response.error {
            print("[API] Error: \(error.localizedDescription)")
            if let afError = error.asAFError {
                print("[API] AFError: \(afError)")
            }
        }
    }
}

// MARK: - UserDefaults Keys

private extension String {
    static let authAccessTokenKey = "auth_access_token"
    static let authRefreshTokenKey = "auth_refresh_token"
    static let authExpirationKey = "auth_expiration"
}
