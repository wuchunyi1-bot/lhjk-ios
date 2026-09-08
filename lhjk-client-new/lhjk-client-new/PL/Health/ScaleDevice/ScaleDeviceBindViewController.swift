import Combine
import SnapKit
import UIKit

/// 设备绑定 — 对齐 Figma 4449:11712 体脂秤蓝牙搜索界面（波光动态循环效果）
final class ScaleDeviceBindViewController: BaseViewController {

    private let viewModel: ScaleDeviceBindViewModel
    private var cancellables = Set<AnyCancellable>()

    init(
        equipmentTypeId: String,
        bluetoothName: String,
        displayName: String
    ) {
        self.viewModel = ScaleDeviceBindViewModel(
            equipmentTypeId: equipmentTypeId,
            bluetoothName: bluetoothName,
            displayName: displayName
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Components

    /// 状态标题（Figma 16pt Medium #1F2942）
    private let statusLabel = UILabel()
    /// 提示副文案（Figma 12pt Regular #6D7381）
    private let hintLabel = UILabel()
    /// 波光雷达动画容器
    private let rippleWaveView = ScaleRippleWaveView()
    /// 体脂秤中心图标（100×100pt）
    private let scaleIconView = UIImageView()
    /// 失败重试按钮（底部 48pt 圆角主色按钮）
    private let retryButton = UIButton(type: .system)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.start()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewModel.phase == .searching || viewModel.phase == .binding {
            rippleWaveView.startAnimating()
            startScaleBreathing()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        rippleWaveView.stopAnimating()
        stopScaleBreathing()
        if isMovingFromParent || isBeingDismissed {
            viewModel.onLeave()
        }
    }

    deinit {
        viewModel.onLeave()
    }

    // MARK: - Setup UI

    override func setupUI() {
        title = "设备绑定"
        view.backgroundColor = .fdBg

        // 顶栏文字
        statusLabel.font = .fdFont(ofSize: 18, weight: .medium)
        statusLabel.textColor = .fdText
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.text = "蓝牙搜索中，请耐心等待"

        hintLabel.font = .fdFont(ofSize: 14, weight: .regular)
        hintLabel.textColor = UIColor(hexString: "#6D7381")
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 0
        hintLabel.text = "请尽量将手机靠近设备，轻踩唤醒体脂秤"

        // 体脂秤图标（带圆角和自然阴影）
        scaleIconView.image = UIImage(named: "scale_search_device")
        scaleIconView.contentMode = .scaleAspectFit
        scaleIconView.layer.cornerRadius = 8
        scaleIconView.clipsToBounds = true

        // 重新搜索按钮（默认隐藏，仅在 failed 展示）
        retryButton.setTitle("重新搜索", for: .normal)
        retryButton.titleLabel?.font = .fdFont(ofSize: 18, weight: .medium)
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.backgroundColor = .fdPrimary
        retryButton.layer.cornerRadius = 24
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(handleRetry), for: .touchUpInside)

        view.addSubview(rippleWaveView)
        view.addSubview(scaleIconView)
        view.addSubview(statusLabel)
        view.addSubview(hintLabel)
        view.addSubview(retryButton)

        // 约束布局（严格对齐 Figma 4449:11712 视觉比例）
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(35)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        // 中心波光动画区（410×410 覆盖同心圆扩散范围）
        rippleWaveView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(410)
        }

        // 中心体脂秤（100×100pt）
        scaleIconView.snp.makeConstraints { make in
            make.center.equalTo(rippleWaveView)
            make.size.equalTo(100)
        }

        // 底部重试按钮
        retryButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
            make.height.equalTo(48)
        }
    }

    // MARK: - Bind ViewModel

    override func bindViewModel() {
        viewModel.$statusText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.statusLabel.text = text
            }
            .store(in: &cancellables)

        viewModel.$hintText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.hintLabel.text = text
            }
            .store(in: &cancellables)

        viewModel.$phase
            .receive(on: DispatchQueue.main)
            .sink { [weak self] phase in
                self?.apply(phase: phase)
            }
            .store(in: &cancellables)

        viewModel.toastPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showToast(message)
            }
            .store(in: &cancellables)

        viewModel.finishedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self?.popToWeightHost()
                }
            }
            .store(in: &cancellables)
    }

    private func apply(phase: ScaleDeviceBindViewModel.Phase) {
        switch phase {
        case .searching:
            retryButton.isHidden = true
            rippleWaveView.startAnimating()
            startScaleBreathing()
        case .binding:
            retryButton.isHidden = true
            rippleWaveView.startAnimating()
            startScaleBreathing()
        case .failed:
            retryButton.isHidden = false
            rippleWaveView.stopAnimating()
            stopScaleBreathing()
        }
    }

    // MARK: - Scale Breathing Animation

    private func startScaleBreathing() {
        scaleIconView.layer.removeAnimation(forKey: "scaleBreath")
        let breath = CABasicAnimation(keyPath: "transform.scale")
        breath.fromValue = 1.0
        breath.toValue = 1.025
        breath.duration = 1.6
        breath.autoreverses = true
        breath.repeatCount = .infinity
        breath.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        scaleIconView.layer.add(breath, forKey: "scaleBreath")
    }

    private func stopScaleBreathing() {
        scaleIconView.layer.removeAnimation(forKey: "scaleBreath")
        scaleIconView.transform = .identity
    }

    // MARK: - Actions & Navigation

    @objc private func handleRetry() {
        viewModel.retry()
    }

    private func popToWeightHost() {
        guard let nav = navigationController else {
            navigationController?.popViewController(animated: true)
            return
        }
        if let host = nav.viewControllers.first(where: { $0 is WebViewController }) {
            nav.popToViewController(host, animated: true)
        } else {
            nav.popViewController(animated: true)
        }
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}

