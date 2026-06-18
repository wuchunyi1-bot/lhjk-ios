import UIKit
import SnapKit

// MARK: - Data Models (fileprivate)

fileprivate struct SvcFeatured {
    let id: String; let code: String; let tag: String; let desc: String
    let benefits: [String]; let price: String; let priceUnit: String
    let status: String; let highlight: Bool; let current: Bool
}

fileprivate struct SvcMatrixItem {
    let code: String; let name: String; let desc: String; let tier: String; let accent: UIColor; let current: Bool
}

fileprivate struct SvcMallProduct {
    let id: String; let name: String; let desc: String; let price: String; let unit: String; let tag: String; let accent: UIColor; let category: String
}

// MARK: - Cells

/// 推荐套餐卡片 Cell — init 创建控件，configure 仅赋值
fileprivate final class FeaturedCardCell: UITableViewCell {
    static let reuseID = "FeaturedCardCell"

    // MARK: - Views (created once)
    private let card = UIView()
    private let highlightBlob = UIView()
    private let codeBg = UIView(); private let codeLbl = UILabel()
    private let nameLbl = UILabel(); private let badgeView = UIView(); private let badgeLbl = UILabel()
    private let descLbl = UILabel(); private let tagRow = UIStackView()
    private let divider = UIView()
    private let priceLbl = UILabel(); private let unitLbl = UILabel(); private let actionBtn = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none; backgroundColor = .clear
        setupViews()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        card.layer.cornerRadius = 18; card.layer.borderWidth = 1; card.clipsToBounds = true
        card.layer.shadowColor = UIColor.black.cgColor; card.layer.shadowOffset = CGSize(width: 0, height: 1); card.layer.shadowRadius = 6; card.layer.shadowOpacity = 0.03
        contentView.addSubview(card); card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        highlightBlob.layer.cornerRadius = 50
        card.addSubview(highlightBlob)
        highlightBlob.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(-20); $0.size.equalTo(100) }

        codeBg.layer.cornerRadius = 14; codeBg.addSubview(codeLbl)
        codeLbl.font = .fdH2; codeLbl.textAlignment = .center
        codeLbl.snp.makeConstraints { $0.center.equalToSuperview() }
        codeBg.snp.makeConstraints { $0.size.equalTo(48) }

        nameLbl.font = .fdBodyBold; nameLbl.textColor = .fdText
        badgeView.layer.cornerRadius = 999
        badgeView.addSubview(badgeLbl)
        badgeLbl.font = .fdMicroSemibold
        badgeLbl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        let nameRow = UIStackView(arrangedSubviews: [nameLbl, badgeView, UIView()]); nameRow.spacing = 8; nameRow.alignment = .center

        descLbl.font = .fdCaption; descLbl.textColor = .fdText2
        let meta = UIStackView(arrangedSubviews: [nameRow, descLbl]); meta.axis = .vertical; meta.spacing = 4
        let header = UIStackView(arrangedSubviews: [codeBg, meta]); header.spacing = 12; header.alignment = .top
        card.addSubview(header)
        header.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(16) }

        tagRow.spacing = 6
        card.addSubview(tagRow)
        tagRow.snp.makeConstraints { $0.top.equalTo(header.snp.bottom).offset(8); $0.leading.equalToSuperview().inset(16) }

        divider.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.2)
        card.addSubview(divider)
        divider.snp.makeConstraints { $0.top.equalTo(tagRow.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(16); $0.height.equalTo(1) }

        priceLbl.font = .fdH2; priceLbl.textColor = .fdPrimary
        unitLbl.font = .fdCaption; unitLbl.textColor = .fdSubtext
        actionBtn.titleLabel?.font = .fdCaptionSemibold
        actionBtn.layer.cornerRadius = 999
        actionBtn.addTarget(self, action: #selector(tapDetail), for: .touchUpInside)
        let footer = UIStackView(arrangedSubviews: [priceLbl, unitLbl, UIView(), actionBtn]); footer.spacing = 2; footer.alignment = .center
        card.addSubview(footer)
        footer.snp.makeConstraints { $0.top.equalTo(divider.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(16); $0.bottom.equalToSuperview().offset(-16) }
        actionBtn.snp.makeConstraints { $0.height.equalTo(36); $0.width.greaterThanOrEqualTo(72) }
    }

    // MARK: - Configure (赋值 only)

    func configure(_ p: SvcFeatured) {
        objc_setAssociatedObject(self, &kRouteKey, p.id, .OBJC_ASSOCIATION_COPY_NONATOMIC)

        card.backgroundColor = p.highlight ? UIColor(hexString: "#FFF7F1") : .fdSurface
        card.layer.borderColor = (p.highlight ? UIColor.fdPrimary.withAlphaComponent(0.25) : UIColor.fdBorder).cgColor
        highlightBlob.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.12)
        highlightBlob.isHidden = !p.highlight

        codeBg.backgroundColor = p.highlight ? .fdPrimary : .fdBg2
        codeLbl.text = p.code
        codeLbl.textColor = p.highlight ? .white : .fdText2

        nameLbl.text = p.tag
        badgeView.backgroundColor = p.current ? UIColor(hexString: "#E6F7EF") : .fdPrimarySoft
        badgeLbl.text = p.current ? "● \(p.status)" : p.status
        badgeLbl.textColor = p.current ? UIColor(hexString: "#1F9A6B") : .fdPrimary

        descLbl.text = p.desc

        // Rebuild only the tag row (variable count)
        tagRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for b in p.benefits {
            let t = UIView(); t.backgroundColor = p.highlight ? UIColor.white.withAlphaComponent(0.7) : .fdBg2; t.layer.cornerRadius = 999
            let tl = UILabel(); tl.text = b; tl.font = .fdMicro; tl.textColor = .fdText2
            t.addSubview(tl); tl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)) }
            tagRow.addArrangedSubview(t)
        }

        priceLbl.text = p.price
        priceLbl.font = .fdH2
        unitLbl.text = p.priceUnit
        actionBtn.setTitle(p.current ? "查看进度" : "了解详情", for: .normal)
        if p.highlight {
            actionBtn.setTitleColor(.white, for: .normal); actionBtn.backgroundColor = .fdPrimary
        } else {
            actionBtn.setTitleColor(.fdPrimary, for: .normal); actionBtn.backgroundColor = .fdPrimarySoft
        }
    }

    @objc private func tapDetail() {
        if let id = objc_getAssociatedObject(self, &kRouteKey) as? String { Router.shared.push("/services/detail", params: ["id": id]) }
    }
}
private var kRouteKey: UInt8 = 0

