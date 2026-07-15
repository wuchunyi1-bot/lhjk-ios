import UIKit
import SnapKit

/// 统计周期行
final class BloodPressureStatsPeriodCell: UITableViewCell {

    static let reuseID = "BloodPressureStatsPeriodCell"

    private let card = UIView()
    private let titleLabel = UILabel()
    private let totalLabel = UILabel()
    private let normalLabel = UILabel()
    private let highLabel = UILabel()
    private let lowLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 10, right: 16))
        }

        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText

        [totalLabel, normalLabel, highLabel, lowLabel].forEach {
            $0.font = .fdCaption
            $0.textColor = .fdText2
            card.addSubview($0)
        }
        card.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(14)
        }
        totalLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.equalTo(titleLabel)
        }
        normalLabel.snp.makeConstraints { make in
            make.top.equalTo(totalLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel)
        }
        highLabel.snp.makeConstraints { make in
            make.top.equalTo(normalLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel)
        }
        lowLabel.snp.makeConstraints { make in
            make.top.equalTo(highLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, stats: BloodPressurePeriodStats?) {
        titleLabel.text = title
        totalLabel.text = "总次数：\(stats?.total?.value ?? 0)"
        normalLabel.text = "正常：\(stats?.normal?.value ?? 0)"
        highLabel.text = "偏高：\(stats?.high?.value ?? 0)"
        lowLabel.text = "偏低：\(stats?.low?.value ?? 0)"
    }
}
