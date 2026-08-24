import UIKit
import SnapKit
import Combine
import Kingfisher

/// 编辑卡片页 — 对齐 funde-client MetricCardEditView.vue
final class MetricCardEditViewController: BaseViewController {

    private let viewModel = MetricCardEditViewModel()
    private var cancellables = Set<AnyCancellable>()

    private enum Section: Int, CaseIterable {
        case displayed
        case hidden
    }

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .fdBg
        cv.dataSource = self
        cv.delegate = self
        cv.dragDelegate = self
        cv.dropDelegate = self
        cv.dragInteractionEnabled = true
        cv.alwaysBounceVertical = true
        cv.register(MetricEditCardCell.self, forCellWithReuseIdentifier: MetricEditCardCell.reuseID)
        cv.register(
            MetricEditHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MetricEditHeaderView.reuseID
        )
        cv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        return cv
    }()

    private lazy var saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("保存", for: .normal)
        b.titleLabel?.font = .fdFont(ofSize: 18, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .fdPrimary
        b.layer.cornerRadius = 24
        b.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return b
    }()

    private lazy var saveBar: UIView = {
        let v = UIView()
        v.backgroundColor = .fdBg
        v.addSubview(saveButton)
        saveButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
            $0.bottom.equalTo(v.safeAreaLayoutGuide).inset(12)
        }
        return v
    }()

    override func setupUI() {
        title = "编辑卡片"
        view.backgroundColor = .fdBg
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )

        view.addSubview(collectionView)
        view.addSubview(saveBar)
        saveBar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }
        collectionView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(saveBar.snp.top)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func bindViewModel() {
        Publishers.CombineLatest(viewModel.$displayed, viewModel.$hidden)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in self?.collectionView.reloadData() }
            .store(in: &cancellables)

        viewModel.$toastMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                self?.presentAlert(msg)
                self?.viewModel.toastMessage = nil
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                self?.presentAlert(msg)
            }
            .store(in: &cancellables)

        viewModel.$isSaving
            .receive(on: DispatchQueue.main)
            .sink { [weak self] saving in
                self?.saveButton.isEnabled = !saving
                self?.saveButton.alpha = saving ? 0.6 : 1
            }
            .store(in: &cancellables)

        viewModel.load()
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.5),
                heightDimension: .absolute(110)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(110)),
                subitems: [item]
            )
            let sec = NSCollectionLayoutSection(group: group)
            sec.interGroupSpacing = 10
            sec.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 11, bottom: 12, trailing: 11)
            sec.boundarySupplementaryItems = [
                NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44)),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
            ]
            return sec
        }
    }

    @objc private func backTapped() {
        guard viewModel.hasChanges else {
            navigationController?.popViewController(animated: true)
            return
        }
        let alert = UIAlertController(
            title: "退出编辑提示",
            message: "是否保存已调整的卡片顺序？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "不保存", style: .cancel) { [weak self] _ in
            self?.viewModel.revertToSnapshot()
            self?.navigationController?.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self] _ in
            self?.performSave(andPop: true)
        })
        present(alert, animated: true)
    }

    @objc private func saveTapped() {
        performSave(andPop: true)
    }

    private func performSave(andPop: Bool) {
        Task { @MainActor in
            let ok = await viewModel.save()
            if ok, andPop {
                navigationController?.popViewController(animated: true)
            }
        }
    }

    private func presentAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - DataSource / Delegate

extension MetricCardEditViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .displayed: return viewModel.displayed.count
        case .hidden: return viewModel.hidden.count
        case .none: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MetricEditCardCell.reuseID,
            for: indexPath
        ) as! MetricEditCardCell
        switch Section(rawValue: indexPath.section) {
        case .displayed:
            let card = viewModel.displayed[indexPath.item]
            cell.configure(card: card, mode: .minus) { [weak self] in
                self?.viewModel.hideCard(card.cardType)
            }
        case .hidden:
            let card = viewModel.hidden[indexPath.item]
            cell.configure(card: card, mode: .plus) { [weak self] in
                self?.viewModel.showCard(card.cardType)
            }
        case .none:
            break
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: MetricEditHeaderView.reuseID,
            for: indexPath
        ) as! MetricEditHeaderView
        switch Section(rawValue: indexPath.section) {
        case .displayed:
            header.configure(title: "显示在健康页", hint: "长按拖拽排序")
        case .hidden:
            header.configure(title: "隐藏的卡片", hint: nil)
        case .none:
            header.configure(title: "", hint: nil)
        }
        return header
    }
}

