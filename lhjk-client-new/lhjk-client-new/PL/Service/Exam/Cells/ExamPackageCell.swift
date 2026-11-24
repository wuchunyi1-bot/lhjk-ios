import Kingfisher
import SnapKit
import UIKit

/// 可预约套餐行。对齐 Vue `ExamPackageCard` 的 bookable 版式。
final class ExamPackageCell: UITableViewCell {

    static let reuseID = "ExamPackageCell"

    var onBook: (() -> Void)?

    private let panel = UIView()
    private let separator = UIView()
    private let coverView = UIImageView()
    private let nameLabel = UILabel()
    private let introLabel = UILabel()
    private let yenLabel = UILabel()
    private let priceLabel = UILabel()
    private let bookButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onBook = nil
        coverView.kf.cancelDownloadTask()
        coverView.image = nil
    }

    func configure(_ item: ServiceItemVO, isFirst: Bool, isLast: Bool) {
        nameLabel.text = item.name
        introLabel.text = item.introText
        introLabel.isHidden = item.introText == nil
        priceLabel.text = item.plainPrice
        let hasPrice = item.plainPrice != nil
        yenLabel.isHidden = !hasPrice
        priceLabel.isHidden = !hasPrice
        coverView.kf.setImage(with: item.coverURL)
        applyCorners(isFirst: isFirst, isLast: isLast)
        separator.isHidden = isFirst
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        panel.backgroundColor = .fdSurface
        panel.layer.masksToBounds = true

        separator.backgroundColor = .fdBorder

        coverView.contentMode = .scaleAspectFill
        coverView.clipsToBounds = true
        coverView.layer.cornerRadius = 8
        coverView.backgroundColor = .fdPrimarySoft

        nameLabel.font = .fdFont(designSize: 15, seniorSize: 18, weight: .bold)
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2

        introLabel.font = .fdMicro
        introLabel.textColor = .fdSubtext
        introLabel.numberOfLines = 2

        yenLabel.text = "¥"
        yenLabel.font = .fdFont(designSize: 12, seniorSize: 14, weight: .bold)
        yenLabel.textColor = .fdPrimary

        priceLabel.font = .fdFont(designSize: 22, seniorSize: 26, weight: .bold)
        priceLabel.textColor = .fdPrimary

        bookButton.setTitle("去预约", for: .normal)
        bookButton.setTitleColor(.white, for: .normal)
        bookButton.titleLabel?.font = .fdCaptionSemibold
        bookButton.backgroundColor = .fdPrimary
        bookButton.layer.cornerRadius = 16
        bookButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        bookButton.addTarget(self, action: #selector(bookTapped), for: .touchUpInside)

        let priceRow = UIStackView(arrangedSubviews: [yenLabel, priceLabel])
        priceRow.axis = .horizontal
        priceRow.alignment = .lastBaseline
        priceRow.spacing = 1

        let spacer = UIView()
        let actionRow = UIStackView(arrangedSubviews: [priceRow, spacer, bookButton])
        actionRow.axis = .horizontal
        actionRow.alignment = .center
        actionRow.spacing = 8

        let body = UIStackView(arrangedSubviews: [nameLabel, introLabel, actionRow])
        body.axis = .vertical
        body.alignment = .fill
        body.spacing = 6

        let row = UIStackView(arrangedSubviews: [coverView, body])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12

        contentView.addSubview(panel)
        panel.addSubview(separator)
        panel.addSubview(row)

        panel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        separator.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(1.0 / UIScreen.main.scale)
        }
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        coverView.snp.makeConstraints { $0.size.equalTo(96) }
        bookButton.snp.makeConstraints { $0.height.equalTo(36) }
        bookButton.setContentHuggingPriority(.required, for: .horizontal)
        bookButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    private func applyCorners(isFirst: Bool, isLast: Bool) {
        var corners: CACornerMask = []
        if isFirst {
            corners.formUnion([.layerMinXMinYCorner, .layerMaxXMinYCorner])
        }
        if isLast {
            corners.formUnion([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
        }
        panel.layer.cornerRadius = corners.isEmpty ? 0 : 8
        panel.layer.maskedCorners = corners
    }

    @objc private func bookTapped() {
        onBook?()
    }
}
