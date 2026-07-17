import UIKit
import SnapKit
import Kingfisher

/// 套餐详情图楼层 — 仅展示长图列表
final class PackageDetailCardView: UIView {

    func configure(with pkg: ServicePackageDetail) {
        subviews.forEach { $0.removeFromSuperview() }

        guard !pkg.detailImageURLs.isEmpty else { return }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12

        for urlString in pkg.detailImageURLs {
            guard let url = URL(string: urlString) else { continue }
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 8
            iv.backgroundColor = .fdBg2
            iv.kf.setImage(with: url, options: [.transition(.fade(0.2))])
            iv.snp.makeConstraints { $0.height.equalTo(220) }
            stack.addArrangedSubview(iv)
        }

        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}
