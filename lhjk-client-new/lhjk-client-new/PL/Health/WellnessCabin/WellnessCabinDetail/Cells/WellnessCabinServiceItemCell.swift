import Kingfisher
import SnapKit
import UIKit

final class WellnessCabinServiceItemCell: UITableViewCell {

    static let reuseID = "WellnessCabinServiceItemCell"

    var onBook: (() -> Void)?

    private let panel = UIView()
    private let cover = UIImageView()
    private let nameLabel = UILabel()
    private let priceLabel = UILabel()
    private let durationLabel = UILabel()
    private let bookButton = UIButton(type: .system)
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        cover.kf.cancelDownloadTask()
        cover.image = nil
        onBook = nil
        panel.layer.cornerRadius = 0
        panel.layer.maskedCorners = []
    }

    func configure(_ item: CabinConfigItemVO, isFirst: Bool, isLast: Bool) {
        nameLabel.text = item.name
        priceLabel.text = item.priceLabel
        priceLabel.isHidden = item.priceLabel == nil
        durationLabel.text = item.durationLabel
        durationLabel.isHidden = item.durationLabel == nil
        separator.isHidden = isLast

        var corners: CACornerMask = []
        if isFirst { corners.formUnion([.layerMinXMinYCorner, .layerMaxXMinYCorner]) }
        if isLast { corners.formUnion([.layerMinXMaxYCorner, .layerMaxXMaxYCorner]) }
        panel.layer.cornerRadius = corners.isEmpty ? 0 : 16
        panel.layer.maskedCorners = corners
        panel.layer.masksToBounds = true

        cover.kf.cancelDownloadTask()
        cover.image = nil
        if let url = item.coverURL {
            cover.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        }
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        panel.backgroundColor = .fdSurface

        cover.backgroundColor = .fdProductImageBg
        cover.contentMode = .scaleAspectFill
        cover.clipsToBounds = true
        cover.layer.cornerRadius = 8

        nameLabel.font = .fdFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 1

        priceLabel.font = .fdFont(ofSize: 13, weight: .semibold)
        priceLabel.textColor = .fdPrimary

        durationLabel.font = .fdFont(ofSize: 11, weight: .regular)
        durationLabel.textColor = .fdMuted

        bookButton.setTitle("立即预约", for: .normal)
        bookButton.setTitleColor(.white, for: .normal)
        bookButton.titleLabel?.font = .fdFont(ofSize: 12, weight: .medium)
        bookButton.backgroundColor = .fdPrimary
        bookButton.layer.cornerRadius = 15
        bookButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 11, bottom: 0, right: 11)
        bookButton.addTarget(self, action: #selector(bookTapped), for: .touchUpInside)

        separator.backgroundColor = .fdBorder

        let body = UIStackView(arrangedSubviews: [nameLabel, priceLabel, durationLabel])
        body.axis = .vertical
        body.alignment = .leading
        body.spacing = 4

        contentView.addSubview(panel)
        panel.addSubview(cover)
        panel.addSubview(body)
        panel.addSubview(bookButton)
        panel.addSubview(separator)

        panel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview()
        }
        cover.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().offset(-12)
            $0.size.equalTo(68)
        }
        bookButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(14)
            $0.centerY.equalTo(cover)
            $0.height.equalTo(30)
        }
        body.snp.makeConstraints {
            $0.leading.equalTo(cover.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(bookButton.snp.leading).offset(-8)
            $0.centerY.equalTo(cover)
        }
        separator.snp.makeConstraints {
            $0.leading.equalTo(body)
            $0.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1.0 / UIScreen.main.scale)
        }
        bookButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        bookButton.setContentHuggingPriority(.required, for: .horizontal)
    }

    @objc private func bookTapped() {
        onBook?()
    }
}
