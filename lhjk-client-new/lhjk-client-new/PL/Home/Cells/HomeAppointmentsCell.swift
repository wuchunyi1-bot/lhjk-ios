import SnapKit
import UIKit

/// 首页「我的预约」。有待服务记录才由首页挂上这一行。
final class HomeAppointmentsCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    static let reuseID = "HomeAppointmentsCell"

    var onUse: ((HomePendingAppointment) -> Void)?

    private var items: [HomePendingAppointment] = []
    private var lastCollectionWidth: CGFloat = 0
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let collectionView: UICollectionView
    private var collectionHeight: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onUse = nil
    }

    func configure(_ items: [HomePendingAppointment]) {
        self.items = items
        applyMetrics()
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    func applyMetrics() {
        collectionHeight?.update(offset: Self.cardAreaHeight())
        for case let cell as HomeAppointmentCardCell in collectionView.visibleCells {
            cell.applyMetrics()
        }
        collectionView.collectionViewLayout.invalidateLayout()
    }

    /// 按当前字号（含长辈模式）撑开横向卡片，避免加大字号后被裁切。
    static func cardAreaHeight() -> CGFloat {
        let title = UIFont.fdFont(ofSize: 18, weight: .semibold).lineHeight
        let time = UIFont.fdFont(ofSize: 14, weight: .regular).lineHeight
        let store = UIFont.fdFont(ofSize: 15, weight: .semibold).lineHeight
        let address = UIFont.fdFont(ofSize: 13, weight: .regular).lineHeight
        let hint = UIFont.fdFont(ofSize: 14, weight: .regular).lineHeight
        let bottom = max(36, ceil(hint) + 16)
        let middle = 8 + store + 4 + address + 8
        return ceil(14 + title + 6 + max(time, 14) + 10 + middle + 8 + bottom)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = collectionView.bounds.width
        guard width > 1, abs(width - lastCollectionWidth) > 0.5 else { return }
        lastCollectionWidth = width
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        titleLabel.text = "我的预约"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .fdText

        cardView.backgroundColor = .fdSurface
        cardView.layer.cornerRadius = 16
        cardView.clipsToBounds = true

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HomeAppointmentCardCell.self, forCellWithReuseIdentifier: HomeAppointmentCardCell.reuseID)

        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(collectionView)
        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }
        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(16)
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            collectionHeight = $0.height.equalTo(Self.cardAreaHeight()).constraint
            $0.bottom.equalToSuperview().inset(16)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HomeAppointmentCardCell.reuseID,
            for: indexPath
        ) as! HomeAppointmentCardCell
        let item = items[indexPath.item]
        cell.configure(item, themeIndex: indexPath.item)
        cell.onUse = { [weak self] in
            self?.onUse?(item)
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let height = collectionView.bounds.height
        let available = collectionView.bounds.width
        let width: CGFloat
        if items.count <= 1 {
            width = max(available - 24, 1)
        } else {
            // 右侧露出下一张，左滑后两种样式交替出现。
            width = max(available - 52, 1)
        }
        return CGSize(width: width, height: height)
    }
}

private final class HomeAppointmentCardCell: UICollectionViewCell {

    static let reuseID = "HomeAppointmentCardCell"

    var onUse: (() -> Void)?

