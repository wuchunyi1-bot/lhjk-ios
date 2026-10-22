import AVFoundation
import UIKit
import SnapKit

// MARK: - Errors

enum QRCodeScannerError: Error, LocalizedError, Equatable {
    case cameraUnavailable
    case permissionDenied
    case permissionRestricted
    case configurationFailed
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "当前设备无法使用相机"
        case .permissionDenied, .notAuthorized:
            return "未获得相机权限，请在设置中开启"
        case .permissionRestricted:
            return "相机权限受限"
        case .configurationFailed:
            return "相机初始化失败"
        }
    }
}

// MARK: - Session (DAL)

/// 二维码 / 条码扫描会话 — 基于系统 AVFoundation，无第三方依赖
final class QRCodeScanner: NSObject {

    private let session = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private let sessionQueue = DispatchQueue(label: "lhjk.qrcode.scanner.session")
    private var isConfigured = false

    /// 识别类型。须在 `prepare` / `start` 之前设置。默认含二维码与常见条码。
    var metadataObjectTypes: [AVMetadataObject.ObjectType] = [
        .qr, .ean8, .ean13, .code128, .code39, .code93, .pdf417, .aztec, .dataMatrix,
    ]

    /// 识别到内容（主线程回调）；默认扫到一次后由上层决定是否 stop
    var onCodeScanned: ((String) -> Void)?
    var onFail: ((QRCodeScannerError) -> Void)?

    var previewLayer: AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    var isRunning: Bool { session.isRunning }

    // MARK: - Permission

    static var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    static func requestAccess() async -> Bool {
        switch authorizationStatus {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { cont in
                AVCaptureDevice.requestAccess(for: .video) { cont.resume(returning: $0) }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Lifecycle

    func prepare() {
        sessionQueue.async { [weak self] in
            self?.configureIfNeeded()
        }
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.configureIfNeeded()
            guard self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }

        guard UIImagePickerController.isSourceTypeAvailable(.camera),
              let device = AVCaptureDevice.default(for: .video) else {
            DispatchQueue.main.async { self.onFail?(.cameraUnavailable) }
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .high

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                session.commitConfiguration()
                DispatchQueue.main.async { self.onFail?(.configurationFailed) }
                return
            }
            session.addInput(input)
        } catch {
            session.commitConfiguration()
            DispatchQueue.main.async { self.onFail?(.configurationFailed) }
            return
        }

        guard session.canAddOutput(metadataOutput) else {
            session.commitConfiguration()
            DispatchQueue.main.async { self.onFail?(.configurationFailed) }
            return
        }
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        let requested = metadataObjectTypes.isEmpty ? [.qr] : metadataObjectTypes
        metadataOutput.metadataObjectTypes = requested.filter {
            metadataOutput.availableMetadataObjectTypes.contains($0)
        }

        session.commitConfiguration()
        isConfigured = true
    }
}

extension QRCodeScanner: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return }
        onCodeScanned?(value)
    }
}

// MARK: - Scan Page (可复用 UI，放在 DAL 供各业务 present/push)

/// 全屏扫码页 — 对齐常见「扫描二维码」交互
final class QRCodeScanViewController: UIViewController {

    /// 扫码成功回调（已 stop）；调用方负责 dismiss/pop 与业务解析
    var onScanResult: ((String) -> Void)?
    /// 用户取消
    var onCancel: (() -> Void)?

    private let scanner = QRCodeScanner()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var didEmitResult = false