/// 就医协助引导卡 — init 创建控件，configure 仅赋值（fixed layout）
fileprivate final class MedicalAssistCell: UITableViewCell {
    static let reuseID = "MedicalAssistCell"

    private let card = UIView()
    private let icon = UILabel()
    private let titleLbl = UILabel()
    private let descLbl = UILabel()
    private let tagStack = UIStackView()
    private let applyBtn = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none; backgroundColor = .clear
        setupViews()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        card.backgroundColor = UIColor(hexString: "#FFF7F1"); card.layer.cornerRadius = 18
        card.layer.borderWidth = 1.5; card.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.2).cgColor
        card.layer.shadowColor = UIColor.black.cgColor; card.layer.shadowOffset = CGSize(width: 0, height: 1); card.layer.shadowRadius = 6; card.layer.shadowOpacity = 0.03
        contentView.addSubview(card); card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        icon.text = "🏥"; icon.font = .fdH1
        titleLbl.font = .fdBodyBold; titleLbl.textColor = .fdText
        descLbl.font = .fdCaption; descLbl.textColor = .fdSubtext
        tagStack.spacing = 6

        let content = UIStackView(arrangedSubviews: [titleLbl, descLbl, tagStack]); content.axis = .vertical; content.spacing = 4; content.setCustomSpacing(8, after: descLbl)
        let row = UIStackView(arrangedSubviews: [icon, content]); row.spacing = 12; row.alignment = .top
        card.addSubview(row); row.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }

        applyBtn.setTitle("申请", for: .normal); applyBtn.titleLabel?.font = .fdCaptionSemibold
        applyBtn.setTitleColor(.white, for: .normal); applyBtn.backgroundColor = .fdPrimary; applyBtn.layer.cornerRadius = 999
        applyBtn.addTarget(self, action: #selector(tap), for: .touchUpInside)
        card.addSubview(applyBtn)
        applyBtn.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.top.equalToSuperview().inset(16); $0.height.equalTo(32); $0.width.greaterThanOrEqualTo(64) }
        card.snp.makeConstraints { $0.bottom.equalTo(row.snp.bottom).offset(16) }

        // Fixed tags
        for t in ["挂号协助", "陪诊服务", "绿通转诊"] {
            let tag = UIView(); tag.backgroundColor = .fdPrimarySoft; tag.layer.cornerRadius = 999
            let tl = UILabel(); tl.text = t; tl.font = .fdMicroSemibold; tl.textColor = .fdPrimary
            tag.addSubview(tl); tl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
            tagStack.addArrangedSubview(tag)
        }
    }

    func configure() {
        titleLbl.text = "就医协助服务"
        descLbl.text = "三甲医院挂号协助 · 专业陪诊 · 绿色通道转诊"
    }

    @objc private func tap() { Router.shared.push("/services") }
}

