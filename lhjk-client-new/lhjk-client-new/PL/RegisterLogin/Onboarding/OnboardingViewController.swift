import UIKit
import SnapKit

/// 完善个人信息 — 对齐 Figma `5330:13324`（未填）/ `5346:16053`（已填）
/// 提交：`POST /v1/archive/saveArchiveHospital`
final class OnboardingViewController: BaseViewController {

    private enum Design {
        static let fieldHeight: CGFloat = 47
        static let fieldRadius: CGFloat = 12
        static let fieldInset: CGFloat = 16
        static let groupSpacing: CGFloat = 16
        static let labelFieldGap: CGFloat = 12
        static let genderGap: CGFloat = 11
        static let sheetRadius: CGFloat = 16
        static let buttonHeight: CGFloat = 51
        static let buttonWidth: CGFloat = 327
        static var buttonRadius: CGFloat { buttonHeight / 2 }
        static let privacyBubbleHeight: CGFloat = 32
        static let privacyTextInsetX: CGFloat = 12
        static let privacyPointerOverlap: CGFloat = 8
        static let headerFallbackRatio: CGFloat = 154.0 / 375.0
        static let titleImageSize = CGSize(width: 119, height: 19)
    }

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

    // MARK: - Header

    private let headerBg: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "onboarding_header_bg"))
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = false
        return iv
    }()

    private let titleImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "onboarding_header_text"))
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = false
        return iv
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.text = "填写基础信息，绑定专属服务机构与业务经理"
        l.font = .fdFont(ofSize: 13, weight: .regular)
        l.textColor = .fdSubtext
        l.textAlignment = .left
        l.numberOfLines = 2
        return l
    }()

    private var headerHeightConstraint: Constraint?

    private let sheetView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = Design.sheetRadius
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.clipsToBounds = true
        return v
    }()

    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        s.keyboardDismissMode = .onDrag
        s.alwaysBounceVertical = false
        s.bounces = false
        return s
    }()

    // MARK: - Fields

    private lazy var nameField: UITextField = makeInputField(placeholder: "请输入您的真实姓名")

    private lazy var maleButton = makeGenderButton(title: "男", tag: 1)
    private lazy var femaleButton = makeGenderButton(title: "女", tag: 2)

    private lazy var birthdayButton = makePickerButton(
        placeholder: "年/月/日",
        action: #selector(openBirthdayPicker),
        trailingIcon: "onboarding_calendar",
        iconSize: 18,
        iconInset: 12
    )

    private lazy var institutionButton = makePickerButton(
        placeholder: "请选择服务机构",
        action: #selector(openInstitutionSelect)
    )

    private lazy var managerButton = makePickerButton(
        placeholder: "请选择业务经理",
        action: #selector(openManagerSelect)
    )

    private let managerHintLabel: UILabel = {
        let l = UILabel()
        l.text = "选择后将自动绑定专属业务经理，享受一对一服务"
        l.font = .fdFont(ofSize: 13, weight: .regular)
        l.textColor = .fdTabInactive
        l.numberOfLines = 0
        return l
    }()

    private let privacyWrap = UIView()

    private let privacyBubble: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "onboarding_privacy_bubble"))
        iv.contentMode = .scaleToFill
        iv.isUserInteractionEnabled = false
        return iv
    }()

    private let privacyLabel: UILabel = {
        let l = UILabel()
        l.text = "您的个人信息将被严格保密，仅用于服务对接"
        l.font = .fdFont(ofSize: 13, weight: .regular)
        l.textColor = .fdLoginTitle
        l.textAlignment = .center
        l.numberOfLines = 1
        l.lineBreakMode = .byClipping
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    private lazy var saveButton: UIButton = {
        let b = UIButton(type: .custom)
        b.backgroundColor = .fdPrimary
        b.layer.cornerRadius = Design.buttonRadius
        b.clipsToBounds = true
        b.setTitle("提交信息", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .fdFont(ofSize: 17, weight: .medium)
        b.addTarget(self, action: #selector(saveAndContinue), for: .touchUpInside)
        return b
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderHeight()
        updateScrollLock()
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        view.addSubview(headerBg)
        view.addSubview(titleImageView)
        view.addSubview(descLabel)
        view.addSubview(sheetView)

        headerBg.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            headerHeightConstraint = $0.height.equalTo(headerHeight(for: UIScreen.main.bounds.width)).constraint
        }
        titleImageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.equalToSuperview().offset(18)
            $0.size.equalTo(Design.titleImageSize)
        }
        descLabel.snp.makeConstraints {
            $0.top.equalTo(titleImageView.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(18)
            $0.width.equalTo(186)
        }
        sheetView.snp.makeConstraints {
            $0.top.equalTo(headerBg.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        sheetView.addSubview(scrollView)
        sheetView.addSubview(saveButton)
        privacyWrap.addSubview(privacyBubble)
        privacyWrap.addSubview(privacyLabel)
        privacyWrap.isUserInteractionEnabled = false
        sheetView.addSubview(privacyWrap)

        saveButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.width.equalTo(Design.buttonWidth)
            $0.height.equalTo(Design.buttonHeight)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
        }
        privacyBubble.snp.makeConstraints { $0.edges.equalToSuperview() }
        privacyLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.leading.equalToSuperview().offset(Design.privacyTextInsetX)
            $0.trailing.equalToSuperview().offset(-Design.privacyTextInsetX)
        }
        privacyWrap.snp.makeConstraints {
            $0.centerX.equalTo(saveButton)
            $0.height.equalTo(Design.privacyBubbleHeight)
            $0.bottom.equalTo(saveButton.snp.top).offset(Design.privacyPointerOverlap)
        }
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(privacyWrap.snp.top).offset(-8)
        }

        let nameBlock = makeLabeledField(required: true, title: "姓名", content: nameField)
        nameField.snp.makeConstraints { $0.height.equalTo(Design.fieldHeight) }

        let genderRow = UIStackView(arrangedSubviews: [maleButton, femaleButton])
        genderRow.axis = .horizontal
        genderRow.spacing = Design.genderGap
        genderRow.distribution = .fillEqually
        maleButton.snp.makeConstraints { $0.height.equalTo(Design.fieldHeight) }
        femaleButton.snp.makeConstraints { $0.height.equalTo(Design.fieldHeight) }
        let genderBlock = makeLabeledField(required: true, title: "性别", content: genderRow)

        birthdayButton.snp.makeConstraints { $0.height.equalTo(Design.fieldHeight) }
        let birthdayBlock = makeLabeledField(required: true, title: "出生日期", content: birthdayButton)
        birthdayBlock.isUserInteractionEnabled = true
        birthdayBlock.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openBirthdayPicker)))

        institutionButton.snp.makeConstraints { $0.height.equalTo(Design.fieldHeight) }
        let institutionBlock = makeLabeledField(required: true, title: "所属机构", content: institutionButton)

        managerButton.snp.makeConstraints { $0.height.equalTo(Design.fieldHeight) }
        let managerLabelRow = makeOptionalLabel(title: "业务经理")
        let managerBlock = UIStackView(arrangedSubviews: [managerLabelRow, managerButton, managerHintLabel])
        managerBlock.axis = .vertical
        managerBlock.spacing = Design.labelFieldGap
        managerBlock.setCustomSpacing(12, after: managerButton)

        let formStack = UIStackView(arrangedSubviews: [
            nameBlock, genderBlock, birthdayBlock, institutionBlock, managerBlock,
        ])
        formStack.axis = .vertical
        formStack.spacing = Design.groupSpacing
        formStack.isLayoutMarginsRelativeArrangement = true
        formStack.layoutMargins = UIEdgeInsets(top: 16, left: Design.fieldInset, bottom: 8, right: Design.fieldInset)

        scrollView.addSubview(formStack)
        formStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }
    }

    private func headerHeight(for width: CGFloat) -> CGFloat {
        BannerImageAspectLayout.height(
            width: width,
            imageSize: headerBg.image?.size,
            fallbackRatio: Design.headerFallbackRatio
        )
    }

    private func updateHeaderHeight() {
        let height = headerHeight(for: view.bounds.width)
        guard height > 0 else { return }
        headerHeightConstraint?.update(offset: height)
    }

    private func updateScrollLock() {
        scrollView.layoutIfNeeded()
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height
        let needsScroll = visibleHeight > 0 && contentHeight > visibleHeight + 1
        scrollView.isScrollEnabled = needsScroll
        scrollView.bounces = needsScroll
    }

    // MARK: - Builders

    private func makeInputField(placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: UIFont.fdFont(ofSize: 15, weight: .regular),
                .foregroundColor: UIColor.fdTabInactive,
            ]
        )
        tf.font = .fdFont(ofSize: 15, weight: .regular)
        tf.textColor = .fdText
        tf.borderStyle = .none
        tf.backgroundColor = .fdProductImageBg
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.fdProductImageBg.cgColor
        tf.layer.cornerRadius = Design.fieldRadius
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.rightViewMode = .always
        return tf
    }

    private func makeGenderButton(title: String, tag: Int) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .fdFont(ofSize: 15, weight: .regular)
        b.tag = tag
        b.layer.cornerRadius = Design.fieldRadius
        b.layer.borderWidth = 1
        b.addTarget(self, action: #selector(genderTapped(_:)), for: .touchUpInside)
        return b
    }

    private func makePickerButton(
        placeholder: String,
        action: Selector,
        trailingIcon: String = "onboarding_chevron",
        iconSize: CGFloat = 12,
        iconInset: CGFloat = 13
    ) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(placeholder, for: .normal)
        b.setTitleColor(.fdTabInactive, for: .normal)
        b.titleLabel?.font = .fdFont(ofSize: 15, weight: .regular)
        b.titleLabel?.lineBreakMode = .byTruncatingTail
        b.backgroundColor = .fdProductImageBg
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.fdProductImageBg.cgColor
        b.layer.cornerRadius = Design.fieldRadius
        b.contentHorizontalAlignment = .leading
        b.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: iconInset + iconSize + 4)
        b.addTarget(self, action: action, for: .touchUpInside)

        let icon = UIImageView(image: UIImage(named: trailingIcon))
        icon.contentMode = .scaleAspectFit
        icon.isUserInteractionEnabled = false
        b.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(iconInset)
            make.centerY.equalToSuperview()
            make.size.equalTo(iconSize)
        }
        return b
    }

    private func makeRequiredLabel(title: String) -> UIView {
        let star = UIImageView(image: UIImage(named: "onboarding_required_star"))
        star.contentMode = .scaleAspectFit
        star.snp.makeConstraints { $0.size.equalTo(CGSize(width: 8, height: 8)) }

        let label = UILabel()
        label.text = title
        label.font = .fdFont(ofSize: 17, weight: .medium)
        label.textColor = .fdText

        let row = UIStackView(arrangedSubviews: [star, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 4
        return row
    }

    private func makeOptionalLabel(title: String) -> UILabel {
        let l = UILabel()
        let attr = NSMutableAttributedString(
            string: title,
            attributes: [
                .font: UIFont.fdFont(ofSize: 17, weight: .medium),
                .foregroundColor: UIColor.fdText,
            ]
        )
        attr.append(NSAttributedString(
            string: " (选填)",
            attributes: [
                .font: UIFont.fdFont(ofSize: 17, weight: .regular),
                .foregroundColor: UIColor.fdMuted,
            ]
        ))
        l.attributedText = attr
        return l
    }

    private func makeLabeledField(required: Bool, title: String, content: UIView) -> UIStackView {
        let label: UIView = required ? makeRequiredLabel(title: title) : makeOptionalLabel(title: title)
        let stack = UIStackView(arrangedSubviews: [label, content])
        stack.axis = .vertical
        stack.spacing = Design.labelFieldGap
        return stack
    }

    // MARK: - Actions

    @objc private func genderTapped(_ sender: UIButton) {
        selectedGender = sender.tag == 1 ? "男" : "女"
        updateGenderAppearance()
    }

    @objc private func openBirthdayPicker() {
        view.endEditing(true)
        let sheet = OnboardingBirthdayPickerSheet(selected: birthDate)
        sheet.onConfirm = { [weak self] date in
            guard let self else { return }
            self.birthDate = date
            self.setPickerTitle(self.birthdayButton, text: Self.displayBirthday(date))
        }
        present(sheet, animated: false)
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
            return
        }
        guard let hospitalIdRaw = selectedHospitalId?.trimmingCharacters(in: .whitespacesAndNewlines),
              !hospitalIdRaw.isEmpty,
              let hospitalId = Int64(hospitalIdRaw) else {
            showAlert("请选择服务机构")
            return
        }

        let birthdayStr = Self.displayBirthday(date)
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
                _ = await UserManager.shared.refreshUserInfo()
                _ = await UserManager.shared.refreshDefaultArchive()
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

    /// 已有字段回填：defaultArchive → currentUser → 本地展示缓存
    private func prefillExistingInfo() {
        let user = UserManager.shared.currentUser
        let archive = UserManager.shared.defaultArchive

        let name = firstNonBlank(
            archive?.chineseName,
            user?.chineseName,
            user?.surname,
            UserDefaults.standard.string(forKey: "fd_profile_name")
        )
        if let name {
            nameField.text = name
        }

        if let gender = Self.normalizedGender(
            firstNonBlank(archive?.sex, user?.sex)
        ) {
            selectedGender = gender
        }

        if let birthday = firstNonBlank(archive?.birthday, user?.birthday),
           let date = Self.parseBirthday(birthday) {
            birthDate = date
            setPickerTitle(birthdayButton, text: Self.displayBirthday(date))
        }

        let hospitalId = firstNonBlank(archive?.hospitalId)
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
        managerButton.setTitleColor(.fdTabInactive, for: .normal)
    }

    private func updateGenderAppearance() {
        styleGender(maleButton, active: selectedGender == "男")
        styleGender(femaleButton, active: selectedGender == "女")
    }

    private func styleGender(_ button: UIButton, active: Bool) {
        if active {
            button.backgroundColor = .fdBg
            button.setTitleColor(.fdPrimary, for: .normal)
            button.layer.borderWidth = 0.5
            button.layer.borderColor = UIColor.fdPrimary.cgColor
        } else {
            button.backgroundColor = .fdProductImageBg
            button.setTitleColor(.fdTabInactive, for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.fdProductImageBg.cgColor
        }
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
