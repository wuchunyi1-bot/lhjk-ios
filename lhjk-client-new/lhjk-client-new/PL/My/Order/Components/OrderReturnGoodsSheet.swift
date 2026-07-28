import UIKit
import SnapKit

/// 去退货底部抽屉 — 对齐 funde `OrderReturnDialog.vue`（接口未出，仅 UI + 校验）
final class OrderReturnGoodsSheet: UIViewController {

    enum Method: Equatable {
        case selfDelivery
        case expressReturn
    }

    struct Submission: Equatable {
        let method: Method
        let logisticsCompany: String?
        let trackingNo: String?
    }

    /// 校验通过后回调；当前无接口时由调用方决定是否 Toast
    var onSubmit: ((Submission) -> Void)?

    private let returnAddressText: String

    private let dimView = UIView()
    private let panel = UIView()
    private let grabber = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let selfDeliveryButton = UIButton(type: .system)
    private let expressButton = UIButton(type: .system)
    private let addressBox = UIView()
    private let addressCaption = UILabel()
    private let addressValue = UILabel()
    private let logisticsStack = UIStackView()
    private let logisticsCompanyButton = UIButton(type: .system)
    private let trackingField = UITextField()
    private let cancelButton = UIButton(type: .system)
    private let submitButton = UIButton(type: .system)

    private var selectedMethod: Method?
    private var selectedCompany: String?
    private let logisticsCompanies = ["顺丰速运", "京东物流", "中通快递", "圆通速递"]

    init(returnAddress: String? = nil) {
        let trimmed = returnAddress?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.returnAddressText = trimmed.isEmpty ? "退货地址待补充" : trimmed
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        buildUI()
        applyMethodSelection(nil)
        updateLogisticsCompanyTitle()
    }

    // MARK: - UI

