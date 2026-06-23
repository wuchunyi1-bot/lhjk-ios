import UIKit

/// 支付页面
final class PaymentViewController: BaseViewController {

    // MARK: - Model

    private let productId: String
    private let productName: String
    private let amount: Int

    // MARK: - UI Components

    private let productLabel: UILabel = {
        let label = UILabel()
        label.font = .fdH3Regular
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let amountLabel: UILabel = {
        let label = UILabel()
        label.font = .fdH1
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var channelStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Initialization

    init(productId: String, productName: String, amount: Int) {
        self.productId = productId
        self.productName = productName
        self.amount = amount
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func setupUI() {
        title = "支付"
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(productLabel)
        view.addSubview(amountLabel)
        view.addSubview(channelStackView)

        NSLayoutConstraint.activate([
            productLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            productLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            productLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            amountLabel.topAnchor.constraint(equalTo: productLabel.bottomAnchor, constant: 12),
            amountLabel.leadingAnchor.constraint(equalTo: productLabel.leadingAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: productLabel.trailingAnchor),

            channelStackView.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 40),
            channelStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            channelStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        productLabel.text = productName
        amountLabel.text = String(format: "¥%.2f", Double(amount) / 100.0)

        setupChannelButtons()
    }

    // MARK: - Channel Setup

    private func setupChannelButtons() {
        let channels = PaymentService.shared.availableChannels()
        for channel in channels {
            let button = createChannelButton(for: channel)
            channelStackView.addArrangedSubview(button)
        }
    }

    private func createChannelButton(for channel: PaymentChannel) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(channel.displayName, for: .normal)
        button.titleLabel?.font = .fdBody
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.separator.cgColor
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        button.addAction(UIAction { [weak self] _ in
            self?.didSelectChannel(channel)
        }, for: .touchUpInside)
        return button
    }

    private func didSelectChannel(_ channel: PaymentChannel) {
        // TODO: 展示加载状态，调用 PaymentService .pay()
        PaymentService.shared.pay(
            productId: productId,
            productName: productName,
            amount: amount,
            channel: channel
        )
        .sink { completion in
            if case .failure(let error) = completion {
                print("[Payment] Error: \(error.localizedDescription)")
            }
        } receiveValue: { result in
            switch result {
            case .success:
                print("[Payment] Success")
            case .cancelled:
                print("[Payment] Cancelled")
            case .failed(_, let error):
                print("[Payment] Failed: \(error.localizedDescription)")
            case .pending:
                print("[Payment] Pending")
            }
        }
    }
}
