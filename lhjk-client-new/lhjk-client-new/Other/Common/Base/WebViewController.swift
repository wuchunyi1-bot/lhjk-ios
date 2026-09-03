import UIKit
import WebKit

/// 通用 WebView 页面 — 加载指定 URL，并注入 FundeBridge / FundeNative
final class WebViewController: BaseViewController {

    private let urlString: String
    private let pageTitle: String?
    private let enablesWeightBle: Bool
    /// WebView 顶部预留高度（如体重蓝牙横条），不含 safe area
    var topContentInset: CGFloat = 0
    private weak var previousPopGestureDelegate: UIGestureRecognizerDelegate?

    private var bridge: FundeNativeBridge?
    private var weightBleCoordinator: WeightScaleBleStatusCoordinator?
    private var scriptHandlerProxy: WeakScriptMessageHandler?
    private var didLogInitialLayout = false
    private var chromeLocalizationTokens: [NSObjectProtocol] = []

    // MARK: - UI

    private lazy var webView: WKWebView = {
        let userContent = WKUserContentController()
        let proxy = WeakScriptMessageHandler(target: self)
        self.scriptHandlerProxy = proxy
        userContent.add(proxy, name: FundeNativeBridge.packageHandlerName)
        userContent.add(proxy, name: FundeNativeBridge.handlerName)

        let routeScriptSource = """
        (function() {
            function notifyRouteChange() {
                try {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.FundeNative) {
                        window.webkit.messageHandlers.FundeNative.postMessage({
                            action: 'routeChanged',
                            params: { url: window.location.href }
                        });
                    }
                } catch(e) {}
            }
            window.addEventListener('hashchange', notifyRouteChange);
            window.addEventListener('popstate', notifyRouteChange);
            var originalPushState = history.pushState;
            if (originalPushState) {
                history.pushState = function() {
                    var result = originalPushState.apply(this, arguments);
                    notifyRouteChange();
                    return result;
                };
            }
            var originalReplaceState = history.replaceState;
            if (originalReplaceState) {
                history.replaceState = function() {
                    var result = originalReplaceState.apply(this, arguments);
                    notifyRouteChange();
                    return result;
                };
            }
            document.addEventListener('focusin', function(e) {
                var target = e.target;
                if (!target || !target.getAttribute) { return; }
                var type = (target.getAttribute('type') || '').toLowerCase();
                if (type === 'time' || type === 'date' || type === 'datetime-local') {
                    try {
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.FundeNative) {
                            window.webkit.messageHandlers.FundeNative.postMessage({
                                action: 'localizeDateTimeChrome'
                            });
                        }
                    } catch (err) {}
                }
            }, true);
        })();
        """
        let userScript = WKUserScript(
            source: routeScriptSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        userContent.addUserScript(userScript)

        let config = WKWebViewConfiguration()
        config.userContentController = userContent
        if #available(iOS 14.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        wv.allowsBackForwardNavigationGestures = true
        wv.scrollView.contentInsetAdjustmentBehavior = .never
        return wv
    }()

    private let progressView: UIProgressView = {
        let p = UIProgressView(progressViewStyle: .default)
        p.trackTintColor = .clear
        p.progressTintColor = .fdPrimary
        return p
    }()

    private let indicator: UIActivityIndicatorView = {
        let i: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            i = UIActivityIndicatorView(style: .medium)
        } else {
            i = UIActivityIndicatorView(style: .gray)
        }
        i.hidesWhenStopped = true
        return i
    }()

    // MARK: - Init

