import SnapKit
import UIKit

/// 今日健康任务卡 — 对齐 Figma 3444:6583
final class HomeTaskCardCell: UITableViewCell {

    static let reuseID = "HomeTaskCardCell"

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
        l.font = .fdFont(ofSize: 16, weight: .medium)
        l.textColor = .fdText
        return l
    }()

    private let moreButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = .fdFont(ofSize: 12, weight: .regular)
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
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let progressTrackView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#FFEAE4")
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        return v
    }()

    private let progressFillView: StripedGradientProgressFillView = {
        let v = StripedGradientProgressFillView()
        return v
    }()

    private let progressCountLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .medium)
        l.textColor = UIColor(hexString: "#FF7A50")
        l.textAlignment = .right
        return l
    }()

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

        moreButton.addTarget(self, action: #selector(viewAll), for: .touchUpInside)
    }

    private func setupConstraints() {
        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16).priority(750)
            $0.bottom.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(15)
        }

        moreButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(12)
        }

        bannerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.height.equalTo(76)
        }

        bannerImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        progressCountLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().offset(-12)
        }

        progressTrackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalTo(progressCountLabel)
            $0.height.equalTo(8)
            $0.trailing.equalTo(progressCountLabel.snp.leading).offset(-12)
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

    func configure(
        previewTasks: [DailyHealthTask],
        doneCount: Int,
        totalCount: Int
    ) {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        progressCountLabel.text = "\(doneCount)/\(max(totalCount, 0))"

        let ratio: CGFloat = totalCount > 0 ? min(1.0, max(0.0, CGFloat(doneCount) / CGFloat(totalCount))) : 0.0

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

    private func buildTaskRow(_ task: DailyHealthTask) -> UIView {
        let row = UIView()
        row.backgroundColor = UIColor(hexString: "#FFF9F7")
        row.layer.cornerRadius = 12
        row.clipsToBounds = true

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(named: "home_task_icon")
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.clipsToBounds = true

        let title = UILabel()
        title.font = .fdFont(ofSize: 14, weight: .medium)
        title.textColor = .fdText
        title.text = task.shortTitle.isEmpty ? task.title : task.shortTitle

        let tagsStack = UIStackView()
        tagsStack.axis = .horizontal
        tagsStack.spacing = 6
        tagsStack.alignment = .center

        if !task.planTime.isEmpty {
            tagsStack.addArrangedSubview(makeTimeTag(time: task.planTime))
        }

        let categoryText = task.category.isEmpty ? "监测任务" : task.category
        tagsStack.addArrangedSubview(makeCategoryTag(text: categoryText))

        let action = UIButton(type: .system)
        action.titleLabel?.font = .fdFont(ofSize: 12, weight: .medium)
        action.layer.cornerRadius = 14
        action.clipsToBounds = true

        if task.done {
            action.setTitle("已完成", for: .normal)
            action.setTitleColor(UIColor(hexString: "#969799"), for: .normal)
            action.backgroundColor = UIColor(hexString: "#F5F6F7")
            action.isEnabled = false
        } else {
            action.setTitle("去完成", for: .normal)
            action.setTitleColor(.white, for: .normal)
            action.backgroundColor = UIColor(hexString: "#FF7950")
            action.isEnabled = true
            action.addAction(UIAction { [weak self] _ in
                self?.onTaskAction?(task)
            }, for: .touchUpInside)
        }

        row.addSubview(iconImageView)
        row.addSubview(title)
        row.addSubview(tagsStack)
        row.addSubview(action)

        row.snp.makeConstraints {
            $0.height.equalTo(68)
        }

        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(10)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(48)
        }

        action.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(70)
            $0.height.equalTo(28)
        }

        title.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(12)
            $0.top.equalToSuperview().offset(14)
            $0.trailing.lessThanOrEqualTo(action.snp.leading).offset(-8)
        }

        tagsStack.snp.makeConstraints {
            $0.leading.equalTo(title)
            $0.top.equalTo(title.snp.bottom).offset(6)
            $0.trailing.lessThanOrEqualTo(action.snp.leading).offset(-8)
        }

        return row
    }

    private func makeTimeTag(time: String) -> UIView {
        let tag = UIView()
        tag.layer.cornerRadius = 4
        tag.layer.borderWidth = 0.5
        tag.layer.borderColor = UIColor(hexString: "#8591AB").withAlphaComponent(0.5).cgColor

        let icon = UIImageView(
            image: UIImage(
                systemName: "clock",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .regular)
            )
        )
        icon.tintColor = UIColor(hexString: "#8591AB")
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = time
        label.font = .fdFont(ofSize: 10, weight: .regular)
        label.textColor = UIColor(hexString: "#8591AB")

        tag.addSubview(icon)
        tag.addSubview(label)

        icon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(4)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(10)
        }

        label.snp.makeConstraints {
            $0.leading.equalTo(icon.snp.trailing).offset(2)
            $0.trailing.equalToSuperview().inset(4)
            $0.top.bottom.equalToSuperview().inset(2)
        }

        return tag
    }

    private func makeCategoryTag(text: String) -> UIView {
        let tag = UIView()
        tag.layer.cornerRadius = 4
        tag.layer.borderWidth = 0.5
        tag.layer.borderColor = UIColor(hexString: "#FF7950").withAlphaComponent(0.5).cgColor

        let label = UILabel()
        label.text = text
        label.font = .fdFont(ofSize: 10, weight: .regular)
        label.textColor = UIColor(hexString: "#FF7950")

        tag.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(6)
            $0.top.bottom.equalToSuperview().inset(2)
        }

        return tag
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

        // 1. 绘制水平线性渐变 (#FFA450 -> #FF7A50)
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

        // 2. 绘制半透明斜向螺旋纹/条纹 (#FFC7B5, 40% 不透明度)
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
