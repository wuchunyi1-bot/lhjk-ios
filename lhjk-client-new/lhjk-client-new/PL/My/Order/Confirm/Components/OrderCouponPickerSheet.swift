import UIKit
import SnapKit

// MARK: - 垂直虚线视图

private final class VerticalDashedLineView: UIView {
    var dashColor: UIColor = UIColor(hexString: "#FFD9C6") {
        didSet { shapeLayer.strokeColor = dashColor.cgColor }
    }

    private let shapeLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        shapeLayer.strokeColor = dashColor.cgColor
        shapeLayer.lineWidth = 0.5
        shapeLayer.lineDashPattern = [3, 3]
        shapeLayer.fillColor = nil
        layer.addSublayer(shapeLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = CGMutablePath()
        path.addLines(between: [CGPoint(x: bounds.midX, y: 0), CGPoint(x: bounds.midX, y: bounds.height)])
        shapeLayer.path = path
        shapeLayer.frame = bounds
    }
}

// MARK: - 优惠券选择底部弹层（对齐 Figma 6013:3517）

final class OrderCouponPickerSheet: UIViewController {

    var onSelect: ((Int64?) -> Void)?
    /// 上拉加载下一页。参数为下一页页码。
    var onLoadMore: ((Int) async throws -> CouponTakeListResult)?
    var onLoadMoreFailed: ((Error) -> Void)?

    private var coupons: [CouponTakeItem]
    private let pageSize = 50
    private let totalCount: Int
    private var currentPage = 1
    private var hasMore: Bool
    private var isLoadingMore = false
    private let selectedTakeId: Int64?
    private var pickedTakeId: Int64?

    private let dimView = UIView()
    private let panel = UIView()
    private let closeButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let headerDivider = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let doneButton = UIButton(type: .custom)
    private let skipButton = UIButton(type: .system)
    private let emptyLabel = UILabel()

