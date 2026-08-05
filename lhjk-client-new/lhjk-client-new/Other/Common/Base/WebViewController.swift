import UIKit
import WebKit

/// 通用 WebView 页面 — 加载指定 URL，并注入 FundeNative Bridge
final class WebViewController: BaseViewController {

    private let urlString: String
    private let pageTitle: String?
    private weak var previousPopGestureDelegate: UIGestureRecognizerDelegate?

    private var bridge: FundeNativeBridge?
    private var scriptHandlerProxy: WeakScriptMessageHandler?
    private var didLogInitialLayout = false

    // MARK: - UI

    private lazy var webView: WKWebView = {
        let userContent = WKUserContentController()
        let proxy = WeakScriptMessageHandler(target: self)
        self.scriptHandlerProxy = proxy
        userContent.add(proxy, name: FundeNativeBridge.handlerName)

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

    init(urlString: String, title: String? = nil) {
        self.urlString = urlString
        self.pageTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = pageTitle
        setupBackNavigation()
        bridge = FundeNativeBridge(webView: webView, hostViewController: self)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        installPopGestureDelegateIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView.stopLoading()
        restorePopGestureDelegateIfNeeded()
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        view.addSubview(webView)
        view.addSubview(progressView)
        view.addSubview(indicator)

        webView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        progressView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(2)
        }
        indicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
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
        webView.load(URLRequest(url: url))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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

    deinit {
        bridge?.detach()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: FundeNativeBridge.handlerName)
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
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
        guard message.name == FundeNativeBridge.handlerName else { return }
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

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        logNavigationEvent("didCommit", url: webView.url)
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
        // 页面就绪后推一次当前蓝牙状态，便于 H5 横条初始化
        ScaleBleSessionService.shared.publishStatus()
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
            var scripts = Array.from(document.scripts || []).map(function(s) { return s.src || '(inline)'; });
            return {
                readyState: document.readyState,
                title: document.title,
                href: location.href.split('?')[0],
                route: location.origin + location.pathname + hashPath,
                bodyTextLength: document.body ? document.body.innerText.length : 0,
                bodyHTMLLength: document.body ? document.body.innerHTML.length : 0,
                appHTMLLength: app ? app.innerHTML.length : 0,
                scriptCount: scripts.length,
                scriptSrcs: scripts.join('|')
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
        }
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

        components.query = nil
        if let fragment = components.fragment {
            components.fragment = fragment
                .split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
                .first
                .map(String.init)
        }
        return components.string ?? "\(url.scheme ?? "unknown")://\(url.host ?? "unknown")"
    }
}
