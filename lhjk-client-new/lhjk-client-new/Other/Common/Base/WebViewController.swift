import UIKit
import WebKit

/// 通用 WebView 页面 — 加载指定 URL
final class WebViewController: BaseViewController {

    private let urlString: String
    private let pageTitle: String?
    private weak var previousPopGestureDelegate: UIGestureRecognizerDelegate?

    // MARK: - UI

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
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

        guard let url = URL(string: urlString) else { return }
        indicator.startAnimating()
        webView.load(URLRequest(url: url))
    }

    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }

    // MARK: - Back Navigation

    private func setupBackNavigation() {
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
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

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        indicator.stopAnimating()
        if title == nil {
            webView.evaluateJavaScript("document.title") { [weak self] result, _ in
                guard let self, let t = result as? String, !t.isEmpty else { return }
                self.title = t
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        indicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        indicator.stopAnimating()
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
