import Combine
import UIKit
import SnapKit

/// 血压详情 — 对齐源项目 `ADBloodPressureDescController`
final class BloodPressureDetailViewController: BaseViewController {

    private let viewModel: BloodPressureDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let timeLabel = UILabel()
    private let statusBadge = UILabel()
    private let highView = BloodPressureMetricColumnView()
    private let lowView = BloodPressureMetricColumnView()
    private let rateView = BloodPressureMetricColumnView()
    private let adviceTitle = UILabel()
    private let adviceContent = UILabel()
    private let referenceLabel = UILabel()

    init(monitorId: String?) {
        self.viewModel = BloodPressureDetailViewModel(monitorId: monitorId)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        title = "血压详情"
        view.backgroundColor = .fdBg

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "删除",
            style: .plain,
            target: self,
            action: #selector(deleteTapped)
        )

        let topBg = UIView()
        topBg.backgroundColor = UIColor(hexString: "#E8F4FF")

        timeLabel.font = .fdBody
        timeLabel.textColor = .fdText

        statusBadge.font = .fdMicroSemibold
        statusBadge.textColor = .white
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 10
        statusBadge.clipsToBounds = true

        highView.configure(title: "--", description: "收缩压", unit: "mmHg")
        lowView.configure(title: "--", description: "舒张压", unit: "mmHg")
        rateView.configure(title: "--", description: "心率", unit: "次/分")

        adviceTitle.font = .fdBodySemibold
        adviceTitle.textColor = .fdText
        adviceTitle.text = "健康建议"

        adviceContent.font = .fdCaption
        adviceContent.textColor = .fdText2
        adviceContent.numberOfLines = 0

        referenceLabel.font = .fdCaption
        referenceLabel.textColor = .fdMuted
        referenceLabel.numberOfLines = 0
        referenceLabel.text = "正常范围值参考：\n收缩压90-139mmHg，舒张压60-89mmHg"

        let metricsRow = UIStackView(arrangedSubviews: [highView, lowView, rateView])
        metricsRow.axis = .horizontal
        metricsRow.distribution = .fillEqually

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12

        view.addSubview(topBg)
        view.addSubview(scrollView)
        scrollView.addSubview(card)

        topBg.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(120)
        }
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        card.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(scrollView).inset(16)
            make.width.equalTo(scrollView).offset(-32)
            make.bottom.equalToSuperview().offset(-24)
        }

        [timeLabel, statusBadge, metricsRow, adviceTitle, adviceContent, referenceLabel].forEach(card.addSubview)

        timeLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }
        statusBadge.snp.makeConstraints { make in
            make.centerY.equalTo(timeLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(50)
        }
        metricsRow.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(90)
        }
        adviceTitle.snp.makeConstraints { make in
            make.top.equalTo(metricsRow.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        adviceContent.snp.makeConstraints { make in
            make.top.equalTo(adviceTitle.snp.bottom).offset(8)
            make.leading.trailing.equalTo(adviceTitle)
        }
        referenceLabel.snp.makeConstraints { make in
            make.top.equalTo(adviceContent.snp.bottom).offset(12)
            make.leading.trailing.equalTo(adviceTitle)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    override func bindViewModel() {
        viewModel.$record
            .receive(on: DispatchQueue.main)
            .sink { [weak self] record in self?.apply(record) }
            .store(in: &cancellables)

        viewModel.deleteSucceeded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.navigationController?.popViewController(animated: true) }
            .store(in: &cancellables)

        viewModel.toastMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in self?.showToast(message) }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.load()
    }

    private func apply(_ record: BloodPressureRecord?) {
        timeLabel.text = record?.formattedRecordTime ?? "--"
        highView.configure(title: record?.systolicDisplay ?? "--", description: "收缩压", unit: "mmHg")
        lowView.configure(title: record?.diastolicDisplay ?? "--", description: "舒张压", unit: "mmHg")
        rateView.configure(title: record?.heartRateDisplay ?? "--", description: "心率", unit: "次/分")
        adviceContent.text = record?.description ?? "暂无建议"
        statusBadge.text = " \(record?.monitorResults ?? "") "
        if let hex = record?.color {
            statusBadge.backgroundColor = UIColor(hexString: hex)
        } else {
            statusBadge.backgroundColor = .fdSuccess
        }
    }

    @objc private func deleteTapped() {
        let alert = UIAlertController(title: "删除记录", message: "确定删除这条血压记录吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.viewModel.delete()
        })
        present(alert, animated: true)
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}
