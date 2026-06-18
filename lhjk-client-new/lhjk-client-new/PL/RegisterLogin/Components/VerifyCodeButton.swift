import UIKit

/// 验证码倒计时按钮
/// 参考 funde-client: login-code-btn / login-code-btn--sent
///
/// 三态切换:
///   - 默认: "获取验证码" (fdPrimary 文字 + fdPrimarySoft 背景)
///   - 倒计时: "{N}s 后重发" (fdMuted 文字 + fdBg2 背景, disabled)
///   - 结束: "重新获取" (fdPrimary 文字 + fdPrimarySoft 背景, enabled)
final class VerifyCodeButton: UIButton {

    // MARK: - Constants

    private let countdownDuration = 60

    // MARK: - State

    private(set) var isCountingDown = false
    private var countdown = 0
    private var timer: Timer?

    /// 点击获取验证码的回调
    var onRequestCode: (() -> Void)?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Style

    private func setupStyle() {
        titleLabel?.font = .fdCaptionSemibold
        layer.cornerRadius = 12
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        updateToDefaultState()
    }

    // MARK: - Actions

    @objc private func didTap() {
        guard !isCountingDown else { return }
        onRequestCode?()
    }

    /// 开始倒计时（由外部在验证码发送成功后调用）
    func startCountdown() {
        countdown = countdownDuration
        isCountingDown = true
        updateCountdownState()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    /// 停止倒计时（用于异常重置场景）
    func stopCountdown() {
        timer?.invalidate()
        timer = nil
        isCountingDown = false
        updateToDefaultState()
    }

    private func tick() {
        countdown -= 1
        if countdown <= 0 {
            timer?.invalidate()
            timer = nil
            isCountingDown = false
            updateToDefaultState()
            setTitle("重新获取", for: .normal)
        } else {
            updateCountdownState()
        }
    }

    // MARK: - UI State

    private func updateCountdownState() {
        isEnabled = false
        backgroundColor = .fdBg2
        setTitleColor(.fdMuted, for: .disabled)
        setTitle("\(countdown)s 后重发", for: .disabled)
    }

    private func updateToDefaultState() {
        isEnabled = true
        backgroundColor = .fdPrimarySoft
        setTitleColor(.fdPrimary, for: .normal)
        setTitle("获取验证码", for: .normal)
    }
}
