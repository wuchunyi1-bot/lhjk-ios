import UIKit
import SnapKit
import Kingfisher

/// 个人信息页
/// 参考 funde-client: prototype/src/views/me/ProfileView.vue
/// PRD: 03_用户_我的编辑资料_v1.0
///
/// 卡片式布局（UIScrollView）：
///   Card 1 — 账号资料: 头像(可点击) / 手机号(只读) / 用户昵称 / 富德 ID(可复制)
///   Hint  — 基础资料缺失提示条（条件展示）
///   Card 2 — 基础资料: 姓名 / 性别 / 出生日期(+年龄) / 所在城市
///   Card 3 — 收货地址入口
final class ProfileViewController: BaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Editable State

    private var user: SUsers?
    private var nickname: String = ""
    private var name: String = ""
    private var gender: String = ""     // "1"=男, "2"=女
    private var birthDate: String = ""  // "yyyy-MM-dd"
    private var city: String = ""

    // MARK: - Dynamic Labels

    private var avatarImageView: UIImageView?
    private var avatarTextLabel: UILabel?
    private var phoneLabel: UILabel?
    private var nicknameLabel: UILabel?
    private var fundeIdLabel: UILabel?
    private var nameLabel: UILabel?
    private var genderLabel: UILabel?
    private var birthLabel: UILabel?
    private var ageLabel: UILabel?
    private var cityLabel: UILabel?
    private var hintView: UIView?

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()

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

    override func setupUI() {
        title = "个人信息"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        buildStaticContent()
    }

    // MARK: - Build Static Layout

    private func buildStaticContent() {
        var lastBottom: ConstraintItem = contentView.snp.top

        // ==== Card 1: 账号资料 ====

        let card1Title = makeSectionTitle("账号资料")
        contentView.addSubview(card1Title)
        card1Title.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        lastBottom = card1Title.snp.bottom

        let card1 = buildCardContainer()
        contentView.addSubview(card1)
        card1.snp.makeConstraints { make in
            make.top.equalTo(lastBottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        lastBottom = card1.snp.bottom

        let card1Stack = UIStackView(); card1Stack.axis = .vertical
        card1.addSubview(card1Stack)
        card1Stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Row: 头像
        let avatarRow = UIView()
        let avatarImg = UIImageView()
        avatarImg.backgroundColor = .fdPrimary
        avatarImg.layer.cornerRadius = 20
        avatarImg.clipsToBounds = true
        avatarImg.contentMode = .scaleAspectFill
        avatarImg.isUserInteractionEnabled = true
        avatarImg.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleAvatarTap)))
        self.avatarImageView = avatarImg

        let avatarChar = UILabel()
        avatarChar.text = "我"
        avatarChar.font = .fdFont(ofSize: 17, weight: .bold)
        avatarChar.textColor = .white
        avatarChar.textAlignment = .center
        self.avatarTextLabel = avatarChar
        avatarImg.addSubview(avatarChar)
        avatarChar.snp.makeConstraints { $0.center.equalToSuperview() }

        avatarRow.addSubview(avatarImg)
        avatarImg.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-36); $0.centerY.equalToSuperview(); $0.size.equalTo(40) }
        addRowContent(to: avatarRow, label: "头像", valueView: avatarImg, showArrow: true, showDivider: true, action: #selector(handleAvatarTap))

        card1Stack.addArrangedSubview(avatarRow)

        // Row: 手机号 (read-only, no arrow)
        let phoneLbl = UILabel(); phoneLbl.font = .fdBody; phoneLbl.textColor = .fdSubtext; phoneLbl.text = "加载中…"
        self.phoneLabel = phoneLbl
        card1Stack.addArrangedSubview(makeStaticRow(label: "手机号", valueView: phoneLbl, showArrow: false, showDivider: true))

        // Row: 用户昵称
        let nickLbl = UILabel(); nickLbl.font = .fdBody; nickLbl.textColor = .fdSubtext; nickLbl.text = "加载中…"
        self.nicknameLabel = nickLbl
        card1Stack.addArrangedSubview(makeStaticRow(label: "用户昵称", valueView: nickLbl, showArrow: true, showDivider: true, action: #selector(handleNicknameTap)))

        // Row: 富德 ID
        let fidLbl = UILabel(); fidLbl.font = .fdBody; fidLbl.textColor = .fdMuted; fidLbl.text = "加载中…"
        self.fundeIdLabel = fidLbl
        card1Stack.addArrangedSubview(makeStaticRow(label: "富德 ID", valueView: fidLbl, showArrow: true, showDivider: false, action: #selector(handleFundeIdTap), isCopyIcon: true))

        // ==== Hint: 基础资料缺失提示 ====

        let hint = buildHintView()
        hint.isHidden = true
        self.hintView = hint
        contentView.addSubview(hint)
        hint.snp.makeConstraints { make in
            make.top.equalTo(lastBottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        lastBottom = hint.snp.bottom

        // ==== Card 2: 基础资料 ====

        let card2Title = makeSectionTitle("基础资料")
        contentView.addSubview(card2Title)
        card2Title.snp.makeConstraints { make in
            make.top.equalTo(lastBottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        lastBottom = card2Title.snp.bottom

        let card2 = buildCardContainer()
        contentView.addSubview(card2)
        card2.snp.makeConstraints { make in
            make.top.equalTo(lastBottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        lastBottom = card2.snp.bottom

        let card2Stack = UIStackView(); card2Stack.axis = .vertical
        card2.addSubview(card2Stack)
        card2Stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        let nameLbl = UILabel(); nameLbl.font = .fdBody; nameLbl.textColor = .fdSubtext; nameLbl.text = "请填写"
        self.nameLabel = nameLbl
        card2Stack.addArrangedSubview(makeStaticRow(label: "姓名", valueView: nameLbl, showArrow: true, showDivider: true, action: #selector(handleNameTap)))

        let genderLbl = UILabel(); genderLbl.font = .fdBody; genderLbl.textColor = .fdSubtext; genderLbl.text = "请选择"
        self.genderLabel = genderLbl
        card2Stack.addArrangedSubview(makeStaticRow(label: "性别", valueView: genderLbl, showArrow: true, showDivider: true, action: #selector(handleGenderTap)))

        // 出生日期 + 年龄
        let birthRow = UIView()
        let birthLbl = UILabel(); birthLbl.font = .fdBody; birthLbl.textColor = .fdSubtext; birthLbl.text = "请选择"
        self.birthLabel = birthLbl
        let ageLbl = UILabel(); ageLbl.font = .fdCaption; ageLbl.textColor = .fdMuted; ageLbl.text = ""
        self.ageLabel = ageLbl
        let birthValueStack = UIStackView(arrangedSubviews: [birthLbl, ageLbl])
        birthValueStack.axis = .horizontal; birthValueStack.spacing = 4; birthValueStack.alignment = .center
        birthRow.addSubview(birthValueStack)
        birthValueStack.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-36); $0.centerY.equalToSuperview() }
        addRowContent(to: birthRow, label: "出生日期", valueView: birthValueStack, showArrow: true, showDivider: true, action: #selector(handleBirthDateTap))
        card2Stack.addArrangedSubview(birthRow)

        let cityLbl = UILabel(); cityLbl.font = .fdBody; cityLbl.textColor = .fdSubtext; cityLbl.text = "请选择"
        self.cityLabel = cityLbl
        card2Stack.addArrangedSubview(makeStaticRow(label: "所在城市", valueView: cityLbl, showArrow: true, showDivider: false, action: #selector(handleCityTap)))

        // ==== Card 3: 收货地址 ====

        let card3 = buildCardContainer()
        contentView.addSubview(card3)
        card3.snp.makeConstraints { make in
            make.top.equalTo(lastBottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-32)
        }

        let card3Stack = UIStackView(); card3Stack.axis = .vertical
        card3.addSubview(card3Stack)
        card3Stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        card3Stack.addArrangedSubview(makeStaticRow(label: "收货地址", valueView: UIView(), showArrow: true, showDivider: false, action: #selector(handleAddressTap)))
    }

    // MARK: - Row Builders

    private func makeSectionTitle(_ text: String) -> UIView {
        let v = UIView()
        let lbl = UILabel()
        lbl.text = text
        lbl.font = .fdCaptionSemibold
        lbl.textColor = .fdSubtext
        v.addSubview(lbl)
        lbl.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(4); $0.top.bottom.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 0, bottom: 4, right: 0)) }
        return v
    }

    private func buildCardContainer() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        return card
    }

    private func buildHintView() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#FFF3EE")
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.18).cgColor
        let lbl = UILabel()
        lbl.text = "可补充姓名、生日等信息，便于后续服务识别。"
        lbl.font = .fdCaption
        lbl.textColor = .fdPrimary
        lbl.numberOfLines = 0
        v.addSubview(lbl)
        lbl.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        return v
    }

    /// Create a standard row with label on left, valueView on right, optional chevron
    private func makeStaticRow(label: String, valueView: UIView, showArrow: Bool, showDivider: Bool, action: Selector? = nil, isCopyIcon: Bool = false) -> UIView {
        let row = UIView()
        row.isUserInteractionEnabled = true
        if let action = action {
            row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))
        }

        let titleLbl = UILabel()
        titleLbl.text = label
        titleLbl.font = .fdBody
        titleLbl.textColor = .fdText
        titleLbl.setContentHuggingPriority(.required, for: .horizontal)

        row.addSubview(titleLbl)
        row.addSubview(valueView)

        titleLbl.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(72)
        }

        if showArrow || isCopyIcon {
            let iconName = isCopyIcon ? "doc.on.doc" : "chevron.right"
            let icon = UIImageView(image: UIImage(systemName: iconName))
            icon.tintColor = .fdMuted; icon.contentMode = .scaleAspectFit
            row.addSubview(icon)
            icon.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview(); $0.size.equalTo(16) }
            valueView.snp.makeConstraints { make in
                make.trailing.equalTo(icon.snp.leading).offset(-8)
                make.centerY.equalToSuperview()
                make.leading.greaterThanOrEqualTo(titleLbl.snp.trailing).offset(12)
            }
        } else {
            valueView.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
                make.leading.greaterThanOrEqualTo(titleLbl.snp.trailing).offset(12)
            }
        }

        if showDivider {
            let divider = UIView(); divider.backgroundColor = .fdBorder
            row.addSubview(divider)
            divider.snp.makeConstraints { $0.leading.equalTo(titleLbl); $0.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
        }
        row.snp.makeConstraints { $0.height.equalTo(56) }
        return row
    }

    /// Add label + arrow to an existing row view (used when valueView needs special layout)
    private func addRowContent(to row: UIView, label: String, valueView: UIView, showArrow: Bool, showDivider: Bool, action: Selector) {
        let titleLbl = UILabel()
        titleLbl.text = label
        titleLbl.font = .fdBody
        titleLbl.textColor = .fdText
        titleLbl.setContentHuggingPriority(.required, for: .horizontal)

        row.addSubview(titleLbl)
        titleLbl.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(72)
        }

        if showArrow {
            let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
            arrow.tintColor = .fdMuted; arrow.contentMode = .scaleAspectFit
            row.addSubview(arrow)
            arrow.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview(); $0.size.equalTo(16) }
        }

        valueView.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(titleLbl.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        if showDivider {
            let divider = UIView(); divider.backgroundColor = .fdBorder
            row.addSubview(divider)
            divider.snp.makeConstraints { $0.leading.equalTo(titleLbl); $0.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
        }
        row.snp.makeConstraints { $0.height.equalTo(56) }
    }

    // MARK: - Data Loading

    private func loadUserProfile() {
        guard let user = UserManager.shared.currentUser else { return }
        applyUserData(user)
    }

    @objc private func onUserUpdated() {
        loadUserProfile()
    }

    private func applyUserData(_ user: SUsers) {
        self.user = user

        // Avatar
        let displayName = user.chineseName ?? user.surname ?? user.nickname ?? "用户"
        let char = String(displayName.prefix(1))
        if let urlStr = user.imageUrl, let url = URL(string: urlStr) {
            avatarTextLabel?.isHidden = true
            avatarImageView?.kf.setImage(with: url)
            avatarImageView?.backgroundColor = .clear
        } else {
            avatarTextLabel?.isHidden = false
            avatarTextLabel?.text = char
            avatarImageView?.backgroundColor = .fdPrimary
        }

        // Phone
        phoneLabel?.text = maskPhone(user.mobile)

        // Nickname
        nickname = user.nickname ?? ""
        nicknameLabel?.text = nickname.isEmpty ? "用户\(user.id?.prefix(8) ?? "")" : nickname

        // Funde ID
        fundeIdLabel?.text = user.id ?? "—"

        // Name
        name = user.chineseName ?? user.surname ?? ""
        nameLabel?.text = name.isEmpty ? "请填写" : name

        // Gender
        gender = user.sex ?? ""
        genderLabel?.text = sexLabel(gender)

        // Birth date
        birthDate = user.birthday ?? ""
        birthLabel?.text = birthDate.isEmpty ? "请选择" : birthDate
        ageLabel?.text = calcAge(from: birthDate)

        // City
        city = user.addressCity ?? user.address ?? ""
        cityLabel?.text = city.isEmpty ? "请选择" : city

        // Hint
        let incomplete = name.isEmpty || gender.isEmpty || birthDate.isEmpty || city.isEmpty
        hintView?.isHidden = !incomplete
    }

    // MARK: - Helpers

    private func maskPhone(_ phone: String?) -> String {
        guard let phone = phone, phone.count == 11 else { return phone ?? "未设置" }
        return "\(phone.prefix(3))****\(phone.suffix(4))"
    }

    private func sexLabel(_ sex: String?) -> String {
        switch sex {
        case "1": return "男"
        case "2": return "女"
        default: return "请选择"
        }
    }

    private func calcAge(from dateStr: String) -> String {
        guard !dateStr.isEmpty else { return "" }
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        guard let birth = fmt.date(from: dateStr) else { return "" }
        let age = Calendar.current.dateComponents([.year], from: birth, to: Date()).year ?? 0
        return age > 0 ? "\(age)岁" : ""
    }

    // MARK: - Actions

    @objc private func handleAvatarTap() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    @objc private func handleNicknameTap() {
        showTextEditor(title: "修改用户昵称", placeholder: "请输入用户昵称", currentValue: nickname) { [weak self] text in
            self?.nickname = text
            self?.nicknameLabel?.text = text
            self?.updateHint()
            self?.showToast("已保存")
        }
    }

    @objc private func handleFundeIdTap() {
        guard let fid = fundeIdLabel?.text, fid != "加载中…", fid != "—" else { return }
        UIPasteboard.general.string = fid
        showToast("富德 ID 已复制")
    }

    @objc private func handleNameTap() {
        showTextEditor(title: "修改姓名", placeholder: "请输入姓名", currentValue: name) { [weak self] text in
            self?.name = text
            self?.nameLabel?.text = text
            self?.updateHint()
            self?.showToast("已保存")
        }
    }

    @objc private func handleGenderTap() {
        let alert = UIAlertController(title: "选择性别", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "男", style: .default) { [weak self] _ in
            self?.gender = "1"
            self?.genderLabel?.text = "男"
            self?.updateHint()
            self?.showToast("已保存")
        })
        alert.addAction(UIAlertAction(title: "女", style: .default) { [weak self] _ in
            self?.gender = "2"
            self?.genderLabel?.text = "女"
            self?.updateHint()
            self?.showToast("已保存")
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func handleBirthDateTap() {
        let alert = UIAlertController(title: "选择出生日期\n\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .alert)
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Date()
        datePicker.minimumDate = Calendar.current.date(from: DateComponents(year: 1920, month: 1, day: 1))
        if !birthDate.isEmpty {
            let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
            if let d = fmt.date(from: birthDate) { datePicker.date = d }
        }
        alert.view.addSubview(datePicker)
        datePicker.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(44)
            make.centerX.equalToSuperview()
            make.height.equalTo(200)
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
            let dateStr = fmt.string(from: datePicker.date)
            self.birthDate = dateStr
            self.birthLabel?.text = dateStr
            self.ageLabel?.text = self.calcAge(from: dateStr)
            self.updateHint()
            self.showToast("已保存")
        })
        present(alert, animated: true)
    }

    @objc private func handleCityTap() {
        let alert = UIAlertController(title: "选择所在城市", message: nil, preferredStyle: .actionSheet)
        let cities: [(String, [String])] = [
            ("广东省", ["深圳市", "广州市", "佛山市"]),
            ("上海市", ["上海市"]),
            ("北京市", ["北京市"]),
            ("浙江省", ["杭州市", "宁波市"]),
            ("江苏省", ["南京市", "苏州市"]),
        ]
        for (province, cityList) in cities {
            for c in cityList {
                let display = province == c ? c : "\(province) \(c)"
                alert.addAction(UIAlertAction(title: display, style: .default) { [weak self] _ in
                    self?.city = display
                    self?.cityLabel?.text = display
                    self?.updateHint()
                    self?.showToast("已保存")
                })
            }
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func handleAddressTap() {
        Router.shared.push("/me/address")
    }

    private func updateHint() {
        let incomplete = name.isEmpty || gender.isEmpty || birthDate.isEmpty || city.isEmpty
        hintView?.isHidden = !incomplete
    }

    // MARK: - Text Editor Helper

    private func showTextEditor(title: String, placeholder: String, currentValue: String, onSave: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = currentValue
            tf.placeholder = placeholder
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else {
                self?.showToast("请输入\(title.replacingOccurrences(of: "修改", with: ""))")
                return
            }
            onSave(text)
        })
        present(alert, animated: true)
    }

    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let img = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            avatarImageView?.image = img
            avatarImageView?.backgroundColor = .clear
            avatarTextLabel?.isHidden = true
            showToast("头像已更新")
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
