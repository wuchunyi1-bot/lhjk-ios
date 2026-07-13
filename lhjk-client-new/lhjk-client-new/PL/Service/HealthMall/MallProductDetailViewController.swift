import UIKit
import SnapKit

/// 富德优选商品详情 — 对齐 `MallProductDetailView.vue`
final class MallProductDetailViewController: BaseViewController {

    private let productId: String
    private let catalog: ServiceCatalogService
    private var product: MallProduct?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let orderBar = UIView()

    init(
        productId: String,
        catalogService: ServiceCatalogService = AppContainer.shared.serviceCatalogService
    ) {
        self.productId = productId
        self.catalog = catalogService
        // 未知 id 时原型阶段 fallback 首件（对齐 Vue），避免空白页
        let found = catalogService.product(id: productId)
        self.product = found ?? (productId.isEmpty ? nil : catalogService.loadMallProducts().first)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func setupUI() {
        view.backgroundColor = .fdBg
        title = product?.name ?? "商品详情"

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        if let product {
            buildContent(product)
            buildOrderBar(product)
        } else {
            buildEmpty()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Empty

    private func buildEmpty() {
        let emptyLabel = UILabel()
        emptyLabel.text = "商品不存在"
        emptyLabel.font = .fdBody
        emptyLabel.textColor = .fdSubtext
        emptyLabel.textAlignment = .center
        contentView.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(120)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-40)
        }
    }

    // MARK: - Content

    private func buildContent(_ p: MallProduct) {
        let copy = MallProductCategoryCopy.forCategory(p.category)
        var last: ConstraintItem = contentView.snp.top

        let hero = MallProductHeroView(product: p, categoryLabel: copy.label)
        contentView.addSubview(hero)
        hero.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }
        last = hero.snp.bottom

        let titleBar = buildTitleBar(p)
        contentView.addSubview(titleBar)
        titleBar.snp.makeConstraints {
            $0.top.equalTo(last).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        last = titleBar.snp.bottom

        last = addSection(title: "商品亮点", below: last) { card in
            let stack = UIStackView()
            stack.axis = .vertical
            card.addSubview(stack)
            stack.snp.makeConstraints {
                $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 12, right: 16))
            }
            for (i, text) in copy.highlights.enumerated() {
                stack.addArrangedSubview(
                    makeHighlightRow(text: text, accent: p.accent, showDivider: i < copy.highlights.count - 1)
                )
            }
        }

        last = addSection(title: "适用人群", below: last) { card in
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 8
            stack.alignment = .leading
            for text in copy.audience {
                let tag = UILabel()
                tag.text = "  \(text)  "
                tag.font = .fdCaptionSemibold
                tag.textColor = p.accent
                tag.backgroundColor = p.accent.withAlphaComponent(0.07)
                tag.layer.cornerRadius = 999
                tag.layer.borderWidth = 1
                tag.layer.borderColor = p.accent.withAlphaComponent(0.2).cgColor
                tag.clipsToBounds = true
                tag.snp.makeConstraints { $0.height.equalTo(28) }
                stack.addArrangedSubview(tag)
            }
            card.addSubview(stack)
            stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
        }

        last = addSection(title: "详情说明", below: last) { card in
            let title = UILabel()
            title.text = copy.scenario
            title.font = .fdFont(ofSize: 16, weight: .bold)
            title.textColor = .fdText
            title.numberOfLines = 0
            let desc = UILabel()
            desc.text = copy.detail
            desc.font = .fdBody
            desc.textColor = .fdSubtext
            desc.numberOfLines = 0
            let stack = UIStackView(arrangedSubviews: [title, desc])
            stack.axis = .vertical
            stack.spacing = 8
            card.addSubview(stack)
            stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        }

