import Alamofire
import Combine
import Foundation

// MARK: - Async/Await Bridge

extension APIManager {

    private func makeURL(_ path: String) -> URL {
        let clean = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return environment.baseURL.appendingPathComponent(clean)
    }

    // MARK: Public (Unauthenticated)

    func publicGetAsync<T: Decodable>(
        path: String, parameters: [String: Any]? = nil, responseType: T.Type
    ) async throws -> T {
        let url = makeURL(path)
        print("[APIManager] GET(public) \(url)")
        return try await request(url: url, method: .get, parameters: parameters, encoding: URLEncoding.default, session: publicSession)
    }

    func publicPostFormURLEncodedAsync<T: Decodable>(
        path: String, parameters: [String: Any]? = nil, responseType: T.Type
    ) async throws -> T {
        let url = makeURL(path)
        print("[APIManager] POST(urlenc,public) \(url)")
        return try await request(url: url, method: .post, parameters: parameters, encoding: URLEncoding.default, session: publicSession)
    }

    // MARK: Authenticated

    func getAsync<T: Decodable>(
        path: String, parameters: [String: Any]? = nil, responseType: T.Type
    ) async throws -> T {
        let url = makeURL(path)
        print("[APIManager] GET \(url)")
        return try await request(url: url, method: .get, parameters: parameters, encoding: URLEncoding.default, session: session)
    }

    func postAsync<T: Decodable>(
        path: String, parameters: [String: Any]? = nil, responseType: T.Type
    ) async throws -> T {
        let url = makeURL(path)
        print("[APIManager] POST \(url)")
        return try await request(url: url, method: .post, parameters: parameters, encoding: JSONEncoding.default, session: session)
    }

    func putAsync<T: Decodable>(
        path: String, parameters: [String: Any]? = nil, responseType: T.Type
    ) async throws -> T {
        let url = makeURL(path)
        print("[APIManager] PUT \(url)")
        return try await request(url: url, method: .put, parameters: parameters, encoding: JSONEncoding.default, session: session)
    }

    func deleteAsync<T: Decodable>(
        path: String, parameters: [String: Any]? = nil, responseType: T.Type
    ) async throws -> T {
        let url = makeURL(path)
        print("[APIManager] DELETE \(url)")
        return try await request(url: url, method: .delete, parameters: parameters, encoding: URLEncoding.default, session: session)
    }

    // MARK: Private

    private func request<T: Decodable>(
        url: URL, method: HTTPMethod, parameters: [String: Any]?, encoding: ParameterEncoding, session: Session
    ) async throws -> T {
        try await withCheckedThrowingContinuation { cont in
            var c: AnyCancellable?
            c = session.request(url, method: method, parameters: parameters, encoding: encoding)
                .validate()
                .publishDecodable(type: T.self, decoder: jsonDecoder)
                .tryMap { r in
                    if let data = r.data, let raw = String(data: data, encoding: .utf8) {
                        print("[APIManager] ✓ \(url.lastPathComponent): \(raw.prefix(3000))")
                    }
                    switch r.result {
                    case .success(let v): return v
                    case .failure(let e): throw APIError(from: e, data: r.data)
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
