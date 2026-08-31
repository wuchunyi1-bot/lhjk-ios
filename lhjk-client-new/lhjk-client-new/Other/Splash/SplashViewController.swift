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

    private let copyrightLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 2
        l.textAlignment = .center
        l.textColor = UIColor.white.withAlphaComponent(0.85)
        l.font = .systemFont(ofSize: 10, weight: .regular)
        l.text = "Copyright © 2024-2026 深圳市富德联好健康服务有限公司 版权所有\n粤ICP备2023016723号-1"
        return l
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
        view.addSubview(copyrightLabel)
        heroImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        copyrightLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
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