    private func buildUI() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissSheet)))
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        panel.backgroundColor = .fdSurface
        panel.layer.cornerRadius = 16
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(panel)
        panel.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }

        grabber.backgroundColor = .fdBorder
        grabber.layer.cornerRadius = 2
        panel.addSubview(grabber)
        grabber.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(36)
            $0.height.equalTo(4)
        }

        titleLabel.text = "去退货"
        titleLabel.font = .fdH3
        titleLabel.textColor = .fdText
        panel.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(grabber.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        subtitleLabel.text = "请选择退货方式并提交退货信息。"
        subtitleLabel.font = .fdCaption
        subtitleLabel.textColor = .fdSubtext
        subtitleLabel.numberOfLines = 0
        panel.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        styleMethodButton(selfDeliveryButton, title: "自行送回")
        styleMethodButton(expressButton, title: "快递寄回")
        selfDeliveryButton.addTarget(self, action: #selector(selectSelfDelivery), for: .touchUpInside)
        expressButton.addTarget(self, action: #selector(selectExpress), for: .touchUpInside)

        let methodsRow = UIStackView(arrangedSubviews: [selfDeliveryButton, expressButton])
        methodsRow.axis = .horizontal
        methodsRow.spacing = 12
        methodsRow.distribution = .fillEqually
        panel.addSubview(methodsRow)
        methodsRow.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }

        addressBox.backgroundColor = .fdSurface2
        addressBox.layer.cornerRadius = 8

        addressCaption.text = "送回地址"
        addressCaption.font = .fdCaption
        addressCaption.textColor = .fdSubtext
        addressValue.text = returnAddressText
        addressValue.font = .fdBodySemibold
        addressValue.textColor = .fdText
        addressValue.numberOfLines = 0
        let addressCol = UIStackView(arrangedSubviews: [addressCaption, addressValue])
        addressCol.axis = .vertical
        addressCol.spacing = 8
        addressBox.addSubview(addressCol)
        addressCol.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
        }

        logisticsStack.axis = .vertical
        logisticsStack.spacing = 16

        logisticsCompanyButton.contentHorizontalAlignment = .left
        logisticsCompanyButton.titleLabel?.font = .fdBody
        logisticsCompanyButton.setTitleColor(.fdText, for: .normal)
        logisticsCompanyButton.backgroundColor = .fdSurface
        logisticsCompanyButton.layer.cornerRadius = 8
        logisticsCompanyButton.layer.borderWidth = 1
        logisticsCompanyButton.layer.borderColor = UIColor.fdBorder.cgColor
        logisticsCompanyButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        logisticsCompanyButton.snp.makeConstraints { $0.height.equalTo(44) }
        logisticsCompanyButton.addTarget(self, action: #selector(pickLogisticsCompany), for: .touchUpInside)

        trackingField.font = .fdBody
        trackingField.textColor = .fdText
        trackingField.placeholder = "请输入物流单号"
        trackingField.borderStyle = .none
        trackingField.backgroundColor = .fdSurface
        trackingField.layer.cornerRadius = 8
        trackingField.layer.borderWidth = 1
        trackingField.layer.borderColor = UIColor.fdBorder.cgColor
        trackingField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        trackingField.leftViewMode = .always
        trackingField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        trackingField.rightViewMode = .always
        trackingField.autocapitalizationType = .allCharacters
        trackingField.returnKeyType = .done
        trackingField.delegate = self
        trackingField.snp.makeConstraints { $0.height.equalTo(44) }

        let companyField = makeLabeledField(
            title: "物流名称",
            required: true,
            control: logisticsCompanyButton
        )
        let trackingLabeled = makeLabeledField(title: "物流单号", required: true, control: trackingField)
        logisticsStack.addArrangedSubview(companyField)
        logisticsStack.addArrangedSubview(trackingLabeled)

        let detailStack = UIStackView(arrangedSubviews: [addressBox, logisticsStack])
        detailStack.axis = .vertical
        detailStack.spacing = 16
        panel.addSubview(detailStack)
        detailStack.snp.makeConstraints {
            $0.top.equalTo(methodsRow.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(.fdText, for: .normal)
        cancelButton.titleLabel?.font = .fdBodySemibold
        cancelButton.backgroundColor = .fdSurface
        cancelButton.layer.cornerRadius = 22
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor.fdBorder.cgColor
        cancelButton.addTarget(self, action: #selector(dismissSheet), for: .touchUpInside)

        submitButton.setTitle("提交", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = .fdBodySemibold
        submitButton.backgroundColor = .fdPrimary
        submitButton.layer.cornerRadius = 22
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)

        let actions = UIStackView(arrangedSubviews: [cancelButton, submitButton])
        actions.axis = .horizontal
        actions.spacing = 12
        actions.distribution = .fillEqually
        panel.addSubview(actions)
        actions.snp.makeConstraints {
            $0.top.equalTo(detailStack.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
            $0.bottom.equalTo(panel.safeAreaLayoutGuide).offset(-12)
        }
    }

    private func styleMethodButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .fdBody
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.backgroundColor = .fdSurface
    }

    private func makeLabeledField(title: String, required: Bool, control: UIView) -> UIView {
        let titleLabel = UILabel()
        let attr = NSMutableAttributedString(
            string: title + " ",
            attributes: [
                .font: UIFont.fdBodySemibold,
                .foregroundColor: UIColor.fdText,
            ]
        )
        if required {
            attr.append(NSAttributedString(
                string: "*",
                attributes: [
                    .font: UIFont.fdBodySemibold,
                    .foregroundColor: UIColor.fdDanger,
                ]
            ))
        }
        titleLabel.attributedText = attr
        let col = UIStackView(arrangedSubviews: [titleLabel, control])
        col.axis = .vertical
        col.spacing = 8
        return col
    }

    private func applyMethodSelection(_ method: Method?) {
        selectedMethod = method
        let selfSelected = method == .selfDelivery
        let expressSelected = method == .expressReturn

        paintMethodButton(selfDeliveryButton, selected: selfSelected)
        paintMethodButton(expressButton, selected: expressSelected)

        addressBox.isHidden = !selfSelected
        logisticsStack.isHidden = !expressSelected
    }

    private func paintMethodButton(_ button: UIButton, selected: Bool) {
        if selected {
            button.layer.borderColor = UIColor.fdPrimary.cgColor
            button.backgroundColor = .fdPrimarySoft
            button.setTitleColor(.fdPrimary, for: .normal)
        } else {
            button.layer.borderColor = UIColor.fdBorder.cgColor
            button.backgroundColor = .fdSurface
            button.setTitleColor(.fdText, for: .normal)
        }
    }

    private func updateLogisticsCompanyTitle() {
        if let selectedCompany {
            logisticsCompanyButton.setTitle(selectedCompany, for: .normal)
            logisticsCompanyButton.setTitleColor(.fdText, for: .normal)
        } else {
            logisticsCompanyButton.setTitle("请选择物流名称", for: .normal)
            logisticsCompanyButton.setTitleColor(.fdMuted, for: .normal)
        }
    }

    // MARK: - Actions

    @objc private func selectSelfDelivery() {
        view.endEditing(true)
        applyMethodSelection(.selfDelivery)
    }

    @objc private func selectExpress() {
        applyMethodSelection(.expressReturn)
    }

    @objc private func pickLogisticsCompany() {
        let sheet = UIAlertController(title: "选择物流名称", message: nil, preferredStyle: .actionSheet)
        for name in logisticsCompanies {
            sheet.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in
                self?.selectedCompany = name
                self?.updateLogisticsCompanyTitle()
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = logisticsCompanyButton
            pop.sourceRect = logisticsCompanyButton.bounds
        }
        present(sheet, animated: true)
    }

    @objc private func dismissSheet() {
        view.endEditing(true)
        dismiss(animated: true)
    }

    @objc private func submit() {
        view.endEditing(true)
        guard let method = selectedMethod else {
            presentToast("请选择退货方式")
            return
        }
        switch method {
        case .selfDelivery:
            onSubmit?(.init(method: .selfDelivery, logisticsCompany: nil, trackingNo: nil))
        case .expressReturn:
            guard let company = selectedCompany, !company.isEmpty else {
                presentToast("请选择物流名称")
                return
            }
            let tracking = trackingField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !tracking.isEmpty else {
                presentToast("请填写物流单号")
                return
            }
            onSubmit?(.init(method: .expressReturn, logisticsCompany: company, trackingNo: tracking))
        }
    }

    private func presentToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak alert] in
            alert?.dismiss(animated: true)
        }
    }
}

extension OrderReturnGoodsSheet: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Flow

enum OrderReturnGoodsFlow {
    static func present(from presenter: UIViewController, order: MOrder) {
        let address = order.hospitalName.map { "\($0)（送回地址待接口下发）" }
        let sheet = OrderReturnGoodsSheet(returnAddress: address)
        sheet.onSubmit = { [weak presenter, weak sheet] _ in
            sheet?.dismiss(animated: true) {
                presenter.map { showPendingAPIToast(on: $0) }
            }
        }
        presenter.present(sheet, animated: true)
    }

    static func present(from presenter: UIViewController, detail: AppOrderDetailBO) {
        let address = [
            detail.hospitalName,
            detail.address,
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
        let sheet = OrderReturnGoodsSheet(returnAddress: address)
        sheet.onSubmit = { [weak presenter, weak sheet] _ in
            sheet?.dismiss(animated: true) {
                presenter.map { showPendingAPIToast(on: $0) }
            }
        }
        presenter.present(sheet, animated: true)
    }

    private static func showPendingAPIToast(on presenter: UIViewController) {
        let alert = UIAlertController(title: nil, message: "退货提交接口即将开放", preferredStyle: .alert)
        presenter.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
