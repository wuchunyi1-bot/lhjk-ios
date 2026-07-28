import UIKit
import SnapKit

/// 我的卡券 Hub — 顶层切换「权益卡 / 优惠券」两大模块（各自独立容器 + 多 TableView）
///
/// 对齐订单：`OrderListViewController` 管状态 Tab；本页再多一层资产类型切换。
final class VoucherListViewController: BaseViewController {

    private let initialTopTab: VoucherTopTab
    private var selectedTopIndex: Int
    private lazy var benefitModule = BenefitListViewController()
    private lazy var couponModule = CouponListViewController()
    private var currentModule: UIViewController?

    private lazy var topSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: VoucherTopTab.allCases.map(\.title))
        sc.selectedSegmentIndex = initialTopTab.rawValue
        sc.selectedSegmentTintColor = .fdPrimary
        sc.setTitleTextAttributes(
            [.font: UIFont.fdCaptionSemibold, .foregroundColor: UIColor.fdSubtext],
            for: .normal
        )
        sc.setTitleTextAttributes(
            [.font: UIFont.fdCaptionSemibold, .foregroundColor: UIColor.white],
            for: .selected
        )
        sc.addTarget(self, action: #selector(topTabChanged(_:)), for: .valueChanged)
        return sc
    }()

    private let moduleContainer = UIView()

    override var shouldAutomaticallyForwardAppearanceMethods: Bool { false }

    init(topTab: VoucherTopTab = .benefit) {
        self.initialTopTab = topTab
        self.selectedTopIndex = topTab.rawValue
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func setupUI() {
        title = "我的卡券"
        view.backgroundColor = .fdBg

        let topBar = UIView()
        topBar.backgroundColor = .fdBg
        view.addSubview(topBar)
        topBar.addSubview(topSegment)
        topBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }
        topSegment.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }

        view.addSubview(moduleContainer)
        moduleContainer.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if currentModule == nil {
            showModule(at: selectedTopIndex)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        currentModule?.beginAppearanceTransition(true, animated: animated)
        if let benefit = currentModule as? BenefitListViewController {
            benefit.refreshVisibleTab()
        } else if let coupon = currentModule as? CouponListViewController {
            coupon.refreshVisibleTab()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        currentModule?.endAppearanceTransition()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        currentModule?.beginAppearanceTransition(false, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        currentModule?.endAppearanceTransition()
    }

    @objc private func topTabChanged(_ sender: UISegmentedControl) {
        showModule(at: sender.selectedSegmentIndex)
    }

    private func showModule(at index: Int) {
        guard index == 0 || index == 1 else { return }
        let isVisible = isViewLoaded && view.window != nil
        selectedTopIndex = index

        if let old = currentModule, isVisible {
            old.beginAppearanceTransition(false, animated: false)
            old.endAppearanceTransition()
        }

        for vc in children {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }

        let child: UIViewController = index == 0 ? benefitModule : couponModule
        addChild(child)
        moduleContainer.addSubview(child.view)
        child.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        child.didMove(toParent: self)
        currentModule = child

        if isVisible {
            child.beginAppearanceTransition(true, animated: false)
            child.endAppearanceTransition()
        }
    }
}
