import UIKit
import SnapKit

/// 拼图滑块真人验证弹窗
/// 参考 funde-client PRD 3.3: 获取验证码前必须完成滑块验证
///
/// 验证通过后获取一次性 captcha_token，随验证码请求提交后端二次校验。
/// V1.0 使用 mock 实现，V1.1 接入真实验证服务。
final class CaptchaVerifyView: UIView {

    // MARK: - Callbacks

    var onVerifySuccess: ((_ captchaToken: String) -> Void)?
    var onDismiss: (() -> Void)?

    // MARK: - UI Elements

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "安全验证"
        label.font = .fdBodySemibold
        label.textColor = .fdText
        label.textAlignment = .center
        return label
    }()

    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        btn.tintColor = .fdSubtext
        btn.addTarget(self, action: #selector(tapClose), for: .touchUpInside)
        return btn
    }()

    /// 拼图示意区域（V1.0 mock 展示）
    private let puzzleArea: UIView = {
        let view = UIView()
        view.backgroundColor = .fdBg
        view.layer.cornerRadius = 8
        return view
    }()

    private let puzzleHintLabel: UILabel = {
        let label = UILabel()
        label.text = "请拖动滑块完成验证"
        label.font = .fdCaption
        label.textColor = .fdSubtext
        label.textAlignment = .center
        return label
    }()

    /// 滑块轨道
    private let sliderTrack: UIView = {
        let view = UIView()
        view.backgroundColor = .fdBg2
        view.layer.cornerRadius = 20
        return view
    }()

    /// 滑块
    private let sliderThumb: UIView = {
        let view = UIView()
        view.backgroundColor = .fdPrimary
        view.layer.cornerRadius = 20
        return view
    }()

    private let sliderIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "arrow.right"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let sliderHintLabel: UILabel = {
        let label = UILabel()
        label.text = "拖动滑块完成拼图"
        label.font = .fdCaption
        label.textColor = .fdMuted
        label.textAlignment = .center
        return label
    }()

    private lazy var refreshButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        btn.tintColor = .fdSubtext
        btn.addTarget(self, action: #selector(tapRefresh), for: .touchUpInside)
        return btn
    }()

    // MARK: - State

    private var failureCount = 0
    private let maxFailures = 5
    private var isVerifying = false

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        addPanGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.45)

        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(closeButton)
        containerView.addSubview(puzzleArea)
        puzzleArea.addSubview(puzzleHintLabel)
        puzzleArea.addSubview(refreshButton)
        containerView.addSubview(sliderTrack)
        sliderTrack.addSubview(sliderHintLabel)
        sliderTrack.addSubview(sliderThumb)
        sliderThumb.addSubview(sliderIcon)

        containerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(28)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.size.equalTo(28)
        }

        puzzleArea.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(120)
        }

        puzzleHintLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        refreshButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(8)
            make.size.equalTo(28)
        }

        sliderTrack.snp.makeConstraints { make in
            make.top.equalTo(puzzleArea.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().offset(-24)
        }

        sliderHintLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        sliderThumb.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(2)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }

        sliderIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(18)
        }
    }

    // MARK: - Pan Gesture

    private func addPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sliderThumb.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !isVerifying else { return }

        let trackWidth = sliderTrack.bounds.width - sliderThumb.bounds.width - 4
        let translation = gesture.translation(in: sliderTrack)

        switch gesture.state {
        case .changed:
            var newX = 2 + translation.x
            newX = max(2, min(newX, trackWidth))
            sliderThumb.snp.updateConstraints { make in
                make.leading.equalToSuperview().offset(newX)
            }
            sliderHintLabel.alpha = max(0, 1 - (newX / trackWidth))

        case .ended:
            let currentX = sliderThumb.frame.minX - 2
            let progress = currentX / trackWidth

            if progress >= 0.85 {
                verifySuccess()
            } else {
                resetSlider(animated: true)
                failureCount += 1
                if failureCount >= maxFailures {
                    showToast("验证失败次数较多，请刷新后重试")
                } else {
                    showToast("验证未通过，请重新拖动")
                }
            }

        default:
            break
        }
    }

    // MARK: - Verification (Mock)

    private func verifySuccess() {
        isVerifying = true
        sliderThumb.backgroundColor = .fdSuccess

        // Mock: 模拟验证延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            // Generate mock captcha_token
            let token = "captcha_\(UUID().uuidString.prefix(12))"
            self.onVerifySuccess?(token)
        }
    }

    private func resetSlider(animated: Bool) {
        let update = {
            self.sliderThumb.snp.updateConstraints { make in
                make.leading.equalToSuperview().offset(2)
            }
            self.sliderHintLabel.alpha = 1
            self.sliderThumb.backgroundColor = .fdPrimary
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: update)
        } else {
            update()
        }
    }

    // MARK: - Actions

    @objc private func tapClose() {
        onDismiss?()
    }

    @objc private func tapRefresh() {
        failureCount = 0
        resetSlider(animated: false)
        puzzleHintLabel.text = "请拖动滑块完成验证"
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        print("[CaptchaView] Toast: \(message)")
        puzzleHintLabel.text = message
        puzzleHintLabel.textColor = .fdDanger
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.puzzleHintLabel.text = "请拖动滑块完成验证"
            self?.puzzleHintLabel.textColor = .fdSubtext
        }
    }

    /// Reset state when re-presenting
    func reset() {
        failureCount = 0
        isVerifying = false
        resetSlider(animated: false)
        puzzleHintLabel.text = "请拖动滑块完成验证"
        puzzleHintLabel.textColor = .fdSubtext
    }
}
