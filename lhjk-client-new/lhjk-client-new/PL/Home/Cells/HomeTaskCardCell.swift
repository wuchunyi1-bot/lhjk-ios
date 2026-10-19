import SnapKit
import UIKit

/// 今日健康任务卡 — 对齐 Figma 3782:15108
final class HomeTaskCardCell: UITableViewCell {

    static let reuseID = "HomeTaskCardCell"

    /// 切图 `home_task_progress_banner` @3x 957×198。未读到图片尺寸时用这个比。
    private static let progressBannerFallbackRatio: CGFloat = 198.0 / 957.0
    /// 卡片左右 16 + 进度条相对卡片左右 12
    private static let bannerHorizontalInset: CGFloat = 56

    var onTaskAction: ((DailyHealthTask) -> Void)?
    var onViewAll: (() -> Void)?

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "今日健康任务"
        l.font = .fdFont(ofSize: 18, weight: .medium)
        l.textColor = .fdText
        l.setContentCompressionResistancePriority(.required, for: .vertical)
        l.setContentHuggingPriority(.required, for: .vertical)
        return l
    }()

    private let moreButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = .fdFont(ofSize: 14, weight: .regular)
        b.setTitleColor(.fdSubtext, for: .normal)
        b.setTitle("查看全部", for: .normal)
        let chevron = UIImage(
            systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .regular)
        )
        b.setImage(chevron, for: .normal)
        b.tintColor = .fdSubtext
        b.semanticContentAttribute = .forceRightToLeft
        b.imageEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        return b
    }()

    // MARK: - Banner (今日进度)

    private let bannerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#FDF6F3")
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        return v
    }()

    private let bannerImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "home_task_progress_banner")
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = false
        return iv
    }()

    private let progressTrackView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#FFEAE4")
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        return v
    }()

    private let progressFillView = StripedGradientProgressFillView()

    private let progressCountLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .medium)
        l.textColor = UIColor(hexString: "#FF7A50")
        l.textAlignment = .right
        return l
    }()

    private var bannerHeightConstraint: Constraint?
    private var appliedBannerHeight: CGFloat = 66
    private var appliedImageHeight: CGFloat = 66
    private var heightRefreshScheduled = false

    // MARK: - Task Stack

    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 10
        return s
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if applyBannerHeights(cellWidth: contentView.bounds.width) {
            scheduleRowHeightRefresh()
        }
    }

    /// 量行高时进度条往往还没有宽度，不能等 `layoutSubviews` 再改高度，否则多出来的高度会压扁标题。
    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        var size = targetSize
        if size.width <= 1, let tableView = enclosingTableView {
            size.width = tableView.bounds.width
        }
        _ = applyBannerHeights(cellWidth: size.width)
        return super.systemLayoutSizeFitting(
            size,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: verticalFittingPriority
        )
    }

    private func setupHierarchy() {
        contentView.addSubview(cardView)

        cardView.addSubview(titleLabel)
        cardView.addSubview(moreButton)
        cardView.addSubview(bannerView)

        bannerView.addSubview(bannerImageView)
        bannerView.addSubview(progressTrackView)
        progressTrackView.addSubview(progressFillView)
        bannerView.addSubview(progressCountLabel)

        cardView.addSubview(contentStack)

        bannerView.sendSubviewToBack(bannerImageView)

        moreButton.addTarget(self, action: #selector(viewAll), for: .touchUpInside)
    }

    private func setupConstraints() {
        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16).priority(750)
            $0.bottom.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(16)
        }

        moreButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(12)
        }

        bannerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(12)
            bannerHeightConstraint = make.height.equalTo(66).constraint
        }

        bannerImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(66)
        }

        progressCountLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(13)
            make.trailing.equalToSuperview().inset(6)
        }

        progressTrackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(8)
        }

        progressFillView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(0)
        }

        contentStack.snp.makeConstraints {
            $0.top.equalTo(bannerView.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().inset(16)
        }
    }

    /// 按单元格宽度直接算进度条高度。返回是否改了约束。
    @discardableResult
    private func applyBannerHeights(cellWidth: CGFloat) -> Bool {
        let bannerWidth = max(0, cellWidth - Self.bannerHorizontalInset)
        guard bannerWidth > 1 else { return false }

        let imageHeight = BannerImageAspectLayout.height(
            width: bannerWidth,
            imageSize: bannerImageView.image?.size,
            fallbackRatio: Self.progressBannerFallbackRatio
        )
        let bannerHeight = max(66, imageHeight)
        guard abs(bannerHeight - appliedBannerHeight) > 0.5
            || abs(imageHeight - appliedImageHeight) > 0.5 else {
            return false
        }
        appliedBannerHeight = bannerHeight
        appliedImageHeight = imageHeight
        bannerHeightConstraint?.update(offset: bannerHeight)
        bannerImageView.snp.updateConstraints { $0.height.equalTo(imageHeight) }
        return true
    }

    private func scheduleRowHeightRefresh() {
        guard !heightRefreshScheduled else { return }
        heightRefreshScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.heightRefreshScheduled = false
            guard let tableView = self.enclosingTableView else { return }
            UIView.performWithoutAnimation {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }

    private var enclosingTableView: UITableView? {
        var view: UIView? = superview
        while let current = view {
            if let tableView = current as? UITableView { return tableView }
            view = current.superview
        }
        return nil
    }

    func configure(
        previewTasks: [DailyHealthTask],
        doneCount: Int,
        totalCount: Int,
        earnedPoints: Int
    ) {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        progressCountLabel.text = Self.progressSummaryText(
            doneCount: doneCount,
            totalCount: totalCount,
            earnedPoints: earnedPoints
        )

        let ratio: CGFloat = totalCount > 0
            ? min(1.0, max(0.0, CGFloat(doneCount) / CGFloat(totalCount)))
            : 0.0

        if ratio <= 0 {
            progressFillView.isHidden = true
            progressFillView.snp.remakeConstraints {
                $0.leading.top.bottom.equalToSuperview()
                $0.width.equalTo(0)
            }
        } else {
            progressFillView.isHidden = false
            progressFillView.snp.remakeConstraints {
                $0.leading.top.bottom.equalToSuperview()
                $0.width.equalTo(progressTrackView.snp.width).multipliedBy(ratio)
            }
            progressFillView.setNeedsDisplay()
        }

        setNeedsLayout()

        if totalCount == 0 {
            let wrap = UIView()
            let empty = UILabel()
            empty.text = "今日暂无健康任务"
            empty.font = .fdBody
            empty.textColor = .fdSubtext
            empty.textAlignment = .center
            wrap.addSubview(empty)
            empty.snp.makeConstraints {
                $0.edges.equalToSuperview().inset(20)
            }
            contentStack.addArrangedSubview(wrap)
            return
        }

        for task in previewTasks {
            contentStack.addArrangedSubview(buildTaskRow(task))
        }
    }

    private static func progressSummaryText(
        doneCount: Int,
        totalCount: Int,
        earnedPoints: Int
    ) -> String {
        let progress = "\(doneCount)/\(max(totalCount, 0))"
        guard earnedPoints > 0 else { return progress }
        return "\(progress)｜+\(earnedPoints)分"
    }

    private func buildTaskRow(_ task: DailyHealthTask) -> UIView {
        let row = UIView()
        row.backgroundColor = UIColor(hexString: "#FFF9F7")
        row.layer.cornerRadius = 12
        row.clipsToBounds = true

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(named: "home_task_icon_high")
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.clipsToBounds = true

        let titleRow = UIStackView()
        titleRow.axis = .horizontal
        titleRow.spacing = 6
        titleRow.alignment = .center

        let title = UILabel()
        title.font = .fdFont(ofSize: 16, weight: .medium)
        title.textColor = task.done ? UIColor(hexString: "#8591AB") : .fdText
        title.text = task.shortTitle.isEmpty ? task.title : task.shortTitle
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        titleRow.addArrangedSubview(title)
        if let badge = makePointsBadge(points: task.rewardPoints) {
            titleRow.addArrangedSubview(badge)
        }

        let subtitle = UILabel()
        subtitle.font = .fdFont(ofSize: 12, weight: .regular)
        subtitle.textColor = UIColor(hexString: "#8591AB")
        subtitle.numberOfLines = 1
        subtitle.lineBreakMode = .byTruncatingTail
        let subtitleText = task.homeSubtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        subtitle.text = subtitleText.isEmpty ? task.desc : subtitleText

        let action = UIButton(type: .system)
        action.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        action.clipsToBounds = true
        action.titleLabel?.lineBreakMode = .byClipping
        let buttonSize = Self.actionButtonSize()
        action.layer.cornerRadius = buttonSize.height / 2

        if task.done {
            action.setTitle("已完成", for: .normal)
            action.setTitleColor(UIColor(hexString: "#FF7950"), for: .normal)
            action.backgroundColor = .clear
            action.layer.borderWidth = 0.5
            action.layer.borderColor = UIColor(hexString: "#FF7950").cgColor
            action.isEnabled = false
        } else {
            action.setTitle("去完成", for: .normal)
            action.setTitleColor(.white, for: .normal)
            action.backgroundColor = UIColor(hexString: "#FF7950")
            action.layer.borderWidth = 0
            action.layer.borderColor = nil
            action.isEnabled = true
            action.addAction(UIAction { [weak self] _ in
                self?.onTaskAction?(task)
            }, for: .touchUpInside)
        }

        row.addSubview(iconImageView)
        row.addSubview(titleRow)
        row.addSubview(subtitle)
        row.addSubview(action)

        row.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(68)
        }

        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(10)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(48)
        }

        action.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(buttonSize.width)
            $0.height.equalTo(buttonSize.height)
        }

        titleRow.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(14)
            make.trailing.lessThanOrEqualTo(action.snp.leading).offset(-8)
        }

        subtitle.snp.makeConstraints { make in
            make.leading.equalTo(titleRow)
            make.top.equalTo(titleRow.snp.bottom).offset(4)
            make.trailing.lessThanOrEqualTo(action.snp.leading).offset(-8)
            make.bottom.lessThanOrEqualToSuperview().offset(-14)
        }

        return row
    }

    /// 普通模式 70×28。长辈模式按「去完成」字号加宽加高。
    private static func actionButtonSize() -> CGSize {
        guard UIFont.isSeniorMode else { return CGSize(width: 70, height: 28) }
        let font = UIFont.fdFont(ofSize: 14, weight: .medium)
        let textWidth = ceil(("去完成" as NSString).size(withAttributes: [.font: font]).width)
        return CGSize(width: max(88, textWidth + 32), height: 36)
    }

    private func makePointsBadge(points: Int?) -> UIView? {
        guard let points, points > 0 else { return nil }

        let wrap = UIView()
        wrap.setContentHuggingPriority(.required, for: .horizontal)
        wrap.setContentCompressionResistancePriority(.required, for: .horizontal)

        let bg = UIImageView(image: UIImage(named: "home_task_goal"))
        bg.contentMode = .scaleToFill

        let label = UILabel()
        label.text = "+\(points)"
        label.font = .fdFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor(hexString: "#FFAC00")
        label.textAlignment = .left

        wrap.addSubview(bg)
        wrap.addSubview(label)

        wrap.snp.makeConstraints {
            $0.height.equalTo(18)
            $0.width.equalTo(44)
        }
        bg.snp.makeConstraints { $0.edges.equalToSuperview() }
        // 背景图左侧为金币图标，数字略靠右（对齐 Figma 3782:15179 x≈21.5/44）
        label.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(21)
            $0.trailing.equalToSuperview().inset(3)
            $0.centerY.equalToSuperview()
        }

        return wrap
    }

    @objc private func viewAll() {
        onViewAll?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTaskAction = nil
        onViewAll = nil
    }
}

