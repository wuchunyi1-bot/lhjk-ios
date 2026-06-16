import UIKit
import SnapKit

// MARK: - Data

fileprivate struct SvcPkg {
    let id: String; let productCode: String; let name: String; let subtitle: String
    let price: String; let priceUnit: String; let tag: String
    let benefits: [String]; let audience: [String]; let detail: String
}

fileprivate struct SvcMatrix {
    let code: String; let name: String; let desc: String; let tier: String; let accent: UIColor; let current: Bool
}

// MARK: - Cells

fileprivate final class CategoryNavCell: UITableViewCell {
    static let reuseID = "CategoryNavCell"
    private let dot = UIView()
    private let codeLbl = UILabel()
    private let nameLbl = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none; backgroundColor = .clear
        dot.layer.cornerRadius = 1.5; dot.isHidden = true
        codeLbl.font = .systemFont(ofSize: 13, weight: .bold); codeLbl.textAlignment = .center
        nameLbl.font = .systemFont(ofSize: 10); nameLbl.textColor = .fdSubtext; nameLbl.textAlignment = .center
        [dot, codeLbl, nameLbl].forEach(contentView.addSubview)
        dot.snp.makeConstraints { $0.leading.equalToSuperview(); $0.centerY.equalToSuperview(); $0.size.equalTo(CGSize(width: 3, height: 24)) }
        codeLbl.snp.makeConstraints { $0.top.equalToSuperview().offset(14); $0.centerX.equalToSuperview() }
        nameLbl.snp.makeConstraints { $0.top.equalTo(codeLbl.snp.bottom).offset(3); $0.centerX.equalToSuperview(); $0.bottom.equalToSuperview().offset(-10) }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ m: SvcMatrix, active: Bool) {
        codeLbl.text = m.code; nameLbl.text = m.name
        dot.isHidden = !active; dot.backgroundColor = m.accent
        contentView.backgroundColor = active ? .fdSurface : .fdBg2
    }
}

fileprivate final class PackageHeaderCell: UITableViewCell {
    static let reuseID = "PackageHeaderCell"
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); selectionStyle = .none; backgroundColor = .clear }
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ m: SvcMatrix) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let icon = UIView(); icon.layer.cornerRadius = 12; icon.layer.borderWidth = 1
        icon.backgroundColor = m.accent.withAlphaComponent(0.09); icon.layer.borderColor = m.accent.withAlphaComponent(0.2).cgColor
        let il = UILabel(); il.text = m.code; il.font = .systemFont(ofSize: 15, weight: .bold); il.textColor = m.accent; il.textAlignment = .center
        icon.addSubview(il); il.snp.makeConstraints { $0.center.equalToSuperview() }; icon.snp.makeConstraints { $0.size.equalTo(44) }

        let name = lbl(m.name, size: 15, weight: .bold); let desc = lbl(m.desc, size: 11, color: .fdSubtext)
        let tier = lbl(m.tier, size: 10, weight: .semibold, color: m.accent)
        let info = UIStackView(arrangedSubviews: [name, desc, tier]); info.axis = .vertical; info.spacing = 2
        let row = UIStackView(arrangedSubviews: [icon, info]); row.spacing = 12; row.alignment = .center
        contentView.addSubview(row); row.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 12, bottom: 14, right: 12)) }

        let div = UIView(); div.backgroundColor = m.accent.withAlphaComponent(0.27)
        contentView.addSubview(div); div.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
    }
    private func lbl(_ t: String, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor = .fdText) -> UILabel {
        let l = UILabel(); l.text = t; l.font = .systemFont(ofSize: size, weight: weight); l.textColor = color; return l
    }
}

// MARK: - Left-Aligned Flow Layout

