import Foundation
import WebKit
import Combine

/// H5 ↔ App Bridge — 对齐《H5 宿主接入文档》
///
/// - `FundeBridge`：套餐中间页等宿主导航（扁平 `{ action, packageId, hospitalId }`）
/// - `FundeNative`：体重 BLE（`{ action, params, callbackId }`）
/// Native → H5: `window.__fundeBridge.respond|reject|emit`
final class FundeNativeBridge: NSObject {

    /// 与 H5 `IOS_BRIDGE_HANDLER` 一致
    static let packageHandlerName = "FundeBridge"
    static let handlerName = "FundeNative"

    private weak var webView: WKWebView?
    private weak var hostViewController: UIViewController?
    private let enablesWeightBle: Bool
    private var cancellables = Set<AnyCancellable>()

    init(
        webView: WKWebView,
        hostViewController: UIViewController,
        enablesWeightBle: Bool = false
    ) {
        self.webView = webView
        self.hostViewController = hostViewController
        self.enablesWeightBle = enablesWeightBle
        super.init()
        if enablesWeightBle {
            observeScaleSession()
        }
    }

    func detach() {
        cancellables.removeAll()
        webView = nil
        hostViewController = nil
    }

    // MARK: - Message handling

    func handle(message body: Any) {
        guard let dict = Self.dictionary(from: body) else {
            #if DEBUG
            print("[H5Bridge] invalid message body")
            #endif
            return
        }
        let action = dict["action"] as? String ?? ""
        let params = dict["params"] as? [String: Any] ?? [:]
        let callbackId = dict["callbackId"] as? String

        DispatchQueue.main.async { [weak self] in
            self?.dispatch(action: action, params: params, callbackId: callbackId, body: dict)
        }
    }

    private func dispatch(
        action: String,
        params: [String: Any],
        callbackId: String?,
        body: [String: Any]
    ) {
        switch action {
        case "navigatePackageDetail":
            handleNavigatePackageDetail(body: body, params: params)
        case "ble.getStatus":
            handleBleGetStatus(params: params, callbackId: callbackId)
        case "ble.openManager":
            handleBleOpenManager(params: params, callbackId: callbackId)
        default:
            reject(callbackId, message: "未知 action: \(action)")
        }
    }

    /// 文档 `openPackageDetail`：打开 iOS 原生套餐详情
    private func handleNavigatePackageDetail(body: [String: Any], params: [String: Any]) {
        let packageId = Self.stringValue(body["packageId"])
            ?? Self.stringValue(params["packageId"])
            ?? ""
        let hospitalId = Self.stringValue(body["hospitalId"])
            ?? Self.stringValue(params["hospitalId"])
            ?? ""
        openPackageDetail(packageId: packageId, hospitalId: hospitalId)
    }