        let steps = MallProductCategoryCopy.usageSteps(productName: p.name)
        let stepsStack = UIStackView()
        stepsStack.axis = .vertical
        stepsStack.spacing = 10
        contentView.addSubview(stepsStack)
        stepsStack.snp.makeConstraints {
            $0.top.equalTo(last).offset(10)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        for (idx, step) in steps.enumerated() {
            stepsStack.addArrangedSubview(
                makeUsageCard(index: idx + 1, title: step.title, desc: step.desc, accent: p.accent)
            )
        }
        last = stepsStack.snp.bottom

        let promise = buildPromiseBar()
        contentView.addSubview(promise)
        promise.snp.makeConstraints {
            $0.top.equalTo(last).offset(14)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-24)
        }
    }

    private func buildTitleBar(_ p: MallProduct) -> UIView {
        let bar = UIView()
        let name = UILabel()
        name.text = p.name
        name.font = .fdFont(ofSize: 18, weight: .bold)
        name.textColor = .fdText
        name.numberOfLines = 2
        let unit = UILabel()
        unit.text = p.unit
        unit.font = .fdCaption
        unit.textColor = .fdSubtext
        let left = UIStackView(arrangedSubviews: [name, unit])
        left.axis = .vertical
        left.spacing = 4
        let price = UILabel()
        price.text = p.price
        price.font = .fdMonoFont(ofSize: 24, weight: .bold)
        price.textColor = p.accent
        price.setContentHuggingPriority(.required, for: .horizontal)
        bar.addSubview(left)
        bar.addSubview(price)
        left.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(price.snp.leading).offset(-14)
        }
        price.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
        return bar
    }

    private func makeHighlightRow(text: String, accent: UIColor, showDivider: Bool) -> UIView {
        let row = UIView()
        let check = UIView()
        check.backgroundColor = accent.withAlphaComponent(0.09)
        check.layer.cornerRadius = 11
        let icon = UIImageView(image: UIImage(systemName: "checkmark"))
        icon.tintColor = accent
        icon.contentMode = .scaleAspectFit
        check.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(12) }

        let label = UILabel()
        label.text = text
        label.font = .fdBody
        label.textColor = .fdText

        row.addSubview(check)
        row.addSubview(label)
        check.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(22)
        }
        label.snp.makeConstraints {
            $0.leading.equalTo(check.snp.trailing).offset(10)
            $0.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(10)
        }
        if showDivider {
            let d = UIView()
            d.backgroundColor = .fdBorder
            row.addSubview(d)
            d.snp.makeConstraints {
                $0.leading.trailing.bottom.equalToSuperview()
                $0.height.equalTo(1)
            }
        }
        return row
    }

    private func makeUsageCard(index: Int, title: String, desc: String, accent: UIColor) -> UIView {
        let card = makeCard()
        let num = UILabel()
        num.text = "\(index)"
        num.font = .fdMonoFont(ofSize: 14, weight: .bold)
        num.textColor = .white
        num.textAlignment = .center
        num.backgroundColor = accent
        num.layer.cornerRadius = 9
        num.clipsToBounds = true

        let t = UILabel()
        t.text = title
        t.font = .fdFont(ofSize: 15, weight: .bold)
        t.textColor = .fdText
        let d = UILabel()
        d.text = desc
        d.font = .fdCaption
        d.textColor = .fdSubtext
        d.numberOfLines = 0
        let right = UIStackView(arrangedSubviews: [t, d])
        right.axis = .vertical
        right.spacing = 4

        card.addSubview(num)
        card.addSubview(right)
        num.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(14)
            $0.size.equalTo(26)
        }
        right.snp.makeConstraints {
            $0.leading.equalTo(num.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(14)
            $0.bottom.equalToSuperview().offset(-14)
        }
        return card
    }

    private func buildPromiseBar() -> UIView {
        let card = makeCard()
        let items: [(String, String)] = [
            ("checkmark.shield", "正品保障"),
            ("shippingbox", "快速发货"),
            ("person.crop.circle.badge.checkmark", "售后无忧"),
        ]
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        for (icon, text) in items {
            let col = UIStackView()
            col.axis = .horizontal
            col.spacing = 4
            col.alignment = .center
            let iv = UIImageView(image: UIImage(systemName: icon))
            iv.tintColor = UIColor(hexString: "#1F9A6B")
            iv.contentMode = .scaleAspectFit
            iv.snp.makeConstraints { $0.size.equalTo(16) }
            let lbl = UILabel()
            lbl.text = text
            lbl.font = .fdMicro
            lbl.textColor = .fdSubtext
            col.addArrangedSubview(iv)
            col.addArrangedSubview(lbl)
            let holder = UIView()
            holder.addSubview(col)
            col.snp.makeConstraints { $0.center.equalToSuperview() }
            stack.addArrangedSubview(holder)
        }
        card.addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 13, left: 10, bottom: 13, right: 10))
            $0.height.equalTo(24)
        }
        return card
    }

    // MARK: - Order bar

    private func buildOrderBar(_ p: MallProduct) {
        orderBar.backgroundColor = UIColor.fdSurface.withAlphaComponent(0.94)
        let border = UIView()
        border.backgroundColor = .fdBorder
        orderBar.addSubview(border)
        border.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }

        let label = UILabel()
        label.text = "优选价"
        label.font = .fdMicro
        label.textColor = .fdSubtext
        let price = UILabel()
        price.text = p.price
        price.font = .fdMonoFont(ofSize: 22, weight: .bold)
        price.textColor = p.accent
        let left = UIStackView(arrangedSubviews: [label, price])
        left.axis = .vertical
        left.spacing = 2

        let consult = UIButton(type: .system)
        consult.setTitle("咨询", for: .normal)
        consult.setTitleColor(.fdPrimary, for: .normal)
        consult.titleLabel?.font = .fdBody
        consult.layer.cornerRadius = 12
        consult.layer.borderWidth = 1
        consult.layer.borderColor = UIColor.fdPrimary.cgColor
        consult.contentEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        consult.addTarget(self, action: #selector(tapConsult), for: .touchUpInside)

        let buy = UIButton(type: .system)
        buy.setTitle("立即购买", for: .normal)
        buy.setTitleColor(.white, for: .normal)
        buy.titleLabel?.font = .fdBodySemibold
        buy.backgroundColor = .fdPrimary
        buy.layer.cornerRadius = 12
        buy.contentEdgeInsets = UIEdgeInsets(top: 0, left: 22, bottom: 0, right: 22)
        buy.addTarget(self, action: #selector(tapBuy), for: .touchUpInside)

        let actions = UIStackView(arrangedSubviews: [consult, buy])
        actions.axis = .horizontal
        actions.spacing = 10
        consult.snp.makeConstraints { $0.height.equalTo(44) }
        buy.snp.makeConstraints { $0.height.equalTo(44) }

        orderBar.addSubview(left)
        orderBar.addSubview(actions)
        view.addSubview(orderBar)

        orderBar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }
        left.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(10)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
        }
        actions.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(left)
        }

        scrollView.snp.remakeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(orderBar.snp.top)
        }
    }

    // MARK: - Helpers

    @discardableResult
    private func addSection(title: String, below: ConstraintItem, build: (UIView) -> Void) -> ConstraintItem {
        let header = UILabel()
        header.text = title
        header.font = .fdFont(ofSize: 16, weight: .bold)
        header.textColor = .fdText
        contentView.addSubview(header)
        header.snp.makeConstraints {
            $0.top.equalTo(below).offset(18)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        let card = makeCard()
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalTo(header.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        build(card)
        return card.snp.bottom
    }

    private func makeCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        return card
    }

    @objc private func tapConsult() {
        Router.shared.push("/conversations/:id", params: ["id": "conv-001"])
    }

    @objc private func tapBuy() {
        let id = product?.id ?? productId
        Router.shared.push("/orders/confirm", params: ["id": id])
    }
}

