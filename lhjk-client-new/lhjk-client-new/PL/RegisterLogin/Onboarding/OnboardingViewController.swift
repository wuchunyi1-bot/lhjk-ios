import UIKit
import SnapKit

/// 基础信息引导页 — 注册后填写姓名、出生日期、性别、所在城市
/// 参考 funde-client: OnboardingView.vue / PRD §5.10 注册后基础信息引导
final class OnboardingViewController: BaseViewController {

    // MARK: - Province / City Data

    private let provinces = ["广东省", "上海市", "北京市", "浙江省", "江苏省"]

    private let cityMap: [String: [String]] = [
        "广东省": ["深圳市", "广州市", "佛山市"],
        "上海市": ["上海市"],
        "北京市": ["北京市"],
        "浙江省": ["杭州市", "宁波市"],
        "江苏省": ["南京市", "苏州市"],
    ]

    // MARK: - State

    private var nameText: String { nameField.textField.text?.trimmingCharacters(in: .whitespaces) ?? "" }
    private var birthDate: Date?
    private var selectedGender = ""
    private var selectedProvince = "广东省"
    private var selectedCity = "深圳市"

    // MARK: - UI — Header

    private let badgeLabel: UILabel = {
        let l = UILabel()
        l.text = "1 分钟完成"
        l.font = .fdCaptionSemibold
        l.textColor = .fdPrimary
        l.backgroundColor = .fdPrimarySoft
        l.textAlignment = .center
        l.layer.cornerRadius = 15
        l.clipsToBounds = true
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "完善基础信息"
        l.font = .fdH2
        l.textColor = .fdText
        return l
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.text = "完善资料，开启您的专属健康管理"
        l.font = .fdCaption
        l.textColor = .fdSubtext
        l.numberOfLines = 0
        return l
    }()

    // MARK: - UI — Form

    private lazy var nameField: LoginFieldView = {
        let f = LoginFieldView(title: "姓名", placeholder: "请输入姓名", sfSymbol: "")
        f.textField.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
        return f
    }()

    // -- Birthday --

    private let birthdayLabel: UILabel = {
        let l = UILabel()
        l.text = "出生日期"
        l.font = .fdCaptionSemibold
        l.textColor = .fdSubtext
        return l
    }()

