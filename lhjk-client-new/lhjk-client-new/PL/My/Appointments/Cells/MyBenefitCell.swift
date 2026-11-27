import Kingfisher
import SnapKit
import UIKit

/// 我的权益卡片。版式对齐订单商品卡和预约记录操作按钮。
final class MyBenefitCell: UITableViewCell {

    static let reuseID = "MyBenefitCell"

    var onBook: (() -> Void)?

    private let card = UIView()
    private let coverView = UIImageView()
    private let nameLabel = UILabel()
    private let introLabel = UILabel()
    private let quantityLabel = UILabel()
    private let bookButton = UIButton(type: .system)
    private var introTop: Constraint?
    private var quantityTop: Constraint?

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

    func configure(_ item: CabinEntitlementVO) {
        nameLabel.text = item.name.isEmpty ? "权益" : item.name
        let intro = item.introText
        introLabel.text = intro
        introLabel.isHidden = intro == nil
        introTop?.update(offset: intro == nil ? 0 : 4)
        quantityLabel.text = item.quantityText
        quantityLabel.isHidden = item.quantityText == nil
        quantityTop?.update(offset: item.quantityText == nil ? 0 : 10)
        coverView.kf.setImage(with: item.coverURL)
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 8
        card.layer.shadowOpacity = 0.04
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalToSuperview().offset(6)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-6).priority(.high)
        }

        coverView.backgroundColor = .fdProductImageBg
        coverView.contentMode = .scaleAspectFill
        coverView.clipsToBounds = true
        coverView.layer.cornerRadius = 12

        nameLabel.font = .fdFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2

        introLabel.font = .fdFont(ofSize: 14, weight: .regular)
        introLabel.textColor = .fdTabInactive
        introLabel.numberOfLines = 2

        quantityLabel.font = .fdFont(ofSize: 14, weight: .medium)
        quantityLabel.textColor = .fdPrimary

        bookButton.setTitle("去预约", for: .normal)
        bookButton.setTitleColor(.white, for: .normal)
        bookButton.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        bookButton.backgroundColor = .fdPrimary
        bookButton.layer.cornerRadius = 16
        bookButton.clipsToBounds = true
        bookButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        bookButton.addTarget(self, action: #selector(bookTapped), for: .touchUpInside)

        card.addSubview(coverView)
        card.addSubview(nameLabel)
        card.addSubview(introLabel)
        card.addSubview(quantityLabel)
        card.addSubview(bookButton)

        coverView.snp.makeConstraints {
            $0.leading.top.equalToSuperview().offset(12)
            $0.size.equalTo(84)
        }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(coverView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-12)
            $0.top.equalTo(coverView)
        }
        introLabel.snp.makeConstraints {
            $0.leading.trailing.equalTo(nameLabel)
            introTop = $0.top.equalTo(nameLabel.snp.bottom).offset(4).constraint
        }
        quantityLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            quantityTop = $0.top.equalTo(introLabel.snp.bottom).offset(10).constraint
        }
        bookButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.centerY.equalTo(quantityLabel)
            $0.leading.greaterThanOrEqualTo(quantityLabel.snp.trailing).offset(8)
            $0.height.equalTo(32)
            $0.width.greaterThanOrEqualTo(88)
        }
        let bottom = UILayoutGuide()
        card.addLayoutGuide(bottom)
        bottom.snp.makeConstraints {
            $0.top.greaterThanOrEqualTo(coverView.snp.bottom)
            $0.top.greaterThanOrEqualTo(bookButton.snp.bottom)
            $0.top.greaterThanOrEqualTo(quantityLabel.snp.bottom)
            $0.bottom.equalToSuperview().offset(-12)
            $0.height.equalTo(0)
        }
        bookButton.setContentHuggingPriority(.required, for: .horizontal)
        bookButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        quantityLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    @objc private func bookTapped() {
        onBook?()
    }
}
