import UIKit
import SnapKit

/// 慢病管理服务横幅 Cell
final class HomeServiceBannerCell: UITableViewCell {

    static let reuseID = "HomeServiceBannerCell"

    // MARK: - UI

    private let bannerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#FFE7D9")
        v.layer.cornerRadius = 18
        v.clipsToBounds = true
        return v
    }()

    private let tagLabel: UILabel = {
        let l = UILabel()
        l.text = "进行中"
        l.font = .fdMicroSemibold
        l.textColor = .white
        l.backgroundColor = .fdPrimary
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.text = "德好 · 慢病逆转管理"
        l.font = .fdH2
        l.textColor = .fdText
        return l
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = .fdCaption
        l.textColor = .fdText2
        return l
    }()

    private let progressBg: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        v.layer.cornerRadius = 4
        return v
    }()

    private let progressFill: UIView = {
        let v = UIView()
        v.backgroundColor = .fdPrimary
        v.layer.cornerRadius = 4
        return v
    }()

    private let daysLabel = UILabel()

    // MARK: - Callback

    var onTapped: (() -> Void)?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .fdBg
        selectionStyle = .none
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        let blob = UIView()
        blob.backgroundColor = UIColor.white.withAlphaComponent(0.45)
        blob.layer.cornerRadius = 65

        bannerView.addSubview(blob)
        blob.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(-30)
            make.size.equalTo(130)
        }

        bannerView.addSubview(tagLabel)
        bannerView.addSubview(nameLabel)
        bannerView.addSubview(descLabel)
        bannerView.addSubview(progressBg)
        progressBg.addSubview(progressFill)
        bannerView.addSubview(daysLabel)

        tagLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
            make.width.equalTo(46)
            make.height.equalTo(20)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(tagLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(16)
        }
        progressBg.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().inset(16)
            make.height.equalTo(8)
            make.bottom.equalToSuperview().offset(-16)
        }
        daysLabel.snp.makeConstraints { make in
            make.centerY.equalTo(progressBg)
            make.leading.equalTo(progressBg.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
        }

        contentView.addSubview(bannerView)
        bannerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(bannerTapped))
        bannerView.addGestureRecognizer(tap)
        bannerView.isUserInteractionEnabled = true
    }

    // MARK: - Configure

    func configure(week: Int, totalWeeks: Int, daysLeft: Int) {
        descLabel.text = "\(totalWeeks) 周完整方案 · 已完成第 \(week) 周 / \(totalWeeks)"
        progressFill.snp.remakeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(progressBg).multipliedBy(CGFloat(week) / CGFloat(totalWeeks))
        }

        let attr = NSMutableAttributedString(
            string: "剩 ",
            attributes: [
                .font: UIFont.fdMicro,
                .foregroundColor: UIColor.fdText2
            ]
        )
        attr.append(NSAttributedString(
            string: "\(daysLeft)",
            attributes: [
                .font: UIFont.fdBodyBold,
                .foregroundColor: UIColor.fdPrimary
            ]
        ))
        attr.append(NSAttributedString(
            string: " 天",
            attributes: [
                .font: UIFont.fdMicro,
                .foregroundColor: UIColor.fdText2
            ]
        ))
        daysLabel.attributedText = attr
    }

    @objc private func bannerTapped() {
        onTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTapped = nil
    }
}
