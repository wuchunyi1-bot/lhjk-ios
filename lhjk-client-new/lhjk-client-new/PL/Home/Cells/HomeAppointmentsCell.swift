import SnapKit
import UIKit

/// 首页「我的预约」。有待服务记录才由首页挂上这一行。
final class HomeAppointmentsCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    static let reuseID = "HomeAppointmentsCell"

    var onUse: ((HomePendingAppointment) -> Void)?

    private var items: [HomePendingAppointment] = []
    private let titleLabel = UILabel()
    private let collectionView: UICollectionView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
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
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        titleLabel.text = "我的预约"
        titleLabel.font = .fdFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .fdText

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HomeAppointmentCardCell.self, forCellWithReuseIdentifier: HomeAppointmentCardCell.reuseID)

        contentView.addSubview(titleLabel)
        contentView.addSubview(collectionView)
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(184)
            $0.bottom.equalToSuperview()
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
        cell.configure(item)
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
        let width: CGFloat
        if items.count <= 1 {
            width = max(collectionView.bounds.width - 32, 1)
        } else {
            width = min(272, max(collectionView.bounds.width - 48, 1))
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
    private let storeIcon = UIImageView()
    private let storeNameLabel = UILabel()
    private let addressLabel = UILabel()
    private let hintLabel = UILabel()
    private let useButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onUse = nil
    }

    func configure(_ item: HomePendingAppointment) {
        titleLabel.text = item.title
        timeLabel.text = item.timeText
        timeLabel.isHidden = item.timeText.isEmpty
        timeIcon.isHidden = item.timeText.isEmpty
        storeNameLabel.text = item.storeName
        storeNameLabel.isHidden = item.storeName.isEmpty
        addressLabel.text = item.address
        addressLabel.isHidden = item.address.isEmpty
        storeIcon.isHidden = item.storeName.isEmpty && item.address.isEmpty
        hintLabel.text = item.hint
    }

    private func setup() {
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdBorder.cgColor
        card.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        contentView.addSubview(card)

        titleLabel.font = .fdFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .fdText
        titleLabel.numberOfLines = 1

        timeIcon.image = UIImage(systemName: "calendar")
        timeIcon.tintColor = .fdPrimary
        timeIcon.contentMode = .scaleAspectFit
        timeLabel.font = .fdFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = .fdSubtext
        let timeChip = UIStackView(arrangedSubviews: [timeIcon, timeLabel])
        timeChip.axis = .horizontal
        timeChip.alignment = .center
        timeChip.spacing = 6
        timeChip.isLayoutMarginsRelativeArrangement = true
        timeChip.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        timeChip.backgroundColor = .fdPrimarySoft
        timeChip.layer.cornerRadius = 8
        timeChip.clipsToBounds = true
        timeChip.isUserInteractionEnabled = false

        storeIcon.image = UIImage(systemName: "storefront")
        storeIcon.tintColor = .fdPrimary
        storeIcon.contentMode = .scaleAspectFit
        storeNameLabel.font = .fdFont(ofSize: 13, weight: .semibold)
        storeNameLabel.textColor = .fdText
        addressLabel.font = .fdFont(ofSize: 12, weight: .regular)
        addressLabel.textColor = .fdSubtext
        let storeText = UIStackView(arrangedSubviews: [storeNameLabel, addressLabel])
        storeText.axis = .vertical
        storeText.spacing = 2
        let storeRow = UIStackView(arrangedSubviews: [storeIcon, storeText])
        storeRow.axis = .horizontal
        storeRow.alignment = .center
        storeRow.spacing = 6
        storeRow.isUserInteractionEnabled = false

        hintLabel.font = .fdFont(ofSize: 12, weight: .regular)
        hintLabel.textColor = .fdSubtext
        hintLabel.numberOfLines = 1
        useButton.setTitle("去查看", for: .normal)
        useButton.setTitleColor(.white, for: .normal)
        useButton.titleLabel?.font = .fdFont(ofSize: 12, weight: .semibold)
        useButton.backgroundColor = .fdPrimary
        useButton.layer.cornerRadius = 14
        useButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        useButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        let footer = UIStackView(arrangedSubviews: [hintLabel, useButton])
        footer.axis = .horizontal
        footer.alignment = .center
        footer.spacing = 8

        let line = UIView()
        line.backgroundColor = .fdBorder

        card.addSubview(titleLabel)
        card.addSubview(timeChip)
        card.addSubview(storeRow)
        card.addSubview(line)
        card.addSubview(footer)

        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        timeIcon.snp.makeConstraints { $0.size.equalTo(14) }
        storeIcon.snp.makeConstraints { $0.size.equalTo(14) }
        useButton.snp.makeConstraints { $0.height.equalTo(28) }
        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(14)
        }
        timeChip.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(14)
            $0.trailing.lessThanOrEqualToSuperview().inset(14)
        }
        storeRow.snp.makeConstraints {
            $0.top.equalTo(timeChip.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(14)
        }
        line.snp.makeConstraints {
            $0.top.equalTo(storeRow.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(14)
            $0.height.equalTo(1.0 / UIScreen.main.scale)
        }
        footer.snp.makeConstraints {
            $0.top.equalTo(line.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(14)
            $0.bottom.lessThanOrEqualToSuperview().inset(12)
        }
    }

    @objc private func tapped() {
        onUse?()
    }
}
