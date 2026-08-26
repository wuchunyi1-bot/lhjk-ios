import UIKit
import SnapKit

/// 省市区滚轮选择 — 数据来自 Bundle `map.json`
final class RegionPickerSheet: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    enum Mode {
        /// 省 + 市（籍贯）
        case provinceCity
        /// 省 + 市 + 区（现居地区）
        case provinceCityArea
    }

    var onSave: ((RegionSelection) -> Void)?

    private let mode: Mode
    private let fieldTitle: String
    private let regionService = ChinaRegionService.shared

    private var provinceIndex = 0
    private var cityIndex = 0
    private var districtIndex = 0

    private let dimView = UIView()
    private let panel = UIView()
    private let cancelBtn = UIButton(type: .system)
    private let titleLbl = UILabel()
    private let saveBtn = UIButton(type: .system)
    private let picker = UIPickerView()

    init(title: String, mode: Mode, current: RegionSelection) {
        self.fieldTitle = title
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        applyInitialSelection(current)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        regionService.loadIfNeeded()

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancel)))
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        panel.backgroundColor = .fdSurface
        panel.layer.cornerRadius = 16
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(panel)

        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.setTitleColor(.fdSubtext, for: .normal)
        cancelBtn.titleLabel?.font = .fdMyBody
        cancelBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)

        titleLbl.text = "选择\(fieldTitle)"
        titleLbl.font = .fdMyBodySemibold
        titleLbl.textColor = .fdText
        titleLbl.textAlignment = .center

        saveBtn.setTitle("确定", for: .normal)
        saveBtn.setTitleColor(UIColor(hexString: "#3D6FB8"), for: .normal)
        saveBtn.titleLabel?.font = .fdMyBodySemibold
        saveBtn.addTarget(self, action: #selector(save), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [cancelBtn, titleLbl, saveBtn])
        header.axis = .horizontal
        header.distribution = .equalCentering
        header.alignment = .center
        panel.addSubview(header)

        let divider = UIView()
        divider.backgroundColor = .fdBorder
        panel.addSubview(divider)

        picker.delegate = self
        picker.dataSource = self
        panel.addSubview(picker)

        header.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(36)
        }
        cancelBtn.snp.makeConstraints { $0.width.greaterThanOrEqualTo(44) }
        saveBtn.snp.makeConstraints { $0.width.greaterThanOrEqualTo(44) }
        divider.snp.makeConstraints {
            $0.top.equalTo(header.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
        picker.snp.makeConstraints {
            $0.top.equalTo(divider.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(216)
            $0.bottom.equalTo(panel.safeAreaLayoutGuide).offset(-8)
        }
        panel.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }

        syncPickerSelection(animated: false)
    }

    // MARK: - UIPickerView

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        mode == .provinceCity ? 2 : 3
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0: return regionService.provinceNames().count
        case 1: return regionService.cityNames(provinceIndex: provinceIndex).count
        case 2: return regionService.districtNames(provinceIndex: provinceIndex, cityIndex: cityIndex).count
        default: return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            let names = regionService.provinceNames()
            return names.indices.contains(row) ? names[row] : nil
        case 1:
            let names = regionService.cityNames(provinceIndex: provinceIndex)
            return names.indices.contains(row) ? names[row] : nil
        case 2:
            let names = regionService.districtNames(provinceIndex: provinceIndex, cityIndex: cityIndex)
            return names.indices.contains(row) ? names[row] : nil
        default: return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            provinceIndex = row
            cityIndex = 0
            districtIndex = 0
            pickerView.reloadComponent(1)
            if mode == .provinceCityArea {
                pickerView.reloadComponent(2)
            }
            pickerView.selectRow(0, inComponent: 1, animated: true)
            if mode == .provinceCityArea {
                pickerView.selectRow(0, inComponent: 2, animated: true)
            }
        case 1:
            cityIndex = row
            districtIndex = 0
            if mode == .provinceCityArea {
                pickerView.reloadComponent(2)
                pickerView.selectRow(0, inComponent: 2, animated: true)
            }
        case 2:
            districtIndex = row
        default:
            break
        }
    }

    // MARK: - Actions

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func save() {
        let selection = regionService.selection(
            provinceIndex: provinceIndex,
            cityIndex: cityIndex,
            districtIndex: districtIndex,
            includeDistrict: mode == .provinceCityArea
        )
        guard !selection.isEmpty else {
            showToastAlert("请选择\(fieldTitle)")
            return
        }
        onSave?(selection)
        dismiss(animated: true)
    }

    // MARK: - Private

    private func applyInitialSelection(_ current: RegionSelection) {
        regionService.loadIfNeeded()
        provinceIndex = regionService.provinceIndex(for: current.province)
        cityIndex = regionService.cityIndex(provinceIndex: provinceIndex, cityName: current.city)
        if mode == .provinceCityArea {
            districtIndex = regionService.districtIndex(
                provinceIndex: provinceIndex,
                cityIndex: cityIndex,
                districtName: current.district
            )
        }
    }

    private func syncPickerSelection(animated: Bool) {
        picker.selectRow(provinceIndex, inComponent: 0, animated: animated)
        picker.reloadComponent(1)
        picker.selectRow(cityIndex, inComponent: 1, animated: animated)
        if mode == .provinceCityArea {
            picker.reloadComponent(2)
            picker.selectRow(districtIndex, inComponent: 2, animated: animated)
        }
    }
}