/// 产品矩阵 3×3 grid Cell
fileprivate final class MatrixGridCell: UITableViewCell {
    static let reuseID = "MatrixGridCell"
    private var items: [SvcMatrixItem] = []
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); selectionStyle = .none; backgroundColor = .clear }
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ items: [SvcMatrixItem]) {
        self.items = items
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor; card.layer.shadowOffset = CGSize(width: 0, height: 1); card.layer.shadowRadius = 6; card.layer.shadowOpacity = 0.03
        contentView.addSubview(card); card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let grid = UIStackView(); grid.axis = .vertical; grid.spacing = 4
        card.addSubview(grid); grid.snp.makeConstraints { $0.edges.equalToSuperview().inset(8) }
        for r in stride(from: 0, to: items.count, by: 3) {
            let row = UIStackView(); row.distribution = .fillEqually; row.spacing = 4
            for c in r..<min(r+3, items.count) { row.addArrangedSubview(buildTile(items[c])) }
            grid.addArrangedSubview(row)
        }
    }

    private func buildTile(_ m: SvcMatrixItem) -> UIView {
        let tile = UIButton(type: .system); tile.backgroundColor = .clear; tile.layer.cornerRadius = 12
        let icon = UIView(); icon.layer.cornerRadius = 12; icon.backgroundColor = m.accent.withAlphaComponent(0.13); icon.layer.borderWidth = 1; icon.layer.borderColor = m.accent.withAlphaComponent(0.2).cgColor
        let il = UILabel(); il.text = m.code; il.font = .fdBodyBold; il.textColor = m.accent; il.textAlignment = .center
        icon.addSubview(il); il.snp.makeConstraints { $0.center.equalToSuperview() }; icon.snp.makeConstraints { $0.size.equalTo(44) }
        let name = UILabel(); name.text = m.name; name.font = .fdCaptionSemibold; name.textColor = .fdText; name.textAlignment = .center
        let desc = UILabel(); desc.text = m.desc; desc.font = .fdMicro; desc.textColor = .fdSubtext; desc.textAlignment = .center
        let tier = UILabel(); tier.text = m.tier; tier.font = .fdMicroSemibold; tier.textColor = m.accent; tier.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [icon, name, desc, tier]); stack.axis = .vertical; stack.alignment = .center; stack.spacing = 4
        stack.isUserInteractionEnabled = false; tile.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 4, bottom: 14, right: 4)) }
        if m.current {
            let badge = UILabel(); badge.text = "使用中"; badge.font = .fdMicroSemibold; badge.textColor = .white; badge.backgroundColor = .fdPrimary; badge.layer.cornerRadius = 4; badge.textAlignment = .center; badge.clipsToBounds = true
            tile.addSubview(badge); badge.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(4); $0.height.equalTo(16); $0.width.equalTo(44) }
        }
        tile.addTarget(self, action: #selector(tileTapped(_:)), for: .touchUpInside)
        objc_setAssociatedObject(tile, &kMatrixKey, m.code, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        return tile
    }
    @objc private func tileTapped(_ sender: UIButton) {
        if let code = objc_getAssociatedObject(sender, &kMatrixKey) as? String { Router.shared.push("/services/list", params: ["code": code]) }
    }
}
private var kMatrixKey: UInt8 = 0

