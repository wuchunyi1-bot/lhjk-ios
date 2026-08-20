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

    private let brandIconView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "splash_brand_icon"))
        iv.contentMode = .scaleAspectFit
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
        view.addSubview(brandIconView)

        heroImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        brandIconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-34)
        }
    }

    private func scheduleFinishIfNeeded() {
        guard !didScheduleFinish else { return }
        didScheduleFinish = true
        DispatchQueue.main.asyncAfter(deadline: .now() + minimumDisplayDuration) { [weak self] in
            self?.onFinish?()
        }
    }
}
