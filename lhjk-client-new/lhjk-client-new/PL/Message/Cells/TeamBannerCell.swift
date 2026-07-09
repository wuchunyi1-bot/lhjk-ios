import UIKit
import SnapKit

final class TeamBannerCell: UITableViewCell {

    static let reuseID = "TeamBannerCell"

    var onTap: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .fdBg

        let banner = UIView()
        banner.backgroundColor = UIColor(hexString: "#FFF7F1")
        banner.layer.cornerRadius = 12
        banner.layer.borderWidth = 1
        banner.layer.borderColor = UIColor(hexString: "#FF7A50").withAlphaComponent(0.18).cgColor
        banner.isUserInteractionEnabled = true

        let heart = UIImageView(image: UIImage(systemName: "heart.fill"))
        heart.tintColor = .fdPrimary
        heart.contentMode = .scaleAspectFit

        let mark = UILabel()
        mark.text = "三好共管 · 您的专属团队"
        mark.font = .fdFont(ofSize: 13, weight: .semibold)
        mark.textColor = .fdText

        let badge = UILabel()
        badge.text = "● 3 人在线"
        badge.font = .fdFont(ofSize: 10, weight: .bold)
        badge.textColor = .fdSuccess
        badge.backgroundColor = UIColor(hexString: "#E6F7EF")
        badge.layer.cornerRadius = 8
        badge.clipsToBounds = true
        badge.textAlignment = .center

        let body = UILabel()
        body.text = "优先从服务群发起问题，医生、营养师、健管师会协同回复。"
        body.font = .fdFont(ofSize: 12)
        body.textColor = .fdSubtext
        body.numberOfLines = 0

        [banner, heart, mark, badge, body].forEach(contentView.addSubview)
        banner.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 16, bottom: 0, right: 16)) }
        heart.snp.makeConstraints { make in
            make.top.leading.equalTo(banner).inset(14); make.size.equalTo(16)
        }
        mark.snp.makeConstraints { make in
            make.leading.equalTo(heart.snp.trailing).offset(6); make.centerY.equalTo(heart)
        }
        badge.snp.makeConstraints { make in
            make.trailing.equalTo(banner).inset(14); make.centerY.equalTo(heart)
            make.height.equalTo(20); make.width.equalTo(72)
        }
        body.snp.makeConstraints { make in
            make.top.equalTo(heart.snp.bottom).offset(8)
            make.leading.trailing.equalTo(banner).inset(14)
            make.bottom.equalTo(banner).offset(-14)
        }

        banner.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func tapped() { onTap?() }
}
