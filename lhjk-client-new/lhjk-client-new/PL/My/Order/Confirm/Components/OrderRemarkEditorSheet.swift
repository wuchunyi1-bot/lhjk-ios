import UIKit
import SnapKit

/// 订单备注底部编辑弹层 — 对齐 funde OrderConfirmView 备注 popup
final class OrderRemarkEditorSheet: UIViewController {

    var onSave: ((String) -> Void)?

    private let maxLength = 300
    private var draft: String

    private let dimView = UIView()
    private let panel = UIView()
    private let cancelBtn = UIButton(type: .system)
    private let titleLbl = UILabel()
    private let saveBtn = UIButton(type: .system)
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let counterLabel = UILabel()

    init(current: String) {
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
        panel.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }

        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.setTitleColor(.fdSubtext, for: .normal)
        cancelBtn.titleLabel?.font = .fdBody
        cancelBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)

        titleLbl.text = "订单备注"
        titleLbl.font = .fdBodySemibold
        titleLbl.textColor = .fdText
        titleLbl.textAlignment = .center

        saveBtn.setTitle("保存", for: .normal)
        saveBtn.setTitleColor(.fdPrimary, for: .normal)
        saveBtn.titleLabel?.font = .fdBodySemibold
        saveBtn.addTarget(self, action: #selector(save), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [cancelBtn, titleLbl, saveBtn])
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
        saveBtn.snp.makeConstraints { $0.width.greaterThanOrEqualTo(44) }

        let divider = UIView()
        divider.backgroundColor = .fdBorder
        panel.addSubview(divider)
        divider.snp.makeConstraints {
            $0.top.equalTo(header.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }

        textView.font = .fdBody
        textView.textColor = .fdText
        textView.backgroundColor = UIColor(hexString: "#F5F7FA")
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor(hexString: "#E4E9F1").cgColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        textView.delegate = self
        textView.text = draft
        panel.addSubview(textView)

        placeholderLabel.text = "请输入订单备注（选填，最多 \(maxLength) 字）"
        placeholderLabel.font = .fdBody
        placeholderLabel.textColor = .fdMuted
        placeholderLabel.numberOfLines = 0
        textView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints {
            $0.top.equalTo(textView.textContainerInset.top)
            $0.leading.equalTo(textView.textContainerInset.left + 5)
            $0.trailing.equalToSuperview().offset(-10)
        }
        placeholderLabel.isHidden = !draft.isEmpty

        counterLabel.font = .fdCaption
        counterLabel.textColor = .fdMuted
        counterLabel.textAlignment = .right
        counterLabel.text = "\(draft.count)/\(maxLength)"
        panel.addSubview(counterLabel)

        textView.snp.makeConstraints {
            $0.top.equalTo(divider.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(140)
        }
        counterLabel.snp.makeConstraints {
            $0.top.equalTo(textView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(panel.safeAreaLayoutGuide).offset(-24)
        }
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
