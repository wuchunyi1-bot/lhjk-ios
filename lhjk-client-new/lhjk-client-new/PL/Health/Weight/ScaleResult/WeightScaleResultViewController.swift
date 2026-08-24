import Combine
import SnapKit
import UIKit

/// 体脂秤体重报告（有阻抗）— 对齐原型 BodyScaleResultView
final class WeightScaleResultViewController: BaseViewController {

    private let viewModel: WeightScaleResultViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let summaryView = WeightScaleResultSummaryView()
    private let sectionTitleLabel = UILabel()
    private let metricsGrid = UIStackView()
    private let emptyLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let remeasureButton = UIButton(type: .system)
    private let loadingView = UIActivityIndicatorView(style: .medium)

    init(viewModel: WeightScaleResultViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(monitorId: String) {
        self.init(viewModel: WeightScaleResultViewModel(monitorId: monitorId))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.load()
    }

    override func setupUI() {
        title = "体重报告"
        view.backgroundColor = .fdBg

        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill

        sectionTitleLabel.text = "我的指标"
        sectionTitleLabel.font = .fdH3
        sectionTitleLabel.textColor = .fdText

        metricsGrid.axis = .vertical
        metricsGrid.spacing = 10

        emptyLabel.font = .fdBody
        emptyLabel.textColor = .fdSubtext
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true

        retryButton.setTitle("重新加载", for: .normal)
        retryButton.titleLabel?.font = .fdBodySemibold
        retryButton.setTitleColor(.fdPrimary, for: .normal)
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(handleRetry), for: .touchUpInside)

        saveButton.setTitle("保存", for: .normal)
        saveButton.titleLabel?.font = .fdBodySemibold
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .fdPrimary
        saveButton.layer.cornerRadius = 16
        saveButton.clipsToBounds = true
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)

        remeasureButton.setTitle("重新测量", for: .normal)
        remeasureButton.titleLabel?.font = .fdBodySemibold
        remeasureButton.setTitleColor(.fdPrimary, for: .normal)
        remeasureButton.backgroundColor = .white
        remeasureButton.layer.cornerRadius = 16
        remeasureButton.layer.borderWidth = 1
        remeasureButton.layer.borderColor = UIColor.fdPrimary.cgColor
        remeasureButton.clipsToBounds = true
        remeasureButton.addTarget(self, action: #selector(handleRemeasure), for: .touchUpInside)

        loadingView.hidesWhenStopped = true
        loadingView.color = .fdPrimary

        view.addSubview(scrollView)
        view.addSubview(loadingView)
        scrollView.addSubview(contentStack)

        contentStack.addArrangedSubview(summaryView)
        contentStack.addArrangedSubview(sectionTitleLabel)
        contentStack.addArrangedSubview(metricsGrid)
        contentStack.addArrangedSubview(emptyLabel)
        contentStack.addArrangedSubview(retryButton)
        contentStack.addArrangedSubview(saveButton)
        contentStack.addArrangedSubview(remeasureButton)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
            make.width.equalTo(scrollView).offset(-32)
        }
        saveButton.snp.makeConstraints { make in
            make.height.equalTo(52)
        }
        remeasureButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func bindViewModel() {
        viewModel.$isLoading
            .combineLatest(viewModel.$isDeleting)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading, deleting in
                if loading || deleting {
                    self?.loadingView.startAnimating()
                } else {
                    self?.loadingView.stopAnimating()
                }
                let enabled = !loading && !deleting
                self?.saveButton.isEnabled = enabled
                self?.remeasureButton.isEnabled = enabled
                self?.saveButton.alpha = enabled ? 1 : 0.5
                self?.remeasureButton.alpha = enabled ? 1 : 0.5
            }
            .store(in: &cancellables)

        viewModel.$record
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.render()
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.emptyLabel.text = message
                self?.emptyLabel.isHidden = message == nil || self?.viewModel.record != nil
                self?.retryButton.isHidden = message == nil || self?.viewModel.record != nil
            }
            .store(in: &cancellables)

        viewModel.toastPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showToast(message)
            }
            .store(in: &cancellables)

        viewModel.dismissPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .store(in: &cancellables)
    }

    private func render() {
        let hasRecord = viewModel.record != nil
        summaryView.isHidden = !hasRecord
        sectionTitleLabel.isHidden = !hasRecord
        metricsGrid.isHidden = !hasRecord
        saveButton.isHidden = !hasRecord
        remeasureButton.isHidden = !hasRecord
        guard hasRecord else { return }

        summaryView.configure(
            weight: viewModel.formattedWeight,
            time: viewModel.formattedTime,
            bodyAge: viewModel.formattedBodyAge,
            bmi: viewModel.formattedBMI,
            bodyFat: viewModel.formattedBodyFat
        )

        metricsGrid.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let items = viewModel.metricItems
        var index = 0
        while index < items.count {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 10
            row.distribution = .fillEqually
            let left = WeightScaleResultMetricCardView()
            left.configure(items[index])
            row.addArrangedSubview(left)
            if index + 1 < items.count {
                let right = WeightScaleResultMetricCardView()
                right.configure(items[index + 1])
                row.addArrangedSubview(right)
            } else {
                let spacer = UIView()
                row.addArrangedSubview(spacer)
            }
            metricsGrid.addArrangedSubview(row)
            index += 2
        }
    }

    @objc private func handleRetry() {
        viewModel.load()
    }

    @objc private func handleSave() {
        viewModel.saveTapped()
    }

    @objc private func handleRemeasure() {
        viewModel.remeasureTapped()
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            alert.dismiss(animated: true)
        }
    }
}
