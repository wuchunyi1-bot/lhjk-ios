import UIKit
import SnapKit

final class PackageDetailInfoView: UIView {

    func configure(with pkg: ServicePackageDetail) {
        subviews.forEach { $0.removeFromSuperview() }

        let titleRow = UIStackView()
        titleRow.axis = .horizontal
        titleRow.spacing = 8
        titleRow.alignment = .center

        if !pkg.tag.isEmpty {
            let badge = UILabel()
            badge.text = " \(pkg.tag) "
            badge.font = .fdMicroSemibold
            badge.textColor = .white
            badge.backgroundColor = .fdPrimary
            badge.layer.cornerRadius = 4
            badge.clipsToBounds = true
            titleRow.addArrangedSubview(badge)
        }

        let name = UILabel()
        name.text = pkg.name
        name.font = .fdFont(ofSize: 20, weight: .heavy)
        name.textColor = .fdText
        name.numberOfLines = 2
        titleRow.addArrangedSubview(name)
        addSubview(titleRow)
        titleRow.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        let subtitle = UILabel()
        subtitle.text = pkg.subtitle
        subtitle.font = .fdCaption
        subtitle.textColor = .fdSubtext
        subtitle.numberOfLines = 2
        subtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let price = UILabel()
        let unitSuffix = pkg.priceUnit.contains("面议") ? "" : " \(pkg.priceUnit)"
        price.text = "\(pkg.priceText)\(unitSuffix)"
        price.font = .fdMonoFont(ofSize: 18, weight: .bold)
        price.textColor = .fdPrimary
        price.setContentHuggingPriority(.required, for: .horizontal)

        let mid = UIStackView(arrangedSubviews: [subtitle, price])
        mid.axis = .horizontal
        mid.alignment = .top
        mid.spacing = 12
        addSubview(mid)
        mid.snp.makeConstraints {
            $0.top.equalTo(titleRow.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
        }

        if pkg.tags.isEmpty {
            mid.snp.makeConstraints { $0.bottom.equalToSuperview() }
        } else {
            let tagStack = UIStackView()
            tagStack.axis = .horizontal
            tagStack.spacing = 8
            tagStack.alignment = .leading
            for text in pkg.tags.prefix(4) {
                let tag = UILabel()
                let short = text.count > 4 ? String(text.prefix(4)) + "…" : text
                tag.text = " \(short) "
                tag.font = .fdCaptionSemibold
                tag.textColor = .fdPrimary
                tag.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.08)
                tag.layer.cornerRadius = 999
                tag.layer.borderWidth = 1
                tag.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.25).cgColor
                tag.clipsToBounds = true
                tagStack.addArrangedSubview(tag)
            }
            addSubview(tagStack)
            tagStack.snp.makeConstraints {
                $0.top.equalTo(mid.snp.bottom).offset(10)
                $0.leading.trailing.bottom.equalToSuperview()
            }
        }
    }
}