    private let birthdayShell: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.fdBorder.cgColor
        v.layer.cornerRadius = 12
        return v
    }()

    private lazy var birthdayField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "请选择出生日期"
        tf.font = .fdBody
        tf.textColor = .fdText
        tf.borderStyle = .none
        tf.tintColor = .clear

        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.maximumDate = Date()
        dp.preferredDatePickerStyle = .wheels
        dp.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        tf.inputView = dp

        // Toolbar with Done button
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(dismissDatePicker)),
        ]
        tf.inputAccessoryView = toolbar
        return tf
    }()

    private let ageLabel: UILabel = {
        let l = UILabel()
        l.font = .fdCaption
        l.textColor = .fdPrimary
        l.isHidden = true
        return l
    }()

    // -- Gender --

    private let genderLabel: UILabel = {
        let l = UILabel()
        l.text = "性别"
        l.font = .fdCaptionSemibold
        l.textColor = .fdSubtext
        return l
    }()

    private lazy var maleChip = OptionChipView(label: "男")
    private lazy var femaleChip = OptionChipView(label: "女")
    private var genderGroup: OptionChipGroup?

    // -- City --

    private let cityLabel: UILabel = {
        let l = UILabel()
        l.text = "所在城市"
        l.font = .fdCaptionSemibold
        l.textColor = .fdSubtext
        return l
    }()

    private lazy var cityButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("请选择省市", for: .normal)
        b.setTitleColor(.fdMuted, for: .normal)
        b.titleLabel?.font = .fdBody
        b.backgroundColor = .fdSurface
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.fdBorder.cgColor
        b.layer.cornerRadius = 12
        b.contentHorizontalAlignment = .leading
        b.titleEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 0)
        b.addTarget(self, action: #selector(showCityPicker), for: .touchUpInside)
        return b
    }()

    // MARK: - UI — City Picker (lazy)

    private var cityPickerContainer: UIView?
    private var cityPickerView: UIPickerView?

    // MARK: - UI — Footer

    private let footerBar: UIView = {
        let v = UIView()
        v.backgroundColor = .fdBg
        return v
    }()

    private lazy var saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("保存并继续", for: .normal)
        b.titleLabel?.font = .fdBodyBold
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .fdPrimary
        b.layer.cornerRadius = 18
        b.layer.shadowColor = UIColor.fdPrimary.cgColor
        b.layer.shadowOffset = CGSize(width: 0, height: 6)
        b.layer.shadowRadius = 18
        b.layer.shadowOpacity = 0.32
        b.addTarget(self, action: #selector(saveAndContinue), for: .touchUpInside)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        updateSaveButtonState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 自动聚焦姓名输入框
        if nameText.isEmpty {
            nameField.textField.becomeFirstResponder()
        }
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        // ScrollView
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        let contentView = UIView()
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }

        // ── Header ──

        contentView.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.leading.equalToSuperview().offset(24)
            make.height.equalTo(30)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(badgeLabel.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        contentView.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        // ── Form ──

        let formStack = UIStackView()
        formStack.axis = .vertical
        formStack.spacing = 18
        contentView.addSubview(formStack)
        formStack.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(26)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        // 姓名
        formStack.addArrangedSubview(nameField)

        // 出生日期
        birthdayShell.addSubview(birthdayField)
        birthdayField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
        birthdayShell.snp.makeConstraints { make in
            make.height.equalTo(52)
        }

        let birthdayStack = UIStackView(arrangedSubviews: [birthdayLabel, birthdayShell])
        birthdayStack.axis = .vertical
        birthdayStack.spacing = 9
        formStack.addArrangedSubview(birthdayStack)

        // 年龄提示
        contentView.addSubview(ageLabel)
        ageLabel.snp.makeConstraints { make in
            make.top.equalTo(birthdayShell.snp.bottom).offset(7)
            make.leading.equalToSuperview().offset(24)
        }

        // 性别
        genderGroup = OptionChipGroup(chips: [maleChip, femaleChip], allowsMultipleSelection: false)
        genderGroup?.onSelectionChanged = { [weak self] labels in
            self?.selectedGender = labels.first ?? ""
            self?.updateSaveButtonState()
        }

        let genderRow = UIStackView(arrangedSubviews: [maleChip, femaleChip])
        genderRow.spacing = 12
        genderRow.distribution = .fillEqually

        let genderStack = UIStackView(arrangedSubviews: [genderLabel, genderRow])
        genderStack.axis = .vertical
        genderStack.spacing = 9
        formStack.addArrangedSubview(genderStack)

        // 所在城市
        cityButton.snp.makeConstraints { make in
            make.height.equalTo(52)
        }

        let cityStack = UIStackView(arrangedSubviews: [cityLabel, cityButton])
        cityStack.axis = .vertical
        cityStack.spacing = 9
        formStack.addArrangedSubview(cityStack)

        formStack.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-100)
        }

        // ── Footer ──

        view.addSubview(footerBar)
        footerBar.addSubview(saveButton)
        footerBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(82)
        }
        saveButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.centerY.equalToSuperview()
            make.height.equalTo(54)
        }
    }

    // MARK: - Actions

    @objc private func fieldChanged() {
        updateSaveButtonState()
    }

    @objc private func dateChanged(_ picker: UIDatePicker) {
        birthDate = picker.date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        birthdayField.text = formatter.string(from: picker.date)
        updateAgeLabel()
        updateSaveButtonState()
    }

    @objc private func dismissDatePicker() {
        birthdayField.resignFirstResponder()
    }

    @objc private func showCityPicker() {
        view.endEditing(true)

        let container = UIView()
        container.backgroundColor = .fdSurface

        // Toolbar
        let toolbar = UIView()
        toolbar.backgroundColor = .fdBg
        container.addSubview(toolbar)
        toolbar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }

        let cancelBtn = UIButton(type: .system)
        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.titleLabel?.font = .fdBody
        cancelBtn.setTitleColor(.fdSubtext, for: .normal)
        cancelBtn.addAction(UIAction { [weak self] _ in self?.dismissCityPicker() }, for: .touchUpInside)
        toolbar.addSubview(cancelBtn)
        cancelBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        let confirmBtn = UIButton(type: .system)
        confirmBtn.setTitle("确定", for: .normal)
        confirmBtn.titleLabel?.font = .fdBodySemibold
        confirmBtn.setTitleColor(.fdPrimary, for: .normal)
        confirmBtn.addAction(UIAction { [weak self] _ in self?.confirmCitySelection() }, for: .touchUpInside)
        toolbar.addSubview(confirmBtn)
        confirmBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        // Picker
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        cityPickerView = picker

        // Set current selection
        if let pIdx = provinces.firstIndex(of: selectedProvince),
           let cities = cityMap[selectedProvince],
           let cIdx = cities.firstIndex(of: selectedCity) {
            picker.selectRow(pIdx, inComponent: 0, animated: false)
            picker.selectRow(cIdx, inComponent: 1, animated: false)
        }

        container.addSubview(picker)
        picker.snp.makeConstraints { make in
            make.top.equalTo(toolbar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(container.safeAreaLayoutGuide)
            make.height.equalTo(216)
        }

        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        cityPickerContainer = container

        // Animate in
        container.transform = CGAffineTransform(translationX: 0, y: 300)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            container.transform = .identity
        }
    }

    private func dismissCityPicker() {
        guard let container = cityPickerContainer else { return }
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            container.transform = CGAffineTransform(translationX: 0, y: 300)
        } completion: { _ in
            container.removeFromSuperview()
            self.cityPickerContainer = nil
            self.cityPickerView = nil
        }
    }

    private func confirmCitySelection() {
        guard let picker = cityPickerView else { return }
        let pIdx = picker.selectedRow(inComponent: 0)
        let cIdx = picker.selectedRow(inComponent: 1)

        selectedProvince = provinces.indices.contains(pIdx) ? provinces[pIdx] : provinces[0]
        let cities = cityMap[selectedProvince] ?? []
        selectedCity = cities.indices.contains(cIdx) ? cities[cIdx] : (cities.first ?? "")

        let text = selectedProvince == selectedCity ? selectedCity : "\(selectedProvince) \(selectedCity)"
        cityButton.setTitle(text, for: .normal)
        cityButton.setTitleColor(.fdText, for: .normal)
        updateSaveButtonState()
        dismissCityPicker()
    }

    @objc private func saveAndContinue() {
        guard !nameText.isEmpty else { showAlert("请输入姓名"); nameField.textField.becomeFirstResponder(); return }
        guard let date = birthDate else { showAlert("请选择出生日期"); birthdayField.becomeFirstResponder(); return }
        guard !selectedGender.isEmpty else { showAlert("请选择性别"); return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let birthdayStr = formatter.string(from: date)

        let mobile = UserDefaults.standard.string(forKey: "current_user_mobile")

        let payload = SUsersOnboardingPayload(
            mobile: mobile,
            chineseName: nameText,
            sex: selectedGender == "男" ? "1" : "2",
            birthday: birthdayStr,
            medicalHistory: nil,
            smokingStatus: nil,
            exerciseFrequency: nil
        )

        // Loading
        saveButton.isEnabled = false
        saveButton.alpha = 0.6
        saveButton.setTitle("保存中…", for: .normal)

        Task {
            do {
                try await UserService.shared.updateCurrentProfile(payload)
                UserManager.shared.patchLoginUserInfo(
                    chineseName: nameText,
                    sex: selectedGender == "男" ? "1" : "2",
                    birthday: birthdayStr
                )
                // 业务侧 currentUser 与门禁 loginUserInfo 分开刷新
                _ = await UserManager.shared.refreshUserInfo()
                await MainActor.run {
                    UserDefaults.standard.set(20, forKey: "fd_archive_progress")
                    if !nameText.isEmpty {
                        UserDefaults.standard.set(nameText, forKey: "fd_profile_name")
                    }
                    // 城市暂存本地（对齐 Vue localStorage）
                    let cityText = selectedProvince == selectedCity ? selectedCity : "\(selectedProvince) \(selectedCity)"
                    UserDefaults.standard.set(cityText, forKey: "fd_profile_city")
                    dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    saveButton.isEnabled = true
                    saveButton.alpha = 1.0
                    saveButton.setTitle("保存并继续", for: .normal)
                    showAlert("保存失败: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Helpers

    private func calculateAge(from date: Date) -> Int {
        Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
    }

    private func updateAgeLabel() {
        guard let date = birthDate else { ageLabel.isHidden = true; return }
        let age = calculateAge(from: date)
        if age > 0 {
            ageLabel.text = "已自动计算年龄：\(age) 岁"
            ageLabel.isHidden = false
        } else {
            ageLabel.isHidden = true
        }
    }

    private func updateSaveButtonState() {
        let can = !nameText.isEmpty && birthDate != nil && !selectedGender.isEmpty
        saveButton.isEnabled = can
        saveButton.alpha = can ? 1.0 : 0.45
        saveButton.layer.shadowOpacity = can ? 0.32 : 0
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}

// MARK: - UIPickerViewDataSource / Delegate

extension OnboardingViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 2 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 { return provinces.count }
        let pIdx = pickerView.selectedRow(inComponent: 0)
        let province = provinces.indices.contains(pIdx) ? provinces[pIdx] : provinces[0]
        return cityMap[province]?.count ?? 0
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 { return provinces.indices.contains(row) ? provinces[row] : nil }
        let pIdx = pickerView.selectedRow(inComponent: 0)
        let province = provinces.indices.contains(pIdx) ? provinces[pIdx] : provinces[0]
        let cities = cityMap[province] ?? []
        return cities.indices.contains(row) ? cities[row] : nil
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            pickerView.reloadComponent(1)
            let province = provinces.indices.contains(row) ? provinces[row] : provinces[0]
            if let cities = cityMap[province], !cities.isEmpty {
                pickerView.selectRow(0, inComponent: 1, animated: true)
            }
        }
    }
}
