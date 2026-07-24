import UIKit
import SnapKit
import Kingfisher

/// 待发货取消 — 退款申请底部弹层（对齐 funde PRD 5.3.3）
final class OrderCancelRefundSheet: UIViewController {

    var onSubmit: ((String) -> Void)?

    private let preview: OrderCancelPackagePreview
    private let sheetTitle: String
    private let maxLength = 20
    private var draft = ""
    private var isSubmitting = false

    private let dimView = UIView()
    private let panel = UIView()
    private let cancelBtn = UIButton(type: .system)
    private let titleLbl = UILabel()
    private let submitBtn = UIButton(type: .system)
    private let packageCard = UIView()
    private let coverImageView = UIImageView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let amountLabel = UILabel()
    private let reasonTitleLabel = UILabel()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let counterLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    init(preview: OrderCancelPackagePreview, sheetTitle: String = "取消订单") {
        self.preview = preview
        self.sheetTitle = sheetTitle
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        buildUI()
        configurePreview()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

    func setSubmitting(_ submitting: Bool) {
        isSubmitting = submitting
        submitBtn.isEnabled = !submitting
        cancelBtn.isEnabled = !submitting
        textView.isEditable = !submitting
        if submitting {
            activityIndicator.startAnimating()
            submitBtn.setTitle("", for: .normal)
        } else {
            activityIndicator.stopAnimating()
            submitBtn.setTitle("提交申请", for: .normal)
        }
    }

    private func buildUI() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancel)))
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        panel.backgroundColor = .fdSurface
        panel.layer.cornerRadius = 16
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(panel)
        panel.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }

        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.setTitleColor(.fdSubtext, for: .normal)
        cancelBtn.titleLabel?.font = .fdBody
        cancelBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)

        titleLbl.text = sheetTitle
        titleLbl.font = .fdBodySemibold
        titleLbl.textColor = .fdText
        titleLbl.textAlignment = .center

        submitBtn.setTitle("提交申请", for: .normal)
        submitBtn.setTitleColor(.fdPrimary, for: .normal)
        submitBtn.titleLabel?.font = .fdBodySemibold
        submitBtn.addTarget(self, action: #selector(submit), for: .touchUpInside)

        activityIndicator.hidesWhenStopped = true
        submitBtn.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { $0.center.equalToSuperview() }

        let header = UIStackView(arrangedSubviews: [cancelBtn, titleLbl, submitBtn])
        header.axis = .horizontal
        header.distribution = .equalCentering
        header.alignment = .center
        panel.addSubview(header)
        header.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(36)
        }
        cancelBtn.snp.makeConstraints { $0.width.greaterThanOrEqualTo(44) }
        submitBtn.snp.makeConstraints { $0.width.greaterThanOrEqualTo(72) }

        packageCard.backgroundColor = UIColor(hexString: "#F5F7FA")
        packageCard.layer.cornerRadius = 8
        panel.addSubview(packageCard)

        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.layer.cornerRadius = 6
        coverImageView.backgroundColor = .fdBorder
        packageCard.addSubview(coverImageView)

        nameLabel.font = .fdBodySemibold
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2

        subtitleLabel.font = .fdCaption
        subtitleLabel.textColor = .fdSubtext
        subtitleLabel.numberOfLines = 2

        amountLabel.font = .fdBodySemibold
        amountLabel.textColor = .fdPrimary
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        packageCard.addSubview(textStack)
        packageCard.addSubview(amountLabel)

        coverImageView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview().inset(12)
            $0.width.height.equalTo(56)
        }
        textStack.snp.makeConstraints {
            $0.leading.equalTo(coverImageView.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-8)
        }
        amountLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }
        packageCard.snp.makeConstraints {
            $0.top.equalTo(header.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        reasonTitleLabel.text = "申请退款原因 *"
        reasonTitleLabel.font = .fdBody
        reasonTitleLabel.textColor = .fdText
        panel.addSubview(reasonTitleLabel)
        reasonTitleLabel.snp.makeConstraints {
            $0.top.equalTo(packageCard.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        textView.font = .fdBody
        textView.textColor = .fdText
        textView.backgroundColor = UIColor(hexString: "#F5F7FA")
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor(hexString: "#E4E9F1").cgColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        textView.delegate = self
        panel.addSubview(textView)

        placeholderLabel.text = "请填写申请退款原因"
        placeholderLabel.font = .fdBody
        placeholderLabel.textColor = .fdMuted
        textView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints {
            $0.top.equalTo(textView.textContainerInset.top)
            $0.leading.equalTo(textView.textContainerInset.left + 5)
            $0.trailing.equalToSuperview().offset(-10)
        }

        counterLabel.font = .fdCaption
        counterLabel.textColor = .fdMuted
        counterLabel.textAlignment = .right
        counterLabel.text = "0/\(maxLength)"
        panel.addSubview(counterLabel)

        textView.snp.makeConstraints {
            $0.top.equalTo(reasonTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(100)
        }
        counterLabel.snp.makeConstraints {
            $0.top.equalTo(textView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(panel.safeAreaLayoutGuide).offset(-24)
        }
    }

    private func configurePreview() {
        nameLabel.text = preview.name
        subtitleLabel.text = preview.subtitle
        subtitleLabel.isHidden = preview.subtitle?.isEmpty != false
        amountLabel.text = preview.amountText
        if let urlString = preview.imageURL, let url = URL(string: urlString) {
            coverImageView.kf.setImage(with: url)
        } else {
            coverImageView.image = nil
        }
    }

    @objc private func cancel() {
        guard !isSubmitting else { return }
        dismiss(animated: true)
    }

    @objc private func submit() {
        guard !isSubmitting else { return }
        let reason = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reason.isEmpty else {
            showHint("请填写申请退款原因")
            return
        }
        onSubmit?(reason)
    }

    private func showHint(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            alert.dismiss(animated: true)
        }
    }
}

extension OrderCancelRefundSheet: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > maxLength {
            textView.text = String(textView.text.prefix(maxLength))
        }
        draft = textView.text
        placeholderLabel.isHidden = !textView.text.isEmpty
        counterLabel.text = "\(textView.text.count)/\(maxLength)"
    }
}

// MARK: - 结算订单申请

/// 结算订单申请 — 对齐 funde `OrderSettlementDialog.vue` / PRD 5.6.4
final class OrderSettlementSheet: UIViewController {

    var onSubmit: ((String) -> Void)?

    private let preview: OrderCancelPackagePreview
    private let maxLength = 20
    private var draft = ""
    private var isSubmitting = false

    private let dimView = UIView()
    private let panel = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let packageCard = UIView()
    private let coverImageView = UIImageView()
    private let nameLabel = UILabel()
    private let subtitlePackageLabel = UILabel()
    private let amountLabel = UILabel()
    private let reasonTitleLabel = UILabel()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let counterLabel = UILabel()
    private let rethinkButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    init(preview: OrderCancelPackagePreview) {
        self.preview = preview
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        buildUI()
        configurePreview()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

    func setSubmitting(_ submitting: Bool) {
        isSubmitting = submitting
        rethinkButton.isEnabled = !submitting
        confirmButton.isEnabled = !submitting
        textView.isEditable = !submitting
        dimView.isUserInteractionEnabled = !submitting
        if submitting {
            activityIndicator.startAnimating()
            confirmButton.setTitle("", for: .normal)
        } else {
            activityIndicator.stopAnimating()
            confirmButton.setTitle("确认结算", for: .normal)
        }
    }

    private func buildUI() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rethink)))
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        panel.backgroundColor = .fdSurface
        panel.layer.cornerRadius = 16
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(panel)
        panel.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }

        titleLabel.text = "确认结算订单？"
        titleLabel.font = .fdH2
        titleLabel.textColor = .fdText

        subtitleLabel.text = "提交后该订单将进入退款审核。"
        subtitleLabel.font = .fdCaption
        subtitleLabel.textColor = .fdSubtext
        subtitleLabel.numberOfLines = 0

        packageCard.backgroundColor = UIColor(hexString: "#F5F7FA")
        packageCard.layer.cornerRadius = 8

        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.layer.cornerRadius = 6
        coverImageView.backgroundColor = .fdBorder
        packageCard.addSubview(coverImageView)

        nameLabel.font = .fdBodySemibold
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2

        subtitlePackageLabel.font = .fdCaption
        subtitlePackageLabel.textColor = .fdSubtext
        subtitlePackageLabel.numberOfLines = 2

        amountLabel.font = .fdBodySemibold
        amountLabel.textColor = .fdPrimary
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitlePackageLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        packageCard.addSubview(textStack)
        packageCard.addSubview(amountLabel)

        coverImageView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview().inset(12)
            $0.width.height.equalTo(56)
        }
        textStack.snp.makeConstraints {
            $0.leading.equalTo(coverImageView.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-8)
        }
        amountLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }

        reasonTitleLabel.text = "申请退款原因 *"
        reasonTitleLabel.font = .fdBodySemibold
        reasonTitleLabel.textColor = .fdText

        textView.font = .fdBody
        textView.textColor = .fdText
        textView.backgroundColor = UIColor(hexString: "#F5F7FA")
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor(hexString: "#E4E9F1").cgColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        textView.delegate = self

        placeholderLabel.text = "请填写申请退款原因"
        placeholderLabel.font = .fdBody
        placeholderLabel.textColor = .fdMuted
        textView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints {
            $0.top.equalTo(textView.textContainerInset.top)
            $0.leading.equalTo(textView.textContainerInset.left + 5)
            $0.trailing.equalToSuperview().offset(-10)
        }

        counterLabel.font = .fdCaption
        counterLabel.textColor = .fdMuted
        counterLabel.textAlignment = .right
        counterLabel.text = "0/\(maxLength)"

        rethinkButton.setTitle("再想想", for: .normal)
        rethinkButton.setTitleColor(.fdText, for: .normal)
        rethinkButton.titleLabel?.font = .fdBody
        rethinkButton.layer.cornerRadius = 22
        rethinkButton.layer.borderWidth = 1
        rethinkButton.layer.borderColor = UIColor.fdBorder.cgColor
        rethinkButton.addTarget(self, action: #selector(rethink), for: .touchUpInside)

        confirmButton.setTitle("确认结算", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = .fdBodySemibold
        confirmButton.backgroundColor = .fdPrimary
        confirmButton.layer.cornerRadius = 22
        confirmButton.addTarget(self, action: #selector(confirm), for: .touchUpInside)
        confirmButton.addSubview(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.snp.makeConstraints { $0.center.equalToSuperview() }

        let actions = UIStackView(arrangedSubviews: [rethinkButton, confirmButton])
        actions.axis = .horizontal
        actions.spacing = 12
        actions.distribution = .fillEqually
        rethinkButton.snp.makeConstraints { $0.height.equalTo(44) }
        confirmButton.snp.makeConstraints { $0.height.equalTo(44) }

        let contentStack = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            packageCard,
            reasonTitleLabel,
            textView,
            counterLabel,
            actions
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.setCustomSpacing(16, after: subtitleLabel)
        contentStack.setCustomSpacing(8, after: reasonTitleLabel)
        contentStack.setCustomSpacing(4, after: textView)
        contentStack.setCustomSpacing(16, after: counterLabel)
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 20, left: 16, bottom: 24, right: 16)
        panel.addSubview(contentStack)
        contentStack.snp.makeConstraints { $0.edges.equalToSuperview() }

        packageCard.snp.makeConstraints { $0.height.greaterThanOrEqualTo(80) }
        textView.snp.makeConstraints { $0.height.equalTo(112) }
    }

    private func configurePreview() {
        nameLabel.text = preview.name
        subtitlePackageLabel.text = preview.subtitle
        subtitlePackageLabel.isHidden = preview.subtitle?.isEmpty != false
        amountLabel.text = preview.amountText
        if let urlString = preview.imageURL, let url = URL(string: urlString) {
            coverImageView.kf.setImage(with: url)
        } else {
            coverImageView.image = nil
        }
    }

    @objc private func rethink() {
        guard !isSubmitting else { return }
        dismiss(animated: true)
    }

    @objc private func confirm() {
        guard !isSubmitting else { return }
        let reason = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reason.isEmpty else {
            showHint("请填写申请退款原因")
            return
        }
        onSubmit?(reason)
    }

    private func showHint(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            alert.dismiss(animated: true)
        }
    }
}

extension OrderSettlementSheet: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > maxLength {
            textView.text = String(textView.text.prefix(maxLength))
        }
        draft = textView.text
        placeholderLabel.isHidden = !textView.text.isEmpty
        counterLabel.text = "\(textView.text.count)/\(maxLength)"
    }
}