/// 富德优选 2×N grid Cell
fileprivate final class MallGridCell: UITableViewCell {
    static let reuseID = "MallGridCell"
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); selectionStyle = .none; backgroundColor = .clear }
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ products: [SvcMallProduct]) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let grid = UIStackView(); grid.axis = .vertical; grid.spacing = 10
        contentView.addSubview(grid); grid.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        for r in stride(from: 0, to: products.count, by: 2) {
            let row = UIStackView(); row.distribution = .fillEqually; row.spacing = 10
            for c in r..<min(r+2, products.count) { row.addArrangedSubview(buildMallCard(products[c])) }
            grid.addArrangedSubview(row)
        }
    }

    private func buildMallCard(_ p: SvcMallProduct) -> UIView {
        let card = UIButton(type: .system); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.clipsToBounds = true
        card.layer.shadowColor = UIColor.black.cgColor; card.layer.shadowOffset = CGSize(width: 0, height: 1); card.layer.shadowRadius = 6; card.layer.shadowOpacity = 0.03

        let img = UIView(); img.backgroundColor = .fdBg2
        if !p.tag.isEmpty {
            let tag = UILabel(); tag.text = p.tag; tag.font = .fdMicroSemibold; tag.textColor = .white; tag.backgroundColor = .fdPrimary; tag.layer.cornerRadius = 4; tag.textAlignment = .center; tag.clipsToBounds = true
            img.addSubview(tag); tag.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(6); $0.height.equalTo(16); $0.width.greaterThanOrEqualTo(30) }
        }
        let pl = UILabel(); pl.text = "商品封面"; pl.font = .fdMicro; pl.textColor = .fdMuted; pl.textAlignment = .center
        img.addSubview(pl); pl.snp.makeConstraints { $0.center.equalToSuperview() }

        let name = lbl(p.name, size: 13, weight: .semibold, color: .fdText); name.numberOfLines = 1
        let desc = lbl(p.desc, size: 11, color: .fdSubtext); desc.numberOfLines = 1
        let price = lbl(p.price, size: 15, weight: .bold, color: p.accent, mono: true)
        let unit = lbl(p.unit, size: 10, color: .fdSubtext)
        let body = UIStackView(arrangedSubviews: [name, desc])
        body.axis = .vertical; body.spacing = 3
        let stack = UIStackView(arrangedSubviews: [img, body, price, unit])
        stack.axis = .vertical; stack.spacing = 6
        stack.setCustomSpacing(10, after: img); stack.setCustomSpacing(6, after: body)
        stack.isUserInteractionEnabled = false; card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)) }
        img.snp.makeConstraints { $0.height.equalTo(90) }

        card.addTarget(self, action: #selector(mallTapped(_:)), for: .touchUpInside)
        objc_setAssociatedObject(card, &kMallKey, p.id, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        return card
    }
    @objc private func mallTapped(_ sender: UIButton) {
        if let id = objc_getAssociatedObject(sender, &kMallKey) as? String { Router.shared.push("/mall/detail", params: ["id": id]) }
    }
    private func lbl(_ t: String, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor, mono: Bool = false) -> UILabel {
        let l = UILabel(); l.text = t; l.textColor = color; l.font = mono ? .fdMonoFont(ofSize: size, weight: weight) : .fdFont(ofSize: size, weight: weight); return l
    }
}
private var kMallKey: UInt8 = 0

