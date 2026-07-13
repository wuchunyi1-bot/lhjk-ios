import UIKit
import SnapKit
import Combine

/// 购物车页 — 对齐 `CartView.vue`
final class ServiceCartViewController: BaseViewController {

    private let viewModel: ServiceCartViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = UIView()
    private let bottomBar = UIView()
    private let selectedLabel = UILabel()
    private let totalLabel = UILabel()
    private let checkoutButton = UIButton(type: .system)

    init(viewModel: ServiceCartViewModel = ServiceCartViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func setupUI() {
        view.backgroundColor = .fdBg
        title = "购物车"

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CartItemCell.self, forCellReuseIdentifier: CartItemCell.reuseID)
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 12, right: 0)
        view.addSubview(tableView)

        buildEmpty()
        buildBottomBar()

        tableView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomBar.snp.top)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reload()
    }

    override func bindViewModel() {
        viewModel.$lines
            .receive(on: DispatchQueue.main)
            .sink { [weak self] lines in
                guard let self else { return }
                self.tableView.reloadData()
                self.emptyView.isHidden = !lines.isEmpty
                self.tableView.isHidden = lines.isEmpty
                self.bottomBar.isHidden = lines.isEmpty
            }
            .store(in: &cancellables)

        viewModel.$selectedCount
            .combineLatest(viewModel.$selectedTotalText)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count, total in
                guard let self else { return }
                self.selectedLabel.text = "已选 \(count) 项"
                self.totalLabel.text = total
                self.checkoutButton.isEnabled = count > 0
                self.checkoutButton.alpha = count > 0 ? 1 : 0.45
            }
            .store(in: &cancellables)
    }

    private func buildEmpty() {
        emptyView.isHidden = true
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let icon = UIImageView(image: UIImage(systemName: "cart"))
        icon.tintColor = .fdSubtext
        icon.contentMode = .scaleAspectFit
        let tip = UILabel()
        tip.text = "购物车空空如也"
        tip.font = .fdBody
        tip.textColor = .fdSubtext
        tip.textAlignment = .center
        let go = UIButton(type: .system)
        go.setTitle("去逛逛", for: .normal)
        go.setTitleColor(.white, for: .normal)
        go.titleLabel?.font = .fdBodySemibold
        go.backgroundColor = .fdPrimary
        go.layer.cornerRadius = 22
        go.contentEdgeInsets = UIEdgeInsets(top: 0, left: 28, bottom: 0, right: 28)
        go.addTarget(self, action: #selector(tapBrowse), for: .touchUpInside)
        go.snp.makeConstraints { $0.height.equalTo(44) }

        let stack = UIStackView(arrangedSubviews: [icon, tip, go])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        icon.snp.makeConstraints { $0.size.equalTo(48) }
        emptyView.addSubview(stack)
        stack.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    private func buildBottomBar() {
        bottomBar.backgroundColor = UIColor.fdSurface.withAlphaComponent(0.96)
        let border = UIView()
        border.backgroundColor = .fdBorder
        bottomBar.addSubview(border)
        border.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }

        selectedLabel.font = .fdCaption
        selectedLabel.textColor = .fdSubtext
        totalLabel.font = .fdMonoFont(ofSize: 22, weight: .heavy)
        totalLabel.textColor = .fdPrimary
        let left = UIStackView(arrangedSubviews: [selectedLabel, totalLabel])
        left.axis = .vertical
        left.spacing = 2

        checkoutButton.setTitle("结算", for: .normal)
        checkoutButton.setTitleColor(.white, for: .normal)
        checkoutButton.titleLabel?.font = .fdBodySemibold
        checkoutButton.backgroundColor = .fdPrimary
        checkoutButton.layer.cornerRadius = 14
        checkoutButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 28, bottom: 0, right: 28)
        checkoutButton.addTarget(self, action: #selector(tapCheckoutBar), for: .touchUpInside)
        checkoutButton.snp.makeConstraints { $0.height.equalTo(44); $0.width.greaterThanOrEqualTo(112) }

        bottomBar.addSubview(left)
        bottomBar.addSubview(checkoutButton)
        view.addSubview(bottomBar)

        bottomBar.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview() }
        left.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalTo(checkoutButton)
        }
        checkoutButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-14)
        }
    }

    @objc private func tapBrowse() {
        Router.shared.push("/mall")
    }

    @objc private func tapCheckoutBar() {
        guard let id = viewModel.firstSelectedTargetId else { return }
        Router.shared.push("/orders/confirm", params: ["id": id])
    }

    private func confirmRemove(line: CartLineDisplay) {
        let alert = UIAlertController(
            title: "确认删除",
            message: "删除后不可恢复，确定从购物车移除「\(line.name)」？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.viewModel.remove(id: line.id)
        })
        present(alert, animated: true)
    }
}

// MARK: - Table

