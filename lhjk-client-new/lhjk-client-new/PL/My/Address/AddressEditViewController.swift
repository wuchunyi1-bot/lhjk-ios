import UIKit
import SnapKit
import Combine

/// 收货地址编辑页（新增 / 修改）
///
/// 对齐 funde-client AddressEditView + PRD 04：收货人、手机号、所在地区+定位、详细地址、默认地址。
/// 保存接口不变：`POST /v1/address/saveOrUpdateAddress`。
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

    private lazy var nameField = makeTextField(placeholder: "请输入收货人姓名")
    private lazy var mobileField = makeTextField(placeholder: "请输入收货人手机号码", keyboardType: .numberPad)

    private let regionValueLabel: UILabel = {
        let l = UILabel()
        l.font = .fdBody
        l.textColor = .fdMuted
        l.textAlignment = .right
        l.numberOfLines = 2
        l.text = "请选择省、市、区"
        return l
    }()

    private lazy var locateButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "定位"
        cfg.image = UIImage(systemName: "location")
        cfg.imagePadding = 2
        cfg.baseForegroundColor = .fdPrimary
        cfg.baseBackgroundColor = UIColor.fdPrimary.withAlphaComponent(0.12)
        cfg.cornerStyle = .capsule
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .fdCaptionSemibold
            return outgoing
        }
        let b = UIButton(configuration: cfg)
        b.addTarget(self, action: #selector(locateTapped), for: .touchUpInside)
        return b
    }()

    private lazy var locateSpinner: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .medium)
        i.color = .fdPrimary
        i.hidesWhenStopped = true
        return i
    }()

    private lazy var addressTextView: UITextView = {
        let tv = UITextView()
        tv.font = .fdBody
        tv.textColor = .fdText
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tv.isScrollEnabled = false
        tv.delegate = self
        return tv
    }()

    private let addressPlaceholderLabel: UILabel = {
        let l = UILabel()
        l.text = "小区楼栋、门牌号、村等"
        l.font = .fdBody
        l.textColor = .fdMuted
        return l
    }()

    private lazy var codeField = makeTextField(placeholder: "邮政编码（选填）", keyboardType: .numberPad)

    private lazy var defaultSwitch: UISwitch = {
        let s = UISwitch()
        s.onTintColor = .fdPrimary
        s.addTarget(self, action: #selector(defaultSwitchChanged), for: .valueChanged)
        return s
    }()

    private let defaultHintLabel: UILabel = {
        let l = UILabel()
        l.text = "第一个地址将自动设为默认地址"
        l.font = .fdCaption
        l.textColor = .fdSubtext
        l.numberOfLines = 0
        l.isHidden = true
        return l
    }()

    private lazy var saveButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "保存地址"
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

    init(address: MAddress? = nil, existingAddressCount: Int = 0) {
        self.viewModel = AddressEditViewModel(address: address, existingAddressCount: existingAddressCount)
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

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        let last = buildContent()
        contentView.snp.makeConstraints { make in
            make.bottom.equalTo(last).offset(32)
        }

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
        viewModel.$isLocating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] locating in
                self?.locateButton.isEnabled = !locating
                if locating {
                    self?.locateSpinner.startAnimating()
                } else {
                    self?.locateSpinner.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.$isSaving
            .receive(on: DispatchQueue.main)
            .sink { [weak self] saving in
                self?.saveButton.isEnabled = !saving
                self?.saveButton.configuration?.showsActivityIndicator = saving
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
                self?.showToast(message)
            }
            .store(in: &cancellables)

        viewModel.saveSucceeded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .store(in: &cancellables)
    }

    // MARK: - Build UI

    private func buildContent() -> ConstraintItem {
        var last = contentView.snp.top

        let infoTitle = sectionTitle("收货信息")
        contentView.addSubview(infoTitle)
        infoTitle.snp.makeConstraints { make in
            make.top.equalTo(last).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        last = infoTitle.snp.bottom

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 14
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalTo(last).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        let nameRow = makeLabeledRow(title: "收货人", content: nameField)
        let mobileRow = makeLabeledRow(title: "手机号", content: mobileField)
        let regionRow = makeRegionRow()
        let detailRow = makeDetailRow()
        let codeRow = makeLabeledRow(title: "邮政编码", content: codeField, showDivider: false)

        let stack = UIStackView(arrangedSubviews: [nameRow, mobileRow, regionRow, detailRow, codeRow])
        stack.axis = .vertical
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        last = card.snp.bottom

        let defaultTitle = sectionTitle("默认设置")
        contentView.addSubview(defaultTitle)
        defaultTitle.snp.makeConstraints { make in
            make.top.equalTo(last).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        last = defaultTitle.snp.bottom

        let defaultCard = UIView()
        defaultCard.backgroundColor = .fdSurface
        defaultCard.layer.cornerRadius = 14
        contentView.addSubview(defaultCard)
        defaultCard.snp.makeConstraints { make in
            make.top.equalTo(last).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(52)
        }

        let defaultLabel = UILabel()
        defaultLabel.text = "设为默认地址"
        defaultLabel.font = .fdBody
        defaultLabel.textColor = .fdText
        defaultCard.addSubview(defaultLabel)
        defaultCard.addSubview(defaultSwitch)
        defaultLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        defaultSwitch.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        last = defaultCard.snp.bottom

        contentView.addSubview(defaultHintLabel)
        defaultHintLabel.snp.makeConstraints { make in
            make.top.equalTo(last).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        last = defaultHintLabel.snp.bottom

        contentView.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(last).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
        return saveButton.snp.bottom
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .fdCaptionSemibold
        l.textColor = .fdSubtext
        return l
    }

    private func makeLabeledRow(title: String, content: UIView, showDivider: Bool = true) -> UIView {
        let row = UIView()
        row.snp.makeConstraints { $0.height.equalTo(52) }

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .fdBody
        titleLabel.textColor = .fdText
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        row.addSubview(titleLabel)
        row.addSubview(content)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(72)
        }
        content.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        if showDivider {
            addDivider(to: row, leading: titleLabel)
        }
        return row
    }

    private func makeRegionRow() -> UIView {
        let row = UIView()
        row.snp.makeConstraints { $0.height.greaterThanOrEqualTo(52) }

        let titleLabel = UILabel()
        titleLabel.text = "所在地区"
        titleLabel.font = .fdBody
        titleLabel.textColor = .fdText

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .fdMuted
        chevron.contentMode = .scaleAspectFit
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        row.addSubview(titleLabel)
        row.addSubview(regionValueLabel)
        row.addSubview(locateButton)
        row.addSubview(locateSpinner)
        row.addSubview(chevron)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(72)
        }
        locateButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
        }
        locateSpinner.snp.makeConstraints { make in
            make.center.equalTo(locateButton)
        }
        chevron.snp.makeConstraints { make in
            make.trailing.equalTo(locateButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }
        regionValueLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
            make.trailing.equalTo(chevron.snp.leading).offset(-6)
            make.top.bottom.equalToSuperview().inset(12)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(regionRowTapped))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        row.addGestureRecognizer(tap)
        row.isUserInteractionEnabled = true

        addDivider(to: row, leading: titleLabel)
        return row
    }

    private func makeDetailRow() -> UIView {
        let row = UIView()

        let titleLabel = UILabel()
        titleLabel.text = "详细地址"
        titleLabel.font = .fdBody
        titleLabel.textColor = .fdText

        row.addSubview(titleLabel)
        row.addSubview(addressTextView)
        row.addSubview(addressPlaceholderLabel)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(14)
            make.width.equalTo(72)
        }
        addressTextView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(4)
            make.trailing.equalToSuperview().inset(12)
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
            make.height.greaterThanOrEqualTo(72)
        }
        addressPlaceholderLabel.snp.makeConstraints { make in
            make.leading.equalTo(addressTextView).offset(5)
            make.top.equalTo(addressTextView).offset(8)
        }

        addDivider(to: row, leading: titleLabel)
        return row
    }

    private func addDivider(to row: UIView, leading: UIView) {
        let divider = UIView()
        divider.backgroundColor = .fdBorder
        row.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.leading.equalTo(leading)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
    }

    private func makeTextField(placeholder: String, keyboardType: UIKeyboardType = .default) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.font = .fdBody
        tf.textColor = .fdText
        tf.textAlignment = .right
        tf.keyboardType = keyboardType
        tf.returnKeyType = .next
        tf.clearButtonMode = .whileEditing
        tf.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        return tf
    }

    private func applyInitialForm() {
        nameField.text = viewModel.name
        mobileField.text = viewModel.mobile
        addressTextView.text = viewModel.address
        addressPlaceholderLabel.isHidden = !viewModel.address.isEmpty
        codeField.text = viewModel.code
        defaultSwitch.isOn = viewModel.isDefault
        defaultSwitch.isEnabled = viewModel.isDefaultSwitchEnabled
        defaultHintLabel.isHidden = viewModel.isDefaultSwitchEnabled
        refreshRegionLabel()
    }

    private func refreshRegionLabel() {
        let text = viewModel.regionDisplayText
        if text.isEmpty {
            regionValueLabel.text = "请选择省、市、区"
            regionValueLabel.textColor = .fdMuted
        } else {
            regionValueLabel.text = text
            regionValueLabel.textColor = .fdText
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
        case codeField: viewModel.code = text
        default: break
        }
    }

    @objc private func defaultSwitchChanged(_ sender: UISwitch) {
        viewModel.isDefault = sender.isOn
    }

    @objc private func locateTapped() {
        view.endEditing(true)
        Task { await viewModel.locate() }
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
        let alert = UIAlertController(title: "编辑所在地区", message: "请填写省、市、区", preferredStyle: .alert)
        alert.addTextField { [weak self] tf in
            tf.placeholder = "省份"
            tf.text = self?.viewModel.province
        }
        alert.addTextField { [weak self] tf in
            tf.placeholder = "城市"
            tf.text = self?.viewModel.city
        }
        alert.addTextField { [weak self] tf in
            tf.placeholder = "区/县"
            tf.text = self?.viewModel.area
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let fields = alert.textFields, fields.count >= 3 else { return }
            self?.viewModel.province = fields[0].text ?? ""
            self?.viewModel.city = fields[1].text ?? ""
            self?.viewModel.area = fields[2].text ?? ""
        })
        present(alert, animated: true)
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

    // MARK: - Toast

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
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
        !(touch.view is UIControl) && !(touch.view?.isDescendant(of: locateButton) ?? false)
    }
}
