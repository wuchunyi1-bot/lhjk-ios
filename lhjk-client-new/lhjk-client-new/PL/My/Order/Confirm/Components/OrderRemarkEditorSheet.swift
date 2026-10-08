import UIKit
import SnapKit

/// 订单备注底部编辑弹层 — 左标题、右上角关闭，正文区右下角字数，底部「取消 / 保存」
final class OrderRemarkEditorSheet: UIViewController {

    var onSave: ((String) -> Void)?

    private let maxLength = 200
    private var draft: String

    private let dimView = UIView()
    private let panel = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .custom)
    private let contentBox = UIView()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let counterLabel = UILabel()
    private let buttonStack = UIStackView()
    private let cancelButton = UIButton(type: .custom)
    private let saveButton = UIButton(type: .custom)
    private let keyboardSupport = OrderBottomSheetKeyboardSupport()
    private var panelBottomConstraint: Constraint?

    init(current: String) {
        self.draft = String(current.prefix(200))
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }
        keyboardSupport.dimTapDismissesKeyboardOnly(dimView: dimView)

        panel.backgroundColor = .white
        panel.layer.cornerRadius = 16
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.clipsToBounds = true
        view.addSubview(panel)
        panel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            panelBottomConstraint = $0.bottom.equalToSuperview().constraint
        }
        keyboardSupport.attach(hostView: view, panelBottomConstraint: panelBottomConstraint!)

        titleLabel.text = "订单备注"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#1F2942")
        panel.addSubview(titleLabel)

        closeButton.setImage(UIImage(named: "order_return_close"), for: .normal)
        closeButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        panel.addSubview(closeButton)
        closeButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.trailing.equalToSuperview().offset(-16)
            $0.size.equalTo(24)
        }
        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(closeButton)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualTo(closeButton.snp.leading).offset(-8)
        }

        contentBox.backgroundColor = UIColor(hexString: "#F5F7FA")
        contentBox.layer.cornerRadius = 12
        panel.addSubview(contentBox)
        contentBox.snp.makeConstraints {
            $0.top.equalTo(closeButton.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        counterLabel.font = .fdFont(ofSize: 12, weight: .regular)
        counterLabel.textColor = UIColor(hexString: "#8591AB")
        counterLabel.textAlignment = .right
        counterLabel.text = "\(draft.count)/\(maxLength)"
        contentBox.addSubview(counterLabel)
        counterLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.bottom.equalToSuperview().offset(-10)
            $0.leading.greaterThanOrEqualToSuperview().offset(12)
        }

        textView.font = .fdFont(ofSize: 14, weight: .regular)
        textView.textColor = UIColor(hexString: "#1F2942")
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 8, right: 8)
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.text = draft
        contentBox.addSubview(textView)
        textView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(counterLabel.snp.top).offset(-4)
            $0.height.equalTo(220)
        }

        placeholderLabel.text = "请输入订单备注（选填，最多 \(maxLength) 字）"
        placeholderLabel.font = .fdFont(ofSize: 14, weight: .regular)
        placeholderLabel.textColor = UIColor(hexString: "#8591AB")
        placeholderLabel.numberOfLines = 0
        textView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(textView.textContainerInset.top)
            $0.leading.equalToSuperview().offset(textView.textContainerInset.left)
            $0.trailing.equalToSuperview().offset(-12)
        }
        placeholderLabel.isHidden = !draft.isEmpty

        buttonStack.axis = .horizontal
        buttonStack.spacing = 11
        buttonStack.distribution = .fillEqually
        panel.addSubview(buttonStack)
        buttonStack.snp.makeConstraints {
            $0.top.equalTo(contentBox.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(43)
            $0.bottom.equalTo(panel.safeAreaLayoutGuide).offset(-12)
        }

        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(UIColor(hexString: "#FF7A50"), for: .normal)
        cancelButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .regular)
        cancelButton.backgroundColor = .white
        cancelButton.layer.borderColor = UIColor(hexString: "#FF7A50").cgColor
        cancelButton.layer.borderWidth = 0.5
        cancelButton.layer.cornerRadius = 21.5
        cancelButton.clipsToBounds = true
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        buttonStack.addArrangedSubview(cancelButton)

        saveButton.setTitle("保存", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        saveButton.backgroundColor = UIColor(hexString: "#FF7A50")
        saveButton.layer.cornerRadius = 21.5
        saveButton.clipsToBounds = true
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        buttonStack.addArrangedSubview(saveButton)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

    @objc private func cancel() { dismiss(animated: true) }

    @objc private func save() {
        let value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave?(value)
        dismiss(animated: true)
    }
}

extension OrderRemarkEditorSheet: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > maxLength {
            textView.text = String(textView.text.prefix(maxLength))
        }
        draft = textView.text
        placeholderLabel.isHidden = !textView.text.isEmpty
        counterLabel.text = "\(textView.text.count)/\(maxLength)"
    }
}