// MARK: - ViewController

/// 服务模块 Hub 页 — UITableView 4 sections
/// 参考 funde-client: ServicesView.vue
///
/// tableHeaderView: Custom Topbar
/// Section 0: FeaturedCardCell × 2
/// Section 1: MedicalAssistCell
/// Section 2: MatrixGridCell (3×3)
/// Section 3: MallGridCell (2×N)
final class ServiceViewController: BaseViewController {

    private let featured: [SvcFeatured] = [
        SvcFeatured(id: "dehao", code: "德好", tag: "向好逆转·慢病管理", desc: "主治医师 + 营养师 + 健管师 三好共管", benefits: ["12 周专属方案", "不限次健管咨询", "体检 + 用药指导"], price: "¥2,980", priceUnit: "/年", status: "进行中 · 剩 45 天", highlight: true, current: true),
        SvcFeatured(id: "dezun", code: "德尊", tag: "臻享极致·长寿医学", desc: "精准抗衰 · 个性化营养 · 干细胞评估 · 私人健康管家", benefits: ["个性化长寿方案", "干细胞评估", "10大防癌项目"], price: "面议", priceUnit: "/定制", status: "为您推荐", highlight: false, current: false),
    ]

    private let matrix: [SvcMatrixItem] = [
        SvcMatrixItem(code: "德康", name: "健康基础", desc: "亚健康·六高干预", tier: "基础", accent: UIColor(hexString: "#1F9A6B"), current: false),
        SvcMatrixItem(code: "德好", name: "向好逆转", desc: "慢病逆转·达标", tier: "主推", accent: .fdPrimary, current: true),
        SvcMatrixItem(code: "德护", name: "专病管护", desc: "全病程专项管护", tier: "专项", accent: UIColor(hexString: "#3D6FB8"), current: false),
        SvcMatrixItem(code: "德元", name: "生命元气", desc: "肿瘤·前沿疗法", tier: "高端", accent: UIColor(hexString: "#7B5E9F"), current: false),
        SvcMatrixItem(code: "德愈", name: "痊愈疑难", desc: "疑难重症·MDT", tier: "高端", accent: UIColor(hexString: "#5C8DC9"), current: false),
        SvcMatrixItem(code: "德医", name: "医路通达", desc: "三甲就医·全程协助", tier: "专项", accent: UIColor(hexString: "#2C7BB0"), current: false),
        SvcMatrixItem(code: "德甄", name: "甄选全球", desc: "全球特药甄选", tier: "高端", accent: UIColor(hexString: "#1A7A6E"), current: false),
        SvcMatrixItem(code: "德际", name: "国际无界", desc: "境外就医服务", tier: "旗舰", accent: UIColor(hexString: "#4A6A8A"), current: false),
        SvcMatrixItem(code: "德尊", name: "臻享极致", desc: "长寿·精准医学", tier: "旗舰", accent: UIColor(hexString: "#B7905F"), current: false),
    ]

