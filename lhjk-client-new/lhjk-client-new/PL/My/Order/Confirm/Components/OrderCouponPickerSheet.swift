import UIKit
import SnapKit
import Kingfisher

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

// MARK: - 优惠券选择底部弹层（对齐 Figma 6086:4704）

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
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let buttonStack = UIStackView()
    private let doneButton = UIButton(type: .custom)
    private let skipButton = UIButton(type: .custom)
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

        // 右上角关闭按钮（24pt）
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
        subtitleLabel.text = "每个订单仅可使用一张优惠券，可选择不使用"
        subtitleLabel.font = .fdFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = UIColor(hexString: "#8591AB")
        subtitleLabel.textAlignment = .center
        panel.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        // 列表
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = 111
        tableView.estimatedRowHeight = 111
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(OrderCouponPickerCell.self, forCellReuseIdentifier: OrderCouponPickerCell.reuseId)
        panel.addSubview(tableView)

        let tableContentHeight = CGFloat(coupons.count) * 111
        tableView.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(min(max(tableContentHeight, 111), 356)).priority(.high)
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

        // 底部双按钮横排（不使用 / 完成）
        buttonStack.axis = .horizontal
        buttonStack.spacing = 11
        buttonStack.distribution = .fillEqually
        panel.addSubview(buttonStack)
        buttonStack.snp.makeConstraints {
            $0.top.equalTo(tableView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(43)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
        }

        // 底部「不使用」描边按钮（43pt，#FF7A50 描边）
        skipButton.setTitle("不使用", for: .normal)
        skipButton.setTitleColor(UIColor(hexString: "#FF7A50"), for: .normal)
        skipButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .regular)
        skipButton.backgroundColor = .white
        skipButton.layer.borderColor = UIColor(hexString: "#FF7A50").cgColor
        skipButton.layer.borderWidth = 0.5
        skipButton.layer.cornerRadius = 21.5
        skipButton.clipsToBounds = true
        skipButton.addTarget(self, action: #selector(skip), for: .touchUpInside)
        skipButton.isHidden = coupons.isEmpty
        buttonStack.addArrangedSubview(skipButton)

        // 底部「完成」主按钮（胶囊形，43pt，#FF7A50）
        doneButton.setTitle(coupons.isEmpty ? "我知道了" : "完成", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        doneButton.backgroundColor = UIColor(hexString: "#FF7A50")
        doneButton.layer.cornerRadius = 21.5
        doneButton.clipsToBounds = true
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        buttonStack.addArrangedSubview(doneButton)
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

// MARK: - 优惠券 Cell（对齐 Figma 6086:4704 票券卡片样式，使用背景图与选中图标）

private final class OrderCouponPickerCell: UITableViewCell {
    static let reuseId = "OrderCouponPickerCell"

    private static let bgCapInsets = UIEdgeInsets(top: 20, left: 111, bottom: 20, right: 50)
    private static let selectedBgImage = UIImage(named: "order_confirm_coupon_bg_selected")?.resizableImage(withCapInsets: bgCapInsets, resizingMode: .stretch)
    private static let unselectedBgImage = UIImage(named: "order_confirm_coupon_bg_unselected")?.resizableImage(withCapInsets: bgCapInsets, resizingMode: .stretch)

    /// 左侧金额与门槛字号阶梯：默认字体更醒目大气，内容字符较多、宽度受限时自动缩小字号
    private enum LeftValueTypography {
        static func amountSizes(for displayText: String) -> (numberSize: CGFloat, unitSize: CGFloat) {
            let count = displayText.filter { !$0.isWhitespace }.count
            switch count {
            case 0...4:
                return (26, 16)
            case 5...6:
                return (22, 14)
            case 7...8:
                return (18, 12)
            default:
                return (15, 11)
            }
        }

        static func thresholdSize(for displayText: String) -> CGFloat {
            let count = displayText.filter { !$0.isWhitespace }.count
            switch count {
            case 0...6:
                return 13
            case 7...9:
                return 12
            case 10...11:
                return 11
            default:
                return 10
            }
        }
    }

    private let cardContainer = UIView()
    private let bgImageView = UIImageView()
    private let leftStack = UIStackView()
    private let amountLabel = UILabel()
    private let thresholdLabel = UILabel()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let chooseImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // 卡片外层容器（343 x 99，底部留白 12pt）
        contentView.addSubview(cardContainer)
        cardContainer.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(99)
        }

        // 背景图（order_confirm_coupon_bg_selected / order_confirm_coupon_bg_unselected）
        bgImageView.contentMode = .scaleToFill
        cardContainer.addSubview(bgImageView)
        bgImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // 左侧金额与门槛纵向容器（居中对齐左侧 98pt 浅色底块区）
        amountLabel.textAlignment = .center
        amountLabel.numberOfLines = 1
        amountLabel.lineBreakMode = .byClipping
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.minimumScaleFactor = 0.5
        amountLabel.baselineAdjustment = .alignCenters

        thresholdLabel.font = .fdFont(ofSize: 13, weight: .regular)
        thresholdLabel.textColor = UIColor(hexString: "#F93838")
        thresholdLabel.textAlignment = .center
        thresholdLabel.numberOfLines = 1
        thresholdLabel.lineBreakMode = .byClipping
        thresholdLabel.adjustsFontSizeToFitWidth = true
        thresholdLabel.minimumScaleFactor = 0.7
        thresholdLabel.baselineAdjustment = .alignCenters

        leftStack.axis = .vertical
        leftStack.spacing = 2
        leftStack.alignment = .center
        leftStack.distribution = .fill
        leftStack.addArrangedSubview(amountLabel)
        leftStack.addArrangedSubview(thresholdLabel)
        cardContainer.addSubview(leftStack)
        leftStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(2)
            $0.width.equalTo(96)
            $0.centerY.equalToSuperview()
        }
        amountLabel.snp.makeConstraints {
            $0.width.equalTo(96)
        }
        thresholdLabel.snp.makeConstraints {
            $0.width.equalTo(96)
        }

        // 右侧选中图标（18 x 18，使用 order_confirm_coupon_choose，与背景图右侧圆圈完全居中对齐）
        chooseImageView.image = UIImage(named: "order_confirm_coupon_choose")
        chooseImageView.contentMode = .scaleAspectFit
        cardContainer.addSubview(chooseImageView)
        chooseImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-14)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(18)
        }

        // 中间优惠券名称（16pt Medium，#1F2942，最多 2 行）
        nameLabel.font = .fdFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byTruncatingTail
        cardContainer.addSubview(nameLabel)

        // 中间有效期（12pt Regular，#8591AB）
        timeLabel.font = .fdFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = UIColor(hexString: "#8591AB")
        timeLabel.lineBreakMode = .byTruncatingTail
        cardContainer.addSubview(timeLabel)

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.leading.equalToSuperview().offset(108)
            $0.trailing.lessThanOrEqualTo(chooseImageView.snp.leading).offset(-14)
        }

        timeLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(108)
            $0.trailing.lessThanOrEqualTo(chooseImageView.snp.leading).offset(-14)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(item: CouponTakeItem, selected: Bool) {
        nameLabel.text = item.displayName
        let threshold = item.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let thresholdText = threshold.isEmpty ? "无门槛" : threshold
        let tSize = LeftValueTypography.thresholdSize(for: thresholdText)
        thresholdLabel.font = .fdFont(ofSize: tSize, weight: .regular)
        thresholdLabel.text = thresholdText
        amountLabel.attributedText = Self.formatAmount(item: item)

        let end = item.endTime?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !end.isEmpty {
            let clean = end.replacingOccurrences(of: "T", with: " ")
            timeLabel.text = "有效期至 \(clean)"
        } else {
            timeLabel.text = "长期有效"
        }

        if selected {
            bgImageView.image = Self.selectedBgImage
            chooseImageView.isHidden = false
        } else {
            bgImageView.image = Self.unselectedBgImage
            chooseImageView.isHidden = true
        }
    }

    private static func formatAmount(item: CouponTakeItem) -> NSAttributedString {
        let color = UIColor(hexString: "#F93838")
        if item.type == 3, let rate = item.discountRatio, rate > 0 {
            let str = String(format: "%g", rate)
            let displayText = "\(str)折"
            let sizes = LeftValueTypography.amountSizes(for: displayText)
            let attr = NSMutableAttributedString(
                string: str,
                attributes: [.font: UIFont.fdFont(ofSize: sizes.numberSize, weight: .medium), .foregroundColor: color]
            )
            attr.append(NSAttributedString(
                string: "折",
                attributes: [.font: UIFont.fdFont(ofSize: sizes.unitSize, weight: .medium), .foregroundColor: color]
            ))
            return attr
        } else {
            let amount = item.discountAmount
            let amountStr: String
            if amount == floor(amount) {
                amountStr = "\(Int(amount))"
            } else {
                amountStr = String(format: "%.2f", amount)
            }
            let displayText = "¥\(amountStr)"
            let sizes = LeftValueTypography.amountSizes(for: displayText)
            let attr = NSMutableAttributedString(
                string: "¥ ",
                attributes: [.font: UIFont.fdFont(ofSize: sizes.unitSize, weight: .medium), .foregroundColor: color]
            )
            attr.append(NSAttributedString(
                string: amountStr,
                attributes: [.font: UIFont.fdFont(ofSize: sizes.numberSize, weight: .medium), .foregroundColor: color]
            ))
            return attr
        }
    }
}

