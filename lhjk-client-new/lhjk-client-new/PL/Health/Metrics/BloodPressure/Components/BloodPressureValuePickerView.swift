import UIKit
import SnapKit

/// 三列数值选择器 — 收缩压 / 舒张压 / 心率
final class BloodPressureValuePickerView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {

    struct Selection {
        let systolic: Int
        let diastolic: Int
        let heartRate: Int
    }

    private let picker = UIPickerView()
    private let columns: [[String]]
    private let defaultIndexes = [50, 30, 70] // ~90/70/90

    override init(frame: CGRect) {
        var systolic = (40...300).map(String.init)
        var diastolic = (40...300).map(String.init)
        var heart = (20...220).map(String.init)
        columns = [systolic, diastolic, heart]
        super.init(frame: frame)
        backgroundColor = .fdSurface

        let header = UIStackView()
        header.axis = .horizontal
        header.distribution = .fillEqually
        ["收缩压", "舒张压", "心率"].forEach { title in
            let label = UILabel()
            label.text = title
            label.font = .fdCaptionSemibold
            label.textColor = .fdSubtext
            label.textAlignment = .center
            header.addArrangedSubview(label)
        }

        picker.dataSource = self
        picker.delegate = self
        addSubview(header)
        addSubview(picker)

        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(36)
        }
        picker.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(200)
        }

        for (index, row) in defaultIndexes.enumerated() {
            picker.selectRow(row, inComponent: index, animated: false)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func currentSelection() -> Selection? {
        let sys = Int(columns[0][picker.selectedRow(inComponent: 0)]) ?? 0
        let dia = Int(columns[1][picker.selectedRow(inComponent: 1)]) ?? 0
        let hr = Int(columns[2][picker.selectedRow(inComponent: 2)]) ?? 0
        return Selection(systolic: sys, diastolic: dia, heartRate: hr)
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { columns.count }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { columns[component].count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        columns[component][row]
    }
}
