import UIKit
import SnapKit
import Combine
import Kingfisher

/// 购物车页 — 对齐 funde `CartView.vue`：单卡结算，无底栏合计
final class ServiceCartViewController: BaseViewController {

    private let viewModel: ServiceCartViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

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
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        buildEmpty()

        loadingIndicator.color = .fdPrimary
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reload()
    }

    override func bindViewModel() {
        viewModel.$lines
            .combineLatest(viewModel.$isLoading, viewModel.$isCheckingOut)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] lines, loading, checkingOut in
                guard let self else { return }
                let busy = loading || checkingOut
                if busy {
                    self.loadingIndicator.startAnimating()
                } else {
                    self.loadingIndicator.stopAnimating()
                }
                self.tableView.isUserInteractionEnabled = !checkingOut
                self.tableView.reloadData()
                let showEmpty = lines.isEmpty && !loading
                self.emptyView.isHidden = !showEmpty
                self.tableView.isHidden = showEmpty || loading
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .sink { [weak self] message in
                self?.showToast(message)
            }
            .store(in: &cancellables)

        viewModel.$toastMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] message in
                self?.showToast(message) {
                    self?.viewModel.consumeToast()
                }
            }
            .store(in: &cancellables)

        viewModel.$confirmRoute
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] route in
                self?.openConfirmOrder(route)
                self?.viewModel.consumeConfirmRoute()
            }
            .store(in: &cancellables)
    }

    private func buildEmpty() {
        emptyView.isHidden = true
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        emptyView.addSubview(card)
        card.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        let icon = UIImageView(image: UIImage(systemName: "cart"))
        icon.tintColor = .fdPrimary
        icon.contentMode = .scaleAspectFit

        let tip = UILabel()
        tip.text = "购物车还是空的"
        tip.font = .fdBodySemibold
        tip.textColor = .fdText
        tip.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [icon, tip])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        icon.snp.makeConstraints { $0.size.equalTo(40) }
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(32) }
    }

    private func checkout(line: CartLineDisplay) {
        viewModel.checkout(line: line)
    }

    private func openConfirmOrder(_ route: CartConfirmRoute) {
        var params: [String: Any] = [
            "orderId": String(route.orderId),
            "entry": "cart",
        ]
        if let serial = route.serialNumber {
            params["serialNumber"] = String(serial)
        }
        Router.shared.push("/orders/confirm", params: params)
    }

    private func confirmRemove(line: CartLineDisplay) {
        guard !viewModel.isDeleting else { return }
        let alert = UIAlertController(
            title: "确认删除",
            message: "确认删除该套餐「\(line.name)」？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.viewModel.remove(id: line.id)
        })
        present(alert, animated: true)
    }

    private func showToast(_ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            alert.dismiss(animated: true) {
                completion?()
            }
        }
    }
}

// MARK: - Table

extension ServiceCartViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.lines.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CartItemCell.reuseID,
            for: indexPath
        ) as! CartItemCell
        let line = viewModel.lines[indexPath.row]
        cell.configure(line)
        cell.onCheckout = { [weak self] in self?.checkout(line: line) }
        cell.onDelete = { [weak self] in self?.confirmRemove(line: line) }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        180
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let line = viewModel.lines[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            guard let self, !self.viewModel.isDeleting else {
                completion(false)
                return
            }
            self.confirmRemove(line: line)
            completion(true)
        }
        delete.backgroundColor = .fdDanger
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - Cell（对齐 CartView 卡片）

private final class CartItemCell: UITableViewCell {
    static let reuseID = "CartItemCell"

    var onCheckout: (() -> Void)?
    var onDelete: (() -> Void)?