// MARK: - 权益卡多选弹层（对齐 Figma 6093:5091）

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
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let hintLabel = UILabel()
    private let buttonStack = UIStackView()
    private let doneButton = UIButton(type: .custom)
    private let skipButton = UIButton(type: .custom)
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

        // 列表
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = 111
        tableView.estimatedRowHeight = 111
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(OrderBenefitPickerCell.self, forCellReuseIdentifier: OrderBenefitPickerCell.reuseId)
        panel.addSubview(tableView)

        let tableContentHeight = CGFloat(cards.count) * 111
        tableView.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(min(max(tableContentHeight, 111), 356)).priority(.high)
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

        // 底部双按钮横排（不使用 / 完成）
        buttonStack.axis = .horizontal
        buttonStack.spacing = 11
        buttonStack.distribution = .fillEqually
        panel.addSubview(buttonStack)
        buttonStack.snp.makeConstraints {
            if cards.isEmpty {
                $0.top.equalTo(tableView.snp.bottom).offset(16)
            } else {
                $0.top.equalTo(hintLabel.snp.bottom).offset(12)
            }
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(43)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
        }

        // 底部「不使用」描边按钮（43pt，#FF7A50 描边）
        skipButton.setTitle("不使用", for: .normal)
        skipButton.setTitleColor(UIColor(hexString: "#FF7A50"), for: .normal)
        skipButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .regular)
        skipButton.backgroundColor = .white
        skipButton.layer.borderColor = UIColor(hexString: "#FF7A50").cgColor
        skipButton.layer.borderWidth = 0.5
        skipButton.layer.cornerRadius = 21.5
        skipButton.clipsToBounds = true
        skipButton.addTarget(self, action: #selector(skip), for: .touchUpInside)
        skipButton.isHidden = cards.isEmpty
        buttonStack.addArrangedSubview(skipButton)

        // 底部「完成」主按钮（胶囊形，43pt，#FF7A50）
        doneButton.setTitle(cards.isEmpty ? "我知道了" : "完成", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        doneButton.backgroundColor = UIColor(hexString: "#FF7A50")
        doneButton.layer.cornerRadius = 21.5
        doneButton.clipsToBounds = true
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        buttonStack.addArrangedSubview(doneButton)
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

// MARK: - 权益卡 Cell（对齐 Figma 6093:5091 99pt 卡片样式，左卡片图标，中标题/有效期，右金额）

private final class OrderBenefitPickerCell: UITableViewCell {
    static let reuseId = "OrderBenefitPickerCell"

    private let card = UIView()
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let descLabel = UILabel()
    private let dashedLine = VerticalDashedLineView()
    private let amountLabel = UILabel()
    private let selectedBadge = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // 卡片容器（343 x 99，圆角 16pt，米黄色渐变底）
        card.backgroundColor = UIColor(hexString: "#FFFBF5")
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 0.5
        card.layer.borderColor = UIColor(hexString: "#FFECD2").cgColor
        card.clipsToBounds = true
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(99)
        }

        // 左侧权益卡图标（75 x 75，圆角 11pt）
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.cornerRadius = 11
        iconImageView.clipsToBounds = true
        card.addSubview(iconImageView)
        iconImageView.snp.makeConstraints {
            $0.leading.top.equalToSuperview().offset(12)
            $0.size.equalTo(75)
        }

        // 中间分隔虚线（距离右侧 82pt，高度 79.5pt，垂直居中）
        dashedLine.dashColor = UIColor(hexString: "#FFD9C6")
        card.addSubview(dashedLine)
        dashedLine.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-82)
            $0.top.equalToSuperview().offset(10)
            $0.bottom.equalToSuperview().offset(-10)
            $0.width.equalTo(1)
        }

        // 右侧金额标签（主数字 22pt Medium，货币符号 14pt，颜色 #883400，居中）
        amountLabel.textAlignment = .center
        amountLabel.numberOfLines = 1
        amountLabel.lineBreakMode = .byClipping
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.minimumScaleFactor = 0.5
        amountLabel.baselineAdjustment = .alignCenters
        card.addSubview(amountLabel)
        amountLabel.snp.makeConstraints {
            $0.leading.equalTo(dashedLine.snp.trailing).offset(4)
            $0.trailing.equalToSuperview().offset(-4)
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
            $0.top.equalToSuperview().offset(26)
            $0.leading.equalTo(iconImageView.snp.trailing).offset(14)
            $0.trailing.lessThanOrEqualTo(dashedLine.snp.leading).offset(-8)
        }

        descLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(6)
            $0.leading.equalTo(iconImageView.snp.trailing).offset(14)
            $0.trailing.lessThanOrEqualTo(dashedLine.snp.leading).offset(-8)
        }

        // 右下角选中角标（22 x 22）
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

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.kf.cancelDownloadTask()
        iconImageView.image = nil
    }

    func configure(card item: BenefitsRedeemCardVO, selected: Bool) {
        nameLabel.text = item.displayName
        let until = item.endTime?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let day = until.isEmpty ? "" : String(until.replacingOccurrences(of: "T", with: " ").prefix(10))
        if item.isAvailable {
            descLabel.text = day.isEmpty ? "可使用" : "有效期至 \(day)"
            descLabel.textColor = UIColor(hexString: "#8591AB")
            nameLabel.textColor = .fdText
        } else {
            descLabel.text = "不可用"
            descLabel.textColor = .fdMuted
            nameLabel.textColor = .fdMuted
        }

        let defaultImage = UIImage(named: "order_benefit_card_icon")
        if let raw = item.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty,
           let url = URL(string: raw) {
            iconImageView.kf.setImage(
                with: url,
                placeholder: defaultImage,
                options: [.transition(.fade(0.2))]
            ) { [weak iconImageView] result in
                if case .failure = result {
                    iconImageView?.image = defaultImage
                }
            }
        } else {
            iconImageView.image = defaultImage
        }

        amountLabel.attributedText = Self.formatBenefitValue(item: item)

        if selected {
            card.layer.borderColor = UIColor(hexString: "#FF9502").cgColor
            card.layer.borderWidth = 1.0
            selectedBadge.isHidden = false
        } else {
            card.layer.borderColor = UIColor(hexString: "#FFECD2").cgColor
            card.layer.borderWidth = 0.5
            selectedBadge.isHidden = true
        }
    }

    private static func formatBenefitValue(item: BenefitsRedeemCardVO) -> NSAttributedString {
        let color = UIColor(hexString: "#883400")
        let amount = item.effectiveDeduct
        let amountStr: String
        if amount == floor(amount) {
            amountStr = "\(Int(amount))"
        } else {
            amountStr = String(format: "%.2f", amount)
        }
        let attr = NSMutableAttributedString(
            string: "¥ ",
            attributes: [.font: UIFont.fdFont(ofSize: 14, weight: .medium), .foregroundColor: color]
        )
        attr.append(NSAttributedString(
            string: amountStr,
            attributes: [.font: UIFont.fdFont(ofSize: 22, weight: .medium), .foregroundColor: color]
        ))
        return attr
    }
}
