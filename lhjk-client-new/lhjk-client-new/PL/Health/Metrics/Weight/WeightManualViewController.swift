import Combine
import UIKit
import SnapKit

/// 手动记录 — 对齐源项目 `ADManualWeightVC`
final class WeightManualViewController: BaseViewController {

    private let viewModel = WeightManualViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let valueLabel = UILabel()
    private let bmiLabel = UILabel()
    private let tipLabel = UILabel()
    private let dateButton = UIButton(type: .system)
    private let rulerView = MetricRulerView(min: 30, max: 200, step: 0.5, defaultValue: 60, labelEvery: 10, unit: "kg")
    private let saveButton = UIButton(type: .system)

    override func setupUI() {
        title = "手动记录"
        view.backgroundColor = UIColor(hexString: "#F1F3F5")

        let scroll = UIScrollView()
        let content = UIView()
        view.addSubview(scroll)
        scroll.addSubview(content)
        scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        content.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        let headCard = UIView()
        headCard.backgroundColor = .fdSurface
        headCard.layer.cornerRadius = 16

        valueLabel.font = .fdNumXL
        valueLabel.textColor = .fdText
        valueLabel.textAlignment = .center
        valueLabel.text = "60.0"

        bmiLabel.font = .fdCaption
        bmiLabel.textColor = .fdSubtext
        bmiLabel.textAlignment = .center

        tipLabel.font = .fdCaption
        tipLabel.textColor = .fdText2
        tipLabel.numberOfLines = 0
        tipLabel.textAlignment = .center

        headCard.addSubview(valueLabel)
        headCard.addSubview(bmiLabel)
        headCard.addSubview(tipLabel)
        valueLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
        }
        bmiLabel.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(bmiLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        let dateCard = UIView()
        dateCard.backgroundColor = .fdSurface
        dateCard.layer.cornerRadius = 12
        dateButton.contentHorizontalAlignment = .left
        dateButton.titleLabel?.font = .fdBody
        dateButton.setTitleColor(.fdText, for: .normal)
        dateButton.addTarget(self, action: #selector(chooseDate), for: .touchUpInside)
        dateCard.addSubview(dateButton)
        dateButton.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let rulerCard = UIView()
        rulerCard.backgroundColor = .fdSurface
        rulerCard.layer.cornerRadius = 16
        rulerCard.addSubview(rulerView)
        rulerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
            make.height.equalTo(100)
        }
        rulerView.onValueChanged = { [weak self] value in
            self?.viewModel.updateWeight(value)
        }

        saveButton.setTitle("保存", for: .normal)
        saveButton.titleLabel?.font = .fdBodySemibold
        saveButton.backgroundColor = UIColor(hexString: "#5AD480")
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 22.5
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        [headCard, dateCard, rulerCard, saveButton].forEach(content.addSubview)
        headCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        dateCard.snp.makeConstraints { make in
            make.top.equalTo(headCard.snp.bottom).offset(12)
            make.leading.trailing.equalTo(headCard)
        }
        rulerCard.snp.makeConstraints { make in
            make.top.equalTo(dateCard.snp.bottom).offset(12)
            make.leading.trailing.equalTo(headCard)
        }
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(rulerCard.snp.bottom).offset(20)
            make.leading.trailing.equalTo(headCard)
            make.height.equalTo(45)
            make.bottom.equalToSuperview().offset(-24)
        }
    }

    override func bindViewModel() {
        viewModel.loadAdvice()

        viewModel.$weightText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in self?.valueLabel.text = text }
            .store(in: &cancellables)

        viewModel.$bmiText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in self?.bmiLabel.text = text }
            .store(in: &cancellables)

        viewModel.$tipText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in self?.tipLabel.text = text }
            .store(in: &cancellables)

        viewModel.$dateText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in self?.dateButton.setTitle(text, for: .normal) }
            .store(in: &cancellables)

        viewModel.saveSucceeded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] monitorId in
                guard let self else { return }
                Router.shared.push("/health/metrics/weight/detail", params: ["monitorId": monitorId])
                if var vcs = navigationController?.viewControllers {
                    vcs.removeAll { $0 === self }
                    navigationController?.setViewControllers(vcs, animated: false)
                }
            }
            .store(in: &cancellables)

        viewModel.toastMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in self?.showToast(message) }
            .store(in: &cancellables)
    }

    @objc private func chooseDate() {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.maximumDate = Date()
        picker.preferredDatePickerStyle = .wheels
        picker.date = viewModel.selectedDate

        let alert = UIAlertController(title: "选择测量时间", message: "\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        alert.view.addSubview(picker)
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 8),
        ])
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.viewModel.updateDate(picker.date)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func saveTapped() { viewModel.save() }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}
