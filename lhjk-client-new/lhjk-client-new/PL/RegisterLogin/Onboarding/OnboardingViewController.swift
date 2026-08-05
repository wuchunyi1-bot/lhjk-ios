import UIKit
import SnapKit

/// 完善个人信息 — 对齐 funde `ProfileSetupView`
/// 提交：`POST /v1/archive/saveArchiveHospital`
final class OnboardingViewController: BaseViewController {

    // MARK: - State

    private var nameText: String {
        nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    private var birthDate: Date?
    private var selectedGender = ""
    private var selectedHospitalId: String?
    private var selectedHospitalName: String?
    private var selectedManagerId: String?
    private var selectedManagerDisplay: String?

    private let userService: UserService

    // MARK: - UI — Card

    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        s.keyboardDismissMode = .onDrag
        return s
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = 20
        v.layer.shadowColor = UIColor.fdText.cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 12)
        v.layer.shadowRadius = 24
        v.layer.shadowOpacity = 0.10
        return v
    }()

    private let heroIconBox: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        return v
    }()

    private let heroIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "person.crop.circle.badge.heart"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "完善个人信息"
        l.font = .fdH2
        l.textColor = .fdText
        l.textAlignment = .center
        return l
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.text = "填写基础信息，绑定专属服务机构与业务经理"
        l.font = .fdCaption
        l.textColor = .fdSubtext
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    // MARK: - Fields

    private lazy var nameField: UITextField = makeInputField(placeholder: "请输入您的真实姓名")

    private lazy var maleButton = makeGenderButton(title: "♂  男", tag: 1)
    private lazy var femaleButton = makeGenderButton(title: "♀  女", tag: 2)

    private lazy var birthdayField: UITextField = {
        let tf = makeInputField(placeholder: "请选择出生日期")
        tf.tintColor = .clear

        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.maximumDate = Date()
        dp.preferredDatePickerStyle = .wheels
        dp.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        tf.inputView = dp

        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(dismissDatePicker)),
        ]
        tf.inputAccessoryView = toolbar
        return tf
    }()

    private let birthdayCalendarIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "calendar"))
        iv.tintColor = .fdPrimary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private lazy var institutionButton = makePickerButton(
        placeholder: "请选择服务机构",
        prefixSymbol: "building.2",
        action: #selector(openInstitutionSelect)
    )

    private lazy var managerButton = makePickerButton(
        placeholder: "请选择业务经理",
        prefixSymbol: "person.badge.plus",
        action: #selector(openManagerSelect)
    )

    private let managerHintLabel: UILabel = {
        let l = UILabel()
        l.text = "选择后将自动绑定专属业务经理，享受一对一服务"
        l.font = .fdMicro
        l.textColor = .fdMuted
        l.numberOfLines = 0
        return l
    }()

    private lazy var saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("提交信息", for: .normal)
        b.titleLabel?.font = .fdBodyBold
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .fdPrimary
        b.layer.cornerRadius = 14
        b.addTarget(self, action: #selector(saveAndContinue), for: .touchUpInside)
        return b
    }()

    private let privacyLabel: UILabel = {
        let l = UILabel()
        l.font = .fdMicro
        l.textColor = .fdMuted
        l.textAlignment = .center
        l.numberOfLines = 0
        let icon = NSTextAttachment()
        icon.image = UIImage(systemName: "checkmark.shield")?
            .withTintColor(.fdMuted, renderingMode: .alwaysOriginal)
        icon.bounds = CGRect(x: 0, y: -2, width: 12, height: 12)
        let attr = NSMutableAttributedString(attachment: icon)
        attr.append(NSAttributedString(string: " 您的个人信息将被严格保密，仅用于服务对接"))
        l.attributedText = attr
        return l
    }()

    // MARK: - Init

    init(userService: UserService = AppContainer.shared.userService) {
        self.userService = userService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        prefillExistingInfo()
        updateGenderAppearance()
        updateSaveButtonState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 子页 push 时会露出导航栏；回到本页再藏掉
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if nameText.isEmpty {
            nameField.becomeFirstResponder()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if heroIconBox.layer.sublayers?.contains(where: { $0 is CAGradientLayer }) != true {
            let g = CAGradientLayer()
            g.colors = [UIColor.fdPrimary.cgColor, UIColor.fdPrimaryDeep.cgColor]
            g.startPoint = CGPoint(x: 0, y: 0)
            g.endPoint = CGPoint(x: 1, y: 1)
            g.frame = heroIconBox.bounds
            heroIconBox.layer.insertSublayer(g, at: 0)
        } else if let g = heroIconBox.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            g.frame = heroIconBox.bounds
        }
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        view.addSubview(scrollView)
        scrollView.addSubview(cardView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
            make.width.equalTo(scrollView).offset(-32)
        }

        // Hero
        heroIconBox.addSubview(heroIcon)
        heroIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(28)
        }

        let heroStack = UIStackView(arrangedSubviews: [heroIconBox, titleLabel, descLabel])
        heroStack.axis = .vertical
        heroStack.alignment = .center
        heroStack.spacing = 8
        heroIconBox.snp.makeConstraints { make in make.size.equalTo(56) }

        // Form fields
        let nameBlock = makeLabeledField(required: true, title: "姓名", content: nameField)
        nameField.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
        nameField.snp.makeConstraints { make in make.height.equalTo(46) }

        let genderRow = UIStackView(arrangedSubviews: [maleButton, femaleButton])
        genderRow.axis = .horizontal
        genderRow.spacing = 10
        genderRow.distribution = .fillEqually
        maleButton.snp.makeConstraints { make in make.height.equalTo(46) }
        femaleButton.snp.makeConstraints { make in make.height.equalTo(46) }
        let genderBlock = makeLabeledField(required: true, title: "性别", content: genderRow)

        let birthdayShell = UIView()
        birthdayShell.addSubview(birthdayField)
        birthdayShell.addSubview(birthdayCalendarIcon)
        birthdayField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 1))
        birthdayField.rightViewMode = .always
        birthdayField.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(46)
        }
        birthdayCalendarIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
        let birthdayBlock = makeLabeledField(required: true, title: "出生日期", content: birthdayShell)

        let divider = makeDivider()

        institutionButton.snp.makeConstraints { make in make.height.equalTo(46) }
        let institutionBlock = makeLabeledField(required: true, title: "所属机构", content: institutionButton)

        managerButton.snp.makeConstraints { make in make.height.equalTo(46) }
        let managerLabelRow = makeOptionalLabel(title: "业务经理")
        let managerBlock = UIStackView(arrangedSubviews: [managerLabelRow, managerButton, managerHintLabel])
        managerBlock.axis = .vertical
        managerBlock.spacing = 8

        let formStack = UIStackView(arrangedSubviews: [
            nameBlock, genderBlock, birthdayBlock, divider, institutionBlock, managerBlock,
        ])
        formStack.axis = .vertical
        formStack.spacing = 14

        saveButton.snp.makeConstraints { make in make.height.equalTo(48) }

        let content = UIStackView(arrangedSubviews: [heroStack, formStack, saveButton, privacyLabel])
        content.axis = .vertical
        content.spacing = 18
        content.setCustomSpacing(16, after: heroStack)
        content.setCustomSpacing(18, after: formStack)
        content.setCustomSpacing(12, after: saveButton)

        cardView.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 18, bottom: 18, right: 18))
        }
    }

    // MARK: - Builders

    private func makeInputField(placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.font = .fdBody
        tf.textColor = .fdText
        tf.borderStyle = .none
        tf.backgroundColor = .fdSurface2
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.fdPrimaryEdge.cgColor
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        tf.rightViewMode = .always
        return tf
    }

    private func makeGenderButton(title: String, tag: Int) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .fdBody
        b.tag = tag
        b.layer.cornerRadius = 12
        b.layer.borderWidth = 1
        b.addTarget(self, action: #selector(genderTapped(_:)), for: .touchUpInside)
        return b
    }

    private func makePickerButton(placeholder: String, prefixSymbol: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(placeholder, for: .normal)
        b.setTitleColor(.fdMuted, for: .normal)
        b.titleLabel?.font = .fdBody
        b.titleLabel?.lineBreakMode = .byTruncatingTail
        b.backgroundColor = .fdSurface
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.fdBorder.cgColor
        b.layer.cornerRadius = 12
        b.contentHorizontalAlignment = .leading
        b.titleEdgeInsets = UIEdgeInsets(top: 0, left: 36, bottom: 0, right: 36)
        b.addTarget(self, action: action, for: .touchUpInside)

        let prefix = UIImageView(image: UIImage(systemName: prefixSymbol))
        prefix.tintColor = .fdMuted
        prefix.contentMode = .scaleAspectFit
        prefix.tag = 101
        b.addSubview(prefix)
        prefix.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .fdMuted
        chevron.contentMode = .scaleAspectFit
        b.addSubview(chevron)
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }
        return b
    }

    private func makeRequiredLabel(title: String) -> UILabel {
        let l = UILabel()
        let attr = NSMutableAttributedString(
            string: "*",
            attributes: [.font: UIFont.fdBodySemibold, .foregroundColor: UIColor.fdDanger]
        )
        attr.append(NSAttributedString(
            string: title,
            attributes: [.font: UIFont.fdBodySemibold, .foregroundColor: UIColor.fdText]
        ))
        l.attributedText = attr
        return l
    }

    private func makeOptionalLabel(title: String) -> UILabel {
        let l = UILabel()
        let attr = NSMutableAttributedString(
            string: title,
            attributes: [.font: UIFont.fdBodySemibold, .foregroundColor: UIColor.fdText]
        )
        attr.append(NSAttributedString(
            string: " (选填)",
            attributes: [.font: UIFont.fdCaption, .foregroundColor: UIColor.fdMuted]
        ))
        l.attributedText = attr
        return l
    }

    private func makeLabeledField(required: Bool, title: String, content: UIView) -> UIStackView {
        let label = required ? makeRequiredLabel(title: title) : makeOptionalLabel(title: title)
        let stack = UIStackView(arrangedSubviews: [label, content])
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }

    private func makeDivider() -> UIView {
        let wrap = UIView()
        wrap.snp.makeConstraints { make in make.height.equalTo(20) }
        let left = UIView()
        left.backgroundColor = UIColor.fdBorder.withAlphaComponent(0.8)
        let right = UIView()
        right.backgroundColor = UIColor.fdBorder.withAlphaComponent(0.8)
        let icon = UIImageView(image: UIImage(systemName: "building.2.fill"))
        icon.tintColor = .fdWarning
        icon.contentMode = .scaleAspectFit
        wrap.addSubview(left)
        wrap.addSubview(icon)
        wrap.addSubview(right)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(14)
        }
        left.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalTo(icon.snp.leading).offset(-10)
            make.centerY.equalToSuperview()
            make.height.equalTo(1)
        }
        right.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.leading.equalTo(icon.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.height.equalTo(1)
        }
        return wrap
    }

    // MARK: - Actions

    @objc private func fieldChanged() {
        updateSaveButtonState()
    }

    @objc private func genderTapped(_ sender: UIButton) {
        selectedGender = sender.tag == 1 ? "男" : "女"
        updateGenderAppearance()
        updateSaveButtonState()
    }

    @objc private func dateChanged(_ picker: UIDatePicker) {
        birthDate = picker.date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        birthdayField.text = formatter.string(from: picker.date)
        updateSaveButtonState()
    }

    @objc private func dismissDatePicker() {
        birthdayField.resignFirstResponder()
    }

    @objc private func openInstitutionSelect() {
        view.endEditing(true)
        let vc = InstitutionSelectViewController(selectedId: selectedHospitalId)
        vc.onInstitutionSelected = { [weak self] institution in
            guard let self else { return }
            let changed = self.selectedHospitalId != institution.id
            self.selectedHospitalId = institution.id
            self.selectedHospitalName = institution.name
            self.setPickerTitle(self.institutionButton, text: institution.name)
            if changed {
                self.clearManagerSelection()
            }
            self.updateSaveButtonState()
        }
        pushOrPresent(vc)
    }

    @objc private func openManagerSelect() {
        view.endEditing(true)
        guard let hospitalId = selectedHospitalId?.trimmingCharacters(in: .whitespacesAndNewlines),
              !hospitalId.isEmpty else {
            showAlert("请先选择所属机构")
            return
        }
        let vc = ManagerSelectViewController(
            hospitalId: hospitalId,
            hospitalName: selectedHospitalName ?? "",
            selectedId: selectedManagerId
        )
        vc.onManagerSelected = { [weak self] doctor in
            self?.selectedManagerId = doctor.id
            self?.selectedManagerDisplay = doctor.pickerDisplay
            self?.setPickerTitle(self?.managerButton, text: doctor.pickerDisplay)
        }
        pushOrPresent(vc)
    }

    @objc private func saveAndContinue() {
        guard !nameText.isEmpty else {
            showAlert("请输入您的真实姓名")
            nameField.becomeFirstResponder()
            return
        }
        guard !selectedGender.isEmpty else {
            showAlert("请选择性别")
            return
        }
        guard let date = birthDate else {
            showAlert("请选择出生日期")
            birthdayField.becomeFirstResponder()
            return
        }
        guard let hospitalIdRaw = selectedHospitalId?.trimmingCharacters(in: .whitespacesAndNewlines),
              !hospitalIdRaw.isEmpty,
              let hospitalId = Int64(hospitalIdRaw) else {
            showAlert("请选择服务机构")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let birthdayStr = formatter.string(from: date)
        let sexCode = selectedGender == "男" ? "1" : "2"
        let managerId = selectedManagerId.flatMap { Int64($0.trimmingCharacters(in: .whitespacesAndNewlines)) }

        let dto = SaveArchiveHospitalDTO(
            chineseName: nameText,
            sex: sexCode,
            birthday: birthdayStr,
            hospitalId: hospitalId,
            businessManagerId: managerId
        )

        saveButton.isEnabled = false
        saveButton.alpha = 0.6
        saveButton.setTitle("提交中…", for: .normal)

        Task {
            do {
                try await userService.saveArchiveHospital(dto)
                UserManager.shared.patchLoginUserInfo(
                    chineseName: nameText,
                    sex: sexCode,
                    birthday: birthdayStr,
                    hospitalId: hospitalIdRaw
                )
                _ = await UserManager.shared.refreshUserInfo()
                await MainActor.run {
                    UserDefaults.standard.set(20, forKey: "fd_archive_progress")
                    UserDefaults.standard.set(nameText, forKey: "fd_profile_name")
                    if let name = selectedHospitalName {
                        UserDefaults.standard.set(name, forKey: "fd_profile_institution")
                    }
                    if let manager = selectedManagerDisplay, !manager.isEmpty {
                        UserDefaults.standard.set(manager, forKey: "fd_profile_manager")
                    }
                    finishOnboardingWithToast("个人信息已提交")
                }
            } catch {
                await MainActor.run {
                    saveButton.isEnabled = true
                    saveButton.alpha = 1.0
                    saveButton.setTitle("提交信息", for: .normal)
                    showAlert("保存失败: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Prefill

    /// 已有字段回填：loginUserInfo → currentUser → defaultArchive → 本地展示缓存
    private func prefillExistingInfo() {
        let login = UserManager.shared.loginUserInfo
        let user = UserManager.shared.currentUser
        let archive = UserManager.shared.defaultArchive

        let name = firstNonBlank(
            login?.chineseName,
            user?.chineseName,
            user?.surname,
            archive?.chineseName,
            UserDefaults.standard.string(forKey: "fd_profile_name")
        )
        if let name {
            nameField.text = name
        }

        if let gender = Self.normalizedGender(
            firstNonBlank(login?.sex, user?.sex)
        ) {
            selectedGender = gender
        }

        if let birthday = firstNonBlank(login?.birthday, user?.birthday),
           let date = Self.parseBirthday(birthday) {
            birthDate = date
            birthdayField.text = Self.displayBirthday(date)
            if let picker = birthdayField.inputView as? UIDatePicker {
                picker.date = date
            }
        }

        let hospitalId = firstNonBlank(login?.hospitalId, archive?.hospitalId)
        if let hospitalId {
            selectedHospitalId = hospitalId
            let hospitalName = firstNonBlank(
                archive?.hospitalName,
                UserDefaults.standard.string(forKey: "fd_profile_institution")
            ) ?? "已绑定机构"
            selectedHospitalName = hospitalName
            setPickerTitle(institutionButton, text: hospitalName)
        }

        if let managerId = firstNonBlank(archive?.businessManagerId) {
            selectedManagerId = managerId
            let managerName = firstNonBlank(
                archive?.businessManagerName,
                UserDefaults.standard.string(forKey: "fd_profile_manager")
            ) ?? "已绑定业务经理"
            selectedManagerDisplay = managerName
            setPickerTitle(managerButton, text: managerName)
        } else if let cachedManager = firstNonBlank(
            UserDefaults.standard.string(forKey: "fd_profile_manager")
        ) {
            selectedManagerDisplay = cachedManager
            setPickerTitle(managerButton, text: cachedManager)
        }
    }

    private func firstNonBlank(_ values: String?...) -> String? {
        for value in values {
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }

    private static func normalizedGender(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let v = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch v {
        case "1", "男", "male", "m": return "男"
        case "2", "女", "female", "f": return "女"
        default: return nil
        }
    }

    private static func parseBirthday(_ raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        for format in ["yyyy-MM-dd", "yyyy/MM/dd", "yyyy.MM.dd"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: String(trimmed.prefix(10))) {
                return date
            }
        }
        if trimmed.count >= 10 {
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: String(trimmed.prefix(10)))
        }
        return nil
    }

    private static func displayBirthday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Helpers

    private func pushOrPresent(_ vc: UIViewController) {
        // Onboarding 已包在 Nav 内（根页隐藏导航栏）；子页需要显示导航栏以便返回
        if let nav = navigationController {
            nav.setNavigationBarHidden(false, animated: true)
            nav.pushViewController(vc, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

    private func setPickerTitle(_ button: UIButton?, text: String) {
        guard let button else { return }
        button.setTitle(text, for: .normal)
        button.setTitleColor(.fdText, for: .normal)
    }

    private func clearManagerSelection() {
        selectedManagerId = nil
        selectedManagerDisplay = nil
        managerButton.setTitle("请选择业务经理", for: .normal)
        managerButton.setTitleColor(.fdMuted, for: .normal)
    }

    private func updateGenderAppearance() {
        styleGender(maleButton, active: selectedGender == "男")
        styleGender(femaleButton, active: selectedGender == "女")
    }

    private func styleGender(_ button: UIButton, active: Bool) {
        if active {
            button.backgroundColor = .fdPrimarySoft
            button.setTitleColor(.fdPrimary, for: .normal)
            button.titleLabel?.font = .fdBodySemibold
            button.layer.borderColor = UIColor.fdPrimary.cgColor
        } else {
            button.backgroundColor = .fdSurface
            button.setTitleColor(.fdSubtext, for: .normal)
            button.titleLabel?.font = .fdBody
            button.layer.borderColor = UIColor.fdBorder.cgColor
        }
    }

    private func updateSaveButtonState() {
        let hasHospital = !(selectedHospitalId?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let can = !nameText.isEmpty && birthDate != nil && !selectedGender.isEmpty && hasHospital
        saveButton.isEnabled = can
        saveButton.alpha = can ? 1.0 : 0.45
    }

    private func finishOnboardingWithToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            alert.dismiss(animated: true) {
                self?.dismissOnboarding()
            }
        }
    }

    private func dismissOnboarding() {
        if let presenting = presentingViewController {
            presenting.dismiss(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