/// 左对齐换行布局 — 用于 benefits tag 流式展示
fileprivate final class LeftAlignedFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attrs = super.layoutAttributesForElements(in: rect) else { return nil }
        var x: CGFloat = sectionInset.left
        var y: CGFloat = sectionInset.top
        var maxY: CGFloat = y

        for attr in attrs where attr.representedElementCategory == .cell {
            if attr.frame.origin.y > maxY + 1 {
                x = sectionInset.left
                y = attr.frame.origin.y
                maxY = y
            }
            attr.frame.origin.x = x
            attr.frame.origin.y = y
            x += attr.frame.width + minimumInteritemSpacing
            maxY = max(maxY, y)
        }
        return attrs
    }
}

/// 固定高度 CollectionView — 提前计算总高度避免 intrinsicContentSize 自举循环
fileprivate final class SelfSizingCollectionView: UICollectionView {
    var fixedHeight: CGFloat = 0 {
        didSet { heightConstraint?.update(offset: fixedHeight) }
    }
    private var heightConstraint: Constraint?

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        snp.makeConstraints { heightConstraint = $0.height.equalTo(0).constraint }
    }
    required init?(coder: NSCoder) { fatalError() }
}

/// Benefit Tag Cell
fileprivate final class BenefitTagCell: UICollectionViewCell {
    static let reuseID = "BenefitTagCell"
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .fdBg2
        label.font = .systemFont(ofSize: 11)
        label.textColor = .fdText2
        label.textAlignment = .center
        contentView.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)) }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(_ text: String) { label.text = text }

    static func size(for text: String) -> CGSize {
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: 300, height: 22),
            options: [.usesLineFragmentOrigin],
            attributes: [.font: UIFont.systemFont(ofSize: 11)],
            context: nil
        )
        return CGSize(width: ceil(rect.width) + 16, height: 22)
    }

    /// 预计算总高度：模拟左对齐换行，item 高 22pt, 行间距 6pt, 列间距 5pt
    static func totalHeight(for texts: [String], maxWidth: CGFloat) -> CGFloat {
        guard !texts.isEmpty else { return 0 }
        var rows = 1
        var x: CGFloat = 0
        let itemSpacing: CGFloat = 5
        let lineSpacing: CGFloat = 6
        let itemHeight: CGFloat = 22

        for t in texts {
            let w = size(for: t).width
            if x + w > maxWidth && x > 0 {
                rows += 1
                x = w + itemSpacing
            } else {
                x += w + itemSpacing
            }
        }
        return CGFloat(rows) * itemHeight + CGFloat(rows - 1) * lineSpacing
    }
}

// MARK: - PackageCardCell

