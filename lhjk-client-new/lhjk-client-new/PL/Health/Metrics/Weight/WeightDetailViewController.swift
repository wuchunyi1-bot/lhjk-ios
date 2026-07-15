import Combine
import UIKit
import SnapKit

/// 体重详情 — 对齐源项目 `ADWeightDescController`
final class WeightDetailViewController: BaseViewController {

    private let viewModel: WeightDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let timeLabel = UILabel()
    private let statusBadge = UILabel()
    private let weightView = BloodPressureMetricColumnView()
    private let bmiView = BloodPressureMetricColumnView()
    private let pregnancyStack = UIStackView()
    private let adviceTitle = UILabel()
    private let adviceContent = UILabel()
    private let bodyFatGrid = UIStackView()

    init(monitorId: String?) {
        self.viewModel = WeightDetailViewModel(monitorId: monitorId)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        title = "体重详情"
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

        weightView.configure(title: "--", description: "体重", unit: "kg")
        bmiView.configure(title: "--", description: "BMI", unit: "")

        pregnancyStack.axis = .vertical
        pregnancyStack.spacing = 8

        adviceTitle.font = .fdBodySemibold
        adviceTitle.textColor = .fdText
        adviceTitle.text = "健康建议"

        adviceContent.font = .fdCaption
        adviceContent.textColor = .fdText2
        adviceContent.numberOfLines = 0

        bodyFatGrid.axis = .vertical
        bodyFatGrid.spacing = 12
        bodyFatGrid.isHidden = true

        let metricsRow = UIStackView(arrangedSubviews: [weightView, bmiView])
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

        [timeLabel, statusBadge, metricsRow, pregnancyStack, adviceTitle, adviceContent, bodyFatGrid].forEach(card.addSubview)

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
        pregnancyStack.snp.makeConstraints { make in
            make.top.equalTo(metricsRow.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        adviceTitle.snp.makeConstraints { make in
            make.top.equalTo(pregnancyStack.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        adviceContent.snp.makeConstraints { make in
            make.top.equalTo(adviceTitle.snp.bottom).offset(8)
            make.leading.trailing.equalTo(adviceTitle)
        }
        bodyFatGrid.snp.makeConstraints { make in
            make.top.equalTo(adviceContent.snp.bottom).offset(16)
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

    private func apply(_ record: WeightRecord?) {
        timeLabel.text = record?.formattedRecordTime ?? "--"
        weightView.configure(title: record?.weightDisplay ?? "--", description: "体重", unit: "kg")
        bmiView.configure(title: record?.bmiDisplay ?? "--", description: "BMI", unit: "")
        adviceContent.text = record?.description ?? "暂无建议"
        statusBadge.text = " \(record?.monitorResults ?? "") "
        if let hex = record?.color {
            statusBadge.backgroundColor = UIColor(hexString: hex)
        } else {
            statusBadge.backgroundColor = .fdSuccess
        }

        pregnancyStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let status = record?.pregnancyStatusText {
            pregnancyStack.addArrangedSubview(infoRow(title: "孕期状态", value: status))
        }
        if let increased = record?.increasedWeight?.value {
            pregnancyStack.addArrangedSubview(infoRow(title: "已增重", value: "\(increased) kg"))
        }
        if let recommend = record?.recommendStr {
            pregnancyStack.addArrangedSubview(infoRow(title: "推荐增重", value: recommend))
        }
        if let week = record?.weekRecommend?.value {
            pregnancyStack.addArrangedSubview(infoRow(title: "本周推荐", value: "\(week) kg"))
        }
        if let distance = record?.distanceTarget?.value {
            pregnancyStack.addArrangedSubview(infoRow(title: "距目标", value: "\(distance) kg"))
        }

        bodyFatGrid.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let isFatScale = record?.bodyFatScaleMonitor?.value == 1
        bodyFatGrid.isHidden = !isFatScale
        bodyFatGrid.snp.updateConstraints { make in
            make.top.equalTo(adviceContent.snp.bottom).offset(isFatScale ? 16 : 0)
        }
        if isFatScale {
            let row1 = metricRow([
                ("体脂率", record?.bodyFat?.value, "%"),
                ("肌肉量", record?.muscle?.value, "kg"),
                ("体水分", record?.bodyWater?.value, "%"),
            ])
            let row2 = metricRow([
                ("基础代谢", record?.basalMetabolism?.value, "kcal"),
                ("脂肪量", record?.fatVolume?.value, "kg"),
                ("骨量", record?.bone?.value, "kg"),
            ])
            bodyFatGrid.addArrangedSubview(row1)
            bodyFatGrid.addArrangedSubview(row2)
        }
    }

    private func infoRow(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = .fdCaption
        titleLabel.textColor = .fdSubtext
        titleLabel.text = title
        let valueLabel = UILabel()
        valueLabel.font = .fdBody
        valueLabel.textColor = .fdText
        valueLabel.text = value
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        return stack
    }

    private func metricRow(_ items: [(String, String?, String)]) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        for (title, value, unit) in items {
            let column = BloodPressureMetricColumnView()
            column.configure(title: value ?? "--", description: title, unit: unit)
            stack.addArrangedSubview(column)
        }
        return stack
    }

    @objc private func deleteTapped() {
        let alert = UIAlertController(title: "删除记录", message: "确定删除这条体重记录吗？", preferredStyle: .alert)
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