    private func openPackageDetail(packageId: String, hospitalId: String) {
        let id = packageId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return }
        var routeParams: [String: Any] = ["id": id]
        let hid = hospitalId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !hid.isEmpty {
            routeParams["hospitalId"] = hid
        }
        Router.shared.push("/services/pkg", params: routeParams, from: hostViewController)
    }

    private func handleBleGetStatus(params: [String: Any], callbackId: String?) {
        let metric = (params["metric"] as? String)?.lowercased() ?? "weight"
        guard metric == "weight" else {
            reject(callbackId, message: "暂不支持 metric=\(metric)")
            return
        }
        // 只读状态；会话由体重 H5 宿主 VC 生命周期管理
        respond(callbackId, result: ScaleBleSessionService.shared.statusDictionary(metric: "weight"))
    }

    private func handleBleOpenManager(params: [String: Any], callbackId: String?) {
        let metric = (params["metric"] as? String)?.lowercased() ?? "weight"
        guard metric == "weight" else {
            reject(callbackId, message: "暂不支持 metric=\(metric)")
            return
        }
        Router.shared.push("/health/scale/devices", from: hostViewController)
        respond(callbackId, result: [String: Any]())
    }

    private func observeScaleSession() {
        let service = ScaleBleSessionService.shared

        service.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.emit("ble.statusChange", payload: status.dictionary)
            }
            .store(in: &cancellables)

        service.syncedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                self?.emit("ble.synced", payload: payload)
            }
            .store(in: &cancellables)

        service.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                self?.emit("ble.error", payload: payload)
            }
            .store(in: &cancellables)
    }

    // MARK: - JS invoke

    func respond(_ callbackId: String?, result: Any) {
        guard let callbackId, !callbackId.isEmpty else { return }
        guard let resultJSON = Self.jsonLiteral(result) else { return }
        let idJSON = Self.jsonLiteral(callbackId) ?? "\"\""
        evaluate(
            "(function(){try{var b=window.__fundeBridge;if(b&&typeof b.respond==='function'){b.respond(\(idJSON),\(resultJSON));}}catch(e){}})();"
        )
    }

    func reject(_ callbackId: String?, message: String) {
        guard let callbackId, !callbackId.isEmpty else { return }
        let idJSON = Self.jsonLiteral(callbackId) ?? "\"\""
        let errJSON = Self.jsonLiteral(["message": message]) ?? "{\"message\":\"error\"}"
        evaluate(
            "(function(){try{var b=window.__fundeBridge;if(b&&typeof b.reject==='function'){b.reject(\(idJSON),\(errJSON));}}catch(e){}})();"
        )
    }

    func emit(_ event: String, payload: Any) {
        let eventJSON = Self.jsonLiteral(event) ?? "\"\""
        let payloadJSON = Self.jsonLiteral(payload) ?? "{}"
        evaluate(
            "(function(){try{var b=window.__fundeBridge;if(b&&typeof b.emit==='function'){b.emit(\(eventJSON),\(payloadJSON));}}catch(e){}})();"
        )
    }

    private func evaluate(_ script: String) {
        guard let webView else { return }
        webView.evaluateJavaScript(script) { _, error in
            #if DEBUG
            if let error {
                print("[H5Bridge] evaluateJS error: \(error.localizedDescription)")
            }
            #endif
        }
    }

    // MARK: - JSON helpers

    static func dictionary(from body: Any) -> [String: Any]? {
        if let dict = body as? [String: Any] { return dict }
        if let data = body as? Data,
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return obj
        }
        if let string = body as? String,
           let data = string.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return obj
        }
        return nil
    }

    static func stringValue(_ value: Any?) -> String? {
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        if let int = value as? Int {
            return String(int)
        }
        if let int64 = value as? Int64 {
            return String(int64)
        }
        return nil
    }

    static func jsonLiteral(_ value: Any) -> String? {
        // String 不能作为 JSONSerialization 顶层对象（会抛 NSException，try? 捕不到）
        if let string = value as? String {
            return quoteJSONString(string)
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        if value is NSNull {
            return "null"
        }
        guard JSONSerialization.isValidJSONObject(value) else {
            #if DEBUG
            print("[H5Bridge] invalid JSON object: \(type(of: value))")
            #endif
            return nil
        }
        guard let data = try? JSONSerialization.data(withJSONObject: value),
              let s = String(data: data, encoding: .utf8) else {
            return nil
        }
        return s
    }

    private static func quoteJSONString(_ string: String) -> String {
        var escaped = ""
        escaped.reserveCapacity(string.count + 2)
        for scalar in string.unicodeScalars {
            switch scalar.value {
            case 0x08: escaped += "\\b"
            case 0x0C: escaped += "\\f"
            case 0x0A: escaped += "\\n"
            case 0x0D: escaped += "\\r"
            case 0x09: escaped += "\\t"
            case 0x22: escaped += "\\\""
            case 0x5C: escaped += "\\\\"
            default:
                if scalar.value < 0x20 {
                    escaped += String(format: "\\u%04x", scalar.value)
                } else {
                    escaped.unicodeScalars.append(scalar)
                }
            }
        }
        return "\"\(escaped)\""
    }
}
