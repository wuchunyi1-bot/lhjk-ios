import UIKit
import SnapKit

/// 健康大会员资产卡 — 对齐 MeView.vue `member-card`
final class MeMembershipCardCell: UITableViewCell {

    static let reuseIdentifier = "MeMembershipCardCell"

    struct AssetItem {
        let label: String
        let value: String
        let route: String
        var accent: Bool = false
    }

    var onTitleTap: (() -> Void)?
    var onRedemptionTap: (() -> Void)?
    var onAssetTap: ((String) -> Void)?

    private let cardView = UIView()
    private let titleButton = UIButton(type: .system)
    private let moreButton = UIButton(type: .system)
    private let assetsStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = UIColor(hexString: "#FFF7F1")
        cardView.layer.cornerRadius = 12
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.2).cgColor

        titleButton.setTitle("健康大会员", for: .normal)
        titleButton.setTitleColor(.fdPrimary, for: .normal)
        titleButton.titleLabel?.font = .fdH3
        titleButton.contentHorizontalAlignment = .leading
        titleButton.addTarget(self, action: #selector(titleTapped), for: .touchUpInside)

        moreButton.setTitle("会员兑换 ›", for: .normal)
        moreButton.setTitleColor(.fdSubtext, for: .normal)
        moreButton.titleLabel?.font = .fdCaption
        moreButton.addTarget(self, action: #selector(redemptionTapped), for: .touchUpInside)

        assetsStack.axis = .horizontal
        assetsStack.distribution = .fillEqually
        assetsStack.alignment = .fill

        contentView.addSubview(cardView)
        [titleButton, moreButton, assetsStack].forEach(cardView.addSubview)

        cardView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        titleButton.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(14)
        }
        moreButton.snp.makeConstraints {
            $0.centerY.equalTo(titleButton)
            $0.trailing.equalToSuperview().inset(14)
        }
        assetsStack.snp.makeConstraints {
            $0.top.equalTo(titleButton.snp.bottom).offset(9)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(10)
            $0.height.greaterThanOrEqualTo(44)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(assets: [AssetItem]) {
        assetsStack.arrangedSubviews.forEach {
            assetsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for (index, asset) in assets.enumerated() {
            let column = makeAssetColumn(asset, showDivider: index > 0)
            assetsStack.addArrangedSubview(column)
        }
    }

    private func makeAssetColumn(_ asset: AssetItem, showDivider: Bool) -> UIView {
        let wrap = UIView()

        if showDivider {
            let divider = UIView()
            divider.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.12)
            wrap.addSubview(divider)
            divider.snp.makeConstraints {
                $0.leading.top.bottom.equalToSuperview()
                $0.width.equalTo(1)
            }
        }

        let button = UIButton(type: .system)
        button.addAction(UIAction { [weak self] _ in
            self?.onAssetTap?(asset.route)
        }, for: .touchUpInside)

        let valueLbl = UILabel()
        valueLbl.text = asset.value
        valueLbl.font = asset.accent
            ? .fdMonoFont(ofSize: 20, weight: .bold)
            : .fdMonoFont(ofSize: 18, weight: .bold)
        valueLbl.textColor = asset.accent ? .fdPrimary : .fdText
        valueLbl.textAlignment = .center

        let labelLbl = UILabel()
        labelLbl.text = asset.label
        labelLbl.font = .fdMicro
        labelLbl.textColor = .fdSubtext
        labelLbl.textAlignment = .center

        button.addSubview(valueLbl)
        button.addSubview(labelLbl)
        wrap.addSubview(button)

        button.snp.makeConstraints {
            if showDivider {
                $0.leading.equalToSuperview().offset(1)
            } else {
                $0.leading.equalToSuperview()
            }
            $0.trailing.top.bottom.equalToSuperview()
        }
        valueLbl.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
        }
        labelLbl.snp.makeConstraints {
            $0.top.equalTo(valueLbl.snp.bottom).offset(4)
            $0.centerX.bottom.equalToSuperview()
        }

        return wrap
    }

    @objc private func titleTapped() { onTitleTap?() }
    @objc private func redemptionTapped() { onRedemptionTap?() }
}
