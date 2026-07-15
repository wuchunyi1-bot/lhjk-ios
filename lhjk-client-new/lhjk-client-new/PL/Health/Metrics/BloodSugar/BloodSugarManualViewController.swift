import Combine
import UIKit
import SnapKit

final class BloodSugarManualViewController: BaseViewController {

    private let viewModel = BloodSugarManualViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let mealTabs = BloodSugarMealTypeTabsView()
    private let valueLabel = UILabel()
    private let tipLabel = UILabel()
    private let dateButton = UIButton(type: .system)
    private let rulerView = MetricRulerView(min: 0, max: 15, step: 0.1, defaultValue: 6.0, labelEvery: 1, unit: "mmol/L")
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
        valueLabel.text = "6.0"

        tipLabel.font = .fdCaption
        tipLabel.textColor = .fdText2
        tipLabel.numberOfLines = 0
        tipLabel.textAlignment = .center

        headCard.addSubview(mealTabs)
        headCard.addSubview(valueLabel)
        headCard.addSubview(tipLabel)
        mealTabs.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(mealTabs.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(8)
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
            self?.viewModel.updateValue(value)
        }

        saveButton.setTitle("保存", for: .normal)
        saveButton.titleLabel?.font = .fdBodySemibold
        saveButton.backgroundColor = UIColor(hexString: "#FF406F")
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
        viewModel.load()

        viewModel.$mealTypes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] types in
                guard let self else { return }
                self.mealTabs.configure(
                    titles: types.compactMap(\.name),
                    selectedIndex: self.viewModel.selectedMealIndex
                )
            }
            .store(in: &cancellables)

        mealTabs.onSelect = { [weak self] index in self?.viewModel.selectMeal(at: index) }

        viewModel.$valueText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in self?.valueLabel.text = text }
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
            .sink { [weak self] result in
                guard let self else { return }
                var params: [String: Any] = ["monitorId": result.monitorId]
                if let sugarId = result.sugarId { params["sugarId"] = sugarId }
                Router.shared.push("/health/metrics/blood-sugar/detail", params: params)
                if var vcs = self.navigationController?.viewControllers {
                    vcs.removeAll { $0 === self }
                    self.navigationController?.setViewControllers(vcs, animated: false)
                }
            }
            .store(in: &cancellables)

        viewModel.duplicateConfirm
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                let alert = UIAlertController(title: "温馨提示", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                alert.addAction(UIAlertAction(title: "确认", style: .default) { _ in
                    self?.viewModel.save(submitTimes: 2)
                })
                self?.present(alert, animated: true)
            }
            .store(in: &cancellables)

        viewModel.toastMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showToast($0) }
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
