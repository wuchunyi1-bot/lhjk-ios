import Combine
import SnapKit
import UIKit

/// 设备绑定 — 对齐 funde-client BodyScaleConnectView（OKOK 广播搜索 + 服务端绑定）
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

    private let statusLabel = UILabel()
    private let hintLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let retryButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.start()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            viewModel.onLeave()
        }
    }

    deinit {
        viewModel.onLeave()
    }

    override func setupUI() {
        title = "设备绑定"
        view.backgroundColor = .fdBg

        statusLabel.font = .fdH3
        statusLabel.textColor = .fdText
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        hintLabel.font = .fdBody
        hintLabel.textColor = .fdSubtext
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 0

        spinner.color = .fdPrimary
        spinner.hidesWhenStopped = true

        retryButton.setTitle("重新搜索", for: .normal)
        retryButton.titleLabel?.font = .fdBodySemibold
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.backgroundColor = .fdPrimary
        retryButton.layer.cornerRadius = 18
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(handleRetry), for: .touchUpInside)

        view.addSubview(statusLabel)
        view.addSubview(hintLabel)
        view.addSubview(spinner)
        view.addSubview(retryButton)

        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(48)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        spinner.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        retryButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
            make.height.equalTo(50)
        }
    }

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
        case .searching, .binding:
            spinner.startAnimating()
            retryButton.isHidden = true
        case .failed:
            spinner.stopAnimating()
            retryButton.isHidden = false
        }
    }

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
