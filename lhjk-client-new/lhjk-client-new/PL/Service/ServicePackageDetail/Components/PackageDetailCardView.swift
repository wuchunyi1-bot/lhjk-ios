import UIKit
import SnapKit
import Kingfisher

final class PackageDetailCardView: UIView {

    func configure(with pkg: ServicePackageDetail) {
        subviews.forEach { $0.removeFromSuperview() }
        backgroundColor = .fdSurface
        layer.cornerRadius = 12

        let title = UILabel()
        title.text = "套餐说明"
        title.font = .fdFont(ofSize: 15, weight: .heavy)
        title.textColor = .fdText
        let body = UILabel()
        body.text = pkg.detailText
        body.font = .fdBody
        body.textColor = .fdText2
        body.numberOfLines = 0
        let deliveryTitle = UILabel()
        deliveryTitle.text = "交付说明"
        deliveryTitle.font = .fdFont(ofSize: 15, weight: .heavy)
        deliveryTitle.textColor = .fdText
        let delivery = UILabel()
        delivery.text = ServicePackageDetailCopy.deliveryNote
        delivery.font = .fdBody
        delivery.textColor = .fdText2
        delivery.numberOfLines = 0

        var arranged: [UIView] = [title, body, deliveryTitle, delivery]
        for urlString in pkg.detailImageURLs {
            guard let url = URL(string: urlString) else { continue }
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 8
            iv.backgroundColor = .fdBg2
            iv.kf.setImage(with: url, options: [.transition(.fade(0.2))])
            iv.snp.makeConstraints { $0.height.equalTo(160) }
            arranged.append(iv)
        }

        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(16, after: body)
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
    }
}
