import UIKit
import SnapKit

/// 发货记录 / 自提记录列表（对齐 funde OrderShipmentRecordsView）
final class OrderShipmentRecordsViewController: BaseViewController {

    private let orderId: Int64
    private let isPickup: Bool

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let emptyLabel = UILabel()

    private var detail: AppOrderDetailBO?

    init(orderId: Int64, isPickup: Bool) {
        self.orderId = orderId
        self.isPickup = isPickup
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func setupUI() {
        title = isPickup ? "自提记录" : "发货记录"
        view.backgroundColor = .fdBg

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .fdPrimary
        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }

        emptyLabel.font = .fdBody
        emptyLabel.textColor = .fdSubtext
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(24)
        }
    }

    override func bindViewModel() {
        loadData()
    }

    private func loadData() {
        loadingIndicator.startAnimating()
        emptyLabel.isHidden = true
        scrollView.isHidden = true

        Task {
            do {
                let data = try await AppContainer.shared.orderService.getAppOrderDetail(orderId: orderId)
                await MainActor.run {
                    self.detail = data
                    self.loadingIndicator.stopAnimating()
                    self.render()
                }
            } catch {
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.emptyLabel.isHidden = false
                    self.emptyLabel.text = "加载失败，请返回重试"
                }
            }
        }
    }

    private func render() {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        guard let detail else {
            emptyLabel.isHidden = false
            emptyLabel.text = isPickup ? "暂无自提记录" : "暂无发货记录"
            return
        }

        let lines = detail.logisticsLines
        guard !lines.isEmpty else {
            emptyLabel.isHidden = false
            emptyLabel.text = isPickup ? "暂无自提记录" : "暂无发货记录"
            scrollView.isHidden = true
            return
        }

        scrollView.isHidden = false
        emptyLabel.isHidden = true
        let summary = detail.logisticsSummary
        for line in lines {
            let card = OrderDetailCardView()
            let taskView = OrderDetailShipmentTaskCardView()
            taskView.configure(line: line, isPickup: isPickup, logisticsSummary: summary)
            taskView.onCopyTracking = { [weak self] trackingNo in
                UIPasteboard.general.string = trackingNo
                self?.showToast("物流单号已复制")
            }
            card.addSubview(taskView)
            taskView.snp.makeConstraints { $0.edges.equalToSuperview() }
            contentStack.addArrangedSubview(card)
        }
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            alert.dismiss(animated: true)
        }
    }
}
