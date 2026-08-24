import UIKit
import SnapKit

/// 健康大会员资产卡片 — 对齐 Figma 3594:8603
final class MeMembershipCardView: UIView {

    struct AssetItem {
        let label: String
        let value: String
        let route: String
    }

    var onTitleTap: (() -> Void)?
    var onRedemptionTap: (() -> Void)?
    var onAssetTap: ((Int) -> Void)?

    private let bgImageView = UIImageView()
    private let featherIconView = UIImageView()
    private let titleLabel = UILabel()
    private let titleButton = UIButton(type: .custom)
    private let redemptionLabel = UILabel()
    private let redemptionArrow = UIImageView()
    private let redemptionButton = UIButton(type: .custom)
    private let assetsStack = UIStackView()
    private var valueLabels: [UILabel] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.cornerRadius = 16
        clipsToBounds = true

        bgImageView.image = UIImage(named: "me_membership_card_bg")
        bgImageView.contentMode = .scaleToFill
        addSubview(bgImageView)
        bgImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Top Row - Left Title
        featherIconView.image = UIImage(named: "me_member_feather_icon")
        featherIconView.contentMode = .scaleAspectFit
        addSubview(featherIconView)
        featherIconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(11.5)
            $0.top.equalToSuperview().offset(11.5)
            $0.size.equalTo(20)
        }

        titleLabel.text = "健康大会员"
        titleLabel.font = .fdFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor(hexString: "#754200")
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(featherIconView.snp.trailing).offset(2)
            $0.centerY.equalTo(featherIconView)
        }

        titleButton.addTarget(self, action: #selector(handleTitleTap), for: .touchUpInside)
        addSubview(titleButton)
        titleButton.snp.makeConstraints {
            $0.leading.top.equalToSuperview()
            $0.trailing.equalTo(titleLabel.snp.trailing).offset(8)
            $0.bottom.equalTo(titleLabel.snp.bottom).offset(8)
        }

        // Top Row - Right "会员兑换" + Arrow
        redemptionArrow.image = UIImage(named: "me_list_more_arrow")
        redemptionArrow.tintColor = UIColor(hexString: "#D18640")
        redemptionArrow.contentMode = .scaleAspectFit
        addSubview(redemptionArrow)
        redemptionArrow.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16.5)
            $0.centerY.equalTo(featherIconView)
            $0.size.equalTo(12)
        }

        redemptionLabel.text = "会员兑换"
        redemptionLabel.font = .fdFont(ofSize: 16, weight: .regular)
        redemptionLabel.textColor = UIColor(hexString: "#D18640")
        addSubview(redemptionLabel)
        redemptionLabel.snp.makeConstraints {
            $0.trailing.equalTo(redemptionArrow.snp.leading).offset(-2)
            $0.centerY.equalTo(featherIconView)
        }

        redemptionButton.addTarget(self, action: #selector(handleRedemptionTap), for: .touchUpInside)
        addSubview(redemptionButton)
        redemptionButton.snp.makeConstraints {
            $0.trailing.top.equalToSuperview()
            $0.leading.equalTo(redemptionLabel.snp.leading).offset(-8)
            $0.bottom.equalTo(redemptionLabel.snp.bottom).offset(8)
        }

        // Bottom 4 Columns Stack
        assetsStack.axis = .horizontal
        assetsStack.distribution = .fillEqually
        assetsStack.alignment = .fill
        addSubview(assetsStack)
        assetsStack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalToSuperview().offset(42.5)
            $0.bottom.equalToSuperview()
        }

        snp.makeConstraints {
            $0.height.equalTo(132)
        }
    }

    func configure(assets: [AssetItem]) {
        assetsStack.arrangedSubviews.forEach {
            assetsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        valueLabels.removeAll()

        for (index, asset) in assets.enumerated() {
            let col = UIView()
            let button = UIButton(type: .custom)
            button.tag = index
            button.addTarget(self, action: #selector(handleAssetTap(_:)), for: .touchUpInside)
            col.addSubview(button)
            button.snp.makeConstraints { $0.edges.equalToSuperview() }

            let valueLbl = UILabel()
            valueLbl.text = asset.value
            valueLbl.font = .fdFont(ofSize: 20, weight: .medium)
            valueLbl.textColor = UIColor(hexString: "#754200")
            valueLbl.textAlignment = .center
            valueLbl.isUserInteractionEnabled = false

            let labelLbl = UILabel()
            labelLbl.text = asset.label
            labelLbl.font = .fdFont(ofSize: 14, weight: .regular)
            labelLbl.textColor = UIColor(hexString: "#754200")
            labelLbl.textAlignment = .center
            labelLbl.isUserInteractionEnabled = false

            button.addSubview(valueLbl)
            button.addSubview(labelLbl)

            valueLbl.snp.makeConstraints {
                $0.top.equalToSuperview().offset(25)
                $0.centerX.equalToSuperview()
            }
            labelLbl.snp.makeConstraints {
                $0.top.equalTo(valueLbl.snp.bottom).offset(4)
                $0.centerX.equalToSuperview()
            }

            valueLabels.append(valueLbl)
            assetsStack.addArrangedSubview(col)
        }
    }

    func updateAssetValue(at index: Int, value: String) {
        guard index < valueLabels.count else { return }
        valueLabels[index].text = value
    }

    @objc private func handleTitleTap() {
        onTitleTap?()
    }

    @objc private func handleRedemptionTap() {
        onRedemptionTap?()
    }

    @objc private func handleAssetTap(_ sender: UIButton) {
        onAssetTap?(sender.tag)
    }
}