    private let overlay = QRCodeScanOverlayView()
    private let tipLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationItem.title = "扫描二维码"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "关闭",
            style: .plain,
            target: self,
            action: #selector(tapClose)
        )

        tipLabel.text = "将二维码放入框内，即可自动扫描"
        tipLabel.font = .fdCaption
        tipLabel.textColor = .white
        tipLabel.textAlignment = .center
        tipLabel.numberOfLines = 0

        view.addSubview(overlay)
        view.addSubview(tipLabel)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        tipLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        scanner.onCodeScanned = { [weak self] code in
            self?.handleScanned(code)
        }
        scanner.onFail = { [weak self] error in
            self?.showError(error.localizedDescription)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        didEmitResult = false
        Task { [weak self] in
            guard let self else { return }
            let granted = await QRCodeScanner.requestAccess()
            await MainActor.run {
                if granted {
                    self.attachPreviewIfNeeded()
                    self.scanner.start()
                } else {
                    self.showError(QRCodeScannerError.permissionDenied.localizedDescription)
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scanner.stop()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func attachPreviewIfNeeded() {
        guard previewLayer == nil else { return }
        let layer = scanner.previewLayer
        layer.frame = view.bounds
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
        scanner.prepare()
    }

    private func handleScanned(_ code: String) {
        guard !didEmitResult else { return }
        didEmitResult = true
        scanner.stop()
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        let result = code
        let callback = onScanResult
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
            // 等返回绑定页后再回填，避免输入框尚未可见
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                callback?(result)
            }
        } else {
            dismiss(animated: true) {
                callback?(result)
            }
        }
    }

    @objc private func tapClose() {
        scanner.stop()
        onCancel?()
        dismissOrPop()
    }

    private func dismissOrPop() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func showError(_ message: String) {
        tipLabel.text = message
        tipLabel.textColor = .fdDanger
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default) { [weak self] _ in
            self?.tapClose()
        })
        if presentedViewController == nil {
            present(alert, animated: true)
        }
    }
}

// MARK: - Overlay

private final class QRCodeScanOverlayView: UIView {

    private let windowSize: CGFloat = 240

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError() }

    func scanWindowFrame(in bounds: CGRect) -> CGRect {
        let x = (bounds.width - windowSize) / 2
        let y = (bounds.height - windowSize) / 2 - 20
        return CGRect(x: x, y: y, width: windowSize, height: windowSize)
    }

    override func draw(_ rect: CGRect) {
        let window = scanWindowFrame(in: bounds)
        let path = UIBezierPath(rect: bounds)
        let hole = UIBezierPath(roundedRect: window, cornerRadius: 8)
        path.append(hole)
        path.usesEvenOddFillRule = true
        UIColor.black.withAlphaComponent(0.55).setFill()
        path.fill()

        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let color = UIColor.fdPrimary.cgColor
        ctx.setStrokeColor(color)
        ctx.setLineWidth(3)
        let len: CGFloat = 22
        strokeCorner(ctx, from: CGPoint(x: window.minX, y: window.minY + len), to: CGPoint(x: window.minX, y: window.minY), then: CGPoint(x: window.minX + len, y: window.minY))
        strokeCorner(ctx, from: CGPoint(x: window.maxX - len, y: window.minY), to: CGPoint(x: window.maxX, y: window.minY), then: CGPoint(x: window.maxX, y: window.minY + len))
        strokeCorner(ctx, from: CGPoint(x: window.minX, y: window.maxY - len), to: CGPoint(x: window.minX, y: window.maxY), then: CGPoint(x: window.minX + len, y: window.maxY))
        strokeCorner(ctx, from: CGPoint(x: window.maxX - len, y: window.maxY), to: CGPoint(x: window.maxX, y: window.maxY), then: CGPoint(x: window.maxX, y: window.maxY - len))
    }

    private func strokeCorner(
        _ ctx: CGContext,
        from: CGPoint,
        to: CGPoint,
        then: CGPoint
    ) {
        ctx.beginPath()
        ctx.move(to: from)
        ctx.addLine(to: to)
        ctx.addLine(to: then)
        ctx.strokePath()
    }
}

// MARK: - H5 scanCode（鹰瞳眼底）

enum H5ScanCodeOutcome {
    case success(String)
    case cancel
    case fail(String)
}

/// 全屏「扫一扫」。对齐原型 `ScanView`：相机取景、白角扫描框、扫描线。只从相机识别，不提供相册。
final class H5ScanCodeViewController: UIViewController {

    /// H5 `scanType`，如 `qrCode`。空则只扫二维码。
    var scanTypes: [String] = ["qrCode"]
    var onFinish: ((H5ScanCodeOutcome) -> Void)?

