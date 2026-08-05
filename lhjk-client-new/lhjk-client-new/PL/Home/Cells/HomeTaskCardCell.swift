import SnapKit
import UIKit

/// 今日健康任务卡 — 对齐 Figma：卡内标题 + 进度文案 + 任务行（积分 / 描边按钮）
final class HomeTaskCardCell: UITableViewCell {

    static let reuseID = "HomeTaskCardCell"

    var onTaskAction: ((DailyHealthTask) -> Void)?
    var onViewAll: (() -> Void)?

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = 16
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
        return b
    }()

    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        return s
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(moreButton)
        cardView.addSubview(contentStack)

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
            $0.trailing.equalToSuperview().inset(8)
        }
        contentStack.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(8)
        }

        moreButton.addTarget(self, action: #selector(viewAll), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(
        previewTasks: [DailyHealthTask],
        doneCount: Int,
        totalCount: Int
    ) {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let earned = previewTasks.filter(\.done).count * 5 + (doneCount > 0 ? 5 : 0)
        moreButton.setTitle("已完成 \(doneCount)/\(max(totalCount, 0)) ｜+\(earned)分 ›", for: .normal)

        if totalCount == 0 {
            let empty = UILabel()
            empty.text = "今日暂无健康任务"
            empty.font = .fdBody
            empty.textColor = .fdSubtext
            empty.textAlignment = .center
            let wrap = UIView()
            wrap.addSubview(empty)
            empty.snp.makeConstraints { $0.edges.equalToSuperview().inset(20) }
            contentStack.addArrangedSubview(wrap)
            return
        }

        for (i, task) in previewTasks.enumerated() {
            contentStack.addArrangedSubview(buildTaskRow(task, points: displayPoints(for: task, index: i)))
            if i < previewTasks.count - 1 {
                contentStack.addArrangedSubview(makeDivider())
            }
        }
    }

    private func displayPoints(for task: DailyHealthTask, index: Int) -> Int {
        // 设计稿示例分值；真实积分字段接入前按序占位
        let defaults = [5, 10, 20]
        return defaults[min(index, defaults.count - 1)]
    }

    private func makeDivider() -> UIView {
        let wrap = UIView()
        let div = UIView()
        div.backgroundColor = UIColor.fdBorder.withAlphaComponent(0.8)
        wrap.addSubview(div)
        div.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(11)
            $0.top.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
        return wrap
    }

    private func buildTaskRow(_ task: DailyHealthTask, points: Int) -> UIView {
        let row = UIView()

        let title = UILabel()
        title.font = .fdFont(ofSize: 14, weight: .medium)
        title.textColor = .fdText
        title.text = task.shortTitle.isEmpty ? task.title : task.shortTitle

        let pointsLabel = UILabel()
        let attr = NSMutableAttributedString(
            string: "+\(points)",
            attributes: [
                .font: UIFont.fdFont(ofSize: 14, weight: .medium),
                .foregroundColor: task.done ? UIColor.fdSubtext : UIColor.fdPrimary,
            ]
        )
        attr.append(NSAttributedString(
            string: "分",
            attributes: [
                .font: UIFont.fdFont(ofSize: 13, weight: .medium),
                .foregroundColor: task.done ? UIColor.fdSubtext : UIColor.fdPrimary,
            ]
        ))
        pointsLabel.attributedText = attr

        let desc = UILabel()
        desc.text = task.desc.isEmpty ? (task.planTime.isEmpty ? "请按时完成今日任务" : "建议 \(task.planTime) 完成") : task.desc
        desc.font = .fdFont(ofSize: 12, weight: .regular)
        desc.textColor = .fdSubtext
        desc.numberOfLines = 1

        let action = UIButton(type: .system)
        action.titleLabel?.font = .fdFont(ofSize: 12, weight: .medium)
        action.layer.cornerRadius = 14
        action.layer.borderWidth = 0.5
        action.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        if task.done {
            action.setTitle("已完成", for: .normal)
            action.setTitleColor(.fdSubtext, for: .normal)
            action.layer.borderColor = UIColor.fdSubtext.cgColor
            action.isEnabled = false
        } else {
            action.setTitle("去完成", for: .normal)
            action.setTitleColor(.fdPrimary, for: .normal)
            action.layer.borderColor = UIColor.fdPrimary.cgColor
            action.addAction(UIAction { [weak self] _ in
                self?.onTaskAction?(task)
            }, for: .touchUpInside)
        }

        row.addSubview(title)
        row.addSubview(pointsLabel)
        row.addSubview(desc)
        row.addSubview(action)

        title.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(14)
        }
        pointsLabel.snp.makeConstraints {
            $0.leading.equalTo(title.snp.trailing).offset(8)
            $0.centerY.equalTo(title)
            $0.trailing.lessThanOrEqualTo(action.snp.leading).offset(-8)
        }
        desc.snp.makeConstraints {
            $0.leading.equalTo(title)
            $0.top.equalTo(title.snp.bottom).offset(6)
            $0.trailing.lessThanOrEqualTo(action.snp.leading).offset(-8)
            $0.bottom.equalToSuperview().offset(-14)
        }
        action.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(13)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(70)
            $0.height.equalTo(28)
        }

        return row
    }

    @objc private func viewAll() { onViewAll?() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTaskAction = nil
        onViewAll = nil
    }
}