    private let mallProducts: [SvcMallProduct] = [
        SvcMallProduct(id: "m001", name: "德好·控糖益生菌", desc: "餐后血糖平稳配方", price: "¥128", unit: "60粒/盒", tag: "热销", accent: .fdPrimary, category: "营养补充"),
        SvcMallProduct(id: "m002", name: "深海鱼油软胶囊", desc: "EPA+DHA 心脑血管养护", price: "¥98", unit: "90粒/瓶", tag: "", accent: UIColor(hexString: "#2C7BB0"), category: "营养补充"),
        SvcMallProduct(id: "m003", name: "膳食纤维复合粉", desc: "助消化·促代谢·饱腹感", price: "¥76", unit: "30袋/盒", tag: "推荐", accent: UIColor(hexString: "#1F9A6B"), category: "功能食品"),
        SvcMallProduct(id: "m004", name: "辅酶Q10胶囊", desc: "心肌细胞能量代谢支持", price: "¥168", unit: "60粒/瓶", tag: "", accent: UIColor(hexString: "#D6602B"), category: "营养补充"),
        SvcMallProduct(id: "m005", name: "维生素D3+K2", desc: "钙吸收协同·骨骼强健", price: "¥88", unit: "120粒/瓶", tag: "", accent: UIColor(hexString: "#B47300"), category: "营养补充"),
        SvcMallProduct(id: "m006", name: "乳清蛋白质粉", desc: "肌肉维持·体重管理首选", price: "¥218", unit: "500g/罐", tag: "精选", accent: UIColor(hexString: "#7B5E9F"), category: "功能食品"),
    ]

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg; tv.separatorStyle = .none; tv.showsVerticalScrollIndicator = false
        tv.dataSource = self; tv.delegate = self
        tv.register(FeaturedCardCell.self, forCellReuseIdentifier: FeaturedCardCell.reuseID)
        tv.register(MedicalAssistCell.self, forCellReuseIdentifier: MedicalAssistCell.reuseID)
        tv.register(MatrixGridCell.self, forCellReuseIdentifier: MatrixGridCell.reuseID)
        tv.register(MallGridCell.self, forCellReuseIdentifier: MallGridCell.reuseID)
        tv.tableHeaderView = buildTopbar()
        tv.contentInsetAdjustmentBehavior = .never
        return tv
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        view.addSubview(tableView); tableView.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.bottom.equalTo(view.safeAreaLayoutGuide) }
    }

    private func buildTopbar() -> UIView {
        let header = UIView(); header.backgroundColor = .fdBg
        let title = UILabel(); title.text = "健康服务"; title.font = .fdH2; title.textColor = .fdText
        let sub = UILabel(); sub.text = "德系健康管理 · 9 大产品线"; sub.font = .fdCaption; sub.textColor = .fdSubtext
        [title, sub].forEach(header.addSubview)
        title.snp.makeConstraints { $0.top.equalToSuperview().offset(54); $0.leading.equalToSuperview().offset(18) }
        sub.snp.makeConstraints { $0.top.equalTo(title.snp.bottom).offset(2); $0.leading.equalToSuperview().offset(18); $0.bottom.equalToSuperview().offset(-8) }
        let size = header.systemLayoutSizeFitting(CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        header.frame.size = CGSize(width: view.bounds.width, height: size.height)
        return header
    }
}

// MARK: - UITableViewDataSource / Delegate

extension ServiceViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 4 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section { case 0: return featured.count; default: return 1 }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: FeaturedCardCell.reuseID, for: indexPath) as! FeaturedCardCell
            cell.configure(featured[indexPath.row]); return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: MedicalAssistCell.reuseID, for: indexPath) as! MedicalAssistCell
            cell.configure(); return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: MatrixGridCell.reuseID, for: indexPath) as! MatrixGridCell
            cell.configure(matrix); return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: MallGridCell.reuseID, for: indexPath) as! MallGridCell
            cell.configure(Array(mallProducts.prefix(6))); return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let titles = [nil, nil, "德系产品矩阵", "富德优选"]
        let mores  = [nil, nil, "了解品牌故事 ›", "查看全部 ›"]
        guard let t = titles[section] else { return nil }
        let h = SectionTitleView(title: t, more: mores[section])
        if section == 3 { h.onMoreTapped = { Router.shared.push("/mall") } }
        let c = UIView(); c.backgroundColor = .fdBg; c.addSubview(h); h.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }; return c
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { [nil, nil, "德系产品矩阵", "富德优选"][section] != nil ? 36 : 8 }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 8 }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }
}