    init(coupons: [CouponTakeItem], total: Int, selectedTakeId: Int64?) {
        self.coupons = coupons
        self.totalCount = max(total, coupons.count)
        self.hasMore = coupons.count < max(total, coupons.count)
        self.selectedTakeId = selectedTakeId
        self.pickedTakeId = selectedTakeId
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancel)))
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        panel.backgroundColor = .white
        panel.layer.cornerRadius = 16
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.clipsToBounds = true
        view.addSubview(panel)
        panel.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.lessThanOrEqualTo(view.snp.height).multipliedBy(0.85)
        }

        // 标题（18pt Medium，居中）
        titleLabel.text = "选择优惠券"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .fdText
        titleLabel.textAlignment = .center
        panel.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
        }

        // 右上角关闭按钮（20pt 图标）
        closeButton.setImage(UIImage(named: "order_return_close"), for: .normal)
        closeButton.tintColor = UIColor(hexString: "#8591AB")
        closeButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        panel.addSubview(closeButton)
        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().offset(-16)
            $0.size.equalTo(24)
        }

        // 副标题（14pt Regular，颜色 #8591AB，居中）
        subtitleLabel.text = "默认先领取先使用，可选择不使用"
        subtitleLabel.font = .fdFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = UIColor(hexString: "#8591AB")
        subtitleLabel.textAlignment = .center
        panel.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        // 顶部分割线
        headerDivider.backgroundColor = UIColor(hexString: "#F0F2F5")
        panel.addSubview(headerDivider)
        headerDivider.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(0.5)
        }

        // 列表
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = 89
        tableView.estimatedRowHeight = 89
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(OrderCouponPickerCell.self, forCellReuseIdentifier: OrderCouponPickerCell.reuseId)
        panel.addSubview(tableView)

        let tableContentHeight = CGFloat(coupons.count) * 89
        tableView.snp.makeConstraints {
            $0.top.equalTo(headerDivider.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(min(max(tableContentHeight, 89), 356)).priority(.high)
        }

        emptyLabel.text = "暂无可用优惠券"
        emptyLabel.font = .fdFont(ofSize: 14, weight: .regular)
        emptyLabel.textColor = UIColor(hexString: "#8591AB")
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = !coupons.isEmpty
        panel.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.center.equalTo(tableView)
        }

        // 底部「完成」主按钮（胶囊形，43pt，#FF7A50）
        doneButton.setTitle("完成", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        doneButton.backgroundColor = UIColor(hexString: "#FF7A50")
        doneButton.layer.cornerRadius = 21.5
        doneButton.clipsToBounds = true
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        panel.addSubview(doneButton)
        doneButton.snp.makeConstraints {
            $0.top.equalTo(tableView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(43)
        }

        // 底部「不使用」文字按钮（14pt，#FF7A50，居中）
        skipButton.setTitle("不使用", for: .normal)
        skipButton.setTitleColor(UIColor(hexString: "#FF7A50"), for: .normal)
        skipButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .regular)
        skipButton.addTarget(self, action: #selector(skip), for: .touchUpInside)
        panel.addSubview(skipButton)
        skipButton.snp.makeConstraints {
            $0.top.equalTo(doneButton.snp.bottom).offset(14)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
        }
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func skip() {
        pickedTakeId = nil
        onSelect?(nil)
        dismiss(animated: true)
    }

    @objc private func done() {
        onSelect?(pickedTakeId)
        dismiss(animated: true)
    }
}

// MARK: - 优惠券 TableView DataSource & Delegate

extension OrderCouponPickerSheet: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        coupons.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OrderCouponPickerCell.reuseId,
            for: indexPath
        ) as? OrderCouponPickerCell else {
            return UITableViewCell()
        }
        let item = coupons[indexPath.row]
        cell.configure(
            item: item,
            selected: item.id != nil && item.id == pickedTakeId
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = coupons[indexPath.row]
        guard let id = item.id else { return }
        pickedTakeId = (pickedTakeId == id) ? nil : id
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row >= coupons.count - 1 else { return }
        loadNextPageIfNeeded()
    }

    private func loadNextPageIfNeeded() {
        guard hasMore, !isLoadingMore, let loadMore = onLoadMore else { return }
        isLoadingMore = true
        tableView.tableFooterView = makeLoadingFooter()
        let page = currentPage + 1
        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await loadMore(page)
                await MainActor.run {
                    self.appendCoupons(result.items, total: result.total)
                    self.currentPage = page
                    self.isLoadingMore = false
                    self.tableView.tableFooterView = nil
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.isLoadingMore = false
                    self.tableView.tableFooterView = nil
                    self.onLoadMoreFailed?(error)
                }
            }
        }
    }

    private func appendCoupons(_ items: [CouponTakeItem], total: Int) {
        let known = Set(coupons.compactMap(\.id))
        let fresh = items.filter { item in
            guard let id = item.id else { return true }
            return !known.contains(id)
        }
        coupons.append(contentsOf: fresh)
        let resolvedTotal = max(total, totalCount, coupons.count)
        hasMore = !fresh.isEmpty && coupons.count < resolvedTotal && items.count >= pageSize
    }

    private func makeLoadingFooter() -> UIView {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44))
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        footer.addSubview(indicator)
        indicator.snp.makeConstraints { $0.center.equalToSuperview() }
        return footer
    }
}

// MARK: - 优惠券 Cell（对齐 Figma 6013:3517 79pt 卡片样式）

private final class OrderCouponPickerCell: UITableViewCell {
    static let reuseId = "OrderCouponPickerCell"