// MARK: - ScaleRippleWaveView（波光动态循环效果组件）

/// 波光雷达扩散视图：以中心体脂秤为原点，向外持续循环扩散同心柔和光晕
final class ScaleRippleWaveView: UIView {

    private let waveCount = 4
    private let waveDuration: CFTimeInterval = 3.2
    private var waveLayers: [CALayer] = []
    private(set) var isAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        setupWaveLayers()
        setupNotification()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupWaveLayers() {
        // 创建 4 层同心波光图层（初始不可见，靠 staggered 动画按节拍启动）
        for _ in 0..<waveCount {
            let waveLayer = CALayer()
            waveLayer.backgroundColor = UIColor(hexString: "#FF7A50").withAlphaComponent(0.12).cgColor
            waveLayer.borderColor = UIColor(hexString: "#FF7A50").withAlphaComponent(0.25).cgColor
            waveLayer.borderWidth = 0.8
            waveLayer.opacity = 0
            layer.addSublayer(waveLayer)
            waveLayers.append(waveLayer)
        }
    }

    private func setupNotification() {
        // App 切换回前台时，恢复被系统清理的 CoreAnimation
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func handleAppWillEnterForeground() {
        if isAnimating {
            restartAnimations()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let side = min(bounds.width, bounds.height)
        guard side > 0 else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for waveLayer in waveLayers {
            waveLayer.bounds = CGRect(x: 0, y: 0, width: side, height: side)
            waveLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
            waveLayer.cornerRadius = side / 2
        }
        CATransaction.commit()

        if isAnimating && waveLayers.first?.animation(forKey: "rippleWave") == nil {
            restartAnimations()
        }
    }

    func startAnimating() {
        isAnimating = true
        restartAnimations()
    }

    func stopAnimating() {
        isAnimating = false
        for waveLayer in waveLayers {
            waveLayer.removeAllAnimations()
            waveLayer.opacity = 0
        }
    }

    private func restartAnimations() {
        guard bounds.width > 0, bounds.height > 0 else { return }

        let now = CACurrentMediaTime()
        let interval = waveDuration / Double(waveCount)

        for (index, waveLayer) in waveLayers.enumerated() {
            waveLayer.removeAllAnimations()

            // 缩放：从中心体脂秤边缘（约 0.24）自然扩张到最外层（1.02）
            let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
            scaleAnim.fromValue = 0.24
            scaleAnim.toValue = 1.02

            // 透明度：刚扩出时显现，随半径扩大逐渐渐隐至 0
            let opacityAnim = CAKeyframeAnimation(keyPath: "opacity")
            opacityAnim.values = [0.0, 1.0, 0.7, 0.0]
            opacityAnim.keyTimes = [0.0, 0.15, 0.6, 1.0]

            let group = CAAnimationGroup()
            group.animations = [scaleAnim, opacityAnim]
            group.duration = waveDuration
            group.repeatCount = .infinity
            group.beginTime = now + (Double(index) * interval)
            group.timingFunction = CAMediaTimingFunction(controlPoints: 0.22, 1.0, 0.36, 1.0)
            group.isRemovedOnCompletion = false
            group.fillMode = .forwards

            waveLayer.add(group, forKey: "rippleWave")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
