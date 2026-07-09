import Alamofire
import Combine
import Foundation

// MARK: - Async/Await Bridge

extension APIManager {

    // MARK: Public (Unauthenticated)

    func publicGetAsync<T: Decodable>(
        path: String, parameters: [String: Any]? = nil, responseType: T.Type
    ) async throws -> T {
        let url = makeURL(for: path)
        return try await request(url: url, method: .get, parameters: parameters, encoding: URLEncoding.default, session: publicSession)
    }

    func publicPostFormURLEncodedAsync<T: Decodable>(
        path: String,
        parameters: [String: Any]? = nil,
        responseType: T.Type,
        useGatewayRoot: Bool = false
    ) async throws -> T {
        let url = makeURL(for: path, useGatewayRoot: useGatewayRoot)
        return try await request(url: url, method: .post, parameters: parameters, encoding: URLEncoding.httpBody, session: publicSession)
    }

    // MARK: Authenticated

    func getAsync<T: Decodable>(
        path: String, parameters: [String: Any]? = nil, responseType: T.Type
    ) async throws -> T {
        let url = makeURL(for: path)
        return try await request(url: url, method: .get, parameters: parameters, encoding: URLEncoding.default, session: session)
    }

    func postAsync<T: Decodable>(
        path: String, parameters: [String: Any]? = nil, responseType: T.Type
    ) async throws -> T {
        let url = makeURL(for: path)
        return try await request(url: url, method: .post, parameters: parameters, encoding: JSONEncoding.default, session: session)
    }

    /// 已认证的 POST 请求，参数以 URL query string 方式传递（非 JSON body）
    func postFormURLEncodedAsync<T: Decodable>(
        path: String, parameters: [String: Any]? = nil, responseType: T.Type
    ) async throws -> T {
        let url = makeURL(for: path)
        return try await request(url: url, method: .post, parameters: parameters, encoding: URLEncoding.default, session: session)
    }

    func putAsync<T: Decodable>(
        path: String, parameters: [String: Any]? = nil, responseType: T.Type
    ) async throws -> T {
        let url = makeURL(for: path)
        return try await request(url: url, method: .put, parameters: parameters, encoding: JSONEncoding.default, session: session)
    }

    func deleteAsync<T: Decodable>(
        path: String,
        parameters: [String: Any]? = nil,
        responseType: T.Type,
        useGatewayRoot: Bool = false
    ) async throws -> T {
        let url = makeURL(for: path, useGatewayRoot: useGatewayRoot)
        return try await request(url: url, method: .delete, parameters: parameters, encoding: URLEncoding.default, session: session)
    }

    // MARK: Private

    private func request<T: Decodable>(
        url: URL, method: HTTPMethod, parameters: [String: Any]?, encoding: ParameterEncoding, session: Session
    ) async throws -> T {
        DebugLogger.logAPIRequest(method: method.rawValue, url: url.absoluteString, parameters: parameters)
        return try await withCheckedThrowingContinuation { cont in
            var c: AnyCancellable?
            c = session.request(url, method: method, parameters: parameters, encoding: encoding)
                .validate()
                .publishDecodable(type: T.self, decoder: jsonDecoder)
                .tryMap { r in
                    switch r.result {
                    case .success(let v):
                        DebugLogger.logAPIResponse(
                            url: url.absoluteString,
                            statusCode: r.response?.statusCode,
                            rawData: r.data,
                            decoded: v
                        )
                        return v
                    case .failure(let e):
                        DebugLogger.logAPIResponse(
                            url: url.absoluteString,
                            statusCode: r.response?.statusCode,
                            rawData: r.data,
                            error: e
                        )
                        throw APIError(from: e, data: r.data)
                    }
                }
                .mapError { ($0 as? APIError) ?? .unknown($0) }
                .sink(
                    receiveCompletion: { if case .failure(let e) = $0 { cont.resume(throwing: e) }; c?.cancel() },
                    receiveValue: { cont.resume(returning: $0); c?.cancel() }
                )
        }
    }
}
