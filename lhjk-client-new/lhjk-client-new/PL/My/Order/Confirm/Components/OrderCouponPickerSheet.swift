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
        skipButton.titleLabel?.font = .fdBodySemibold
        skipButton.addTarget(self, action: #selector(skip), for: .touchUpInside)

        titleLabel.text = "选择优惠券"
        titleLabel.font = .fdH2
        titleLabel.textColor = .fdText

        subtitleLabel.text = "默认先领取先使用，可选择不使用。"
        subtitleLabel.font = .fdCaption
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
        emptyLabel.font = .fdCaption
        emptyLabel.textColor = .fdMuted
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = !coupons.isEmpty
        panel.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.center.equalTo(tableView)
        }

        doneButton.setTitle("完成", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.titleLabel?.font = .fdBodySemibold
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

        nameLabel.font = .fdBodySemibold
        nameLabel.textColor = .fdText
        descLabel.font = .fdCaption
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
