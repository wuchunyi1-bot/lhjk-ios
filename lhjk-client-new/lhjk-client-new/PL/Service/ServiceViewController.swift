import UIKit
import SnapKit
import Combine

/// 健康服务页：顶部 Banner 与「选择套餐」下半部分（类目 + 套餐）。不再展示德系产品矩阵。
final class ServiceViewController: BaseViewController {

    private var cancellables = Set<AnyCancellable>()
    /// 嵌在首页页签里时不改导航栏，并隐藏本页顶栏。
    private let embedsInHomeHub: Bool

    init(embedsInHomeHub: Bool = false) {
        self.embedsInHomeHub = embedsInHomeHub
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let hubHeader = ServiceHubHeaderView()
    private let bannerBar = ServiceHubBannerBar()
    private let packageHost = UIView()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !embedsInHomeHub {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
        bannerBar.load()
        AppContainer.shared.shoppingCartBadgeStore.refresh()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !embedsInHomeHub {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        bannerBar.onBannerTap = { [weak self] banner in
            self?.bannerBar.open(banner, from: self)
        }
        view.addSubview(bannerBar)
        view.addSubview(packageHost)

        if embedsInHomeHub {
            hubHeader.isHidden = true
            bannerBar.snp.makeConstraints {
                $0.top.leading.trailing.equalToSuperview()
            }
        } else {
            hubHeader.onCartTapped = { [weak self] in
                Router.shared.push("/services/cart", from: self)
            }
            view.addSubview(hubHeader)
            hubHeader.snp.makeConstraints {
                $0.top.equalTo(view.safeAreaLayoutGuide)
                $0.leading.trailing.equalToSuperview()
            }
            bannerBar.snp.makeConstraints {
                $0.top.equalTo(hubHeader.snp.bottom)
                $0.leading.trailing.equalToSuperview()
            }
        }
        packageHost.snp.makeConstraints {
            $0.top.equalTo(bannerBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        let list = ServiceListViewController(productCode: "", showsPackageBrowserOnly: true)
        addChild(list)
        packageHost.addSubview(list.view)
        list.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        list.didMove(toParent: self)
    }

    override func bindViewModel() {
        guard !embedsInHomeHub else { return }
        AppContainer.shared.shoppingCartBadgeStore.$count
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.hubHeader.applyCartCount(count)
            }
            .store(in: &cancellables)
    }
}