fileprivate final class PackageCardCell: UITableViewCell {
    static let reuseID = "PackageCardCell"
    private var benefits: [String] = []
    private var benefitsCV: UICollectionView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); selectionStyle = .none; backgroundColor = .clear }
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ p: SvcPkg, accent: UIColor) {
        self.benefits = p.benefits
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor; card.layer.shadowOffset = CGSize(width: 0, height: 1); card.layer.shadowRadius = 6; card.layer.shadowOpacity = 0.03
        contentView.addSubview(card); card.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)) }

        let name = lbl(p.name, size: 15, weight: .bold, color: .fdText)
        var header: UIStackView = UIStackView(arrangedSubviews: [name])
        if !p.tag.isEmpty {
            let tag = UIView(); tag.backgroundColor = accent.withAlphaComponent(0.09); tag.layer.cornerRadius = 999
            let tl = lbl(p.tag, size: 10, weight: .semibold, color: accent); tag.addSubview(tl)
            tl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 7, bottom: 2, right: 7)) }
            header.addArrangedSubview(tag); header.addArrangedSubview(UIView())
        }
        header.spacing = 8; header.alignment = .center

        let sub = lbl(p.subtitle, size: 12, color: .fdSubtext)

        // Benefits: self-sizing CollectionView with left-aligned flow layout
        let layout = LeftAlignedFlowLayout()
        layout.minimumInteritemSpacing = 5; layout.minimumLineSpacing = 6
        layout.sectionInset = .zero
        // Fixed estimate; actual size provided by sizeForItemAt
        layout.estimatedItemSize = CGSize(width: 40, height: 22)

        let benefitsCV = SelfSizingCollectionView(frame: .zero, collectionViewLayout: layout)
        benefitsCV.backgroundColor = .clear; benefitsCV.isScrollEnabled = false
        benefitsCV.register(BenefitTagCell.self, forCellWithReuseIdentifier: BenefitTagCell.reuseID)
        benefitsCV.dataSource = self
        benefitsCV.delegate = self
        self.benefitsCV = benefitsCV

        // Pre-calculate height to avoid intrinsicContentSize chicken-and-egg
        let maxWidth = contentView.bounds.width - 52  // 24(card) + 28(stack)
        let h = BenefitTagCell.totalHeight(for: p.benefits, maxWidth: maxWidth > 0 ? maxWidth : 270)
        benefitsCV.fixedHeight = h

        let price = lbl(p.price, size: 18, weight: .bold, color: .fdPrimary, mono: true)
        let unit = lbl(p.priceUnit, size: 11, color: .fdSubtext)
        let btn = UIButton(type: .system); btn.setTitle("查看详情 ›", for: .normal); btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        btn.setTitleColor(.fdPrimary, for: .normal); btn.backgroundColor = .fdPrimarySoft; btn.layer.cornerRadius = 10
        btn.snp.makeConstraints { $0.height.equalTo(32); $0.width.greaterThanOrEqualTo(80) }
        let footer = UIStackView(arrangedSubviews: [price, unit, UIView(), btn]); footer.spacing = 2; footer.alignment = .center
        let div = UIView(); div.backgroundColor = .fdBorder

        let stack = UIStackView(arrangedSubviews: [header, sub, benefitsCV, div, footer]); stack.axis = .vertical; stack.spacing = 0
        stack.setCustomSpacing(4, after: header); stack.setCustomSpacing(10, after: sub); stack.setCustomSpacing(10, after: benefitsCV)
        card.addSubview(stack); stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
        div.snp.makeConstraints { $0.height.equalTo(1) }

        btn.addTarget(self, action: #selector(tap), for: .touchUpInside)
        objc_setAssociatedObject(self, &kPkgKey, p.id, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        benefits = []
        benefitsCV = nil
    }

    @objc private func tap() {
        if let id = objc_getAssociatedObject(self, &kPkgKey) as? String { Router.shared.push("/services/detail", params: ["id": id]) }
    }
    private func lbl(_ t: String, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor, mono: Bool = false) -> UILabel {
        let l = UILabel(); l.text = t; l.textColor = color; l.font = mono ? .monospacedSystemFont(ofSize: size, weight: weight) : .systemFont(ofSize: size, weight: weight); return l
    }
}

// MARK: - UICollectionViewDataSource for PackageCardCell's benefit tags

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

private var kPkgKey: UInt8 = 0
private var kBenefitsTag = 0  // unused now

// MARK: - ViewController

/// 套餐选择页 — 双 TableView 布局
/// 参考 funde-client: ServiceListView.vue
final class ServiceListViewController: BaseViewController {

    private let productCode: String

    private let matrix: [SvcMatrix] = [
        SvcMatrix(code: "德康", name: "健康基础", desc: "亚健康·六高干预", tier: "基础", accent: UIColor(hexString: "#1F9A6B"), current: false),
        SvcMatrix(code: "德好", name: "向好逆转", desc: "慢病逆转·达标", tier: "主推", accent: .fdPrimary, current: true),
        SvcMatrix(code: "德护", name: "专病管护", desc: "全病程专项管护", tier: "专项", accent: UIColor(hexString: "#3D6FB8"), current: false),
        SvcMatrix(code: "德元", name: "生命元气", desc: "肿瘤·前沿疗法", tier: "高端", accent: UIColor(hexString: "#7B5E9F"), current: false),
        SvcMatrix(code: "德愈", name: "痊愈疑难", desc: "疑难重症·MDT", tier: "高端", accent: UIColor(hexString: "#5C8DC9"), current: false),
        SvcMatrix(code: "德医", name: "医路通达", desc: "三甲就医·全程协助", tier: "专项", accent: UIColor(hexString: "#2C7BB0"), current: false),
        SvcMatrix(code: "德甄", name: "甄选全球", desc: "全球特药甄选", tier: "高端", accent: UIColor(hexString: "#1A7A6E"), current: false),
        SvcMatrix(code: "德际", name: "国际无界", desc: "境外就医服务", tier: "旗舰", accent: UIColor(hexString: "#4A6A8A"), current: false),
        SvcMatrix(code: "德尊", name: "臻享极致", desc: "长寿·精准医学", tier: "旗舰", accent: UIColor(hexString: "#B7905F"), current: false),
    ]

