import UIKit
import SnapKit

/// 我的卡券 Hub — 顶层切换「权益卡 / 优惠券」两大模块（各自独立容器 + 多 TableView）
/// 对齐 Figma 3835:32584 与 3838:32984
final class VoucherListViewController: BaseViewController {

    private let initialTopTab: VoucherTopTab
    private var selectedTopIndex: Int
    private lazy var benefitModule = BenefitListViewController()
    private lazy var couponModule = CouponListViewController()
    private var currentModule: UIViewController?

    private lazy var topTabBar: VoucherTopTabBar = {
        let bar = VoucherTopTabBar(initialIndex: initialTopTab.rawValue)
        bar.onTabSelected = { [weak self] index in
            self?.showModule(at: index)
        }
        return bar
    }()

    private let moduleContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.clipsToBounds = true
        return v
    }()

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
        view.backgroundColor = UIColor(hexString: "#FDF6F3")

        view.addSubview(topTabBar)
        topTabBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(69)
        }

        view.addSubview(moduleContainer)
        moduleContainer.snp.makeConstraints { make in
            make.top.equalTo(topTabBar.snp.bottom)
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

    private func showModule(at index: Int) {
        guard index == 0 || index == 1 else { return }
        let isVisible = isViewLoaded && view.window != nil
        selectedTopIndex = index
        topTabBar.setSelectedIndex(index, animated: true)

        if let old = currentModule, isVisible {
            old.beginAppearanceTransition(false, animated: false)
            old.endAppearanceTransition()
        }

        for vc in children {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }

        let target: UIViewController = index == 0 ? benefitModule : couponModule
        currentModule = target

        addChild(target)
        moduleContainer.addSubview(target.view)
        target.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        target.didMove(toParent: self)

        if isVisible {
            target.beginAppearanceTransition(true, animated: false)
            target.endAppearanceTransition()
        }
    }
}

// MARK: - VoucherTopTabBar

final class VoucherTopTabBar: UIView {
    var onTabSelected: ((Int) -> Void)?
    private(set) var selectedIndex: Int = 0

    private let bgImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let benefitButton = UIButton(type: .custom)
    private let couponButton = UIButton(type: .custom)

    init(initialIndex: Int = 0) {
        self.selectedIndex = initialIndex
        super.init(frame: .zero)
        setupUI()
        updateTabState(animated: false)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(bgImageView)
        bgImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let stack = UIStackView(arrangedSubviews: [benefitButton, couponButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
        }

        benefitButton.setTitle("权益卡", for: .normal)
        benefitButton.titleLabel?.font = .fdFont(ofSize: 20, weight: .regular)
        benefitButton.addTarget(self, action: #selector(benefitTapped), for: .touchUpInside)

        couponButton.setTitle("优惠券", for: .normal)
        couponButton.titleLabel?.font = .fdFont(ofSize: 20, weight: .regular)
        couponButton.addTarget(self, action: #selector(couponTapped), for: .touchUpInside)
    }

    func setSelectedIndex(_ index: Int, animated: Bool) {
        guard index != selectedIndex else { return }
        selectedIndex = index
        updateTabState(animated: animated)
    }

    private func updateTabState(animated: Bool) {
        let isBenefit = selectedIndex == 0
        let imageName = isBenefit ? "voucher_top_tab_benefit" : "voucher_top_tab_coupon"
        let targetImage = UIImage(named: imageName)

        if animated {
            UIView.transition(with: bgImageView, duration: 0.2, options: .transitionCrossDissolve) {
                self.bgImageView.image = targetImage
            }
        } else {
            bgImageView.image = targetImage
        }

        benefitButton.setTitleColor(isBenefit ? UIColor(hexString: "#1F2942") : UIColor(hexString: "#8591AB"), for: .normal)
        benefitButton.titleLabel?.font = isBenefit ? .fdFont(ofSize: 20, weight: .medium) : .fdFont(ofSize: 20, weight: .regular)

        couponButton.setTitleColor(!isBenefit ? UIColor(hexString: "#1F2942") : UIColor(hexString: "#8591AB"), for: .normal)
        couponButton.titleLabel?.font = !isBenefit ? .fdFont(ofSize: 20, weight: .medium) : .fdFont(ofSize: 20, weight: .regular)
    }

    @objc private func benefitTapped() {
        guard selectedIndex != 0 else { return }
        selectedIndex = 0
        updateTabState(animated: true)
        onTabSelected?(0)
    }

    @objc private func couponTapped() {
        guard selectedIndex != 1 else { return }
        selectedIndex = 1
        updateTabState(animated: true)
        onTabSelected?(1)
    }
}
