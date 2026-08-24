import UIKit
import SnapKit

/// 验证码倒计时按钮
///
/// - `inline`：输入壳内橙色文字（登录页 Figma）
/// - `pill`：独立胶囊按钮（忘记密码 / 绑定手机号等）
final class VerifyCodeButton: UIButton {

    enum Style {
        case inline
        case pill
    }

    private let countdownDuration = 60
    private(set) var isCountingDown = false
    private var countdown = 0
    private var timer: Timer?
    private let style: Style

    var onRequestCode: (() -> Void)?

    init(style: Style = .inline) {
        self.style = style
        super.init(frame: .zero)
        setupStyle()
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { timer?.invalidate() }

    private func setupStyle() {
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)

        switch style {
        case .inline:
            titleLabel?.font = .fdLoginInput
            backgroundColor = .clear
            contentEdgeInsets = .zero
        case .pill:
            titleLabel?.font = .fdLoginMeta
            layer.cornerRadius = 12
            contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
            snp.makeConstraints { $0.height.equalTo(48) }
        }
        updateToDefaultState()
    }

    @objc private func didTap() {
        guard !isCountingDown else { return }
        onRequestCode?()
    }

    func startCountdown() {
        countdown = countdownDuration
        isCountingDown = true
        updateCountdownState()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

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

    private func updateCountdownState() {
        isEnabled = false
        switch style {
        case .inline:
            setTitleColor(.fdMuted, for: .disabled)
        case .pill:
            backgroundColor = .fdBg2
            setTitleColor(.fdMuted, for: .disabled)
        }
        setTitle("\(countdown)s 后重发", for: .disabled)
    }

    private func updateToDefaultState() {
        isEnabled = true
        setTitleColor(.fdPrimary, for: .normal)
        setTitle("获取验证码", for: .normal)
        if style == .pill {
            backgroundColor = .fdPrimarySoft
        }
    }
}