// MARK: - StripedGradientProgressFillView (渐变 + 单色透明斜向螺旋纹条纹)

/// 渐变 + 单色透明斜向螺旋纹/条纹进度填充视图 — 对齐 Figma 3444:6602
final class StripedGradientProgressFillView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = true
        layer.cornerRadius = 4
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        clipsToBounds = true
        layer.cornerRadius = 4
        contentMode = .redraw
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), rect.width > 0, rect.height > 0 else { return }

        let clipPath = UIBezierPath(roundedRect: rect, cornerRadius: rect.height / 2)
        ctx.addPath(clipPath.cgPath)
        ctx.clip()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let startColor = UIColor(hexString: "#FFA450").cgColor
        let endColor = UIColor(hexString: "#FF7A50").cgColor
        if let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: [startColor, endColor] as CFArray,
            locations: [0.0, 1.0]
        ) {
            ctx.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: rect.midY),
                end: CGPoint(x: rect.width, y: rect.midY),
                options: []
            )
        }

        let stripeColor = UIColor(hexString: "#FFC7B5").withAlphaComponent(0.4)
        ctx.setFillColor(stripeColor.cgColor)

        let stripeWidth: CGFloat = 6.0
        let period: CGFloat = 11.0
        let h = rect.height
        let slantDx: CGFloat = h * (11.0 / 15.0)

        var startX: CGFloat = -slantDx - period
        while startX < rect.width + slantDx + period {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: startX + slantDx, y: 0))
            p.addLine(to: CGPoint(x: startX + slantDx + stripeWidth, y: 0))
            p.addLine(to: CGPoint(x: startX + stripeWidth, y: h))
            p.addLine(to: CGPoint(x: startX, y: h))
            p.close()
            ctx.addPath(p.cgPath)
            ctx.fillPath()

            startX += period
        }
    }
}
