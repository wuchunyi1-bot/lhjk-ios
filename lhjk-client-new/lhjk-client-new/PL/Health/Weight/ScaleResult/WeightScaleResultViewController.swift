import Combine
import SnapKit
import UIKit

/// 体脂秤体重报告（有阻抗）— 对齐 Figma `5175:12518`
final class WeightScaleResultViewController: BaseViewController {

    private let viewModel: WeightScaleResultViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let summaryView = WeightScaleResultSummaryView()
    private let metricsCard = UIView()
    private let sectionAccent = UIView()
    private let sectionTitleLabel = UILabel()
    private let metricsGrid = UIStackView()
    private let emptyLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let actionsStack = UIStackView()
    private let saveButton = UIButton(type: .custom)
    private let remeasureButton = UIButton(type: .system)
    private let loadingView = UIActivityIndicatorView(style: .medium)

    init(viewModel: WeightScaleResultViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(monitorId: String, preloaded: WeightHomePageDataVO? = nil) {
        self.init(viewModel: WeightScaleResultViewModel(monitorId: monitorId, preloaded: preloaded))
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
        scrollView.backgroundColor = .fdBg

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.alignment = .fill

        setupMetricsCard()
        setupActions()

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

        loadingView.hidesWhenStopped = true
        loadingView.color = .fdPrimary

        view.addSubview(scrollView)
        view.addSubview(loadingView)
        scrollView.addSubview(contentStack)

        contentStack.addArrangedSubview(summaryView)
        contentStack.addArrangedSubview(metricsCard)
        contentStack.addArrangedSubview(emptyLabel)
        contentStack.addArrangedSubview(retryButton)
        contentStack.addArrangedSubview(actionsStack)
        contentStack.setCustomSpacing(28, after: metricsCard)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
            make.width.equalTo(scrollView).offset(-32)
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
                self?.showToastAlert(message, duration: 1.5)
            }
            .store(in: &cancellables)

        viewModel.dismissPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .store(in: &cancellables)
    }

    private func setupMetricsCard() {
        metricsCard.backgroundColor = .fdSurface
        metricsCard.layer.cornerRadius = 16
        metricsCard.clipsToBounds = true

        sectionAccent.backgroundColor = .fdPrimary
        sectionAccent.layer.cornerRadius = 1.5

        sectionTitleLabel.text = "我的指标"
        sectionTitleLabel.font = .fdFont(ofSize: 16, weight: .medium)
        sectionTitleLabel.textColor = .fdText

        metricsGrid.axis = .vertical
        metricsGrid.spacing = 12

        metricsCard.addSubview(sectionAccent)
        metricsCard.addSubview(sectionTitleLabel)
        metricsCard.addSubview(metricsGrid)

        sectionAccent.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalTo(sectionTitleLabel)
            make.width.equalTo(3)
            make.height.equalTo(14)
        }
        sectionTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(sectionAccent.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-12)
        }
        metricsGrid.snp.makeConstraints { make in
            make.top.equalTo(sectionTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    private func setupActions() {
        saveButton.setTitle("保存", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        saveButton.backgroundColor = .fdPrimary
        saveButton.layer.cornerRadius = 25.5
        saveButton.clipsToBounds = true
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)

        remeasureButton.setTitle("重新测量", for: .normal)
        remeasureButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .regular)
        remeasureButton.setTitleColor(.fdSubtext, for: .normal)
        remeasureButton.addTarget(self, action: #selector(handleRemeasure), for: .touchUpInside)

        actionsStack.axis = .vertical
        actionsStack.alignment = .fill
        actionsStack.spacing = 24
        actionsStack.isLayoutMarginsRelativeArrangement = true
        actionsStack.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        actionsStack.addArrangedSubview(saveButton)
        actionsStack.addArrangedSubview(remeasureButton)

        saveButton.snp.makeConstraints { make in
            make.height.equalTo(51)
        }
    }

    private func render() {
        let hasRecord = viewModel.record != nil
        summaryView.isHidden = !hasRecord
        metricsCard.isHidden = !hasRecord
        actionsStack.isHidden = !hasRecord
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
            row.spacing = 12
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
            row.snp.makeConstraints { make in
                make.height.equalTo(WeightScaleResultMetricCardView.preferredHeight)
            }
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
}