// MARK: - Hero

private final class MallProductHeroView: UIView {
    private let gradient = CAGradientLayer()

    init(product: MallProduct, categoryLabel: String) {
        super.init(frame: .zero)
        clipsToBounds = true
        gradient.colors = [
            product.accent.withAlphaComponent(0.12).cgColor,
            product.accent.withAlphaComponent(0.26).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradient, at: 0)

        if !product.tag.isEmpty {
            let tag = UILabel()
            tag.text = " \(product.tag) "
            tag.font = .fdMicroSemibold
            tag.textColor = .white
            tag.backgroundColor = product.accent
            tag.layer.cornerRadius = 6
            tag.clipsToBounds = true
            addSubview(tag)
            tag.snp.makeConstraints {
                $0.top.equalToSuperview().offset(14)
                $0.trailing.equalToSuperview().offset(-16)
                $0.height.equalTo(22)
            }
        }

        let emojiBox = UIView()
        emojiBox.backgroundColor = UIColor.white.withAlphaComponent(0.72)
        emojiBox.layer.cornerRadius = 24
        let emoji = UILabel()
        emoji.text = product.emoji
        emoji.font = .systemFont(ofSize: 38)
        emoji.textAlignment = .center
        emojiBox.addSubview(emoji)
        emoji.snp.makeConstraints { $0.center.equalToSuperview() }

        let cat = UILabel()
        cat.text = categoryLabel
        cat.font = .fdCaptionSemibold
        cat.textColor = product.accent

        let name = UILabel()
        name.text = product.name
        name.font = .fdFont(ofSize: 22, weight: .bold)
        name.textColor = .fdText
        name.textAlignment = .center
        name.numberOfLines = 2

        let desc = UILabel()
        desc.text = product.desc
        desc.font = .fdBody
        desc.textColor = .fdSubtext
        desc.textAlignment = .center
        desc.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [emojiBox, cat, name, desc])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.setCustomSpacing(14, after: emojiBox)
        addSubview(stack)
        emojiBox.snp.makeConstraints { $0.size.equalTo(76) }
        stack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().offset(-24)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }
}
