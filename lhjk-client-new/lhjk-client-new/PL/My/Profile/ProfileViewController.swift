import UIKit
import SnapKit
import Kingfisher

/// 个人信息页 — 对齐 `ProfileView.vue`
///
/// 居中头像 + 单卡片三组字段；可编辑项走底部 `ProfileFieldEditorSheet`
final class ProfileViewController: BaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Field Keys

    private enum FieldKey: String {
        case name, gender, birthday, phone, email
        case occupation, education, idType, idNumber
        case nationality, ethnic, nativePlace, residence, district, address
    }

    private enum FieldKind {
        case readonly
        case text(keyboard: UIKeyboardType, maxLength: Int)
        case select(options: [String])
        case date
    }

    private struct FieldDef {
        let key: FieldKey
        let label: String
        let kind: FieldKind
        let placeholder: String
    }

    private struct SectionDef {
        let title: String
        let fields: [FieldDef]
    }

    // MARK: - Options (对齐 ProfileView.vue)

    private static let genderOptions = ["男", "女"]
    private static let occupationOptions = ["在职人员", "学生", "自由职业", "退休", "无业"]
    private static let educationOptions = ["小学", "初中", "高中/中专", "大专", "本科", "硕士及以上"]
    private static let idTypeOptions = ["居民身份证", "护照", "军官证", "港澳通行证", "台胞证"]
    private static let nationalityOptions = ["中国", "中国香港", "中国澳门", "中国台湾", "其他"]
    private static let ethnicOptions = ["汉族", "蒙古族", "回族", "藏族", "维吾尔族", "其他"]
    private static let provinceOptions = ["北京市", "上海市", "广东省", "江苏省", "浙江省", "四川省"]
    private static let districtOptions = ["浦东新区", "黄浦区", "徐汇区", "长宁区", "静安区", "天河区", "越秀区"]

    /// 证件类型中文 ↔ Int（1…5）
    private static let idTypeToInt: [String: Int] = [
        "居民身份证": 1, "护照": 2, "军官证": 3, "港澳通行证": 4, "台胞证": 5
    ]
    private static let idTypeFromInt: [Int: String] = [
        1: "居民身份证", 2: "护照", 3: "军官证", 4: "港澳通行证", 5: "台胞证"
    ]

    private lazy var sections: [SectionDef] = [
        SectionDef(title: "个人基础信息", fields: [
            FieldDef(key: .name, label: "姓名", kind: .readonly, placeholder: "未设置"),
            FieldDef(key: .gender, label: "性别", kind: .select(options: Self.genderOptions), placeholder: "请选择"),
            FieldDef(key: .birthday, label: "出生日期", kind: .date, placeholder: "请选择日期"),
            FieldDef(key: .phone, label: "手机号", kind: .readonly, placeholder: "未设置"),
            FieldDef(key: .email, label: "邮箱", kind: .text(keyboard: .emailAddress, maxLength: 100), placeholder: "请输入邮箱"),
        ]),
        SectionDef(title: "身份与职业", fields: [
            FieldDef(key: .occupation, label: "职业", kind: .select(options: Self.occupationOptions), placeholder: "请选择"),
            FieldDef(key: .education, label: "文化程度", kind: .select(options: Self.educationOptions), placeholder: "请选择"),
            FieldDef(key: .idType, label: "证件类型", kind: .select(options: Self.idTypeOptions), placeholder: "请选择"),
            FieldDef(key: .idNumber, label: "证件号码", kind: .text(keyboard: .asciiCapable, maxLength: 18), placeholder: "请输入证件号码"),
        ]),
        SectionDef(title: "地区信息", fields: [
            FieldDef(key: .nationality, label: "国籍", kind: .select(options: Self.nationalityOptions), placeholder: "请选择"),
            FieldDef(key: .ethnic, label: "民族", kind: .select(options: Self.ethnicOptions), placeholder: "请选择"),
            FieldDef(key: .nativePlace, label: "籍贯", kind: .select(options: Self.provinceOptions), placeholder: "请选择"),
            FieldDef(key: .residence, label: "现居地", kind: .select(options: Self.provinceOptions), placeholder: "请选择"),
            FieldDef(key: .district, label: "省/区", kind: .select(options: Self.districtOptions), placeholder: "请选择"),
            FieldDef(key: .address, label: "详细地址", kind: .text(keyboard: .default, maxLength: 100), placeholder: "请输入详细地址"),
        ]),
    ]

    // MARK: - State

    private var values: [FieldKey: String] = [:]
    private var valueLabels: [FieldKey: UILabel] = [:]

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let avatarSection = UIControl()
    private let avatarImageView = UIImageView()
    private let avatarTextLabel = UILabel()
    private let avatarGradient = CAGradientLayer()
    private var avatarLoading: UIActivityIndicatorView?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(onUserUpdated),
                                               name: .userDidUpdate, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        loadUserProfile()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avatarGradient.frame = avatarImageView.bounds
    }

    override func setupUI() {
        title = "个人信息"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        buildAvatarSection()
        buildInfoCard()
    }

    // MARK: - Build

    private func buildAvatarSection() {
        avatarSection.addTarget(self, action: #selector(handleAvatarTap), for: .touchUpInside)
        contentView.addSubview(avatarSection)
        avatarSection.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.trailing.equalToSuperview()
        }

        avatarGradient.colors = [
            UIColor(hexString: "#CC4A20").cgColor,
            UIColor(hexString: "#FF7A50").cgColor
        ]
        avatarGradient.startPoint = CGPoint(x: 0, y: 0)
        avatarGradient.endPoint = CGPoint(x: 1, y: 1)
        avatarImageView.layer.insertSublayer(avatarGradient, at: 0)
        avatarImageView.layer.cornerRadius = 24
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.isUserInteractionEnabled = false

        avatarTextLabel.font = .fdFont(ofSize: 34, weight: .bold)
        avatarTextLabel.textColor = .white
        avatarTextLabel.textAlignment = .center
        avatarImageView.addSubview(avatarTextLabel)
        avatarTextLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        let hint = UILabel()
        hint.text = "点击更换头像"
        hint.font = .fdCaption
        hint.textColor = .fdSubtext

        avatarSection.addSubview(avatarImageView)
        avatarSection.addSubview(hint)
        avatarImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(80)
        }
        hint.snp.makeConstraints {
            $0.top.equalTo(avatarImageView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-4)
        }
    }

    private func buildInfoCard() {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalTo(avatarSection.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-32)
        }

        let stack = UIStackView()
        stack.axis = .vertical
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)) }

        for (idx, section) in sections.enumerated() {
            let group = UIView()
            let groupStack = UIStackView()
            groupStack.axis = .vertical
            group.addSubview(groupStack)
            groupStack.snp.makeConstraints {
                $0.top.equalToSuperview().offset(14)
                $0.leading.trailing.equalToSuperview()
                $0.bottom.equalToSuperview().offset(idx == sections.count - 1 ? -14 : -6)
            }

            let title = UILabel()
            title.text = section.title
            title.font = .fdCaptionSemibold
            title.textColor = .fdText
            groupStack.addArrangedSubview(title)
            groupStack.setCustomSpacing(6, after: title)

            for field in section.fields {
                groupStack.addArrangedSubview(makeRow(field))
            }

            if idx < sections.count - 1 {
                let divider = UIView()
                divider.backgroundColor = .fdBorder
                group.addSubview(divider)
                divider.snp.makeConstraints {
                    $0.leading.trailing.bottom.equalToSuperview()
                    $0.height.equalTo(1)
                }
            }

            stack.addArrangedSubview(group)
        }
    }

    private func makeRow(_ field: FieldDef) -> UIView {
        let row = UIControl()
        if case .readonly = field.kind {
            // 只读：不响应
        } else {
            row.addAction(UIAction { [weak self] _ in
                self?.openEditor(for: field)
            }, for: .touchUpInside)
        }

        let label = UILabel()
        label.text = field.label
        label.font = .fdBody
        label.textColor = .fdSubtext
        label.setContentHuggingPriority(.required, for: .horizontal)

        let value = UILabel()
        value.font = .fdBody
        value.textColor = .fdText
        value.textAlignment = .right
        value.lineBreakMode = .byTruncatingTail
        valueLabels[field.key] = value

        row.addSubview(label)
        row.addSubview(value)

        label.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.equalTo(88)
        }

        if case .readonly = field.kind {
            value.snp.makeConstraints {
                $0.leading.equalTo(label.snp.trailing).offset(8)
                $0.trailing.equalToSuperview()
                $0.centerY.equalToSuperview()
            }
        } else {
            let arrow = UILabel()
            arrow.text = "›"
            arrow.font = .fdFont(ofSize: 16, weight: .regular)
            arrow.textColor = .fdMuted
            row.addSubview(arrow)
            arrow.snp.makeConstraints {
                $0.trailing.equalToSuperview()
                $0.centerY.equalToSuperview()
            }
            value.snp.makeConstraints {
                $0.leading.equalTo(label.snp.trailing).offset(8)
                $0.trailing.equalTo(arrow.snp.leading).offset(-6)
                $0.centerY.equalToSuperview()
            }
        }

        row.snp.makeConstraints { $0.height.equalTo(44) }
        return row
    }

    // MARK: - Data

    private func loadUserProfile() {
        guard let user = UserManager.shared.currentUser else { return }
        applyUserData(user)
    }

    @objc private func onUserUpdated() {
        loadUserProfile()
    }

    private func applyUserData(_ user: SUsers) {
        let displayName = user.chineseName ?? user.surname ?? user.nickname ?? "用户"
        let char = String(displayName.prefix(1))

        if let urlStr = user.imageUrl, let url = URL(string: urlStr) {
            avatarTextLabel.isHidden = true
            avatarGradient.isHidden = true
            avatarImageView.kf.setImage(with: url)
        } else {
            avatarImageView.image = nil
            avatarTextLabel.isHidden = false
            avatarTextLabel.text = char
            avatarGradient.isHidden = false
        }

        values[.name] = user.chineseName ?? user.surname ?? ""
        values[.gender] = Self.sexDisplay(user.sex)
        values[.birthday] = user.birthday ?? ""
        values[.phone] = maskPhone(user.mobile)
        values[.email] = user.email ?? ""
        values[.occupation] = user.career ?? ""
        values[.education] = user.education ?? ""
        values[.idType] = Self.idTypeDisplay(user.idType)
        values[.idNumber] = user.idNumber ?? ""
        values[.nationality] = user.nationality ?? ""
        values[.ethnic] = user.ethnic ?? ""
        values[.nativePlace] = user.province ?? user.householdProvince ?? ""
        values[.residence] = user.addressProvince ?? ""
        values[.district] = user.addressArea ?? user.addressCity ?? ""
        values[.address] = user.address ?? ""

        refreshAllValueLabels()
    }

    private func refreshAllValueLabels() {
        for section in sections {
            for field in section.fields {
                applyValueLabel(field)
            }
        }
    }

    private func applyValueLabel(_ field: FieldDef) {
        guard let label = valueLabels[field.key] else { return }
        let raw = values[field.key] ?? ""
        if raw.isEmpty {
            label.text = field.placeholder
            if case .readonly = field.kind {
                label.textColor = .fdSubtext
            } else {
                label.textColor = .fdMuted
            }
        } else {
            label.text = raw
            label.textColor = .fdText
        }
    }

    // MARK: - Editor

    private func openEditor(for field: FieldDef) {
        let sheetKind: ProfileFieldEditorSheet.FieldKind
        switch field.kind {
        case .readonly:
            return
        case .text(let keyboard, let maxLength):
            sheetKind = .text(keyboard: keyboard, maxLength: maxLength)
        case .select(let options):
            sheetKind = .select(options: options)
        case .date:
            sheetKind = .date
        }

        let sheet = ProfileFieldEditorSheet(
            title: field.label,
            kind: sheetKind,
            current: values[field.key] ?? ""
        )
        sheet.onSave = { [weak self] value in
            self?.commitField(field, value: value)
        }
        present(sheet, animated: true)
    }

    private func commitField(_ field: FieldDef, value: String) {
        values[field.key] = value
        applyValueLabel(field)
        saveField(field, value: value)
    }

    // MARK: - Save

    private func saveField(_ field: FieldDef, value: String) {
        var payload = SUsersOnboardingPayload()
        payload.mobile = UserDefaults.standard.string(forKey: "current_user_mobile")

        switch field.key {
        case .gender:
            payload.sex = value == "男" ? "1" : (value == "女" ? "2" : nil)
        case .birthday:
            payload.birthday = value
            payload.age = Self.age(from: value)
        case .email:
            payload.email = value
        case .occupation:
            payload.career = value
        case .education:
            payload.education = value
        case .idType:
            payload.idType = Self.idTypeToInt[value]
        case .idNumber:
            payload.idNumber = value
        case .nationality:
            payload.nationality = value
        case .ethnic:
            payload.ethnic = value
        case .nativePlace:
            payload.province = value
        case .residence:
            payload.addressProvince = value
        case .district:
            payload.addressArea = value
        case .address:
            payload.address = value
        case .name, .phone:
            return
        }

        Task {
            do {
                _ = try await UserService.shared.updateCurrentProfile(payload)
                _ = await UserManager.shared.refreshUserInfo()
                await MainActor.run { showToast("\(field.label)已保存") }
            } catch {
                await MainActor.run { showToast("保存失败: \(error.localizedDescription)") }
            }
        }
    }

    // MARK: - Avatar

    @objc private func handleAvatarTap() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let img = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            picker.dismiss(animated: true)
            return
        }
        avatarImageView.image = img
        avatarTextLabel.isHidden = true
        avatarGradient.isHidden = true
        picker.dismiss(animated: true)
        uploadAvatar(img)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func uploadAvatar(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            showToast("图片处理失败")
            return
        }

        let loading = UIActivityIndicatorView(style: .medium)
        loading.color = .white
        loading.startAnimating()
        avatarImageView.addSubview(loading)
        loading.snp.makeConstraints { $0.center.equalToSuperview() }
        avatarLoading = loading

        Task {
            do {
                let url = try await OSSManager.shared.upload(
                    data: data,
                    folderName: "common",
                    ext: "jpg",
                    mimeType: "image/jpeg"
                )
                var payload = SUsersOnboardingPayload()
                payload.mobile = UserDefaults.standard.string(forKey: "current_user_mobile")
                payload.imageUrl = url
                _ = try await UserService.shared.updateCurrentProfile(payload)
                _ = await UserManager.shared.refreshUserInfo()
                await MainActor.run {
                    loading.removeFromSuperview()
                    showToast("头像已更新")
                }
            } catch {
                await MainActor.run {
                    loading.removeFromSuperview()
                    showToast("头像上传失败: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Helpers

    private func maskPhone(_ phone: String?) -> String {
        guard let phone, phone.count == 11 else { return phone ?? "" }
        return "\(phone.prefix(3))****\(phone.suffix(4))"
    }

    private static func sexDisplay(_ sex: String?) -> String {
        switch sex {
        case "1": return "男"
        case "2": return "女"
        default: return ""
        }
    }

    private static func idTypeDisplay(_ type: Int?) -> String {
        guard let type else { return "" }
        return idTypeFromInt[type] ?? ""
    }

    private static func age(from dateStr: String) -> Int? {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        guard let birth = fmt.date(from: dateStr) else { return nil }
        return Calendar.current.dateComponents([.year], from: birth, to: Date()).year
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
