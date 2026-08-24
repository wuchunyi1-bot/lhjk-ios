import UIKit
import SnapKit

/// 优惠券选择底部弹层 — 对齐 funde OrderConfirmView 优惠券 popup
final class OrderCouponPickerSheet: UIViewController {

    var onSelect: ((Int64?) -> Void)?

    private let coupons: [CouponTakeItem]
    private let selectedTakeId: Int64?
    private var pickedTakeId: Int64?

    private let dimView = UIView()
    private let panel = UIView()
    private let skipButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let doneButton = UIButton(type: .system)
    private let emptyLabel = UILabel()

    init(coupons: [CouponTakeItem], selectedTakeId: Int64?) {
        self.coupons = coupons
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

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancel)))
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        panel.backgroundColor = .fdSurface
        panel.layer.cornerRadius = 16
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(panel)
        panel.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.lessThanOrEqualTo(view.snp.height).multipliedBy(0.76)
        }

        skipButton.setTitle("不使用", for: .normal)
        skipButton.setTitleColor(.fdPrimary, for: .normal)
        skipButton.titleLabel?.font = .fdFont(ofSize: 15, weight: .semibold)
        skipButton.addTarget(self, action: #selector(skip), for: .touchUpInside)

        titleLabel.text = "选择优惠券"
        titleLabel.font = .fdFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .fdText

        subtitleLabel.text = "默认先领取先使用，可选择不使用。"
        subtitleLabel.font = .fdFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .fdMuted
        subtitleLabel.numberOfLines = 0

        let headerTop = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerTop.axis = .vertical
        headerTop.spacing = 4

        let header = UIStackView(arrangedSubviews: [headerTop, skipButton])
        header.axis = .horizontal
        header.alignment = .top
        header.distribution = .fill
        panel.addSubview(header)
        header.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(16)
        }
        skipButton.setContentHuggingPriority(.required, for: .horizontal)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(OrderCouponPickerCell.self, forCellReuseIdentifier: OrderCouponPickerCell.reuseId)
        panel.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(header.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(min(CGFloat(coupons.count) * 76, 320)).priority(.high)
        }

        emptyLabel.text = "暂无可用优惠券"
        emptyLabel.font = .fdFont(ofSize: 13, weight: .regular)
        emptyLabel.textColor = .fdMuted
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = !coupons.isEmpty
        panel.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.center.equalTo(tableView)
        }

        doneButton.setTitle("完成", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.titleLabel?.font = .fdFont(ofSize: 15, weight: .semibold)
        doneButton.backgroundColor = .fdPrimary
        doneButton.layer.cornerRadius = 22
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        panel.addSubview(doneButton)
        doneButton.snp.makeConstraints {
            $0.top.equalTo(tableView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            $0.height.equalTo(44)
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

// MARK: - UITableView

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
}

// MARK: - Cell

private final class OrderCouponPickerCell: UITableViewCell {
    static let reuseId = "OrderCouponPickerCell"

    private let card = UIView()
    private let radio = UIView()
    private let nameLabel = UILabel()
    private let descLabel = UILabel()
    private let amountLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 8
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdBorder.cgColor
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
        }

        radio.layer.cornerRadius = 10
        radio.layer.borderWidth = 1
        radio.layer.borderColor = UIColor.fdBorder.cgColor
        card.addSubview(radio)
        radio.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        nameLabel.font = .fdFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .fdText
        descLabel.font = .fdFont(ofSize: 13, weight: .regular)
        descLabel.textColor = .fdMuted
        amountLabel.font = .fdMonoFont(ofSize: 15, weight: .bold)
        amountLabel.textColor = .fdSuccess
        amountLabel.textAlignment = .right

        let textStack = UIStackView(arrangedSubviews: [nameLabel, descLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        card.addSubview(textStack)
        card.addSubview(amountLabel)
        textStack.snp.makeConstraints {
            $0.leading.equalTo(radio.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview().offset(12)
            $0.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        amountLabel.snp.makeConstraints {
            $0.leading.greaterThanOrEqualTo(textStack.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().offset(-12)
            $0.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(item: CouponTakeItem, selected: Bool) {
        nameLabel.text = item.displayName
        descLabel.text = item.subtitle
        amountLabel.text = "-\(OrderConfirmMoney.yen(item.discountAmount))"
        if selected {
            card.backgroundColor = .fdPrimarySoft
            card.layer.borderColor = UIColor.fdPrimary.cgColor
            radio.layer.borderWidth = 6
            radio.layer.borderColor = UIColor.fdPrimary.cgColor
        } else {
            card.backgroundColor = .fdSurface
            card.layer.borderColor = UIColor.fdBorder.cgColor
            radio.layer.borderWidth = 1
            radio.layer.borderColor = UIColor.fdBorder.cgColor
        }
    }
}

// MARK: - 权益卡多选弹层

/// 权益卡选择底部弹层 — `BenefitsRedeemCardVO` 多选（对齐确认订单设计稿）
final class OrderBenefitPickerSheet: UIViewController {

    var onConfirm: (([String]) -> Void)?

    private let cards: [BenefitsRedeemCardVO]
    private var pickedIds: Set<String>
    private let cardLimit: Double

    private let dimView = UIView()
    private let panel = UIView()
    private let skipButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let hintLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let doneButton = UIButton(type: .system)
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

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancel)))
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        panel.backgroundColor = .fdSurface
        panel.layer.cornerRadius = 16
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(panel)
        panel.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.lessThanOrEqualTo(view.snp.height).multipliedBy(0.76)
        }

        skipButton.setTitle(cards.isEmpty ? "" : "不使用", for: .normal)
        skipButton.setTitleColor(.fdPrimary, for: .normal)
        skipButton.titleLabel?.font = .fdFont(ofSize: 15, weight: .semibold)
        skipButton.isHidden = cards.isEmpty
        skipButton.addTarget(self, action: #selector(skip), for: .touchUpInside)

        titleLabel.text = "选择权益卡"
        titleLabel.font = .fdFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .fdText

        subtitleLabel.text = cards.isEmpty
            ? "当前套餐暂不支持使用权益卡。"
            : "支持多张同时使用，权益卡不抵扣运费。"
        subtitleLabel.font = .fdFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .fdMuted
        subtitleLabel.numberOfLines = 0

        let headerTop = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerTop.axis = .vertical
        headerTop.spacing = 4

        let header = UIStackView(arrangedSubviews: [headerTop, skipButton])
        header.axis = .horizontal
        header.alignment = .top
        header.distribution = .fill
        panel.addSubview(header)
        header.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(16)
        }
        skipButton.setContentHuggingPriority(.required, for: .horizontal)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(OrderBenefitPickerCell.self, forCellReuseIdentifier: OrderBenefitPickerCell.reuseId)
        panel.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(header.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(min(max(CGFloat(cards.count), 1) * 76, 320)).priority(.high)
        }

        emptyLabel.text = "暂无可用权益卡"
        emptyLabel.font = .fdFont(ofSize: 13, weight: .regular)
        emptyLabel.textColor = .fdMuted
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = !cards.isEmpty
        panel.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.center.equalTo(tableView)
        }

        hintLabel.font = .fdFont(ofSize: 13, weight: .regular)
        hintLabel.textColor = .fdMuted
        hintLabel.numberOfLines = 0
        hintLabel.isHidden = cards.isEmpty
        panel.addSubview(hintLabel)
        hintLabel.snp.makeConstraints {
            $0.top.equalTo(tableView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        refreshHint()

        doneButton.setTitle(cards.isEmpty ? "我知道了" : "完成", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.titleLabel?.font = .fdFont(ofSize: 15, weight: .semibold)
        doneButton.backgroundColor = .fdPrimary
        doneButton.layer.cornerRadius = 22
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        panel.addSubview(doneButton)
        doneButton.snp.makeConstraints {
            $0.top.equalTo(hintLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            $0.height.equalTo(44)
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
        hintLabel.text = "当前最多可抵扣 \(OrderConfirmMoney.yen(cardLimit))，已抵扣 \(OrderConfirmMoney.yen(currentDiscount))"
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

private final class OrderBenefitPickerCell: UITableViewCell {
    static let reuseId = "OrderBenefitPickerCell"

    private let card = UIView()
    private let check = UIView()
    private let nameLabel = UILabel()
    private let descLabel = UILabel()
    private let amountLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 8
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdBorder.cgColor
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
        }

        check.layer.cornerRadius = 4
        check.layer.borderWidth = 1
        check.layer.borderColor = UIColor.fdBorder.cgColor
        card.addSubview(check)
        check.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        nameLabel.font = .fdFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .fdText
        descLabel.font = .fdFont(ofSize: 13, weight: .regular)
        descLabel.textColor = .fdMuted
        amountLabel.font = .fdMonoFont(ofSize: 15, weight: .bold)
        amountLabel.textColor = .fdPrimary
        amountLabel.textAlignment = .right

        let textStack = UIStackView(arrangedSubviews: [nameLabel, descLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        card.addSubview(textStack)
        card.addSubview(amountLabel)
        textStack.snp.makeConstraints {
            $0.leading.equalTo(check.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview().offset(12)
            $0.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        amountLabel.snp.makeConstraints {
            $0.leading.greaterThanOrEqualTo(textStack.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().offset(-12)
            $0.centerY.equalToSuperview()
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
            card.backgroundColor = .fdPrimarySoft
            card.layer.borderColor = UIColor.fdPrimary.cgColor
            check.backgroundColor = .fdPrimary
            check.layer.borderColor = UIColor.fdPrimary.cgColor
        } else {
            card.backgroundColor = .fdSurface
            card.layer.borderColor = UIColor.fdBorder.cgColor
            check.backgroundColor = .clear
            check.layer.borderColor = UIColor.fdBorder.cgColor
        }
    }
}