    private let card = UIControl()
    private let titleLabel = UILabel()
    private let timeIcon = UIImageView()
    private let timeLabel = UILabel()
    private let middleBox = UIView()
    private let storeNameLabel = UILabel()
    private let addressLabel = UILabel()
    private let bottomBar = UIView()
    private let hintLabel = UILabel()
    private let useButton = UIButton(type: .system)
    private var bottomBarHeight: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onUse = nil
    }

    func configure(_ item: HomePendingAppointment, themeIndex: Int = 0) {
        titleLabel.text = item.title
        timeLabel.text = item.timeText
        timeLabel.isHidden = item.timeText.isEmpty
        timeIcon.isHidden = item.timeText.isEmpty
        storeNameLabel.text = item.storeName
        storeNameLabel.isHidden = item.storeName.isEmpty
        addressLabel.text = item.address
        addressLabel.isHidden = item.address.isEmpty
        hintLabel.text = item.hint
        applyMetrics()
        applyTheme(isWarm: themeIndex % 2 != 0)
    }

    private func applyTheme(isWarm: Bool) {
        if isWarm {
            card.backgroundColor = UIColor(hexString: "#FFFDF9")
            card.layer.borderColor = UIColor(hexString: "#FCEEE3").cgColor
            titleLabel.textColor = UIColor(hexString: "#8C4A27")
            timeIcon.tintColor = UIColor(hexString: "#B86B3E")
            timeLabel.textColor = UIColor(hexString: "#B86B3E")
            middleBox.backgroundColor = UIColor(hexString: "#FFF8F2")
            middleBox.layer.borderColor = UIColor(hexString: "#F7E6D7").cgColor
            storeNameLabel.textColor = UIColor(hexString: "#6E3519")
            addressLabel.textColor = UIColor(hexString: "#9C7662")
            hintLabel.textColor = UIColor(hexString: "#B86B3E")
            useButton.setTitleColor(UIColor(hexString: "#B86B3E"), for: .normal)
            useButton.setImage(UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)), for: .normal)
            useButton.tintColor = UIColor(hexString: "#B86B3E")
            bottomBar.backgroundColor = UIColor(hexString: "#FFF1E5")
        } else {
            card.backgroundColor = UIColor(hexString: "#F7FAFF")
            card.layer.borderColor = UIColor(hexString: "#E3EEFC").cgColor
            titleLabel.textColor = UIColor(hexString: "#1F4E8C")
            timeIcon.tintColor = UIColor(hexString: "#2B6CB0")
            timeLabel.textColor = UIColor(hexString: "#2B6CB0")
            middleBox.backgroundColor = .white
            middleBox.layer.borderColor = UIColor(hexString: "#E6F0FA").cgColor
            storeNameLabel.textColor = UIColor(hexString: "#1A365D")
            addressLabel.textColor = UIColor(hexString: "#4A6E9B")
            hintLabel.textColor = UIColor(hexString: "#3182CE")
            useButton.setTitleColor(UIColor(hexString: "#2B6CB0"), for: .normal)
            useButton.setImage(UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)), for: .normal)
            useButton.tintColor = UIColor(hexString: "#2B6CB0")
            bottomBar.backgroundColor = UIColor(hexString: "#EAF2FC")
        }
    }

    private func setup() {
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.clipsToBounds = true
        card.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        contentView.addSubview(card)

        titleLabel.font = .fdFont(ofSize: 18, weight: .semibold)
        titleLabel.numberOfLines = 1

        timeIcon.image = UIImage(systemName: "clock.fill")
        timeIcon.contentMode = .scaleAspectFit
        timeLabel.font = .fdFont(ofSize: 14, weight: .regular)
        let timeRow = UIStackView(arrangedSubviews: [timeIcon, timeLabel])
        timeRow.axis = .horizontal
        timeRow.alignment = .center
        timeRow.spacing = 6
        timeRow.isUserInteractionEnabled = false

        middleBox.layer.cornerRadius = 8
        middleBox.layer.borderWidth = 0.5
        middleBox.isUserInteractionEnabled = false

        storeNameLabel.font = .fdFont(ofSize: 15, weight: .semibold)
        addressLabel.font = .fdFont(ofSize: 13, weight: .regular)
        let storeStack = UIStackView(arrangedSubviews: [storeNameLabel, addressLabel])
        storeStack.axis = .vertical
        storeStack.spacing = 4
        storeStack.alignment = .leading
        middleBox.addSubview(storeStack)
        storeStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10))
        }

        bottomBar.isUserInteractionEnabled = false
        hintLabel.font = .fdFont(ofSize: 14, weight: .regular)
        hintLabel.numberOfLines = 1
        hintLabel.lineBreakMode = .byTruncatingTail
        hintLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        useButton.setTitle("去使用", for: .normal)
        useButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        useButton.semanticContentAttribute = .forceRightToLeft
        useButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: -3)
        useButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        bottomBar.addSubview(hintLabel)
        bottomBar.addSubview(useButton)
        hintLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(useButton.snp.leading).offset(-8)
        }
        useButton.setContentHuggingPriority(.required, for: .horizontal)
        useButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        useButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }

        card.addSubview(titleLabel)
        card.addSubview(timeRow)
        card.addSubview(middleBox)
        card.addSubview(bottomBar)

        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        timeIcon.snp.makeConstraints { $0.size.equalTo(14) }

        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(14)
        }
        timeRow.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(14)
        }
        middleBox.snp.makeConstraints {
            $0.top.equalTo(timeRow.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.lessThanOrEqualTo(bottomBar.snp.top).offset(-8)
        }
        bottomBar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            bottomBarHeight = $0.height.equalTo(Self.bottomBarHeight()).constraint
        }
    }

    func applyMetrics() {
        titleLabel.font = .fdFont(ofSize: 18, weight: .semibold)
        timeLabel.font = .fdFont(ofSize: 14, weight: .regular)
        storeNameLabel.font = .fdFont(ofSize: 15, weight: .semibold)
        addressLabel.font = .fdFont(ofSize: 13, weight: .regular)
        hintLabel.font = .fdFont(ofSize: 14, weight: .regular)
        useButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        bottomBarHeight?.update(offset: Self.bottomBarHeight())
    }

    private static func bottomBarHeight() -> CGFloat {
        max(36, ceil(UIFont.fdFont(ofSize: 14, weight: .regular).lineHeight) + 16)
    }

    @objc private func tapped() {
        onUse?()
    }
}