    init(urlString: String, title: String? = nil, enablesWeightBle: Bool = false) {
        self.urlString = H5Config.normalizedH5URLString(urlString)
        self.pageTitle = title
        let impliesWeight = Self.urlImpliesWeightMetric(self.urlString)
        self.enablesWeightBle = enablesWeightBle || impliesWeight
        super.init(nibName: nil, bundle: nil)
        if self.enablesWeightBle {
            let isInitialWeightHome = Self.isWeightHomePageURL(URL(string: self.urlString))
            topContentInset = isInitialWeightHome ? WeightScaleBleStatusCoordinator.topContentInset : 0
            let coordinator = WeightScaleBleStatusCoordinator()
            coordinator.setVisible(isInitialWeightHome)
            weightBleCoordinator = coordinator
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = pageTitle
        setupBackNavigation()
        bridge = FundeNativeBridge(
            webView: webView,
            hostViewController: self,
            enablesWeightBle: enablesWeightBle
        )
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: [.new, .old], context: nil)
        installSystemChromeLocalization()
    }

    private func installSystemChromeLocalization() {
        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            UIResponder.keyboardWillShowNotification,
            UIResponder.keyboardDidShowNotification,
            UITextField.textDidBeginEditingNotification,
        ]
        chromeLocalizationTokens = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { _ in
                WebViewSystemChromeLocalizer.localizeVisibleChrome()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    WebViewSystemChromeLocalizer.localizeVisibleChrome()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    WebViewSystemChromeLocalizer.localizeVisibleChrome()
                }
            }
        }
    }

    private func refreshSystemChromeLocalization() {
        WebViewSystemChromeLocalizer.localizeVisibleChrome()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        installPopGestureDelegateIfNeeded()
        weightBleCoordinator?.onAppear()
        refreshSystemChromeLocalization()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView.stopLoading()
        restorePopGestureDelegateIfNeeded()
        weightBleCoordinator?.onDisappear(isLeaving: isMovingFromParent || isBeingDismissed)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if enablesWeightBle {
            weightBleCoordinator?.bringStatusBarToFront(on: view)
        }
        guard !didLogInitialLayout else { return }
        didLogInitialLayout = true
        logNavigationEvent(
            "initialLayout",
            params: [
                "viewBounds": "\(view.bounds)",
                "webViewFrame": "\(webView.frame)",
                "safeAreaInsets": "\(view.safeAreaInsets)",
            ]
        )
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        view.addSubview(webView)
        view.addSubview(progressView)
        view.addSubview(indicator)

        webView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(topContentInset)
        }
        progressView.snp.makeConstraints { make in
            if enablesWeightBle {
                make.top.equalTo(view.safeAreaLayoutGuide).offset(topContentInset)
            } else {
                make.top.equalTo(view.safeAreaLayoutGuide)
            }
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(2)
        }
        indicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        if enablesWeightBle {
            weightBleCoordinator?.install(in: self)
        }

        guard let url = URL(string: urlString) else {
            logNavigationEvent(
                "invalidURL",
                params: ["rawLength": urlString.count]
            )
            return
        }
        logNavigationEvent(
            "loadRequest",
            url: url,
            params: [
                "webViewFrame": "\(webView.frame)",
                "allowsJavaScript": webView.configuration.defaultWebpagePreferences.allowsContentJavaScript,
            ]
        )
        indicator.startAnimating()
        var request = URLRequest(url: url)
        if Self.shouldBypassCache(for: url) {
            request.cachePolicy = .reloadIgnoringLocalCacheData
            logNavigationEvent(
                "loadRequestBypassCache",
                url: url,
                params: ["reason": "h5-host"]
            )
        }
        webView.load(request)
    }

    /// H5 部署后 hash 文件名会变；WKWebView 若缓存旧 index.html 会引用已删除的 JS，nginx 回退 HTML 导致白屏。
    private static func shouldBypassCache(for url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("lianhaojiankang.com") || host.hasSuffix(".lhjk.com")
    }

    deinit {
        chromeLocalizationTokens.forEach { NotificationCenter.default.removeObserver($0) }
        bridge?.detach()
        let controller = webView.configuration.userContentController
        controller.removeScriptMessageHandler(forName: FundeNativeBridge.packageHandlerName)
        controller.removeScriptMessageHandler(forName: FundeNativeBridge.handlerName)
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.url))
    }

    private static func urlImpliesWeightMetric(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        let fragment = url.fragment ?? ""
        let path = fragment.split(separator: "?", maxSplits: 1).first.map(String.init) ?? ""
        return FundePageURL.isWeightH5Path(path)
    }

    /// 判断 URL 是否为体重 H5 首页（`#/weight`）
    static func isWeightHomePageURL(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        let rawPath: String
        if let fragment = url.fragment, !fragment.isEmpty {
            let withoutHash = fragment.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            rawPath = withoutHash.components(separatedBy: "?").first ?? ""
        } else {
            rawPath = url.path
        }
        let normalized = rawPath
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return normalized == "weight"
    }

    func handleURLChanged(_ url: URL?) {
        updateWeightBleVisibility(for: url)
    }

    /// 根据当前 web 页面路由动态控制体重蓝牙横条显示/隐藏及蓝牙开关
    func updateWeightBleVisibility(for url: URL?) {
        guard enablesWeightBle, let coordinator = weightBleCoordinator else { return }
        let isWeightHome = Self.isWeightHomePageURL(url)
        coordinator.setVisible(isWeightHome)

        let targetInset: CGFloat = isWeightHome ? WeightScaleBleStatusCoordinator.topContentInset : 0
        guard topContentInset != targetInset else { return }
        topContentInset = targetInset

        guard isViewLoaded else { return }
        webView.snp.updateConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(targetInset)
        }
        progressView.snp.updateConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(targetInset)
        }
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    // MARK: - Back Navigation

    private func setupBackNavigation() {
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: .fdNavBack,
            style: .plain,
            target: self,
            action: #selector(handleBackTapped)
        )
    }

    private func installPopGestureDelegateIfNeeded() {
        guard let gesture = navigationController?.interactivePopGestureRecognizer else { return }
        if previousPopGestureDelegate == nil {
            previousPopGestureDelegate = gesture.delegate
        }
        gesture.delegate = self
        gesture.isEnabled = true
    }

    private func restorePopGestureDelegateIfNeeded() {
        guard let gesture = navigationController?.interactivePopGestureRecognizer else { return }
        guard gesture.delegate === self else { return }
        gesture.delegate = previousPopGestureDelegate
        previousPopGestureDelegate = nil
    }

    @objc private func handleBackTapped() {
        handleBackNavigation()
    }

    private func handleBackNavigation() {
        if webView.canGoBack {
            webView.goBack()
            return
        }
        leaveWebViewContainer()
    }

    private func leaveWebViewContainer() {
        if let navigationController,
           navigationController.viewControllers.count > 1,
           navigationController.topViewController === self {
            navigationController.popViewController(animated: true)
            return
        }
        if presentingViewController != nil {
            dismiss(animated: true)
            return
        }
        navigationController?.popViewController(animated: true)
    }

    // MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            let progress = Float(webView.estimatedProgress)
            progressView.progress = progress
            progressView.isHidden = progress >= 1.0
        } else if keyPath == #keyPath(WKWebView.url) {
            updateWeightBleVisibility(for: webView.url)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

