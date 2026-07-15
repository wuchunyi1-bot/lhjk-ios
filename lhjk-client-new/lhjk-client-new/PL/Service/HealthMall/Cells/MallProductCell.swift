import UIKit
import SnapKit

final class MallProductCell: UICollectionViewCell {
    static let reuseID = "MallProductCell"

    private var productId: String?
    private let imgArea = UIView()
    private let tagLabel = UILabel()
    private let nameLabel = UILabel()
    private let descLabel = UILabel()
    private let unitLabel = UILabel()
    private let priceLabel = UILabel()
    private let buyBtn = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface
        layer.cornerRadius = 18
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.03
        layer.masksToBounds = false
        clipsToBounds = false

        imgArea.backgroundColor = .fdBg2
        imgArea.layer.cornerRadius = 0
        contentView.addSubview(imgArea)
        imgArea.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.height.equalTo(90) }

        let placeholder = UILabel()
        placeholder.text = "商品封面"
        placeholder.font = .fdMicro
        placeholder.textColor = .fdMuted
        placeholder.textAlignment = .center
        imgArea.addSubview(placeholder)
        placeholder.snp.makeConstraints { $0.center.equalToSuperview() }

        tagLabel.font = .fdMicroSemibold
        tagLabel.textColor = .white
        tagLabel.backgroundColor = .fdPrimary
        tagLabel.layer.cornerRadius = 4
        tagLabel.clipsToBounds = true
        tagLabel.textAlignment = .center
        tagLabel.isHidden = true
        imgArea.addSubview(tagLabel)
        tagLabel.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(6); $0.height.equalTo(16) }

        nameLabel.font = .fdCaptionSemibold
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2
        descLabel.font = .fdMicro
        descLabel.textColor = .fdSubtext
        descLabel.numberOfLines = 1
        unitLabel.font = .fdMicro
        unitLabel.textColor = .fdMuted
        priceLabel.font = .fdMonoFont(ofSize: 16, weight: .bold)

        buyBtn.titleLabel?.font = .fdMicroSemibold
        buyBtn.setTitle("购买", for: .normal)
        buyBtn.setTitleColor(.white, for: .normal)
        buyBtn.layer.cornerRadius = 999

        [nameLabel, descLabel, unitLabel, priceLabel, buyBtn].forEach(contentView.addSubview)
        nameLabel.snp.makeConstraints { $0.top.equalTo(imgArea.snp.bottom).offset(10); $0.leading.trailing.equalToSuperview().inset(10) }
        descLabel.snp.makeConstraints { $0.top.equalTo(nameLabel.snp.bottom).offset(3); $0.leading.trailing.equalToSuperview().inset(10) }
        unitLabel.snp.makeConstraints { $0.top.equalTo(descLabel.snp.bottom).offset(3); $0.leading.trailing.equalToSuperview().inset(10) }
        priceLabel.snp.makeConstraints { $0.top.equalTo(unitLabel.snp.bottom).offset(8); $0.leading.equalToSuperview().inset(10); $0.bottom.equalToSuperview().offset(-10) }
        buyBtn.snp.makeConstraints { $0.centerY.equalTo(priceLabel); $0.trailing.equalToSuperview().inset(10); $0.height.equalTo(26) }

        buyBtn.addTarget(self, action: #selector(tapBuy), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        productId = nil
    }

    func configure(_ item: HealthPackageItem) {
        nameLabel.text = item.name
        descLabel.text = item.subtitle
        unitLabel.text = ""
        priceLabel.text = item.price
        priceLabel.textColor = item.accent
        buyBtn.backgroundColor = item.accent
        if let badge = item.badge, !badge.isEmpty {
            tagLabel.isHidden = false
            tagLabel.text = " \(badge) "
        } else {
            tagLabel.isHidden = true
        }
        productId = item.id
    }

    func configure(_ p: MallProduct) {
        nameLabel.text = p.name
        descLabel.text = p.desc
        unitLabel.text = p.unit
        priceLabel.text = p.price
        priceLabel.textColor = p.accent
        buyBtn.backgroundColor = p.accent
        tagLabel.isHidden = p.tag.isEmpty
        tagLabel.text = " \(p.tag) "
        productId = p.id
    }

    @objc private func tapBuy() {
        guard let id = productId else { return }
        Router.shared.push("/services/pkg", params: ["id": id])
    }
}
