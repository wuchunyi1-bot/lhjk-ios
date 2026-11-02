import SnapKit
import UIKit

/// 就医协助落地页。`FundeApp:/services/medical-assist`
///
/// 头图与卖点为页面固定文案。可预约 / 推荐套餐待接口，当前不展示假套餐。
final class MedicalAssistViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        title = "就医协助"
        view.backgroundColor = .fdBg

        let recordsItem = UIBarButtonItem(
            title: "使用记录",
            style: .plain,
            target: self,
            action: #selector(openUsageRecords)
        )
        recordsItem.tintColor = .fdPrimary
        navigationItem.rightBarButtonItem = recordsItem

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.alwaysBounceVertical = true
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        let hero = MedicalAssistHeroView()
        let empty = FDEmptyStateView(
            style: .page,
            message: "暂无就医协助套餐",
            subtitle: "可预约与推荐套餐待接口接入"
        )
        contentView.addSubview(hero)
        contentView.addSubview(empty)
        hero.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }
        empty.snp.makeConstraints {
            $0.top.equalTo(hero.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.greaterThanOrEqualTo(220)
        }
    }

    @objc private func openUsageRecords() {
        Router.shared.push("/services/medical-assist/usage-records", from: self)
    }
}

/// 使用记录。履约列表待接口。
final class MedicalAssistUsageRecordsViewController: BaseViewController {

    override func setupUI() {
        title = "使用记录"
        view.backgroundColor = .fdBg
        let empty = FDEmptyStateView(style: .page, message: "暂无使用记录")
        view.addSubview(empty)
        empty.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

// MARK: - Hero

private final class MedicalAssistHeroView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdBg

        let photo = UIView()
        photo.backgroundColor = .fdPrimary

        let titleLabel = UILabel()
        titleLabel.text = "富德联好健康·就医协助"
        titleLabel.font = .fdH2
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let slogan = MedicalAssistSloganLabel()
        slogan.text = "暖心陪诊 护你所爱"
        slogan.font = .fdCaptionSemibold
        slogan.textColor = .fdPrimaryDeep
        slogan.textAlignment = .center
        slogan.backgroundColor = UIColor.fdPrimarySoft.withAlphaComponent(0.92)
        slogan.layer.cornerRadius = 14
        slogan.layer.masksToBounds = true
        slogan.contentInsets = UIEdgeInsets(top: 4, left: 14, bottom: 4, right: 14)

        let features = UIStackView()
        features.axis = .horizontal
        features.distribution = .fillEqually
        features.spacing = 0
        [
            ("cross.case", "陪同就诊", "代办手续"),
            ("mappin.and.ellipse", "覆盖全国", "统一标准"),
            ("gift", "暖心礼包", "贴心助诊"),
        ].forEach { symbol, title, subtitle in
            features.addArrangedSubview(MedicalAssistFeatureView(symbol: symbol, title: title, subtitle: subtitle))
        }

        let featureCard = UIView()
        featureCard.backgroundColor = .fdSurface
        featureCard.layer.cornerRadius = 16
        featureCard.addSubview(features)

        addSubview(photo)
        photo.addSubview(titleLabel)
        photo.addSubview(slogan)
        addSubview(featureCard)

        photo.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(240)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(28)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        slogan.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }
        featureCard.snp.makeConstraints {
            $0.top.equalTo(photo.snp.bottom).offset(-48)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-8)
        }
        features.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 18, left: 8, bottom: 14, right: 8))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class MedicalAssistSloganLabel: UILabel {
    var contentInsets = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }
}

private final class MedicalAssistFeatureView: UIView {

    init(symbol: String, title: String, subtitle: String) {
        super.init(frame: .zero)
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = .fdPrimary
        icon.contentMode = .scaleAspectFit
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .fdCaptionSemibold
        titleLabel.textColor = .fdText
        titleLabel.textAlignment = .center
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .fdFont(ofSize: 12)
        subtitleLabel.textColor = .fdSubtext
        subtitleLabel.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        addSubview(stack)
        icon.snp.makeConstraints { $0.size.equalTo(22) }
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
