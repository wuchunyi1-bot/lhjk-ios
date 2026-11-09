import SnapKit
import UIKit

final class ExamPackageCell: UITableViewCell {

    static let reuseID = "ExamPackageCell"

    var onBook: (() -> Void)?

    private let panel = UIView()
    private let nameLabel = UILabel()
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
    }

    func configure(_ item: ServiceItemVO) {
        nameLabel.text = item.name
        priceLabel.text = item.priceText
        priceLabel.isHidden = item.priceText == nil
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        panel.backgroundColor = .fdSurface
        panel.layer.cornerRadius = 12

        nameLabel.font = .fdFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2

        priceLabel.font = .fdFont(ofSize: 15, weight: .semibold)
        priceLabel.textColor = .fdPrimary

        bookButton.setTitle("去预约", for: .normal)
        bookButton.setTitleColor(.white, for: .normal)
        bookButton.titleLabel?.font = .fdFont(ofSize: 13, weight: .medium)
        bookButton.backgroundColor = .fdPrimary
        bookButton.layer.cornerRadius = 16
        bookButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        bookButton.addTarget(self, action: #selector(bookTapped), for: .touchUpInside)

        contentView.addSubview(panel)
        panel.addSubview(nameLabel)
        panel.addSubview(priceLabel)
        panel.addSubview(bookButton)

        panel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }
        nameLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(14)
            $0.trailing.lessThanOrEqualTo(bookButton.snp.leading).offset(-12)
        }
        priceLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(8)
            $0.leading.equalTo(nameLabel)
            $0.bottom.equalToSuperview().offset(-14)
        }
        bookButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-14)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(32)
        }
        bookButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @objc private func bookTapped() {
        onBook?()
    }
}