    private let card = UIView()
    private let rightBg = UIView()
    private let dashedLine = VerticalDashedLineView()
    private let nameLabel = UILabel()
    private let descLabel = UILabel()
    private let amountLabel = UILabel()
    private let selectedBadge = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // 卡片容器（343 x 79，圆角 16pt，浅底 #FFF9F6）
        card.backgroundColor = UIColor(hexString: "#FFF9F6")
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 0.5
        card.layer.borderColor = UIColor(hexString: "#FFECE2").cgColor
        card.clipsToBounds = true
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalToSuperview().offset(5)
            $0.bottom.equalToSuperview().offset(-5)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(79)
        }

        // 右侧金额浅色底块（宽 110pt，右侧圆角）
        rightBg.backgroundColor = UIColor(hexString: "#FFF0E6")
        rightBg.layer.cornerRadius = 16
        rightBg.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        rightBg.clipsToBounds = true
        card.addSubview(rightBg)
        rightBg.snp.makeConstraints {
            $0.trailing.top.bottom.equalToSuperview()
            $0.width.equalTo(110)
        }

        // 中间垂直虚线
        card.addSubview(dashedLine)
        dashedLine.snp.makeConstraints {
            $0.trailing.equalTo(rightBg.snp.leading)
            $0.top.bottom.equalToSuperview()
            $0.width.equalTo(1)
        }

        // 金额标签（18pt Medium，#F93838，靠右；放不下时缩小字号，完整展示）
        amountLabel.font = .fdFont(ofSize: 18, weight: .medium)
        amountLabel.textColor = UIColor(hexString: "#F93838")
        amountLabel.textAlignment = .right
        amountLabel.numberOfLines = 1
        amountLabel.lineBreakMode = .byClipping
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.minimumScaleFactor = 0.5
        amountLabel.baselineAdjustment = .alignCenters
        rightBg.addSubview(amountLabel)
        amountLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(4)
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }

        // 左侧优惠券名称（16pt Medium，#1F2942）
        nameLabel.font = .fdFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .fdText
        nameLabel.lineBreakMode = .byTruncatingTail
        card.addSubview(nameLabel)

        // 左侧使用门槛（12pt Regular，#8591AB）
        descLabel.font = .fdFont(ofSize: 12, weight: .regular)
        descLabel.textColor = UIColor(hexString: "#8591AB")
        descLabel.lineBreakMode = .byTruncatingTail
        card.addSubview(descLabel)

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualTo(dashedLine.snp.leading).offset(-8)
        }

        descLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualTo(dashedLine.snp.leading).offset(-8)
        }

        // 右下角选中角标
        selectedBadge.image = UIImage(named: "order_card_selected_badge")
        selectedBadge.contentMode = .scaleAspectFit
        selectedBadge.isHidden = true
        card.addSubview(selectedBadge)
        selectedBadge.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview()
            $0.size.equalTo(22)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(item: CouponTakeItem, selected: Bool) {
        nameLabel.text = item.displayName
        let threshold = item.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        descLabel.text = threshold.isEmpty ? "无门槛" : threshold
        amountLabel.text = "-\(OrderConfirmMoney.yen(item.discountAmount))"

        if selected {
            card.layer.borderColor = UIColor(hexString: "#FF7A50").cgColor
            card.layer.borderWidth = 1.0
            selectedBadge.isHidden = false
        } else {
            card.layer.borderColor = UIColor(hexString: "#FFECE2").cgColor
            card.layer.borderWidth = 0.5
            selectedBadge.isHidden = true
        }
    }
}

// MARK: - 权益卡多选弹层（对齐 Figma 6014:4224）

final class OrderBenefitPickerSheet: UIViewController {

    var onConfirm: (([String]) -> Void)?

    private let cards: [BenefitsRedeemCardVO]
    private var pickedIds: Set<String>
    private let cardLimit: Double

    private let dimView = UIView()
    private let panel = UIView()
    private let closeButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let headerDivider = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let hintLabel = UILabel()
    private let doneButton = UIButton(type: .custom)
    private let skipButton = UIButton(type: .system)
    private let emptyLabel = UILabel()

