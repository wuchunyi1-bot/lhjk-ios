import UIKit
import SnapKit

/// 每日健康任务卡片 Cell — 多项任务列表，含勾选、描述、积分
final class HomeTaskCardCell: UITableViewCell {

    static let reuseID = "HomeTaskCardCell"

    // MARK: - Data types

    struct Task {
        let title: String
        let description: String
        let points: Int
        let isDone: Bool
        let isHighlighted: Bool
    }

    // MARK: - UI

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = 18
        v.addFundeShadow()
        return v
    }()

    // MARK: - Callback

    var onTaskTapped: ((Int) -> Void)?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .fdBg
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(tasks: [Task]) {
        cardView.subviews.forEach { $0.removeFromSuperview() }
        if cardView.superview == nil {
            contentView.addSubview(cardView)
            cardView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(16)
                make.bottom.equalToSuperview()
            }
        }

        var prev: UIView?
        for (i, task) in tasks.enumerated() {
            let row = makeTaskRow(task, index: i, isLast: i == tasks.count - 1)
            cardView.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                if let p = prev {
                    make.top.equalTo(p.snp.bottom)
                } else {
                    make.top.equalToSuperview().offset(4)
                }
            }
            prev = row
        }
        prev?.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-4)
        }
    }

    // MARK: - Row builder

    private func makeTaskRow(_ t: Task, index: Int, isLast: Bool) -> UIView {
        let row = UIView()
        row.isUserInteractionEnabled = true

        let checkView = UIView()
        checkView.layer.cornerRadius = 13
        checkView.layer.borderWidth = 1.6

        if t.isDone {
            checkView.backgroundColor = .fdSuccess
            checkView.layer.borderColor = UIColor.fdSuccess.cgColor
            let chk = UIImageView(image: UIImage(systemName: "checkmark"))
            chk.tintColor = .white
            checkView.addSubview(chk)
            chk.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(14) }
        } else {
            checkView.backgroundColor = .clear
            checkView.layer.borderColor = UIColor.fdBorderStrong.cgColor
        }

        let titleLbl = UILabel()
        titleLbl.font = .fdBodySemibold
        if t.isDone {
            titleLbl.attributedText = NSAttributedString(
                string: t.title,
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: UIColor.fdMuted
                ]
            )
        } else {
            titleLbl.text = t.title
            titleLbl.textColor = .fdText
        }

        let descLbl = UILabel()
        descLbl.text = t.description
        descLbl.font = .fdMicro
        descLbl.textColor = .fdSubtext

        let ptsBg = UIView()
        ptsBg.layer.cornerRadius = 999
        let ptsLbl = UILabel()
        ptsLbl.text = "+\(t.points)"
        ptsLbl.font = .fdCaptionSemibold
        if t.isDone {
            ptsBg.backgroundColor = .fdSuccessSoft
            ptsLbl.textColor = .fdSuccess
        } else if t.isHighlighted {
            ptsBg.backgroundColor = .fdPrimary
            ptsLbl.textColor = .white
        } else {
            ptsBg.backgroundColor = .fdPrimarySoft
            ptsLbl.textColor = .fdPrimary
        }
        ptsBg.addSubview(ptsLbl)
        ptsLbl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)) }

        row.addSubview(checkView)
        row.addSubview(titleLbl)
        row.addSubview(descLbl)
        row.addSubview(ptsBg)

        checkView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview()
            make.size.equalTo(26)
        }
        titleLbl.snp.makeConstraints { make in
            make.top.equalTo(checkView)
            make.leading.equalTo(checkView.snp.trailing).offset(12)
        }
        descLbl.snp.makeConstraints { make in
            make.top.equalTo(titleLbl.snp.bottom).offset(2)
            make.leading.equalTo(titleLbl)
            make.bottom.equalToSuperview().offset(-14)
        }
        ptsBg.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
        }

        if !isLast {
            let div = UIView()
            div.backgroundColor = .fdBorder
            row.addSubview(div)
            div.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(1)
            }
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(taskTapped(_:)))
        row.addGestureRecognizer(tap)
        row.accessibilityValue = "\(index)"

        return row
    }

    @objc private func taskTapped(_ gesture: UITapGestureRecognizer) {
        guard let indexStr = gesture.view?.accessibilityValue, let idx = Int(indexStr) else { return }
        onTaskTapped?(idx)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cardView.subviews.forEach { $0.removeFromSuperview() }
        onTaskTapped = nil
    }
}