    private let scanner = QRCodeScanner()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let overlay = H5ScanCodeFrameView()
    private let tipLabel = UILabel()
    private var didFinish = false
    private var didSaveBarStyle = false
    private var savedBarStyle: UIBarStyle = .default
    private var savedTranslucent = false
    private var savedTintColor: UIColor?
    private var savedStandardAppearance: UINavigationBarAppearance?
    private var savedScrollEdgeAppearance: UINavigationBarAppearance?
    private var savedCompactAppearance: UINavigationBarAppearance?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationItem.title = "扫一扫"
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.fdNavBack,
            style: .plain,
            target: self,
            action: #selector(tapBack)
        )
        navigationItem.leftBarButtonItem?.tintColor = .white

        tipLabel.text = "将二维码放入框内，即可自动扫描"
        tipLabel.font = .fdBody
        tipLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        tipLabel.textAlignment = .center
        tipLabel.numberOfLines = 0

        view.addSubview(overlay)
        view.addSubview(tipLabel)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        tipLabel.snp.makeConstraints {
            $0.top.equalTo(overlay.frameGuide.snp.bottom).offset(28)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        scanner.metadataObjectTypes = Self.metadataTypes(for: scanTypes)
        scanner.onCodeScanned = { [weak self] code in
            self?.finish(.success(code), dismiss: true)
        }
        scanner.onFail = { [weak self] error in
            self?.finish(.fail(Self.failMessage(for: error)), dismiss: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyNavigationChrome()
        guard !didFinish else { return }
        Task { [weak self] in
            guard let self else { return }
            let granted = await QRCodeScanner.requestAccess()
            await MainActor.run {
                guard !self.didFinish, self.view.window != nil else { return }
                if granted {
                    self.attachPreviewIfNeeded()
                    self.scanner.start()
                } else {
                    self.finish(.fail(Self.permissionFailMessage()), dismiss: true)
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scanner.stop()
        restoreNavigationChrome()
        guard !didFinish, isMovingFromParent || isBeingDismissed else { return }
        if let coordinator = transitionCoordinator, coordinator.isInteractive {
            coordinator.notifyWhenInteractionChanges { [weak self] context in
                guard let self, !self.didFinish else { return }
                if context.isCancelled {
                    self.applyNavigationChrome()
                    self.scanner.start()
                } else {
                    self.finish(.cancel, dismiss: false)
                }
            }
        } else {
            finish(.cancel, dismiss: false)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    @objc private func tapBack() {
        finish(.cancel, dismiss: true)
    }

    private func finish(_ outcome: H5ScanCodeOutcome, dismiss: Bool) {
        guard !didFinish else { return }
        didFinish = true
        scanner.stop()
        if case .success = outcome {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        let callback = onFinish
        onFinish = nil
        let deliver = { () -> Void in
            if let callback {
                callback(outcome)
            }
        }
        if dismiss {
            leave(completion: deliver)
        } else {
            deliver()
        }
    }

    private func leave(completion: @escaping () -> Void) {
        if let nav = navigationController, nav.topViewController === self, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
            completion()
            return
        }
        if presentingViewController != nil, navigationController?.viewControllers.first === self {
            dismiss(animated: true)
            completion()
            return
        }
        completion()
    }

    private func attachPreviewIfNeeded() {
        guard previewLayer == nil else { return }
        let layer = scanner.previewLayer
        layer.frame = view.bounds
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
        scanner.prepare()
    }

    /// 全局导航栏是浅色底。这里若只把标题和返回改成白色，会和浅色底叠在一起看不见。
    private func applyNavigationChrome() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.fdFont(ofSize: 20, weight: .medium),
        ]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.compactScrollEdgeAppearance = appearance
        navigationItem.leftBarButtonItem?.tintColor = .white
        guard let bar = navigationController?.navigationBar else { return }
        if !didSaveBarStyle {
            savedBarStyle = bar.barStyle
            savedTranslucent = bar.isTranslucent
            savedTintColor = bar.tintColor
            savedStandardAppearance = bar.standardAppearance
            savedScrollEdgeAppearance = bar.scrollEdgeAppearance
            savedCompactAppearance = bar.compactAppearance
            didSaveBarStyle = true
        }
        bar.isTranslucent = false
        bar.barStyle = .black
        bar.tintColor = .white
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
    }

    private func restoreNavigationChrome() {
        guard didSaveBarStyle, let bar = navigationController?.navigationBar else { return }
        bar.barStyle = savedBarStyle
        bar.isTranslucent = savedTranslucent
        bar.tintColor = savedTintColor ?? .fdText
        if let savedStandardAppearance {
            bar.standardAppearance = savedStandardAppearance
        }
        bar.scrollEdgeAppearance = savedScrollEdgeAppearance
        bar.compactAppearance = savedCompactAppearance
    }

    private static func permissionFailMessage() -> String {
        switch QRCodeScanner.authorizationStatus {
        case .restricted:
            return "相机权限受限"
        default:
            return "相机权限被拒绝"
        }
    }

    private static func failMessage(for error: QRCodeScannerError) -> String {
        switch error {
        case .permissionDenied, .notAuthorized:
            return "相机权限被拒绝"
        case .permissionRestricted:
            return "相机权限受限"
        case .cameraUnavailable:
            return "当前设备无法使用相机"
        case .configurationFailed:
            return "相机初始化失败"
        }
    }

    private static func metadataTypes(for scanTypes: [String]) -> [AVMetadataObject.ObjectType] {
        var types: [AVMetadataObject.ObjectType] = []
        for raw in scanTypes {
            switch raw.lowercased() {
            case "qrcode", "qr":
                if !types.contains(.qr) { types.append(.qr) }
            case "barcode":
                for type in [AVMetadataObject.ObjectType.ean8, .ean13, .code128, .code39, .code93] where !types.contains(type) {
                    types.append(type)
                }
            case "datamatrix":
                if !types.contains(.dataMatrix) { types.append(.dataMatrix) }
            case "pdf417":
                if !types.contains(.pdf417) { types.append(.pdf417) }
            default:
                break
            }
        }
        return types.isEmpty ? [.qr] : types
    }
}

/// 扫描框：暗色遮罩、白色四角、主题色扫描线。对齐原型 `ScanView`。
private final class H5ScanCodeFrameView: UIView {

    let frameGuide = UILayoutGuide()
    private let scanLine = UIView()
    private let frameSize: CGFloat = 260
    private var didStartLine = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        isOpaque = false
        addLayoutGuide(frameGuide)
        frameGuide.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-24)
            make.size.equalTo(frameSize)
        }

        scanLine.backgroundColor = .fdPrimary
        scanLine.layer.shadowColor = UIColor.fdPrimary.cgColor
        scanLine.layer.shadowOpacity = 0.5
        scanLine.layer.shadowRadius = 6
        scanLine.layer.shadowOffset = .zero
        addSubview(scanLine)
        scanLine.snp.makeConstraints { make in
            make.leading.equalTo(frameGuide).offset(8)
            make.trailing.equalTo(frameGuide).offset(-8)
            make.top.equalTo(frameGuide).offset(8)
            make.height.equalTo(2)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
        startScanLineIfNeeded()
    }

    override func draw(_ rect: CGRect) {
        let window = frameGuide.layoutFrame
        guard window.width > 1, window.height > 1 else { return }
        let path = UIBezierPath(rect: bounds)
        path.append(UIBezierPath(roundedRect: window, cornerRadius: 4))
        path.usesEvenOddFillRule = true
        UIColor.black.withAlphaComponent(0.55).setFill()
        path.fill()

        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.8).cgColor)
        ctx.setLineWidth(3)
        let len: CGFloat = 24
        strokeCorner(ctx, from: CGPoint(x: window.minX, y: window.minY + len), to: CGPoint(x: window.minX, y: window.minY), then: CGPoint(x: window.minX + len, y: window.minY))
        strokeCorner(ctx, from: CGPoint(x: window.maxX - len, y: window.minY), to: CGPoint(x: window.maxX, y: window.minY), then: CGPoint(x: window.maxX, y: window.minY + len))
        strokeCorner(ctx, from: CGPoint(x: window.minX, y: window.maxY - len), to: CGPoint(x: window.minX, y: window.maxY), then: CGPoint(x: window.minX + len, y: window.maxY))
        strokeCorner(ctx, from: CGPoint(x: window.maxX - len, y: window.maxY), to: CGPoint(x: window.maxX, y: window.maxY), then: CGPoint(x: window.maxX, y: window.maxY - len))
    }

    private func startScanLineIfNeeded() {
        guard !didStartLine, frameGuide.layoutFrame.height > 1 else { return }
        didStartLine = true
        let travel = frameSize - 18
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.fromValue = 0
        animation.toValue = travel
        animation.duration = 2.4
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        scanLine.layer.add(animation, forKey: "scan")
    }

    private func strokeCorner(_ ctx: CGContext, from: CGPoint, to: CGPoint, then: CGPoint) {
        ctx.beginPath()
        ctx.move(to: from)
        ctx.addLine(to: to)
        ctx.addLine(to: then)
        ctx.strokePath()
    }
}