    init(cards: [BenefitsRedeemCardVO], selectedIds: [String], cardLimit: Double) {
        self.cards = cards
        self.pickedIds = Set(selectedIds)
        self.cardLimit = cardLimit
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancel)))
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        panel.backgroundColor = .white
        panel.layer.cornerRadius = 16
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.clipsToBounds = true
        view.addSubview(panel)
        panel.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.lessThanOrEqualTo(view.snp.height).multipliedBy(0.85)
        }

        // 标题（18pt Medium，居中）
        titleLabel.text = "选择权益卡"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .fdText
        titleLabel.textAlignment = .center
        panel.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
        }

        // 右上角关闭按钮
        closeButton.setImage(UIImage(named: "order_return_close"), for: .normal)
        closeButton.tintColor = UIColor(hexString: "#8591AB")
        closeButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        panel.addSubview(closeButton)
        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().offset(-16)
            $0.size.equalTo(24)
        }

        // 副标题（14pt Regular，颜色 #8591AB，居中）
        subtitleLabel.text = cards.isEmpty
            ? "当前套餐暂不支持使用权益卡"
            : "支持多张同时使用，权益卡不抵扣运费"
        subtitleLabel.font = .fdFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = UIColor(hexString: "#8591AB")
        subtitleLabel.textAlignment = .center
        panel.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        // 顶部分割线
        headerDivider.backgroundColor = UIColor(hexString: "#F0F2F5")
        panel.addSubview(headerDivider)
        headerDivider.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(0.5)
        }

        // 列表
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = 89
        tableView.estimatedRowHeight = 89
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(OrderBenefitPickerCell.self, forCellReuseIdentifier: OrderBenefitPickerCell.reuseId)
        panel.addSubview(tableView)

        let tableContentHeight = CGFloat(cards.count) * 89
        tableView.snp.makeConstraints {
            $0.top.equalTo(headerDivider.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(min(max(tableContentHeight, 89), 356)).priority(.high)
        }

        emptyLabel.text = "暂无可用权益卡"
        emptyLabel.font = .fdFont(ofSize: 14, weight: .regular)
        emptyLabel.textColor = UIColor(hexString: "#8591AB")
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = !cards.isEmpty
        panel.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.center.equalTo(tableView)
        }

        // 权益卡抵扣提示文案（12pt Regular，颜色 #8591AB）
        hintLabel.font = .fdFont(ofSize: 12, weight: .regular)
        hintLabel.textColor = UIColor(hexString: "#8591AB")
        hintLabel.isHidden = cards.isEmpty
        panel.addSubview(hintLabel)
        hintLabel.snp.makeConstraints {
            $0.top.equalTo(tableView.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(18)
        }
        refreshHint()

        // 底部「完成」主按钮（胶囊形，43pt，#FF7A50）
        doneButton.setTitle(cards.isEmpty ? "我知道了" : "完成", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        doneButton.backgroundColor = UIColor(hexString: "#FF7A50")
        doneButton.layer.cornerRadius = 21.5
        doneButton.clipsToBounds = true
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        panel.addSubview(doneButton)
        doneButton.snp.makeConstraints {
            if cards.isEmpty {
                $0.top.equalTo(tableView.snp.bottom).offset(16)
            } else {
                $0.top.equalTo(hintLabel.snp.bottom).offset(12)
            }
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(43)
        }

        // 底部「不使用」文字按钮（14pt，#FF7A50，居中）
        skipButton.setTitle("不使用", for: .normal)
        skipButton.setTitleColor(UIColor(hexString: "#FF7A50"), for: .normal)
        skipButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .regular)
        skipButton.isHidden = cards.isEmpty
        skipButton.addTarget(self, action: #selector(skip), for: .touchUpInside)
        panel.addSubview(skipButton)
        skipButton.snp.makeConstraints {
            $0.top.equalTo(doneButton.snp.bottom).offset(14)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
        }
    }

    private var currentDiscount: Double {
        let raw = cards.filter { pickedIds.contains($0.id) }.reduce(0) { $0 + $1.effectiveDeduct }
        return min(cardLimit, raw)
    }

    private func refreshHint() {
        guard !cards.isEmpty else {
            hintLabel.text = nil
            return
        }
        hintLabel.text = "当前最多可抵扣 \(OrderConfirmMoney.yen(cardLimit)) ，已抵扣 \(OrderConfirmMoney.yen(currentDiscount))"
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func skip() {
        pickedIds.removeAll()
        onConfirm?([])
        dismiss(animated: true)
    }

    @objc private func done() {
        if cards.isEmpty {
            dismiss(animated: true)
            return
        }
        let ordered = cards.map(\.id).filter { pickedIds.contains($0) && !$0.isEmpty }
        onConfirm?(ordered)
        dismiss(animated: true)
    }
}

// MARK: - 权益卡 TableView DataSource & Delegate

extension OrderBenefitPickerSheet: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cards.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OrderBenefitPickerCell.reuseId,
            for: indexPath
        ) as? OrderBenefitPickerCell else {
            return UITableViewCell()
        }
        let item = cards[indexPath.row]
        cell.configure(card: item, selected: pickedIds.contains(item.id))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = cards[indexPath.row]
        guard item.isAvailable, !item.id.isEmpty else { return }
        if pickedIds.contains(item.id) {
            pickedIds.remove(item.id)
        } else {
            pickedIds.insert(item.id)
        }
        refreshHint()
        tableView.reloadData()
    }
}

