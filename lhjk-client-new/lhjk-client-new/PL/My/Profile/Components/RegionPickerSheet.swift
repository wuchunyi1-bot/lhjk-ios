import UIKit
import SnapKit

/// 省市区滚轮选择 — 对齐 Figma 4522:6771；数据来自 Bundle `map.json`
final class RegionPickerSheet: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    enum Mode {
        case provinceCity
        case provinceCityArea
    }

    var onSave: ((RegionSelection) -> Void)?

    private let mode: Mode
    private let fieldTitle: String
    private let sheetTitle: String
    private let regionService = ChinaRegionService.shared

    private var provinceIndex = 0
    private var cityIndex = 0
    private var districtIndex = 0

    private let dimView = UIView()
    private let panel = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .custom)
    private let headerDivider = AddressFormDivider.make()
    private let pickerContainer = UIView()
    private let selectionHighlight = UIView()
    private let saveButton = UIButton(type: .system)
    private let picker = UIPickerView()

    init(
        title: String,
        mode: Mode,
        current: RegionSelection,
        sheetTitle: String? = nil
    ) {
        self.fieldTitle = title
        self.mode = mode
        self.sheetTitle = sheetTitle ?? "选择\(title)"
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
        setupUI()
        syncPickerSelection(animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        stripSystemPickerChrome()
    }

    private func setupUI() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(AddressStyle.modalDimAlpha)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancel)))
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        panel.backgroundColor = .fdSurface
        panel.layer.cornerRadius = AddressStyle.cardRadius
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.clipsToBounds = true
        view.addSubview(panel)
        panel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(320)
        }

        titleLabel.text = sheetTitle
        titleLabel.font = AddressStyle.sheetTitleFont
        titleLabel.textColor = .fdText
        titleLabel.textAlignment = .center

        closeButton.setImage(AddressIcons.closeBig(), for: .normal)
        closeButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)

        saveButton.setTitle("保存", for: .normal)
        saveButton.titleLabel?.font = AddressStyle.buttonFont
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .fdPrimary
        saveButton.layer.cornerRadius = AddressStyle.pickerSaveButtonHeight / 2
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)

        picker.delegate = self
        picker.dataSource = self

        selectionHighlight.backgroundColor = .fdBg
        selectionHighlight.layer.cornerRadius = 20
        selectionHighlight.isUserInteractionEnabled = false

        panel.addSubview(titleLabel)
        panel.addSubview(closeButton)
        panel.addSubview(headerDivider)
        panel.addSubview(pickerContainer)
        panel.addSubview(saveButton)

        pickerContainer.addSubview(selectionHighlight)
        pickerContainer.addSubview(picker)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.size.equalTo(32)
        }

        headerDivider.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(AddressStyle.horizontalInset)
        }

        pickerContainer.snp.makeConstraints { make in
            make.top.equalTo(headerDivider.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(AddressStyle.horizontalInset)
            make.bottom.equalTo(saveButton.snp.top).offset(-16)
        }

        selectionHighlight.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(40)
        }

        picker.snp.makeConstraints { $0.edges.equalToSuperview() }

        saveButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(AddressStyle.horizontalInset)
            make.bottom.equalTo(panel.safeAreaLayoutGuide).offset(-8)
            make.height.equalTo(AddressStyle.pickerSaveButtonHeight)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        stripSystemPickerChrome()
    }

    /// 隐藏 UIPickerView 系统选区条/遮罩，只保留自定义 `selectionHighlight`
    private func stripSystemPickerChrome() {
        guard picker.bounds.height > 0 else { return }
        let wheelMinHeight = picker.bounds.height * 0.85
        picker.backgroundColor = .clear
        for subview in picker.subviews {
            let height = subview.bounds.height
            if height > 0 && height < wheelMinHeight {
                subview.isHidden = true
            } else {
                subview.backgroundColor = .clear
            }
        }
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

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        40
    }

    func pickerView(
        _ pickerView: UIPickerView,
        viewForRow row: Int,
        forComponent component: Int,
        reusing view: UIView?
    ) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.textAlignment = .center
        label.text = self.pickerView(pickerView, titleForRow: row, forComponent: component)

        let selected = row == pickerView.selectedRow(inComponent: component)
        label.font = selected ? AddressStyle.pickerSelectedFont : AddressStyle.pickerNormalFont
        label.textColor = selected ? .fdPrimary : AddressStyle.tertiaryText
        return label
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
        reloadPickerAppearance()
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
        reloadPickerAppearance()
    }

    private func reloadPickerAppearance() {
        let components = numberOfComponents(in: picker)
        for component in 0..<components {
            let rows = pickerView(picker, numberOfRowsInComponent: component)
            for row in 0..<rows {
                if let label = picker.view(forRow: row, forComponent: component) as? UILabel {
                    let selected = row == picker.selectedRow(inComponent: component)
                    label.font = selected ? AddressStyle.pickerSelectedFont : AddressStyle.pickerNormalFont
                    label.textColor = selected ? .fdPrimary : AddressStyle.tertiaryText
                }
            }
        }
        stripSystemPickerChrome()
    }
}
