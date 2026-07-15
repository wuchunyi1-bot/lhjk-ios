import UIKit
import SnapKit

final class ExerciseFoodAddBottomBar: UIView {

    var onConfirm: (() -> Void)?

    private let totalLabel = UILabel()
    private let calorieLabel = UILabel()
    private let confirmButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface

        totalLabel.font = .fdCaption
        totalLabel.textColor = .fdSubtext
        totalLabel.text = "合计"
        calorieLabel.font = .fdNumL
        calorieLabel.textColor = UIColor(hexString: "#FF5B83")
        calorieLabel.text = "0"

        confirmButton.setTitle("确定", for: .normal)
        confirmButton.titleLabel?.font = .fdBodySemibold
        confirmButton.backgroundColor = UIColor(hexString: "#FF406F")
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.layer.cornerRadius = 20
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        addSubview(totalLabel)
        addSubview(calorieLabel)
        addSubview(confirmButton)
        totalLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(8)
        }
        calorieLabel.snp.makeConstraints { make in
            make.leading.equalTo(totalLabel)
            make.top.equalTo(totalLabel.snp.bottom).offset(2)
            make.bottom.equalToSuperview().offset(-8)
        }
        confirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(40)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(selectedCount: Int, totalCalorie: Double) {
        calorieLabel.text = String(format: "%.0f kcal", totalCalorie)
        confirmButton.setTitle(selectedCount > 0 ? "确定(\(selectedCount))" : "确定", for: .normal)
    }

    @objc private func confirmTapped() { onConfirm?() }
}