// MARK: - 权益卡 Cell（对齐 Figma 6014:4224 79pt 卡片样式）

private final class OrderBenefitPickerCell: UITableViewCell {
    static let reuseId = "OrderBenefitPickerCell"

    private let card = UIView()
    private let rightBg = UIView()
    private let dashedLine = VerticalDashedLineView()
    private let nameLabel = UILabel()
    private let descLabel = UILabel()
    private let amountLabel = UILabel()
    private let selectedBadge = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // 卡片容器（343 x 79，圆角 16pt，浅底 #FFF9F6）
        card.backgroundColor = UIColor(hexString: "#FFF9F6")
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 0.5
        card.layer.borderColor = UIColor(hexString: "#FFECE2").cgColor
        card.clipsToBounds = true
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalToSuperview().offset(5)
            $0.bottom.equalToSuperview().offset(-5)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(79)
        }

        // 右侧金额浅色底块（宽 110pt，右侧圆角）
        rightBg.backgroundColor = UIColor(hexString: "#FFF0E6")
        rightBg.layer.cornerRadius = 16
        rightBg.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        rightBg.clipsToBounds = true
        card.addSubview(rightBg)
        rightBg.snp.makeConstraints {
            $0.trailing.top.bottom.equalToSuperview()
            $0.width.equalTo(110)
        }

        // 中间垂直虚线
        card.addSubview(dashedLine)
        dashedLine.snp.makeConstraints {
            $0.trailing.equalTo(rightBg.snp.leading)
            $0.top.bottom.equalToSuperview()
            $0.width.equalTo(1)
        }

        // 金额标签（18pt Medium，#F93838，靠右；放不下时缩小字号，完整展示）
        amountLabel.font = .fdFont(ofSize: 18, weight: .medium)
        amountLabel.textColor = UIColor(hexString: "#F93838")
        amountLabel.textAlignment = .right
        amountLabel.numberOfLines = 1
        amountLabel.lineBreakMode = .byClipping
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.minimumScaleFactor = 0.5
        amountLabel.baselineAdjustment = .alignCenters
        rightBg.addSubview(amountLabel)
        amountLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(4)
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }

        // 左侧权益卡名称（16pt Medium，#1F2942）
        nameLabel.font = .fdFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .fdText
        nameLabel.lineBreakMode = .byTruncatingTail
        card.addSubview(nameLabel)

        // 左侧有效期（12pt Regular，#8591AB）
        descLabel.font = .fdFont(ofSize: 12, weight: .regular)
        descLabel.textColor = UIColor(hexString: "#8591AB")
        descLabel.lineBreakMode = .byTruncatingTail
        card.addSubview(descLabel)

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualTo(dashedLine.snp.leading).offset(-8)
        }

        descLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualTo(dashedLine.snp.leading).offset(-8)
        }

        // 右下角选中角标
        selectedBadge.image = UIImage(named: "order_card_selected_badge")
        selectedBadge.contentMode = .scaleAspectFit
        selectedBadge.isHidden = true
        card.addSubview(selectedBadge)
        selectedBadge.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview()
            $0.size.equalTo(22)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(card item: BenefitsRedeemCardVO, selected: Bool) {
        nameLabel.text = item.displayName
        let until = item.endTime?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let day = until.isEmpty ? "" : String(until.replacingOccurrences(of: "T", with: " ").prefix(10))
        if item.isAvailable {
            descLabel.text = day.isEmpty ? "可使用" : "有效期至 \(day)"
            contentView.alpha = 1
        } else {
            descLabel.text = "当前不可用"
            contentView.alpha = 0.45
        }
        amountLabel.text = OrderConfirmMoney.yen(item.effectiveDeduct)

        if selected {
            card.layer.borderColor = UIColor(hexString: "#FF7A50").cgColor
            card.layer.borderWidth = 1.0
            selectedBadge.isHidden = false
        } else {
            card.layer.borderColor = UIColor(hexString: "#FFECE2").cgColor
            card.layer.borderWidth = 0.5
            selectedBadge.isHidden = true
        }
    }
}
