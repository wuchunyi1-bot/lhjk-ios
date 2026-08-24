import UIKit
import SnapKit

/// 启动页：`splash_hero` 全屏铺满 + 底部 `splash_brand_icon` 叠在上面
final class SplashViewController: UIViewController {

    var minimumDisplayDuration: TimeInterval = 1.2
    var onFinish: (() -> Void)?

    private var didScheduleFinish = false

    private let heroImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "splash_hero"))
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        // 不用橙色底；hero 未铺满的边角用黑色兜底
        view.backgroundColor = .black
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scheduleFinishIfNeeded()
    }

    private func setupUI() {
        view.addSubview(heroImageView)
        heroImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func scheduleFinishIfNeeded() {
        guard !didScheduleFinish else { return }
        didScheduleFinish = true
        DispatchQueue.main.asyncAfter(deadline: .now() + minimumDisplayDuration) { [weak self] in
            self?.onFinish?()
        }
    }
}
