import SnapKit
import UIKit

/// 今日健康任务详情页顶部进度 Hero — `home_task_header_bg` + `home_task_header_word`
final class DailyTasksHeroView: UIView {

    private static let headerBgFallbackRatio: CGFloat = 144.0 / 343.0
    private static let titleWordAspect: CGFloat = 282.0 / 43.0
    /// 背景图中间分隔线约在 52% 高度处
    private static let bottomPanelHeightRatio: CGFloat = 0.48

    private let bgImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "home_task_header_bg")
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let titleWordImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "home_task_header_word")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let countLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 36, weight: .medium)
        l.textColor = .white
        l.textAlignment = .right
        return l
    }()

    private let bottomPanel = UIView()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "坚持完成每日任务，帮助健管师更好跟进您的健康状态"
        l.font = .fdFont(ofSize: 13, weight: .regular)
        l.textColor = UIColor.white.withAlphaComponent(0.85)
        l.numberOfLines = 0
        return l
    }()

    private let progressTrackView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        return v
    }()

    private let progressFillView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 4
        return v
    }()

    private var heightConstraint: Constraint?
    private var progressFillWidthConstraint: Constraint?
    private var titleWordWidthConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateHeightIfNeeded()
        updateTitleWordWidthIfNeeded()
    }

    func configure(doneCount: Int, totalCount: Int) {
        countLabel.text = "\(doneCount) / \(max(totalCount, 0))"
        let ratio: CGFloat = totalCount > 0
            ? min(1.0, max(0.0, CGFloat(doneCount) / CGFloat(totalCount)))
            : 0.0

        progressFillView.isHidden = ratio <= 0
        progressFillWidthConstraint?.deactivate()
        progressFillView.snp.remakeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            if ratio > 0 {
                progressFillWidthConstraint = make.width
                    .equalTo(progressTrackView.snp.width)
                    .multipliedBy(ratio)
                    .constraint
            } else {
                progressFillWidthConstraint = make.width.equalTo(0).constraint
            }
        }
    }

    private func setupUI() {
        layer.cornerRadius = 18
        clipsToBounds = true

        addSubview(bgImageView)
        addSubview(titleWordImageView)
        addSubview(countLabel)
        addSubview(bottomPanel)
        bottomPanel.addSubview(subtitleLabel)
        bottomPanel.addSubview(progressTrackView)
        progressTrackView.addSubview(progressFillView)

        bgImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        snp.makeConstraints { make in
            heightConstraint = make.height.equalTo(144).constraint
        }

        // 上半区：标题图略下移，与完成数字垂直居中对齐
        titleWordImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(18)
            titleWordWidthConstraint = make.width.equalTo(18 * Self.titleWordAspect).constraint
        }

        countLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleWordImageView)
            make.trailing.equalToSuperview().inset(16)
            make.leading.greaterThanOrEqualTo(titleWordImageView.snp.trailing).offset(8)
        }

        // 下半区（分隔线以下）：说明文案 + 进度条
        bottomPanel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(Self.bottomPanelHeightRatio)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().inset(12)
        }

        progressTrackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(18)
            make.height.equalTo(8)
            make.top.greaterThanOrEqualTo(subtitleLabel.snp.bottom).offset(10)
        }

        progressFillView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            progressFillWidthConstraint = make.width.equalTo(0).constraint
        }
    }

    private func updateHeightIfNeeded() {
        let width = bounds.width
        guard width > 1 else { return }
        let height = BannerImageAspectLayout.height(
            width: width,
            imageSize: bgImageView.image?.size,
            fallbackRatio: Self.headerBgFallbackRatio
        )
        heightConstraint?.update(offset: max(144, height))
    }

    private func updateTitleWordWidthIfNeeded() {
        titleWordWidthConstraint?.update(offset: 18 * Self.titleWordAspect)
    }
}
