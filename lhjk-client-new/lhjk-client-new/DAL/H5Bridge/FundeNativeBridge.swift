import Foundation
import QuickLook
import UIKit
import WebKit
import Combine

/// H5 ↔ App Bridge — 对齐《H5 宿主接入文档》
///
/// - `FundeBridge`：套餐中间页、保存食谱、文档预览（扁平 JSON）
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
    private var documentPreviewGeneration = 0
    private var documentLoadingAlert: UIAlertController?
    /// Quick Look 不持有 dataSource，必须由 Bridge 强引用到关闭。
    private var documentPreviewSession: DocumentPreviewSession?

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
        documentPreviewGeneration += 1
        documentLoadingAlert?.dismiss(animated: false)
        documentLoadingAlert = nil
        documentPreviewSession = nil
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
        case "saveImageToAlbum":
            handleSaveImageToAlbum(body: body, params: params, callbackId: callbackId)
        case "previewDocument":
            handlePreviewDocument(body: body, params: params)
        case "gotoBuy":
            openServicePackageList()
        case "navigateH5", "openH5", "openH5Page", "openPage":
            if let path = resolveH5Path(body: body, params: params) {
                openAuthenticatedH5Page(path: path)
            }
        case "todoTask":
            openAuthenticatedH5Page(path: "todoTask", title: "健康积分")
        case "myVip":
            openAuthenticatedH5Page(path: "myVip", title: "会员等级")
        case "exchangeMall":
            openAuthenticatedH5Page(path: "exchangeMall", title: "会员兑换")
        case "routeChanged":
            handleRouteChanged(params: params)
        case "localizeDateTimeChrome":
            WebViewSystemChromeLocalizer.localizeVisibleChrome()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                WebViewSystemChromeLocalizer.localizeVisibleChrome()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                WebViewSystemChromeLocalizer.localizeVisibleChrome()
            }
        case "ble.getStatus":
            handleBleGetStatus(params: params, callbackId: callbackId)
        case "ble.openManager":
            handleBleOpenManager(params: params, callbackId: callbackId)
        default:
            reject(callbackId, message: "未知 action: \(action)")
        }
    }

    private func handleRouteChanged(params: [String: Any]) {
        let urlString = Self.stringValue(params["url"])
        let url = urlString.flatMap { URL(string: $0) } ?? webView?.url
        (hostViewController as? WebViewController)?.handleURLChanged(url)
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

    /// 饮食方案「保存食谱到手机」
    private func handleSaveImageToAlbum(body: [String: Any], params: [String: Any], callbackId: String?) {
        let dateTime = Self.stringValue(body["dateTime"])
            ?? Self.stringValue(params["dateTime"])
            ?? ""
        let schemeId = Self.stringValue(body["schemeId"])
            ?? Self.stringValue(params["schemeId"])
            ?? ""
        let fileName = Self.stringValue(body["fileName"])
            ?? Self.stringValue(params["fileName"])
            ?? "食谱清单.png"
        let bizType = Self.stringValue(body["bizType"])
            ?? Self.stringValue(params["bizType"])
            ?? "dietPoster"

        Task { [weak self] in
            guard let self else { return }
            do {
                try await AppContainer.shared.diningSchemeService.saveDietPosterToAlbum(
                    dateTime: dateTime,
                    schemeId: schemeId,
                    bizType: bizType
                )
                await MainActor.run {
                    self.hostViewController?.showToastAlert("已保存到相册", duration: 1.5)
                    self.respond(callbackId, result: ["fileName": fileName])
                }
            } catch let error as DiningSchemeService.DiningSchemeServiceError {
                await MainActor.run {
                    self.presentSavePosterFailure(error)
                    self.reject(callbackId, message: error.localizedDescription)
                }
            } catch {
                await MainActor.run {
                    self.hostViewController?.showToastAlert(error.localizedDescription, duration: 1.5)
                    self.reject(callbackId, message: error.localizedDescription)
                }
            }
        }
    }

    /// 体检报告「查看原件」。无异步回传，失败只在宿主提示。
    private func handlePreviewDocument(body: [String: Any], params: [String: Any]) {
        let fileURLString = Self.stringValue(body["fileUrl"])
            ?? Self.stringValue(params["fileUrl"])
            ?? ""
        let fileName = Self.stringValue(body["fileName"])
            ?? Self.stringValue(params["fileName"])
            ?? "报告原件"
        let fileType = (
            Self.stringValue(body["fileType"])
            ?? Self.stringValue(params["fileType"])
            ?? ""
        ).lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))

        guard let remoteURL = URL(string: fileURLString),
              remoteURL.scheme?.lowercased() == "https" else {
            showDocumentFailure(.invalidAddress)
            return
        }
        guard DocumentPreviewFile.allowedTypes.contains(fileType) else {
            showDocumentFailure(.unsupportedType)
            return
        }

        documentPreviewGeneration += 1
        let generation = documentPreviewGeneration
        showDocumentLoading()
        Task { [weak self] in
            do {
                let localURL = try await DocumentPreviewFile.download(
                    from: remoteURL,
                    displayName: fileName,
                    fileType: fileType
                )
                await MainActor.run {
                    guard let self, generation == self.documentPreviewGeneration else {
                        try? FileManager.default.removeItem(at: localURL)
                        return
                    }
                    self.presentDocumentPreview(
                        localURL: localURL,
                        title: fileName,
                        generation: generation
                    )
                }
            } catch let error as DocumentPreviewError {
                await MainActor.run {
                    guard let self, generation == self.documentPreviewGeneration else { return }
                    self.hideDocumentLoading {
                        self.showDocumentFailure(error)
                    }
                }
            } catch let error as URLError {
                await MainActor.run {
                    guard let self, generation == self.documentPreviewGeneration else { return }
                    self.hideDocumentLoading {
                        self.showDocumentFailure(DocumentPreviewError(urlError: error))
                    }
                }
            } catch {
                await MainActor.run {
                    guard let self, generation == self.documentPreviewGeneration else { return }
                    self.hideDocumentLoading {
                        self.showDocumentFailure(.network)
                    }
                }
            }
        }
    }

    private func showDocumentLoading() {
        guard let host = hostViewController, host.presentedViewController == nil else { return }
        let alert = UIAlertController(title: nil, message: "正在打开文档…", preferredStyle: .alert)
        documentLoadingAlert = alert
        host.present(alert, animated: false)
    }

    private func hideDocumentLoading(completion: (() -> Void)? = nil) {
        let alert = documentLoadingAlert
        documentLoadingAlert = nil
        if let alert, alert.presentingViewController != nil {
            alert.dismiss(animated: false, completion: completion)
        } else {
            completion?()
        }
    }

    private func showDocumentFailure(_ error: DocumentPreviewError) {
        FDToast.show(error.message, duration: 2)
    }

    private func presentDocumentPreview(localURL: URL, title: String, generation: Int) {
        let item = DocumentPreviewItem(fileURL: localURL, title: title)
        guard QLPreviewController.canPreview(item) else {
            try? FileManager.default.removeItem(at: localURL)
            hideDocumentLoading {
                self.showDocumentFailure(.unreadable)
            }
            return
        }
        let session = DocumentPreviewSession(item: item)
        session.onDismiss = { [weak self] in
            guard let self, self.documentPreviewSession === session else { return }
            self.documentPreviewSession = nil
            try? FileManager.default.removeItem(at: localURL)
        }
        documentPreviewSession = session
        let preview = QLPreviewController()
        preview.dataSource = session
        preview.delegate = session
        hideDocumentLoading { [weak self] in
            guard let self, generation == self.documentPreviewGeneration else { return }
            guard let host = self.hostViewController else { return }
            host.present(preview, animated: true)
        }
    }

    private func presentSavePosterFailure(_ error: DiningSchemeService.DiningSchemeServiceError) {
        guard let host = hostViewController else { return }
        if case .photoDenied = error {
            let cancel = UIAlertAction(title: "取消", style: .cancel)
            let settings = UIAlertAction(title: "去设置", style: .default) { _ in
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            host.showAlert(
                title: "无法保存到相册",
                message: error.localizedDescription,
                actions: [cancel, settings]
            )
            return
        }
        host.showToastAlert(error.localizedDescription, duration: 1.5)
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

    /// 成长任务「去购买」→ 原生选择套餐页
    private func openServicePackageList() {
        Router.shared.push("/services/list", params: ["code": ""], from: hostViewController)
    }

    private func resolveH5Path(body: [String: Any], params: [String: Any]) -> String? {
        let raw = Self.stringValue(body["path"])
            ?? Self.stringValue(params["path"])
            ?? Self.stringValue(body["url"])
            ?? Self.stringValue(params["url"])
        return Self.normalizeH5Path(raw)
    }

    private func openAuthenticatedH5Page(path: String, title: String? = nil) {
        let normalized = Self.normalizeH5Path(path)
        guard !normalized.isEmpty else { return }
        let url = H5Config.authenticatedPageURL(path: normalized)
        let enablesWeightBle = FundePageURL.shouldEnableWeightBle(forH5Path: normalized)
        let webVC = WebViewController(
            urlString: url.absoluteString,
            title: title,
            enablesWeightBle: enablesWeightBle
        )
        guard let source = hostViewController else { return }
        if let nav = source.navigationController {
            nav.pushViewController(webVC, animated: true)
        } else {
            source.present(webVC, animated: true)
        }
    }

    private static func normalizeH5Path(_ raw: String?) -> String {
        var path = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if path.hasPrefix("#/") {
            path = String(path.dropFirst(2))
        } else if path.hasPrefix("#") {
            path = String(path.dropFirst())
        }
        if path.hasPrefix("/") {
            path = String(path.dropFirst())
        }
        if let queryIndex = path.firstIndex(of: "?") {
            path = String(path[..<queryIndex])
        }
        return path.trimmingCharacters(in: .whitespacesAndNewlines)
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

private enum DocumentPreviewError: Error {
    case invalidAddress
    case unsupportedType
    case expired
    case http(Int)
    case timeout
    case network
    case empty
    case unreadable

    init(urlError: URLError) {
        switch urlError.code {
        case .timedOut:
            self = .timeout
        default:
            self = .network
        }
    }

    var message: String {
        switch self {
        case .invalidAddress:
            return "无法打开文档，请返回报告重新获取"
        case .unsupportedType:
            return "暂不支持预览该文件"
        case .expired:
            return "链接已过期，请返回报告重新获取"
        case .http(let code):
            return "下载失败（\(code)），请稍后重试"
        case .timeout:
            return "下载超时，请稍后重试"
        case .network:
            return "网络异常，请稍后重试"
        case .empty, .unreadable:
            return "文件无法预览"
        }
    }
}

private enum DocumentPreviewFile {
    static let allowedTypes: Set<String> = ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx"]

    static func download(from remoteURL: URL, displayName: String, fileType: String) async throws -> URL {
        var request = URLRequest(url: remoteURL)
        request.timeoutInterval = 60
        request.httpShouldHandleCookies = false
        let (tempURL, response) = try await URLSession.shared.download(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw DocumentPreviewError.network
        }
        switch http.statusCode {
        case 200...299:
            break
        case 401, 403:
            throw DocumentPreviewError.expired
        default:
            throw DocumentPreviewError.http(http.statusCode)
        }
        let attributes = try FileManager.default.attributesOfItem(atPath: tempURL.path)
        let size = (attributes[.size] as? NSNumber)?.int64Value ?? 0
        guard size > 0 else { throw DocumentPreviewError.empty }

        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FundeDocumentPreview", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appendingPathComponent(storageName(displayName: displayName, fileType: fileType))
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: tempURL, to: destination)
        return destination
    }

    /// 显示名去掉路径字符后作为落盘名，并带上类型扩展名。
    private static func storageName(displayName: String, fileType: String) -> String {
        let forbidden = CharacterSet(charactersIn: "/\\:\u{0}")
        var base = displayName.components(separatedBy: forbidden).joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if base.isEmpty || base == "." || base == ".." {
            base = "报告原件"
        }
        let currentExt = (base as NSString).pathExtension.lowercased()
        if currentExt != fileType {
            if !currentExt.isEmpty {
                base = (base as NSString).deletingPathExtension
            }
            base += ".\(fileType)"
        }
        return "\(UUID().uuidString)-\(base)"
    }
}

private final class DocumentPreviewItem: NSObject, QLPreviewItem {
    let previewItemURL: URL?
    let previewItemTitle: String?

    init(fileURL: URL, title: String) {
        previewItemURL = fileURL
        previewItemTitle = title
        super.init()
    }
}

private final class DocumentPreviewSession: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    let item: DocumentPreviewItem
    var onDismiss: (() -> Void)?

    init(item: DocumentPreviewItem) {
        self.item = item
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        item
    }

    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        onDismiss?()
    }
}