extension ServiceCartViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.lines.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CartItemCell.reuseID, for: indexPath) as! CartItemCell
        let line = viewModel.lines[indexPath.row]
        cell.configure(line)
        cell.onToggle = { [weak self] in self?.viewModel.toggle(id: line.id) }
        cell.onCheckout = { [weak self] in
            Router.shared.push("/orders/confirm", params: ["id": line.targetId])
            _ = self
        }
        cell.onDelete = { [weak self] in self?.confirmRemove(line: line) }
        return cell
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let line = viewModel.lines[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            self?.viewModel.remove(id: line.id)
            completion(true)
        }
        delete.backgroundColor = .fdDanger
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - Cell

private final class CartItemCell: UITableViewCell {
    static let reuseID = "CartItemCell"

    var onToggle: (() -> Void)?
    var onCheckout: (() -> Void)?
    var onDelete: (() -> Void)?

    private let card = UIView()
    private let check = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let priceLabel = UILabel()
    private let deleteButton = UIButton(type: .system)
    private let metaStack = UIStackView()
    private let cycleLabel = UILabel()
    private let settleButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 14
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.04
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
        }

        check.layer.cornerRadius = 11
        check.layer.borderWidth = 1
        check.tintColor = .white
        check.addTarget(self, action: #selector(tapCheck), for: .touchUpInside)
        check.snp.makeConstraints { $0.size.equalTo(22) }

        titleLabel.font = .fdFont(ofSize: 15, weight: .bold)
        titleLabel.textColor = .fdText
        titleLabel.numberOfLines = 2
        subtitleLabel.font = .fdCaption
        subtitleLabel.textColor = .fdSubtext
        subtitleLabel.numberOfLines = 2
        priceLabel.font = .fdMonoFont(ofSize: 16, weight: .heavy)

        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = .fdMuted
        deleteButton.addTarget(self, action: #selector(tapDelete), for: .touchUpInside)
        deleteButton.snp.makeConstraints { $0.size.equalTo(32) }

        let titleCol = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleCol.axis = .vertical
        titleCol.spacing = 4

        let head = UIStackView(arrangedSubviews: [check, titleCol, deleteButton, priceLabel])
        head.axis = .horizontal
        head.alignment = .top
        head.spacing = 10
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)

        metaStack.axis = .vertical
        metaStack.spacing = 10

        cycleLabel.font = .fdCaption
        cycleLabel.textColor = .fdSubtext

        settleButton.setTitle("去结算", for: .normal)
        settleButton.setTitleColor(.white, for: .normal)
        settleButton.titleLabel?.font = .fdCaptionSemibold
        settleButton.backgroundColor = .fdPrimary
        settleButton.layer.cornerRadius = 14
        settleButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        settleButton.addTarget(self, action: #selector(tapSettle), for: .touchUpInside)
        settleButton.snp.makeConstraints { $0.height.equalTo(30) }

        let actions = UIStackView(arrangedSubviews: [cycleLabel, UIView(), settleButton])
        actions.axis = .horizontal
        actions.alignment = .center

        let sep = UIView()
        sep.backgroundColor = .fdBorder
        sep.snp.makeConstraints { $0.height.equalTo(1) }

        let body = UIStackView(arrangedSubviews: [head, sep, metaStack, actions])
        body.axis = .vertical
        body.spacing = 14
        card.addSubview(body)
        body.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ line: CartLineDisplay) {
        titleLabel.text = line.name
        subtitleLabel.text = line.subtitle
        priceLabel.text = line.linePriceText
        priceLabel.textColor = line.accent
        cycleLabel.text = line.serviceCycle
        card.alpha = line.selected ? 1 : 0.62

        if line.selected {
            check.backgroundColor = .fdPrimary
            check.layer.borderColor = UIColor.fdPrimary.cgColor
            check.setImage(UIImage(systemName: "checkmark"), for: .normal)
        } else {
            check.backgroundColor = .clear
            check.layer.borderColor = UIColor.fdBorder.cgColor
            check.setImage(nil, for: .normal)
        }

        metaStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let row1 = metaRow(left: ("服务对象", line.serviceObject), right: (line.deliveryLabel, line.deliveryMethod))
        let row2 = metaRow(left: ("数量", "\(line.quantity)"), right: ("优惠", line.couponText))
        metaStack.addArrangedSubview(row1)
        metaStack.addArrangedSubview(row2)
    }

    private func metaRow(left: (String, String), right: (String, String)) -> UIView {
        let stack = UIStackView(arrangedSubviews: [metaCell(left.0, left.1), metaCell(right.0, right.1)])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
        return stack
    }

    private func metaCell(_ label: String, _ value: String) -> UIView {
        let l = UILabel()
        l.text = label
        l.font = .fdMicro
        l.textColor = .fdMuted
        let v = UILabel()
        v.text = value
        v.font = .fdCaption
        v.textColor = .fdText
        v.numberOfLines = 2
        let s = UIStackView(arrangedSubviews: [l, v])
        s.axis = .vertical
        s.spacing = 4
        return s
    }

    @objc private func tapCheck() { onToggle?() }
    @objc private func tapSettle() { onCheckout?() }
    @objc private func tapDelete() { onDelete?() }
}
