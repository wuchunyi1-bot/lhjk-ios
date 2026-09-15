import UIKit
import SnapKit
import Combine

/// 添加 / 编辑收货地址 — 对齐 Figma 4522:6521 / 4522:6675
final class AddressEditViewController: BaseViewController {

    // MARK: - ViewModel

    private let viewModel: AddressEditViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .onDrag
        return sv
    }()

    private let contentView = UIView()
    private let stackView = UIStackView()
    private let bottomBar = UIView()

    private lazy var nameField = makeTextField(placeholder: "请输入收货人姓名")
    private lazy var mobileField = makeTextField(placeholder: "请输入收货人手机号码", keyboardType: .numberPad)

    private let regionValueLabel: UILabel = {
        let l = UILabel()
        l.font = AddressStyle.fieldFont
        l.textColor = AddressStyle.placeholderColor
        l.numberOfLines = 1
        l.text = "请选择省、市、区、街道"
        return l
    }()

    private let regionChevron: UIImageView = {
        let iv = UIImageView(image: AddressIcons.open())
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private lazy var addressTextView: UITextView = {
        let tv = UITextView()
        tv.font = AddressStyle.fieldFont
        tv.textColor = .fdText
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.isScrollEnabled = false
        tv.delegate = self
        return tv
    }()

    private let addressPlaceholderLabel: UILabel = {
        let l = UILabel()
        l.text = "小区楼栋、门牌号、村等"
        l.font = AddressStyle.fieldFont
        l.textColor = AddressStyle.placeholderColor
        return l
    }()

    private lazy var defaultSwitch: UISwitch = {
        let s = UISwitch()
        s.onTintColor = .fdPrimary
        s.addTarget(self, action: #selector(defaultSwitchChanged), for: .valueChanged)
        return s
    }()

    private lazy var saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("保存地址", for: .normal)
        btn.titleLabel?.font = AddressStyle.buttonFont
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .fdPrimary
        btn.layer.cornerRadius = AddressStyle.primaryButtonRadius
        btn.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: - Init

    init(address: MAddress? = nil) {
        self.viewModel = AddressEditViewModel(address: address)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = viewModel.navigationTitle
        view.backgroundColor = .fdBg

        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
        }

        bottomBar.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(AddressStyle.primaryButtonHeight)
        }

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top).offset(-16)
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }

        stackView.axis = .vertical
        stackView.spacing = 12
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(AddressStyle.horizontalInset)
            make.bottom.equalToSuperview().offset(-12)
        }

        stackView.addArrangedSubview(makeSectionTitle("收货信息"))
        stackView.setCustomSpacing(8, after: stackView.arrangedSubviews.last!)
        stackView.addArrangedSubview(makeFormCard())
        stackView.addArrangedSubview(makeSectionTitle("默认设置"))
        stackView.setCustomSpacing(8, after: stackView.arrangedSubviews.last!)
        stackView.addArrangedSubview(makeDefaultCard())

        applyInitialForm()
        setupKeyboardDismiss()

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
    }

    override func bindViewModel() {
        viewModel.$isSaving
            .receive(on: DispatchQueue.main)
            .sink { [weak self] saving in
                self?.saveButton.isEnabled = !saving
                self?.saveButton.alpha = saving ? 0.6 : 1
                self?.saveButton.setTitle(saving ? "保存中..." : "保存地址", for: .normal)
            }
            .store(in: &cancellables)

        Publishers.CombineLatest3(viewModel.$province, viewModel.$city, viewModel.$area)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
                self?.refreshRegionLabel()
            }
            .store(in: &cancellables)

        viewModel.$address
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self else { return }
                if self.addressTextView.text != text {
                    self.addressTextView.text = text
                }
                self.addressPlaceholderLabel.isHidden = !text.isEmpty
            }
            .store(in: &cancellables)

        viewModel.toastMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showToastAlert(message, duration: 1.5)
            }
            .store(in: &cancellables)

        viewModel.saveSucceeded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self, let nav = self.navigationController else { return }
                nav.popViewController(animated: true)
                DispatchQueue.main.async {
                    nav.topViewController?.showToastAlert("地址已保存", duration: 1.2)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Build UI

    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 13, weight: .semibold)
        label.textColor = .fdSubtext
        return label
    }

    private func makeFormCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = AddressStyle.cardRadius
        card.clipsToBounds = true

        let rows: [UIView] = [
            makeLabeledRow(title: "收货人", content: nameField),
            makeLabeledRow(title: "手机号", content: mobileField),
            makeRegionRow(),
            makeDetailRow(),
        ]

        let innerStack = UIStackView(arrangedSubviews: rows)
        innerStack.axis = .vertical
        card.addSubview(innerStack)
        innerStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        return card
    }

    private func makeDefaultCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = AddressStyle.cardRadius

        let label = UILabel()
        label.text = "设为默认地址"
        label.font = AddressStyle.fieldMediumFont
        label.textColor = .fdText

        card.addSubview(label)
        card.addSubview(defaultSwitch)

        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AddressStyle.cardHorizontalInset)
            make.centerY.equalToSuperview()
        }

        defaultSwitch.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-AddressStyle.cardHorizontalInset)
            make.centerY.equalToSuperview()
        }

        card.snp.makeConstraints { $0.height.equalTo(53) }
        return card
    }

    private func makeLabeledRow(title: String, content: UIView, showDivider: Bool = true) -> UIView {
        let row = UIView()
        row.snp.makeConstraints { $0.height.equalTo(AddressStyle.rowHeight) }

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = AddressStyle.fieldFont
        titleLabel.textColor = .fdText
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        row.addSubview(titleLabel)
        row.addSubview(content)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AddressStyle.cardHorizontalInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(AddressStyle.labelWidth)
        }

        content.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(86)
            make.trailing.equalToSuperview().offset(-AddressStyle.cardHorizontalInset)
            make.centerY.equalToSuperview()
        }

        if showDivider {
            let divider = AddressFormDivider.make()
            row.addSubview(divider)
            divider.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(AddressStyle.cardHorizontalInset)
                make.bottom.equalToSuperview()
            }
        }
        return row
    }

    private func makeRegionRow() -> UIView {
        let row = UIView()
        row.snp.makeConstraints { $0.height.equalTo(AddressStyle.rowHeight) }

        let titleLabel = UILabel()
        titleLabel.text = "所在地区"
        titleLabel.font = AddressStyle.fieldFont
        titleLabel.textColor = .fdText

        let valueStack = UIStackView(arrangedSubviews: [regionValueLabel, regionChevron])
        valueStack.axis = .horizontal
        valueStack.spacing = 4
        valueStack.alignment = .center

        row.addSubview(titleLabel)
        row.addSubview(valueStack)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AddressStyle.cardHorizontalInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(AddressStyle.labelWidth)
        }

        regionChevron.snp.makeConstraints { $0.size.equalTo(12) }

        valueStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(86)
            make.trailing.equalToSuperview().offset(-AddressStyle.cardHorizontalInset)
            make.centerY.equalToSuperview()
        }

        let divider = AddressFormDivider.make()
        row.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(AddressStyle.cardHorizontalInset)
            make.bottom.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(regionRowTapped))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        row.addGestureRecognizer(tap)
        row.isUserInteractionEnabled = true
        return row
    }

    private func makeDetailRow() -> UIView {
        let row = UIView()

        let titleLabel = UILabel()
        titleLabel.text = "详细地址"
        titleLabel.font = AddressStyle.fieldFont
        titleLabel.textColor = .fdText

        row.addSubview(titleLabel)
        row.addSubview(addressTextView)
        row.addSubview(addressPlaceholderLabel)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AddressStyle.cardHorizontalInset)
            make.top.equalToSuperview().offset(16)
            make.width.equalTo(AddressStyle.labelWidth)
        }

        addressTextView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(86)
            make.trailing.equalToSuperview().offset(-AddressStyle.cardHorizontalInset)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.height.greaterThanOrEqualTo(44)
        }

        addressPlaceholderLabel.snp.makeConstraints { make in
            make.leading.equalTo(addressTextView)
            make.top.equalTo(addressTextView)
        }

        return row
    }

    private func makeTextField(placeholder: String, keyboardType: UIKeyboardType = .default) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.font = AddressStyle.fieldFont
        tf.textColor = .fdText
        tf.textAlignment = .left
        tf.keyboardType = keyboardType
        tf.returnKeyType = .next
        tf.clearButtonMode = .whileEditing
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: AddressStyle.placeholderColor]
        )
        tf.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        return tf
    }

    private func applyInitialForm() {
        nameField.text = viewModel.name
        mobileField.text = viewModel.mobile
        addressTextView.text = viewModel.address
        addressPlaceholderLabel.isHidden = !viewModel.address.isEmpty
        defaultSwitch.isOn = viewModel.isDefault
        refreshRegionLabel()
    }

    private func refreshRegionLabel() {
        let text = viewModel.regionDisplayText
        if text.isEmpty {
            regionValueLabel.text = "请选择省、市、区、街道"
            regionValueLabel.textColor = AddressStyle.placeholderColor
            regionChevron.isHidden = false
        } else {
            regionValueLabel.text = text
            regionValueLabel.textColor = .fdText
            regionChevron.isHidden = false
        }
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - Actions

    @objc private func textFieldChanged(_ field: UITextField) {
        let text = field.text ?? ""
        switch field {
        case nameField: viewModel.name = text
        case mobileField: viewModel.mobile = text
        default: break
        }
    }

    @objc private func defaultSwitchChanged(_ sender: UISwitch) {
        viewModel.isDefault = sender.isOn
    }

    @objc private func regionRowTapped() {
        presentRegionEditor()
    }

    @objc private func saveTapped() {
        view.endEditing(true)
        Task { await viewModel.save() }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func presentRegionEditor() {
        let current = RegionSelection(
            province: viewModel.province,
            city: viewModel.city,
            district: viewModel.area
        )
        let sheet = RegionPickerSheet(
            title: "所在地区",
            mode: .provinceCityArea,
            current: current,
            sheetTitle: "选择省市区街道"
        )
        sheet.onSave = { [weak self] selection in
            self?.viewModel.province = selection.province
            self?.viewModel.city = selection.city
            self?.viewModel.area = selection.district
        }
        present(sheet, animated: true)
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
}

// MARK: - UITextViewDelegate

extension AddressEditViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        viewModel.address = textView.text ?? ""
        addressPlaceholderLabel.isHidden = !(textView.text ?? "").isEmpty
    }
}

// MARK: - UIGestureRecognizerDelegate

extension AddressEditViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !(touch.view is UIControl)
    }
}