    private let card = UIView()
    private let institutionIcon = UIImageView(image: UIImage(systemName: "building.2"))
    private let institutionLabel = UILabel()
    private let statusBadge = UILabel()
    private let coverView = UIView()
    private let coverImageView = UIImageView()
    private let coverPlaceholder = UILabel()
    private let nameLabel = UILabel()
    private let introLabel = UILabel()
    private let priceLabel = UILabel()
    private let deleteButton = UIButton(type: .system)
    private let settleButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.04
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
        }

        institutionIcon.tintColor = .fdMuted
        institutionIcon.contentMode = .scaleAspectFit
        institutionIcon.snp.makeConstraints { $0.size.equalTo(16) }

        institutionLabel.font = .fdCaptionSemibold
        institutionLabel.textColor = .fdText
        institutionLabel.lineBreakMode = .byTruncatingTail

        statusBadge.font = .fdMicroSemibold
        statusBadge.textColor = .fdMuted
        statusBadge.backgroundColor = .fdSurface2
        statusBadge.layer.cornerRadius = 8
        statusBadge.clipsToBounds = true
        statusBadge.textAlignment = .center
        statusBadge.isHidden = true
        statusBadge.setContentHuggingPriority(.required, for: .horizontal)

        let institutionLeft = UIStackView(arrangedSubviews: [institutionIcon, institutionLabel])
        institutionLeft.axis = .horizontal
        institutionLeft.spacing = 6
        institutionLeft.alignment = .center

        let institutionRow = UIStackView(arrangedSubviews: [institutionLeft, statusBadge])
        institutionRow.axis = .horizontal
        institutionRow.spacing = 8
        institutionRow.alignment = .center

        coverView.backgroundColor = .fdSurface2
        coverView.layer.cornerRadius = 10
        coverView.clipsToBounds = true
        coverView.snp.makeConstraints { $0.size.equalTo(72) }

        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverView.addSubview(coverImageView)
        coverImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        coverPlaceholder.text = "套餐"
        coverPlaceholder.font = .fdCaptionSemibold
        coverPlaceholder.textColor = .fdMuted
        coverPlaceholder.textAlignment = .center
        coverView.addSubview(coverPlaceholder)
        coverPlaceholder.snp.makeConstraints { $0.center.equalToSuperview() }

        nameLabel.font = .fdBodySemibold
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2

        introLabel.font = .fdCaption
        introLabel.textColor = .fdSubtext
        introLabel.numberOfLines = 1
        introLabel.lineBreakMode = .byTruncatingTail

        priceLabel.font = .fdMonoFont(ofSize: 16, weight: .heavy)
        priceLabel.textColor = .fdPrimary
        priceLabel.textAlignment = .right
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let textCol = UIStackView(arrangedSubviews: [nameLabel, introLabel])
        textCol.axis = .vertical
        textCol.spacing = 4

        let mainRow = UIStackView(arrangedSubviews: [textCol, priceLabel])
        mainRow.axis = .horizontal
        mainRow.alignment = .top
        mainRow.spacing = 8

        let bodyRow = UIStackView(arrangedSubviews: [coverView, mainRow])
        bodyRow.axis = .horizontal
        bodyRow.alignment = .top
        bodyRow.spacing = 12

        deleteButton.setTitle("删除", for: .normal)
        deleteButton.setTitleColor(.fdText2, for: .normal)
        deleteButton.titleLabel?.font = .fdCaptionSemibold
        deleteButton.backgroundColor = .fdSurface
        deleteButton.layer.cornerRadius = 16
        deleteButton.layer.borderWidth = 1
        deleteButton.layer.borderColor = UIColor.fdBorder.cgColor
        deleteButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        deleteButton.addTarget(self, action: #selector(tapDelete), for: .touchUpInside)
        deleteButton.snp.makeConstraints { $0.height.equalTo(32) }

        settleButton.setTitle("去结算", for: .normal)
        settleButton.setTitleColor(.white, for: .normal)
        settleButton.titleLabel?.font = .fdCaptionSemibold
        settleButton.backgroundColor = .fdPrimary
        settleButton.layer.cornerRadius = 16
        settleButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        settleButton.addTarget(self, action: #selector(tapSettle), for: .touchUpInside)
        settleButton.snp.makeConstraints { $0.height.equalTo(32) }

        let spacer = UIView()
        let actions = UIStackView(arrangedSubviews: [spacer, deleteButton, settleButton])
        actions.axis = .horizontal
        actions.spacing = 8
        actions.alignment = .center

        let root = UIStackView(arrangedSubviews: [institutionRow, bodyRow, actions])
        root.axis = .vertical
        root.spacing = 12
        card.addSubview(root)
        root.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        statusBadge.snp.makeConstraints {
            $0.height.equalTo(20)
            $0.width.greaterThanOrEqualTo(48)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ line: CartLineDisplay) {
        institutionLabel.text = line.displayInstitutionName
        nameLabel.text = line.name
        introLabel.text = line.subtitle
        introLabel.isHidden = line.subtitle.isEmpty
        priceLabel.text = line.linePriceText

        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        if let urlString = line.imageUrl, let url = URL(string: urlString) {
            coverPlaceholder.isHidden = true
            coverImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            coverPlaceholder.isHidden = false
        }

        applyInvalidStyle(line.isInvalid, badge: line.status?.badgeText)
        settleButton.isHidden = line.isInvalid
    }

    private func applyInvalidStyle(_ invalid: Bool, badge: String?) {
        if invalid {
            card.alpha = 0.62
            card.backgroundColor = .fdSurface2
            nameLabel.textColor = .fdMuted
            introLabel.textColor = .fdMuted
            priceLabel.textColor = .fdMuted
            institutionLabel.textColor = .fdMuted
            institutionIcon.tintColor = .fdMuted
            statusBadge.isHidden = false
            statusBadge.text = " \(badge ?? "已失效") "
        } else {
            card.alpha = 1
            card.backgroundColor = .fdSurface
            nameLabel.textColor = .fdText
            introLabel.textColor = .fdSubtext
            priceLabel.textColor = .fdPrimary
            institutionLabel.textColor = .fdText
            institutionIcon.tintColor = .fdMuted
            statusBadge.isHidden = true
            statusBadge.text = nil
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        onCheckout = nil
        onDelete = nil
        applyInvalidStyle(false, badge: nil)
        settleButton.isHidden = false
    }

    @objc private func tapSettle() { onCheckout?() }
    @objc private func tapDelete() { onDelete?() }
}