// MARK: - WKScriptMessageHandler

extension WebViewController: WKScriptMessageHandler {

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == FundeNativeBridge.packageHandlerName
                || message.name == FundeNativeBridge.handlerName else { return }
        bridge?.handle(message: message.body)
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        logNavigationEvent("didStartProvisionalNavigation", url: webView.url)
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        logNavigationEvent("didReceiveServerRedirect", url: webView.url)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        logNavigationEvent(
            "decidePolicyForAction",
            url: navigationAction.request.url,
            params: ["navigationType": navigationAction.navigationType.rawValue]
        )
        updateWeightBleVisibility(for: navigationAction.request.url ?? webView.url)
        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        let response = navigationResponse.response
        var params: [String: Any?] = [
            "mimeType": response.mimeType ?? "nil",
            "expectedContentLength": response.expectedContentLength,
            "isForMainFrame": navigationResponse.isForMainFrame,
            "webViewURL": Self.redactedURLString(webView.url?.absoluteString),
        ]
        if let httpResponse = response as? HTTPURLResponse {
            params["statusCode"] = httpResponse.statusCode
            params["contentType"] = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "nil"
        }
        logNavigationEvent(
            "decidePolicyForResponse",
            url: response.url,
            params: params
        )
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        logNavigationEvent("didCommit", url: webView.url)
        updateWeightBleVisibility(for: webView.url)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        indicator.stopAnimating()
        logNavigationEvent(
            "didFinish",
            url: webView.url,
            params: [
                "estimatedProgress": webView.estimatedProgress,
                "title": webView.title ?? "nil",
            ]
        )
        updateWeightBleVisibility(for: webView.url)
        refreshSystemChromeLocalization()
        if enablesWeightBle {
            ScaleBleSessionService.shared.publishStatus()
        }
        runDomDiagnostics(webView: webView, label: "domDiagnostics")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self, self.isViewLoaded else { return }
            self.runDomDiagnostics(webView: webView, label: "domDiagnosticsDelayed")
        }
        if title == nil {
            webView.evaluateJavaScript("document.title") { [weak self] result, _ in
                guard let self, let t = result as? String, !t.isEmpty else { return }
                self.title = t
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        indicator.stopAnimating()
        logNavigationFailure("didFail", webView: webView, error: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        indicator.stopAnimating()
        logNavigationFailure("didFailProvisionalNavigation", webView: webView, error: error)
    }

    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        logNavigationEvent(
            "didReceiveAuthenticationChallenge",
            params: [
                "host": challenge.protectionSpace.host,
                "authenticationMethod": challenge.protectionSpace.authenticationMethod,
            ]
        )
        completionHandler(.performDefaultHandling, nil)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension WebViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === navigationController?.interactivePopGestureRecognizer else {
            return true
        }

        if webView.canGoBack {
            webView.goBack()
            return false
        }

        let stackCount = navigationController?.viewControllers.count ?? 0
        return stackCount > 1
    }
}

