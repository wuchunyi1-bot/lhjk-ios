import Combine
import SnapKit
import UIKit

/// 体脂秤广播测量页 — 中间按钮启停扫描，展示实时/锁定体重
final class ScaleBroadcastMeasureViewController: BaseViewController {

    private let viewModel: ScaleBroadcastMeasureViewModel
    private var cancellables = Set<AnyCancellable>()

    private let statusLabel = UILabel()
    private let weightLabel = UILabel()
    private let unitLabel = UILabel()
    private let detailLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    init(viewModel: ScaleBroadcastMeasureViewModel = ScaleBroadcastMeasureViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        title = "体脂秤测量"
        view.backgroundColor = .fdBg

        statusLabel.font = .fdBody
        statusLabel.textColor = .fdSubtext
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        weightLabel.font = .fdNumXL
        weightLabel.textColor = .fdText
        weightLabel.textAlignment = .center
        weightLabel.adjustsFontSizeToFitWidth = true
        weightLabel.minimumScaleFactor = 0.5

        unitLabel.text = "kg"
        unitLabel.font = .fdH3
        unitLabel.textColor = .fdSubtext

        detailLabel.font = .fdCaption
        detailLabel.textColor = .fdText2
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 2

        actionButton.titleLabel?.font = .fdBodySemibold
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.backgroundColor = .fdPrimary
        actionButton.layer.cornerRadius = 28
        actionButton.addTarget(self, action: #selector(handleActionTap), for: .touchUpInside)

        let weightRow = UIStackView(arrangedSubviews: [weightLabel, unitLabel])
        weightRow.axis = .horizontal
        weightRow.alignment = .lastBaseline
        weightRow.spacing = 8

        view.addSubview(statusLabel)
        view.addSubview(weightRow)
        view.addSubview(detailLabel)
        view.addSubview(actionButton)

        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(48)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        weightRow.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(actionButton.snp.top).offset(-40)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }

        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(actionButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        actionButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(160)
            make.height.equalTo(56)
        }
    }

    override func bindViewModel() {
        viewModel.$statusText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.statusLabel.text = text
            }
            .store(in: &cancellables)

        viewModel.$weightText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.weightLabel.text = text
            }
            .store(in: &cancellables)

        viewModel.$detailText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.detailLabel.text = text
            }
            .store(in: &cancellables)

        viewModel.$buttonTitle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title in
                self?.actionButton.setTitle(title, for: .normal)
                let isStop = title == "停止"
                self?.actionButton.backgroundColor = isStop ? .fdDanger : .fdPrimary
            }
            .store(in: &cancellables)

        viewModel.toastPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showToast(message)
            }
            .store(in: &cancellables)
    }

    @objc private func handleActionTap() {
        viewModel.toggleMeasuring()
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
