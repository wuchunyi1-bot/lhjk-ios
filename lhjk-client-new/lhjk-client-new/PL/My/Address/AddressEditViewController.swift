import UIKit
import SnapKit

/// 收货地址编辑页（新增 / 修改）
///
/// 表单包含：收货人、手机号、所在地区（省/市/区）、详细地址、邮政编码、是否默认地址
/// - 新增模式：不传 `address`，表单为空，标题为"新增地址"
/// - 修改模式：传入 `address`，直接填充表单（无网络请求），标题为"编辑地址"
///
/// 参考 funde-client 地址编辑表单交互
final class AddressEditViewController: BaseViewController {

    // MARK: - Mode

    private let existingAddress: MAddress?
    private var isEditMode: Bool { existingAddress != nil }

    // MARK: - Form State

    private var nameText: String = ""
    private var mobileText: String = ""
    private var provinceText: String = ""
    private var cityText: String = ""
    private var areaText: String = ""
    private var addressText: String = ""
    private var codeText: String = ""
    private var isDefault: Bool = false

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .onDrag
        return sv
    }()

    private let contentView = UIView()

    private lazy var nameField: UITextField = makeTextField(placeholder: "收货人姓名")
    private lazy var mobileField: UITextField = makeTextField(placeholder: "手机号码", keyboardType: .numberPad)
    private lazy var provinceField: UITextField = makeTextField(placeholder: "省份")
    private lazy var cityField: UITextField = makeTextField(placeholder: "城市")
    private lazy var areaField: UITextField = makeTextField(placeholder: "区/县")
    private lazy var addressField: UITextField = makeTextField(placeholder: "详细地址（街道、门牌号等）")
    private lazy var codeField: UITextField = makeTextField(placeholder: "邮政编码（选填）", keyboardType: .numberPad)

    private lazy var defaultSwitch: UISwitch = {
        let s = UISwitch()
        s.onTintColor = .fdPrimary
        s.addTarget(self, action: #selector(defaultSwitchChanged), for: .valueChanged)
        return s
    }()

    private lazy var saveButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "保存"
        cfg.baseForegroundColor = .white
        cfg.baseBackgroundColor = .fdPrimary
        cfg.cornerStyle = .large
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .fdBodySemibold
            return outgoing
        }
        let b = UIButton(configuration: cfg)
        b.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Init

    init(address: MAddress? = nil) {
        self.existingAddress = address
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = isEditMode ? "编辑地址" : "新增地址"
        view.backgroundColor = .fdBg

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        // 构建表单
        var lastBottom = buildFormFields()
        lastBottom = buildDefaultRow(lastBottom)
        lastBottom = buildSaveButton(lastBottom)

        contentView.snp.makeConstraints { make in
            make.bottom.equalTo(lastBottom).offset(32)
        }

        // 键盘通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

        // 点击空白收起键盘
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        // 编辑模式：直接填充表单
        if let addr = existingAddress {
            fillForm(with: addr)
        }
    }

    // MARK: - Form Builder

    private func buildFormFields() -> ConstraintItem {
        let fields: [(String, UITextField)] = [
            ("收货人", nameField),
            ("手机号", mobileField),
            ("省份", provinceField),
            ("城市", cityField),
            ("区/县", areaField),
            ("详细地址", addressField),
            ("邮政编码", codeField),
        ]

        var last: ConstraintItem = contentView.snp.top

        for (index, (label, field)) in fields.enumerated() {
            let row = makeFormRow(label: label, field: field, isLast: index == fields.count - 1)
            contentView.addSubview(row)
            row.snp.makeConstraints { make in
                make.top.equalTo(last).offset(index == 0 ? 8 : 0)
                make.leading.trailing.equalToSuperview().inset(16).priority(750)
            }
            last = row.snp.bottom
        }

        return last
    }

    private func buildDefaultRow(_ lastBottom: ConstraintItem) -> ConstraintItem {
        let row = UIView()
        row.backgroundColor = .fdSurface
        row.layer.cornerRadius = 14

        let titleLabel = UILabel()
        titleLabel.text = "设为默认地址"
        titleLabel.font = .fdBody
        titleLabel.textColor = .fdText

        row.addSubview(titleLabel)
        row.addSubview(defaultSwitch)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        defaultSwitch.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        row.snp.makeConstraints { $0.height.equalTo(52) }

        contentView.addSubview(row)
        row.snp.makeConstraints { make in
            make.top.equalTo(lastBottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16).priority(750)
        }

        return row.snp.bottom
    }

    private func buildSaveButton(_ lastBottom: ConstraintItem) -> ConstraintItem {
        contentView.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(lastBottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16).priority(750)
            make.height.equalTo(48)
        }
        return saveButton.snp.bottom
    }

    // MARK: - Row Builder

    private func makeFormRow(label: String, field: UITextField, isLast: Bool) -> UIView {
        let row = UIView()
        row.backgroundColor = .fdSurface

        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.font = .fdBody
        titleLabel.textColor = .fdText
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        field.textAlignment = .right
        field.delegate = self

        row.addSubview(titleLabel)
        row.addSubview(field)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(80)
        }
        field.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        // 首行加圆角顶部
        if label == "收货人" {
            row.layer.cornerRadius = 14
            row.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }

        // 末行加圆角底部 + 无分割线
        if isLast {
            // 如果只有普通字段行，给末行加底部圆角
            if label == "邮政编码" {
                row.layer.cornerRadius = 14
                row.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            }
        } else {
            let divider = UIView()
            divider.backgroundColor = .fdBorder
            row.addSubview(divider)
            divider.snp.makeConstraints { make in
                make.leading.equalTo(titleLabel)
                make.trailing.bottom.equalToSuperview()
                make.height.equalTo(1)
            }
        }

        row.snp.makeConstraints { $0.height.equalTo(52) }
        return row
    }

    private func makeTextField(placeholder: String, keyboardType: UIKeyboardType = .default) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.font = .fdBody
        tf.textColor = .fdText
        tf.keyboardType = keyboardType
        tf.returnKeyType = .next
        tf.clearButtonMode = .whileEditing
        return tf
    }

    // MARK: - Fill Form

    private func fillForm(with address: MAddress) {
        nameField.text = address.name
        mobileField.text = address.mobile
        provinceField.text = address.province
        cityField.text = address.city
        areaField.text = address.area
        addressField.text = address.address
        codeField.text = address.code
        defaultSwitch.isOn = address.isDefaultAddress

        nameText = address.name ?? ""
        mobileText = address.mobile ?? ""
        provinceText = address.province ?? ""
        cityText = address.city ?? ""
        areaText = address.area ?? ""
        addressText = address.address ?? ""
        codeText = address.code ?? ""
        isDefault = address.isDefaultAddress
    }

    // MARK: - Validation

    private func validate() -> String? {
        if nameText.trimmingCharacters(in: .whitespaces).isEmpty {
            return "请填写收货人姓名"
        }
        if mobileText.trimmingCharacters(in: .whitespaces).isEmpty {
            return "请填写手机号码"
        }
        let mobile = mobileText.trimmingCharacters(in: .whitespaces)
        if mobile.count != 11 || !mobile.allSatisfy({ $0.isNumber }) {
            return "请输入正确的手机号码"
        }
        if provinceText.trimmingCharacters(in: .whitespaces).isEmpty {
            return "请填写省份"
        }
        if cityText.trimmingCharacters(in: .whitespaces).isEmpty {
            return "请填写城市"
        }
        if areaText.trimmingCharacters(in: .whitespaces).isEmpty {
            return "请填写区/县"
        }
        if addressText.trimmingCharacters(in: .whitespaces).isEmpty {
            return "请填写详细地址"
        }
        return nil
    }

    // MARK: - Save

    @objc private func saveTapped() {
        view.endEditing(true)

        if let error = validate() {
            showToast(error)
            return
        }

        let payload = AddressSavePayload(
            id: existingAddress?.id,
            name: nameText.trimmingCharacters(in: .whitespaces),
            mobile: mobileText.trimmingCharacters(in: .whitespaces),
            isDefault: isDefault ? 1 : 0,
            province: provinceText.trimmingCharacters(in: .whitespaces),
            city: cityText.trimmingCharacters(in: .whitespaces),
            area: areaText.trimmingCharacters(in: .whitespaces),
            address: addressText.trimmingCharacters(in: .whitespaces),
            code: codeText.trimmingCharacters(in: .whitespaces).isEmpty ? nil : codeText.trimmingCharacters(in: .whitespaces)
        )

        saveButton.isEnabled = false
        saveButton.configuration?.showsActivityIndicator = true

        Task {
            do {
                try await AddressService.shared.saveOrUpdateAddress(payload)
                await MainActor.run {
                    self.saveButton.isEnabled = true
                    self.saveButton.configuration?.showsActivityIndicator = false
                    self.showToast(isEditMode ? "地址已更新" : "地址已保存")
                    // 延迟 pop，让用户看到提示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    self.saveButton.isEnabled = true
                    self.saveButton.configuration?.showsActivityIndicator = false
                    self.showToast("保存失败: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc private func defaultSwitchChanged(_ sender: UISwitch) {
        isDefault = sender.isOn
    }

    // MARK: - Keyboard

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }

    @objc private func keyboardWillHide() {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
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

// MARK: - UITextFieldDelegate

extension AddressEditViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        let text = textField.text ?? ""
        switch textField {
        case nameField: nameText = text
        case mobileField: mobileText = text
        case provinceField: provinceText = text
        case cityField: cityText = text
        case areaField: areaText = text
        case addressField: addressText = text
        case codeField: codeText = text
        default: break
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let fields: [UITextField] = [nameField, mobileField, provinceField, cityField, areaField, addressField, codeField]
        if let index = fields.firstIndex(of: textField), index + 1 < fields.count {
            fields[index + 1].becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