// MARK: - Diagnostics

private extension WebViewController {

    func runDomDiagnostics(webView: WKWebView, label: String) {
        let diagnosticsScript = """
        (function() {
            var app = document.querySelector('#app');
            var hashPath = (location.hash || '').split('?')[0];
            var scripts = Array.from(document.scripts || []);
            var scriptInfos = scripts.map(function(s) {
                return {
                    src: s.src || '(inline)',
                    type: s.type || 'text/javascript',
                    async: !!s.async,
                    defer: !!s.defer
                };
            });
            var failedScripts = [];
            scripts.forEach(function(s) {
                if (!s.src) return;
                try {
                    if (s.src && !s.src.includes('inline') && document.querySelector('link[href="' + s.src + '"]')) {
                        return;
                    }
                } catch (e) {}
            });
            return {
                readyState: document.readyState,
                title: document.title,
                href: location.href.split('?')[0],
                route: location.origin + location.pathname + hashPath,
                bodyTextLength: document.body ? document.body.innerText.length : 0,
                bodyHTMLLength: document.body ? document.body.innerHTML.length : 0,
                appHTMLLength: app ? app.innerHTML.length : 0,
                appChildCount: app ? app.childElementCount : 0,
                scriptCount: scripts.length,
                scriptSrcs: scripts.map(function(s) { return s.src || '(inline)'; }).join('|'),
                scriptInfos: scriptInfos,
                hasBootSkeleton: !!(document.querySelector('.boot-skeleton')),
                userAgent: navigator.userAgent
            };
        })();
        """
        webView.evaluateJavaScript(diagnosticsScript) { [weak self] result, error in
            guard let self else { return }
            if let error {
                self.logNavigationEvent(
                    "\(label)Failed",
                    url: webView.url,
                    params: ["error": error.localizedDescription]
                )
                return
            }
            self.logNavigationEvent(
                label,
                url: webView.url,
                params: ["result": String(describing: result)]
            )
            self.detectStaleH5Bundle(webView: webView, diagnostics: result, label: label)
        }
    }

