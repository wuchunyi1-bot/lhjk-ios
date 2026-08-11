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
        let supported: [AVMetadataObject.ObjectType] = [
            .qr, .ean8, .ean13, .code128, .code39, .code93, .pdf417, .aztec, .dataMatrix,
        ]
        metadataOutput.metadataObjectTypes = supported.filter {
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
