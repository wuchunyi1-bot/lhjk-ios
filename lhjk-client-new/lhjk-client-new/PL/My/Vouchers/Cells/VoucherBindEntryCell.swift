import UIKit
import SnapKit

/// 绑定权益卡入口 — Figma 3835:32594，整卡使用 `benefit_bind_toBind` 切图
final class VoucherBindEntryCell: UITableViewCell {
    static let reuseID = "VoucherBindEntryCell"

    private enum Design {
        static let cardWidth: CGFloat = 343
        static let horizontalInset: CGFloat = 32
        static let verticalInset: CGFloat = 12
        static let cornerRadius: CGFloat = 16

        static var cellPadding: CGFloat { verticalInset / 2 }
        static var fallbackAspectRatio: CGFloat { 81 / cardWidth }
    }

    var onTap: (() -> Void)?

    private let cardButton = UIButton(type: .custom)
    private let cardImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "benefit_bind_toBind"))
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = false
        return iv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .white
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    static func rowHeight(for tableWidth: CGFloat) -> CGFloat {
        ceil(Design.verticalInset + cardHeight(for: tableWidth))
    }

    private static func cardHeight(for tableWidth: CGFloat) -> CGFloat {
        let width = max(0, tableWidth - Design.horizontalInset)
        guard let image = UIImage(named: "benefit_bind_toBind"), image.size.width > 0 else {
            return width * Design.fallbackAspectRatio
        }
        return width * image.size.height / image.size.width
    }

    private func setupUI() {
        cardButton.layer.cornerRadius = Design.cornerRadius
        cardButton.clipsToBounds = true
        cardButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        cardButton.addSubview(cardImageView)
        contentView.addSubview(cardButton)

        cardButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Design.cellPadding)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-Design.cellPadding)
        }

        cardImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @objc private func tapped() {
        onTap?()
    }
}
