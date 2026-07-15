import Combine
import UIKit
import SnapKit

final class BloodSugarDetailViewController: BaseViewController {

    private let viewModel: BloodSugarDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private let timeLabel = UILabel()
    private let mealLabel = UILabel()
    private let statusBadge = UILabel()
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()
    private let adviceContent = UILabel()

    init(monitorId: String?, sugarId: String?) {
        viewModel = BloodSugarDetailViewModel(monitorId: monitorId, sugarId: sugarId)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        title = "血糖详情"
        view.backgroundColor = .fdBg
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "删除", style: .plain, target: self, action: #selector(deleteTapped))

        let topBg = UIView()
        topBg.backgroundColor = UIColor(hexString: "#FFF0F4")

        timeLabel.font = .fdBody
        timeLabel.textColor = .fdText
        mealLabel.font = .fdBodySemibold
        mealLabel.textColor = .fdText
        statusBadge.font = .fdMicroSemibold
        statusBadge.textColor = .white
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 10
        statusBadge.clipsToBounds = true
        valueLabel.font = .systemFont(ofSize: 40, weight: .bold)
        valueLabel.textColor = .fdText
        unitLabel.font = .fdBody
        unitLabel.textColor = .fdSubtext
        unitLabel.text = "mmol/L"
        adviceContent.font = .fdCaption
        adviceContent.textColor = .fdText2
        adviceContent.numberOfLines = 0

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12

        view.addSubview(topBg)
        view.addSubview(card)
        topBg.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(120)
        }
        card.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        [timeLabel, mealLabel, statusBadge, valueLabel, unitLabel, adviceContent].forEach(card.addSubview)
        timeLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }
        mealLabel.snp.makeConstraints { make in
            make.leading.equalTo(timeLabel.snp.trailing).offset(8)
            make.centerY.equalTo(timeLabel)
        }
        statusBadge.snp.makeConstraints { make in
            make.centerY.equalTo(timeLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(50)
        }
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
        }
        unitLabel.snp.makeConstraints { make in
            make.leading.equalTo(valueLabel.snp.trailing).offset(8)
            make.bottom.equalTo(valueLabel).offset(-6)
        }
        adviceContent.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    override func bindViewModel() {
        viewModel.$record
            .receive(on: DispatchQueue.main)
            .sink { [weak self] record in
                guard let record else { return }
                self?.timeLabel.text = record.formattedRecordTime
                self?.mealLabel.text = record.typeRemark
                self?.valueLabel.text = record.valueDisplay
                self?.unitLabel.text = record.unitDisplay
                self?.adviceContent.text = record.description ?? "暂无建议"
                self?.statusBadge.text = " \(record.monitorResults ?? "") "
                if let hex = record.color {
                    self?.statusBadge.backgroundColor = UIColor(hexString: hex)
                } else {
                    self?.statusBadge.backgroundColor = .fdSuccess
                }
            }
            .store(in: &cancellables)

        viewModel.deleteSucceeded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.navigationController?.popViewController(animated: true) }
            .store(in: &cancellables)

        viewModel.toastMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showToast($0) }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.load()
    }

    @objc private func deleteTapped() {
        let alert = UIAlertController(title: "删除记录", message: "确定删除这条血糖记录吗？", preferredStyle: .alert)
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