// MARK: - Drag / Drop（仅显示区）

extension MetricCardEditViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        guard Section(rawValue: indexPath.section) == .displayed else { return [] }
        let type = viewModel.displayed[indexPath.item].cardType
        let item = UIDragItem(itemProvider: NSItemProvider(object: "\(type)" as NSString))
        item.localObject = type
        return [item]
    }

    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        guard session.localDragSession != nil,
              let dest = destinationIndexPath,
              Section(rawValue: dest.section) == .displayed else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        performDropWith coordinator: UICollectionViewDropCoordinator
    ) {
        guard let dest = coordinator.destinationIndexPath,
              Section(rawValue: dest.section) == .displayed,
              let item = coordinator.items.first,
              let cardType = item.dragItem.localObject as? Int else { return }

        var order = viewModel.displayed.map(\.cardType)
        guard let from = order.firstIndex(of: cardType) else { return }
        order.remove(at: from)
        let to = min(dest.item, order.count)
        order.insert(cardType, at: to)
        viewModel.reorderDisplayed(to: order)
        coordinator.drop(item.dragItem, toItemAt: IndexPath(item: to, section: Section.displayed.rawValue))
    }
}

// MARK: - Header / Card cells

private final class MetricEditHeaderView: UICollectionReusableView {
    static let reuseID = "MetricEditHeaderView"

    private let titleLabel = UILabel()
    private let hintLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .fdFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .fdText
        hintLabel.font = .fdFont(ofSize: 14, weight: .regular)
        hintLabel.textColor = .fdMuted
        addSubview(titleLabel)
        addSubview(hintLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
        hintLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, hint: String?) {
        titleLabel.text = title
        hintLabel.text = hint
        hintLabel.isHidden = (hint ?? "").isEmpty
    }
}

private final class MetricEditCardCell: UICollectionViewCell {
    static let reuseID = "MetricEditCardCell"

    enum Mode { case plus, minus }

    private let iconBg = UIView()
    private let iconView = UIImageView()
    private let label = UILabel()
    private let actionButton = UIButton(type: .system)
    private var onAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .fdSurface
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        iconBg.backgroundColor = UIColor(hexString: "#E9F6F2")
        iconBg.layer.cornerRadius = 14
        iconView.contentMode = .scaleAspectFit

        label.font = .fdFont(ofSize: 15, weight: .medium)
        label.textColor = .fdText
        label.textAlignment = .center

        actionButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        contentView.addSubview(iconBg)
        iconBg.addSubview(iconView)
        contentView.addSubview(label)
        contentView.addSubview(actionButton)

        actionButton.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(6)
            $0.size.equalTo(24)
        }
        iconBg.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(44)
        }
        iconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(22)
        }
        label.snp.makeConstraints {
            $0.top.equalTo(iconBg.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(8)
            $0.bottom.lessThanOrEqualToSuperview().inset(12)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(card: MetricCardEditViewModel.EditCard, mode: Mode, onAction: @escaping () -> Void) {
        self.onAction = onAction
        label.text = card.cardName
        iconView.kf.cancelDownloadTask()
        if let iconUrl = card.iconUrl, let url = URL(string: iconUrl) {
            iconView.tintColor = nil
            iconView.kf.setImage(with: url)
        } else {
            let key = MonitorCardDisplayMapper.metricKey(for: card.cardType)
            iconView.image = UIImage(systemName: MonitorCardDisplayMapper.iconSF(for: key))
            iconView.tintColor = UIColor(hexString: "#52b96a")
        }
        let symbol = mode == .minus ? "minus.circle.fill" : "plus.circle.fill"
        let color: UIColor = mode == .minus ? .fdPrimary : UIColor(hexString: "#52b96a")
        actionButton.setImage(UIImage(systemName: symbol), for: .normal)
        actionButton.tintColor = color
    }

    @objc private func tapped() { onAction?() }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.kf.cancelDownloadTask()
        iconView.image = nil
        onAction = nil
    }
}