    // Mock packages — filtered by productCode
    private var allPackages: [SvcPkg] = [
        SvcPkg(id: "dekang-s", productCode: "德康", name: "入门版", subtitle: "亚健康基础干预", price: "¥680", priceUnit: "/年", tag: "", benefits: ["健管师月度随访","六维健康测评","基础膳食建议","体征异常提醒"], audience: [], detail: ""),
        SvcPkg(id: "dekang-m", productCode: "德康", name: "标准版", subtitle: "六高全面干预方案", price: "¥1,280", priceUnit: "/年", tag: "推荐", benefits: ["健管师双周随访","营养师膳食方案","季度1369报告","异常预警24H","绿色就医通道"], audience: [], detail: ""),
        SvcPkg(id: "dehao-s", productCode: "德好", name: "入门版", subtitle: "慢病逆转基础方案", price: "¥1,580", priceUnit: "/年", tag: "", benefits: ["健管师周随访","主治医师月度会诊","个性化逆转方案","达标目标追踪"], audience: [], detail: ""),
        SvcPkg(id: "dehao-m", productCode: "德好", name: "标准版", subtitle: "三好共管全程达标", price: "¥2,980", priceUnit: "/年", tag: "热销", benefits: ["主治医师+营养师+健管师三好共管","12周专属逆转方案","不限次健管咨询","季度1369报告","体检+用药全程指导"], audience: [], detail: ""),
        SvcPkg(id: "dehao-l", productCode: "德好", name: "旗舰版", subtitle: "精准医疗个性化管理", price: "¥5,800", priceUnit: "/年", tag: "精选", benefits: ["5人专家团队","基因检测分析","精准干预方案","绿色就医通道","住院全程协助"], audience: [], detail: ""),
        SvcPkg(id: "dehu-s", productCode: "德护", name: "专病版", subtitle: "全病程专项管护", price: "¥3,800", priceUnit: "/年", tag: "", benefits: ["专科医师全程跟诊","病程方案个性化定制","住院协助服务","复查提醒与结果解读","院外用药指导"], audience: [], detail: ""),
        SvcPkg(id: "deyuan-s", productCode: "德元", name: "标准版", subtitle: "肿瘤全程管理", price: "面议", priceUnit: "/定制", tag: "高端", benefits: ["肿瘤专科顾问团队","前沿疗法信息支持","MDT多学科会诊协调","个案管理师全程陪伴"], audience: [], detail: ""),
        SvcPkg(id: "deyu-s", productCode: "德愈", name: "标准版", subtitle: "疑难重症全程支持", price: "面议", priceUnit: "/定制", tag: "高端", benefits: ["疑难重症MDT专家团队","国内顶级专家资源匹配","个案管理师专属支持","二次诊疗意见服务"], audience: [], detail: ""),
        SvcPkg(id: "deyi-s", productCode: "德医", name: "标准版", subtitle: "三甲就医全程协助", price: "¥1,980", priceUnit: "/年", tag: "", benefits: ["三甲医院挂号协助","专科医生推荐匹配","陪诊服务10次/年","体检报告解读"], audience: [], detail: ""),
        SvcPkg(id: "deyi-m", productCode: "德医", name: "尊享版", subtitle: "全国三甲无忧就医", price: "¥3,980", priceUnit: "/年", tag: "推荐", benefits: ["全国三甲绿色通道","专属医疗协调员","不限次陪诊服务","住院全程管理"], audience: [], detail: ""),
        SvcPkg(id: "dezhen-s", productCode: "德甄", name: "标准版", subtitle: "全球特药甄选配送", price: "面议", priceUnit: "/次起", tag: "", benefits: ["全球特效药品甄选","合规进口渠道配送","用药安全全程监测","专业用药指导"], audience: [], detail: ""),
        SvcPkg(id: "deji-s", productCode: "德际", name: "标准版", subtitle: "境外就医全程服务", price: "面议", priceUnit: "/定制", tag: "旗舰", benefits: ["境外知名医院预约","医疗签证协助办理","全程翻译陪同","境外医疗保险协调","回国后衔接治疗"], audience: [], detail: ""),
        SvcPkg(id: "dezun-s", productCode: "德尊", name: "旗舰版", subtitle: "长寿医学极致定制", price: "面议", priceUnit: "/定制", tag: "旗舰", benefits: ["精准抗衰老方案定制","干细胞评估与应用","长寿相关基因检测","10大防癌专项筛查","私人健康管家团队"], audience: [], detail: ""),
    ]

