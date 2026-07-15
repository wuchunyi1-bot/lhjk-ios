import UIKit
import SnapKit

/// 血压记录 — 三 Tab 容器
final class BloodPressureHistoryViewController: BaseViewController {

    private let segmented = UISegmentedControl(items: ["趋势图", "日志", "统计"])
    private let container = UIView()

    private lazy var chartVC = BloodPressureHistoryChartViewController()
    private lazy var logVC = BloodPressureHistoryLogViewController()
    private lazy var statsVC = BloodPressureHistoryStatsViewController()

    private var currentChild: UIViewController?

    override func setupUI() {
        title = "血压记录"
        view.backgroundColor = UIColor(hexString: "#F1F3F5")

        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(tabChanged), for: .valueChanged)

        view.addSubview(segmented)
        view.addSubview(container)
        segmented.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }
        container.snp.makeConstraints { make in
            make.top.equalTo(segmented.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        showChild(chartVC)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeleteNotification),
            name: .bloodPressureRecordDidDelete,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func tabChanged() {
        switch segmented.selectedSegmentIndex {
        case 0: showChild(chartVC)
        case 1: showChild(logVC)
        default: showChild(statsVC)
        }
    }

    @objc private func handleDeleteNotification() {
        chartVC.reloadData()
        logVC.reloadData()
        statsVC.reloadData()
    }

    private func showChild(_ child: UIViewController) {
        if let currentChild {
            currentChild.willMove(toParent: nil)
            currentChild.view.removeFromSuperview()
            currentChild.removeFromParent()
        }
        addChild(child)
        container.addSubview(child.view)
        child.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        child.didMove(toParent: self)
        currentChild = child
    }
}
