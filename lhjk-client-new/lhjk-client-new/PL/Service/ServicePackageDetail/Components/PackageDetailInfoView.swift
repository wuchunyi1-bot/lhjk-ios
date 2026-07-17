import UIKit
import SnapKit

final class PackageDetailInfoView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with pkg: ServicePackageDetail) {
        subviews.forEach { $0.removeFromSuperview() }

        let titleLabel = UILabel()
        titleLabel.font = .fdFont(ofSize: 20, weight: .heavy)
        titleLabel.textColor = .fdText
        titleLabel.numberOfLines = 2

        if !pkg.tag.isEmpty {
            let badge = UILabel()
            badge.text = " \(pkg.tag) "
            badge.font = .fdMicroSemibold
            badge.textColor = .white
            badge.backgroundColor = .fdPrimary
            badge.layer.cornerRadius = 4
            badge.clipsToBounds = true

            let titleRow = UIStackView(arrangedSubviews: [badge, titleLabel])
            titleRow.axis = .horizontal
            titleRow.spacing = 8
            titleRow.alignment = .center
            titleLabel.text = pkg.name
            addSubview(titleRow)
            titleRow.snp.makeConstraints {
                $0.top.leading.trailing.equalToSuperview().inset(16)
            }

            let intro = makeIntroLabel(pkg.subtitle)
            addSubview(intro)
            intro.snp.makeConstraints {
                $0.top.equalTo(titleRow.snp.bottom).offset(8)
                $0.leading.trailing.equalToSuperview().inset(16)
            }
            addPriceRow(pkg: pkg, below: intro)
        } else {
            titleLabel.text = pkg.name
            addSubview(titleLabel)
            titleLabel.snp.makeConstraints {
                $0.top.leading.trailing.equalToSuperview().inset(16)
            }

            let intro = makeIntroLabel(pkg.subtitle)
            addSubview(intro)
            intro.snp.makeConstraints {
                $0.top.equalTo(titleLabel.snp.bottom).offset(8)
                $0.leading.trailing.equalToSuperview().inset(16)
            }
            addPriceRow(pkg: pkg, below: intro)
        }
    }

    private func makeIntroLabel(_ text: String) -> UILabel {
        let intro = UILabel()
        intro.text = text
        intro.font = .fdBody
        intro.textColor = .fdSubtext
        intro.numberOfLines = 2
        return intro
    }

    private func addPriceRow(pkg: ServicePackageDetail, below anchor: UIView) {
        let unitSuffix = pkg.priceUnit.contains("面议") ? "" : " \(pkg.priceUnit)"
        let price = UILabel()
        price.text = "\(pkg.priceText)\(unitSuffix)"
        price.font = .fdMonoFont(ofSize: 22, weight: .heavy)
        price.textColor = .fdPrimary
        price.textAlignment = .right
        addSubview(price)
        price.snp.makeConstraints {
            $0.top.equalTo(anchor.snp.bottom).offset(12)
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
        }
    }
}