    private var activeCode: String
    private var packages: [SvcPkg] { allPackages.filter { $0.productCode == activeCode } }
    private var activeMatrix: SvcMatrix? { matrix.first { $0.code == activeCode } }

    // MARK: - UI

    private lazy var leftTable: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg2; tv.separatorStyle = .none; tv.showsVerticalScrollIndicator = false
        tv.register(CategoryNavCell.self, forCellReuseIdentifier: CategoryNavCell.reuseID)
        tv.dataSource = self; tv.delegate = self; tv.tag = 0
        return tv
    }()

    private lazy var rightTable: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg; tv.separatorStyle = .none; tv.showsVerticalScrollIndicator = false
        tv.register(PackageHeaderCell.self, forCellReuseIdentifier: PackageHeaderCell.reuseID)
        tv.register(PackageCardCell.self, forCellReuseIdentifier: PackageCardCell.reuseID)
        tv.dataSource = self; tv.delegate = self; tv.tag = 1
        return tv
    }()

    init(productCode: String) {
        self.productCode = productCode
        self.activeCode = productCode
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选择套餐"
        // Scroll left to active item
        if let idx = matrix.firstIndex(where: { $0.code == activeCode }) {
            leftTable.scrollToRow(at: IndexPath(row: idx, section: 0), at: .middle, animated: false)
        }
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        view.addSubview(leftTable)
        view.addSubview(rightTable)

        leftTable.snp.makeConstraints { make in
            make.top.leading.bottom.equalTo(view.safeAreaLayoutGuide)
            make.width.equalTo(78)
        }
        rightTable.snp.makeConstraints { make in
            make.top.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
            make.leading.equalTo(leftTable.snp.trailing)
        }
    }
}

// MARK: - UITableViewDataSource / Delegate

extension ServiceListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableView.tag == 0 ? matrix.count : (packages.isEmpty ? 2 : packages.count + 1) // +1 for header
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CategoryNavCell.reuseID, for: indexPath) as! CategoryNavCell
            let m = matrix[indexPath.row]
            cell.configure(m, active: m.code == activeCode)
            return cell
        }

        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: PackageHeaderCell.reuseID, for: indexPath) as! PackageHeaderCell
            if let m = activeMatrix { cell.configure(m) }
            return cell
        }

        if packages.isEmpty {
            let cell = UITableViewCell()
            cell.selectionStyle = .none; cell.backgroundColor = .clear
            let label = UILabel(); label.text = "🚧\n套餐即将开放\n敬请期待"; label.font = .systemFont(ofSize: 14); label.textColor = .fdSubtext
            label.textAlignment = .center; label.numberOfLines = 0
            cell.contentView.addSubview(label); label.snp.makeConstraints { $0.center.equalToSuperview() }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: PackageCardCell.reuseID, for: indexPath) as! PackageCardCell
        let pkg = packages[indexPath.row - 1]
        cell.configure(pkg, accent: activeMatrix?.accent ?? .fdPrimary)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag == 0 {
            activeCode = matrix[indexPath.row].code
            leftTable.reloadData()
            rightTable.reloadData()
            rightTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }
}
