import UIKit
import SnapKit

/// 个人信息字段底部编辑弹层 — 对齐 ProfileView.vue van-popup editor
final class ProfileFieldEditorSheet: UIViewController {

    enum FieldKind {
        case text(keyboard: UIKeyboardType, maxLength: Int)
        case select(options: [String])
        case date
    }

    var onSave: ((String) -> Void)?

    private let fieldTitle: String
    private let kind: FieldKind
    private var draft: String

    private let dimView = UIView()
    private let panel = UIView()
    private let cancelBtn = UIButton(type: .system)
    private let titleLbl = UILabel()
    private let saveBtn = UIButton(type: .system)
    private let textField = UITextField()
    private let datePicker = UIDatePicker()
    private let optionsStack = UIStackView()
    private let optionsScroll = UIScrollView()

    init(title: String, kind: FieldKind, current: String) {
        self.fieldTitle = title
        self.kind = kind
        self.draft = current
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

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
        cancelBtn.titleLabel?.font = .fdBody
        cancelBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)

        titleLbl.text = "编辑\(fieldTitle)"
        titleLbl.font = .fdBodySemibold
        titleLbl.textColor = .fdText
        titleLbl.textAlignment = .center

        saveBtn.setTitle("保存", for: .normal)
        saveBtn.setTitleColor(UIColor(hexString: "#3D6FB8"), for: .normal)
        saveBtn.titleLabel?.font = .fdBodySemibold
        saveBtn.addTarget(self, action: #selector(save), for: .touchUpInside)

        let hd = UIStackView(arrangedSubviews: [cancelBtn, titleLbl, saveBtn])
        hd.axis = .horizontal
        hd.distribution = .equalCentering
        hd.alignment = .center
        panel.addSubview(hd)

        let divider = UIView()
        divider.backgroundColor = .fdBorder
        panel.addSubview(divider)

        hd.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(36)
        }
        cancelBtn.snp.makeConstraints { $0.width.greaterThanOrEqualTo(44) }
        saveBtn.snp.makeConstraints { $0.width.greaterThanOrEqualTo(44) }
        divider.snp.makeConstraints {
            $0.top.equalTo(hd.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }

        switch kind {
        case .text(let keyboard, let maxLength):
            textField.text = draft
            textField.placeholder = "请输入\(fieldTitle)"
            textField.font = .fdBody
            textField.textColor = .fdText
            textField.keyboardType = keyboard
            textField.backgroundColor = UIColor(hexString: "#F5F7FA")
            textField.layer.cornerRadius = 8
            textField.layer.borderWidth = 1
            textField.layer.borderColor = UIColor(hexString: "#E4E9F1").cgColor
            textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
            textField.leftViewMode = .always
            textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
            textField.rightViewMode = .always
            textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
            textField.tag = maxLength
            panel.addSubview(textField)
            textField.snp.makeConstraints {
                $0.top.equalTo(divider.snp.bottom).offset(16)
                $0.leading.trailing.equalToSuperview().inset(16)
                $0.height.equalTo(44)
                $0.bottom.equalTo(panel.safeAreaLayoutGuide).offset(-24)
            }

        case .date:
            datePicker.datePickerMode = .date
            datePicker.preferredDatePickerStyle = .wheels
            datePicker.maximumDate = Date()
            datePicker.minimumDate = Calendar.current.date(from: DateComponents(year: 1920, month: 1, day: 1))
            let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
            if let d = fmt.date(from: draft) { datePicker.date = d }
            panel.addSubview(datePicker)
            datePicker.snp.makeConstraints {
                $0.top.equalTo(divider.snp.bottom).offset(8)
                $0.leading.trailing.equalToSuperview()
                $0.height.equalTo(200)
                $0.bottom.equalTo(panel.safeAreaLayoutGuide).offset(-16)
            }

        case .select(let options):
            optionsStack.axis = .vertical
            optionsStack.spacing = 8
            optionsScroll.addSubview(optionsStack)
            panel.addSubview(optionsScroll)
            optionsScroll.snp.makeConstraints {
                $0.top.equalTo(divider.snp.bottom).offset(16)
                $0.leading.trailing.equalToSuperview().inset(16)
                $0.height.equalTo(min(360, CGFloat(options.count) * 52))
                $0.bottom.equalTo(panel.safeAreaLayoutGuide).offset(-24)
            }
            optionsStack.snp.makeConstraints {
                $0.edges.width.equalToSuperview()
            }
            for opt in options {
                let btn = UIButton(type: .system)
                btn.setTitle(opt, for: .normal)
                btn.contentHorizontalAlignment = .left
                btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
                btn.titleLabel?.font = .fdBody
                btn.layer.cornerRadius = 8
                btn.layer.borderWidth = 1
                applyOptionStyle(btn, selected: opt == draft)
                btn.addAction(UIAction { [weak self] _ in
                    guard let self else { return }
                    self.draft = opt
                    self.optionsStack.arrangedSubviews.compactMap { $0 as? UIButton }.forEach {
                        self.applyOptionStyle($0, selected: $0.title(for: .normal) == opt)
                    }
                }, for: .touchUpInside)
                optionsStack.addArrangedSubview(btn)
            }
        }

        panel.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if case .text = kind { textField.becomeFirstResponder() }
    }

    private func applyOptionStyle(_ btn: UIButton, selected: Bool) {
        if selected {
            btn.backgroundColor = UIColor(hexString: "#3D6FB8").withAlphaComponent(0.08)
            btn.layer.borderColor = UIColor(hexString: "#3D6FB8").cgColor
            btn.setTitleColor(UIColor(hexString: "#3D6FB8"), for: .normal)
            btn.titleLabel?.font = .fdBodySemibold
        } else {
            btn.backgroundColor = UIColor(hexString: "#F7F8FA")
            btn.layer.borderColor = UIColor.fdBorder.cgColor
            btn.setTitleColor(.fdText, for: .normal)
            btn.titleLabel?.font = .fdBody
        }
    }

    @objc private func textChanged() {
        draft = textField.text ?? ""
        let maxLen = textField.tag
        if maxLen > 0, draft.count > maxLen {
            draft = String(draft.prefix(maxLen))
            textField.text = draft
        }
    }

    @objc private func cancel() { dismiss(animated: true) }

    @objc private func save() {
        let value: String
        switch kind {
        case .date:
            let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
            value = fmt.string(from: datePicker.date)
        case .text, .select:
            value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !value.isEmpty else {
            showToast("请填写\(fieldTitle)")
            return
        }
        if fieldTitle == "邮箱", !value.contains("@") {
            showToast("请输入正确的邮箱格式")
            return
        }
        onSave?(value)
        dismiss(animated: true)
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}
