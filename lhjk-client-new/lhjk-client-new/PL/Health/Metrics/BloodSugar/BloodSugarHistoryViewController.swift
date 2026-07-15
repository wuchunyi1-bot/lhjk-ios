import UIKit
import SnapKit

final class BloodSugarHistoryViewController: BaseViewController {

    private let segmented = UISegmentedControl(items: ["表格", "趋势图", "日志", "统计"])
    private let container = UIView()

    private lazy var formVC = BloodSugarHistoryFormViewController()
    private lazy var chartVC = BloodSugarHistoryChartViewController()
    private lazy var logVC = BloodSugarHistoryLogViewController()
    private lazy var statsVC = BloodSugarHistoryStatsViewController()
    private var currentChild: UIViewController?

    override func setupUI() {
        title = "血糖记录"
        view.backgroundColor = UIColor(hexString: "#F1F3F5")

        segmented.selectedSegmentIndex = 0
        segmented.selectedSegmentTintColor = UIColor(hexString: "#FF406F")
        segmented.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
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

        showChild(formVC)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDelete), name: .bloodSugarRecordDidDelete, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func tabChanged() {
        switch segmented.selectedSegmentIndex {
        case 0: showChild(formVC)
        case 1: showChild(chartVC)
        case 2: showChild(logVC)
        default: showChild(statsVC)
        }
    }

    @objc private func handleDelete() {
        formVC.reloadData()
        chartVC.reloadData()
        logVC.reloadData()
        statsVC.reloadData()
    }

    private func showChild(_ child: UIViewController) {
        currentChild?.willMove(toParent: nil)
        currentChild?.view.removeFromSuperview()
        currentChild?.removeFromParent()
        addChild(child)
        container.addSubview(child.view)
        child.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        child.didMove(toParent: self)
        currentChild = child
    }
}