    func detectStaleH5Bundle(webView: WKWebView, diagnostics: Any?, label: String) {
        guard let dict = diagnostics as? [String: Any] else { return }
        let appChildCount = dict["appChildCount"] as? Int ?? 0
        let bodyTextLength = dict["bodyTextLength"] as? Int ?? 0
        let hasBootSkeleton = dict["hasBootSkeleton"] as? Bool ?? false
        let scriptSrcs = dict["scriptSrcs"] as? String ?? ""

        guard appChildCount == 0, bodyTextLength == 0, hasBootSkeleton || scriptSrcs.contains(".js") else {
            return
        }

        guard let firstScript = scriptSrcs.split(separator: "|").first(where: { $0.contains(".js") }),
              let scriptURL = URL(string: String(firstScript)) else {
            return
        }

        URLSession.shared.dataTask(with: scriptURL) { [weak self] data, response, error in
            guard let self else { return }
            let mime = (response as? HTTPURLResponse)?.allHeaderFields["Content-Type"] as? String ?? "nil"
            let prefix = data.flatMap { String(data: $0.prefix(32), encoding: .utf8) } ?? "nil"
            let looksLikeHTML = prefix.contains("<!DOCTYPE") || prefix.contains("<html")
            let params: [String: Any?] = [
                "label": label,
                "scriptURL": Self.redactedURLString(scriptURL.absoluteString),
                "contentType": mime,
                "prefix": prefix,
                "looksLikeHTML": looksLikeHTML,
                "hint": looksLikeHTML
                    ? "JS 资源返回了 HTML，多为 H5 发版后缓存了旧 index.html（hash 文件名已失效）"
                    : "SPA 未挂载，请检查 JS 执行错误或 API 失败",
                "sessionError": error?.localizedDescription,
            ]
            DispatchQueue.main.async {
                self.logNavigationEvent("h5BundleSuspect", url: webView.url, params: params)
            }
        }.resume()
    }

    func logNavigationEvent(
        _ event: String,
        url: URL? = nil,
        params: [String: Any?] = [:]
    ) {
        var values = params
        if let url {
            values["url"] = Self.redactedURLString(url.absoluteString)
        }
        DebugLogger.logCall(module: "WebView", function: event, params: values)
    }

    func logNavigationFailure(_ event: String, webView: WKWebView, error: Error) {
        let nsError = error as NSError
        var params: [String: Any?] = [
            "domain": nsError.domain,
            "code": nsError.code,
            "description": nsError.localizedDescription,
            "webViewURL": Self.redactedURLString(webView.url?.absoluteString),
        ]
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            params["underlyingDomain"] = underlying.domain
            params["underlyingCode"] = underlying.code
            params["underlyingDescription"] = underlying.localizedDescription
        }
        logNavigationEvent(event, params: params)
    }

    static func redactedURLString(_ rawURL: String?) -> String {
        guard let rawURL, let url = URL(string: rawURL) else {
            return "<invalid-or-nil-url>"
        }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return "\(url.scheme ?? "unknown")://\(url.host ?? "unknown")"
        }

        components.queryItems = nil

        if let fragment = components.fragment {
            let pathOnly = fragment
                .split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
                .first
                .map(String.init)
            if pathOnly != fragment {
                components.fragment = "\(pathOnly ?? fragment)?<redacted>"
            } else {
                components.fragment = pathOnly
            }
        }
        return components.string ?? "\(url.scheme ?? "unknown")://\(url.host ?? "unknown")"
    }
}
