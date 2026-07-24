import UIKit
import SnapKit

final class PackageCardCell: UITableViewCell {
    static let reuseID = "PackageCardCell"

    private var packageId: String?
    private var hospitalId: String?
    private var categoryServiceId: String?
    private var benefits: [String] = []
    private var benefitsCV: UICollectionView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ item: HealthPackageItem, categoryServiceId: String? = nil) {
        packageId = item.id
        hospitalId = item.hospitalId
        self.categoryServiceId = categoryServiceId
        benefits = item.audienceTags
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 12, bottom: 12, right: 12)) }

        let name = lbl(item.name, size: 15, weight: .bold, color: .fdText)
        let header: UIStackView = UIStackView(arrangedSubviews: [name])
        if let badge = item.badge, !badge.isEmpty, badge != "无" {
            let tag = UIView()
            tag.backgroundColor = UIColor.fdPrimarySoft
            tag.layer.cornerRadius = 999
            let tl = lbl(badge, size: 10, weight: .semibold, color: .fdPrimary)
            tag.addSubview(tl)
            tl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 7, bottom: 2, right: 7)) }
            header.addArrangedSubview(tag)
            header.addArrangedSubview(UIView())
        }
        header.spacing = 8
        header.alignment = .center

        let sub = lbl(item.subtitle, size: 12, color: .fdSubtext)

        let price = lbl(item.price, size: 15, weight: .bold, color: .fdPrimary, mono: true)
        let btn = UIButton(type: .system)
        btn.setTitle("查看详情 ›", for: .normal)
        btn.titleLabel?.font = .fdCaptionSemibold
        btn.setTitleColor(.fdPrimary, for: .normal)
        btn.backgroundColor = .clear
        btn.snp.makeConstraints { $0.height.equalTo(36); $0.width.greaterThanOrEqualTo(88) }
        let footer = UIStackView(arrangedSubviews: [price, UIView(), btn])
        footer.alignment = .center

        let div = DashedSeparatorView()

        let stack = UIStackView(arrangedSubviews: [header, sub, div, footer])
        stack.axis = .vertical
        stack.spacing = 0
        stack.setCustomSpacing(4, after: header)
        stack.setCustomSpacing(12, after: sub)
        stack.setCustomSpacing(12, after: div)
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        div.snp.makeConstraints { $0.height.equalTo(1) }

        btn.addTarget(self, action: #selector(tap), for: .touchUpInside)
    }

    func configure(_ p: SvcPkg, accent: UIColor) {
        packageId = p.id
        benefits = p.benefits
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)) }

        let name = lbl(p.name, size: 15, weight: .bold, color: .fdText)
        let header: UIStackView = UIStackView(arrangedSubviews: [name])
        if !p.tag.isEmpty {
            let tag = UIView()
            tag.backgroundColor = accent.withAlphaComponent(0.09)
            tag.layer.cornerRadius = 999
            let tl = lbl(p.tag, size: 10, weight: .semibold, color: accent)
            tag.addSubview(tl)
            tl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 7, bottom: 2, right: 7)) }
            header.addArrangedSubview(tag)
            header.addArrangedSubview(UIView())
        }
        header.spacing = 8
        header.alignment = .center

        let sub = lbl(p.subtitle, size: 12, color: .fdSubtext)

        let layout = LeftAlignedFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 6
        layout.sectionInset = .zero
        layout.estimatedItemSize = CGSize(width: 40, height: 22)

        let benefitsCV = SelfSizingCollectionView(frame: .zero, collectionViewLayout: layout)
        benefitsCV.backgroundColor = .clear
        benefitsCV.isScrollEnabled = false
        benefitsCV.register(BenefitTagCell.self, forCellWithReuseIdentifier: BenefitTagCell.reuseID)
        benefitsCV.dataSource = self
        benefitsCV.delegate = self
        self.benefitsCV = benefitsCV

        let maxWidth = contentView.bounds.width - 52
        let h = BenefitTagCell.totalHeight(for: p.benefits, maxWidth: maxWidth > 0 ? maxWidth : 270)
        benefitsCV.fixedHeight = h

        let price = lbl(p.price, size: 18, weight: .bold, color: .fdPrimary, mono: true)
        let unit = lbl(p.priceUnit, size: 11, color: .fdSubtext)
        let btn = UIButton(type: .system)
        btn.setTitle("查看详情 ›", for: .normal)
        btn.titleLabel?.font = .fdCaptionSemibold
        btn.setTitleColor(.fdPrimary, for: .normal)
        btn.backgroundColor = .fdPrimarySoft
        btn.layer.cornerRadius = 10
        btn.snp.makeConstraints { $0.height.equalTo(32); $0.width.greaterThanOrEqualTo(80) }
        let footer = UIStackView(arrangedSubviews: [price, unit, UIView(), btn])
        footer.spacing = 2
        footer.alignment = .center
        let div = UIView()
        div.backgroundColor = .fdBorder

        let stack = UIStackView(arrangedSubviews: [header, sub, benefitsCV, div, footer])
        stack.axis = .vertical
        stack.spacing = 0
        stack.setCustomSpacing(4, after: header)
        stack.setCustomSpacing(10, after: sub)
        stack.setCustomSpacing(10, after: benefitsCV)
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
        div.snp.makeConstraints { $0.height.equalTo(1) }

        btn.addTarget(self, action: #selector(tap), for: .touchUpInside)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        packageId = nil
        hospitalId = nil
        categoryServiceId = nil
        benefits = []
        benefitsCV = nil
    }

    @objc private func tap() {
        guard let id = packageId else { return }
        Router.shared.push(
            "/services/pkg",
            params: ServiceRoutes.packageDetailParams(
                packageId: id,
                hospitalId: hospitalId,
                categoryServiceId: categoryServiceId
            )
        )
    }

    private func lbl(_ t: String, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor, mono: Bool = false) -> UILabel {
        let l = UILabel()
        l.text = t
        l.textColor = color
        l.font = mono ? .fdMonoFont(ofSize: size, weight: weight) : .fdFont(ofSize: size, weight: weight)
        return l
    }
}

// MARK: - Dashed separator

private final class DashedSeparatorView: UIView {
    private let shape = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        shape.strokeColor = UIColor.fdBorder.cgColor
        shape.lineWidth = 1
        shape.lineDashPattern = [4, 3]
        layer.addSublayer(shape)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        shape.frame = bounds
        shape.path = UIBezierPath(rect: bounds).cgPath
    }
}

// MARK: - UICollectionViewDataSource for benefit tags

extension PackageCardCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { benefits.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BenefitTagCell.reuseID, for: indexPath) as! BenefitTagCell
        cell.configure(benefits[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        BenefitTagCell.size(for: benefits[indexPath.item])
    }
}
