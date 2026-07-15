import UIKit
import SnapKit
import Kingfisher

/// 数量编辑底部弹层 — 简化版 `ADFoodSelectUnitShowView`
final class ExerciseFoodQuantitySheet: UIViewController {

    struct Result {
        let quantity: Int
        let calorie: String
    }

    var onSave: ((Result) -> Void)?
    var onDelete: (() -> Void)?

    private let item: ExerciseFoodRecordItem
    private let definition: ExerciseFoodDefinitionItem?
    private let isSport: Bool
    private let allowsDelete: Bool

    private let dimView = UIView()
    private let panel = UIView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let valueLabel = UILabel()
    private let rulerView: MetricRulerView
    private let saveButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)

    private var currentQuantity: Int

    init(
        item: ExerciseFoodRecordItem,
        definition: ExerciseFoodDefinitionItem? = nil,
        isSport: Bool,
        allowsDelete: Bool = false
    ) {
        self.item = item
        self.definition = definition
        self.isSport = isSport
        self.allowsDelete = allowsDelete
        let baseQty = item.quantity?.value ?? definition?.quantity?.value ?? 1
        self.currentQuantity = max(baseQty, 1)
        let maxValue = Double(item.maxNum?.value ?? definition?.maxNum?.value ?? (isSport ? 180 : 500))
        let step = Double(item.coefficient?.value ?? definition?.coefficient?.value ?? 1)
        rulerView = MetricRulerView(
            min: step,
            max: maxValue,
            step: step,
            defaultValue: Double(currentQuantity),
            labelEvery: max(step * 10, 10),
            unit: isSport ? "分钟" : "g"
        )
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissTapped)))

        panel.backgroundColor = .fdSurface
        panel.layer.cornerRadius = 16
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 8
        nameLabel.font = .fdBodySemibold
        nameLabel.textColor = .fdText
        nameLabel.text = item.name ?? definition?.name
        valueLabel.font = .fdNumL
        valueLabel.textColor = .fdText
        valueLabel.textAlignment = .center

        saveButton.setTitle("保存", for: .normal)
        saveButton.backgroundColor = UIColor(hexString: "#FF406F")
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 20
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        deleteButton.setTitle("删除", for: .normal)
        deleteButton.setTitleColor(.fdDanger, for: .normal)
        deleteButton.isHidden = !allowsDelete
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        if let urlString = item.imgSmallUrl ?? definition?.imgSmallUrl, let url = URL(string: urlString) {
            iconView.kf.setImage(with: url)
        }

        view.addSubview(dimView)
        view.addSubview(panel)
        [iconView, nameLabel, valueLabel, rulerView, saveButton, deleteButton].forEach(panel.addSubview)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }
        panel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        iconView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
            make.size.equalTo(48)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.centerY.equalTo(iconView)
        }
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }
        rulerView.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(100)
        }
        if allowsDelete {
            deleteButton.snp.makeConstraints { make in
                make.top.equalTo(rulerView.snp.bottom).offset(16)
                make.leading.equalToSuperview().offset(16)
                make.height.equalTo(40)
                make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
            }
            saveButton.snp.makeConstraints { make in
                make.centerY.equalTo(deleteButton)
                make.trailing.equalToSuperview().offset(-16)
                make.leading.equalTo(deleteButton.snp.trailing).offset(12)
                make.height.equalTo(40)
            }
        } else {
            saveButton.snp.makeConstraints { make in
                make.top.equalTo(rulerView.snp.bottom).offset(16)
                make.leading.trailing.equalToSuperview().inset(16)
                make.height.equalTo(40)
                make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
            }
        }

        rulerView.onValueChanged = { [weak self] value in
            self?.currentQuantity = max(Int(value), 1)
            self?.refreshCalorieText()
        }
        refreshCalorieText()
    }

    private func refreshCalorieText() {
        let baseQty = definition?.quantity?.value ?? item.quantity?.value ?? 1
        let baseCal = definition?.showCalorie ?? definition?.calorie?.value
            ?? item.showCalorie ?? item.calorie?.value ?? "0"
        let calorie = ExerciseFoodService.calorie(for: currentQuantity, baseQuantity: baseQty, baseCalorie: baseCal)
        valueLabel.text = "\(currentQuantity) · \(calorie) kcal"
    }

    @objc private func dismissTapped() { dismiss(animated: true) }

    @objc private func saveTapped() {
        let baseQty = definition?.quantity?.value ?? item.quantity?.value ?? 1
        let baseCal = definition?.showCalorie ?? definition?.calorie?.value
            ?? item.showCalorie ?? item.calorie?.value ?? "0"
        let calorie = ExerciseFoodService.calorie(for: currentQuantity, baseQuantity: baseQty, baseCalorie: baseCal)
        onSave?(Result(quantity: currentQuantity, calorie: calorie))
        dismiss(animated: true)
    }

    @objc private func deleteTapped() {
        onDelete?()
        dismiss(animated: true)
    }
}
