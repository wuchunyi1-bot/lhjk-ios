import UIKit
import SnapKit

/// 血压建议卡
final class BloodPressureAdviceCell: UITableViewCell {

    static let reuseID = "BloodPressureAdviceCell"

    var onMoreTap: (() -> Void)?

    private let card = UIView()
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    private let moreButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16))
        }

        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText

        contentLabel.font = .fdCaption
        contentLabel.textColor = .fdText2
        contentLabel.numberOfLines = 0

        moreButton.setTitle("查看更多", for: .normal)
        moreButton.titleLabel?.font = .fdCaption
        moreButton.setTitleColor(.fdPrimary, for: .normal)
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)

        card.addSubview(titleLabel)
        card.addSubview(contentLabel)
        card.addSubview(moreButton)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(titleLabel)
        }
        moreButton.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, content: String, showsMore: Bool) {
        titleLabel.text = title
        contentLabel.text = content
        moreButton.isHidden = !showsMore
    }

    @objc private func moreTapped() { onMoreTap?() }
}
