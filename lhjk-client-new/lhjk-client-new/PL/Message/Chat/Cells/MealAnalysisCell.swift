import UIKit
import SnapKit

/// 餐食分析卡片 Cell — 营养师专属消息类型
final class MealAnalysisCell: UITableViewCell {
    static let reuseID = "MealAnalysisCell"

    private let cardView = UIView()
    private let headerLabel = UILabel()
    private let photoPlaceholder = UIView()
    private let annotationsStack = UIStackView()
    private let commentLabel = UILabel()
    private let fromLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        cardView.backgroundColor = .fdSurface
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 1)
        cardView.layer.shadowRadius = 4
        cardView.layer.shadowOpacity = 0.04
        cardView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]

        headerLabel.font = .fdFont(ofSize: 12, weight: .semibold)
        headerLabel.textColor = .fdPrimary

        photoPlaceholder.backgroundColor = UIColor(hexString: "#F5F0EB")
        photoPlaceholder.layer.cornerRadius = 10

        let photoIcon = UIImageView(image: UIImage(systemName: "photo.on.rectangle"))
        photoIcon.tintColor = .fdMuted
        photoIcon.contentMode = .scaleAspectFit
        let photoText = UILabel()
        photoText.text = "餐食照片"
        photoText.font = .fdFont(ofSize: 12)
        photoText.textColor = .fdMuted

        [photoIcon, photoText].forEach(photoPlaceholder.addSubview)
        photoIcon.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(28)
        }
        photoText.snp.makeConstraints { make in
            make.top.equalTo(photoIcon.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-8)
        }

        annotationsStack.axis = .vertical
        annotationsStack.spacing = 7

        commentLabel.font = .fdFont(ofSize: 13)
        commentLabel.textColor = .fdSubtext
        commentLabel.numberOfLines = 0

        fromLabel.font = .fdFont(ofSize: 11)
        fromLabel.textColor = .fdSubtext
        fromLabel.textAlignment = .right

        contentView.addSubview(cardView)
        [headerLabel, photoPlaceholder, annotationsStack, commentLabel, fromLabel].forEach(cardView.addSubview)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.equalToSuperview().offset(50)
            make.width.lessThanOrEqualTo(300)
            make.bottom.equalToSuperview().offset(-6)
        }

        headerLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(14)
        }

        photoPlaceholder.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(14)
            make.height.equalTo(80)
        }

        annotationsStack.snp.makeConstraints { make in
            make.top.equalTo(photoPlaceholder.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        commentLabel.snp.makeConstraints { make in
            make.top.equalTo(annotationsStack.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        fromLabel.snp.makeConstraints { make in
            make.top.equalTo(commentLabel.snp.bottom).offset(6)
            make.trailing.equalToSuperview().offset(-14)
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ msg: ChatMessage) {
        guard let meal = msg.meal else { return }
        headerLabel.text = "\(meal.label) · 营养师分析"

        annotationsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for a in meal.annotations {
            let row = makeAnnotation(a)
            annotationsStack.addArrangedSubview(row)
        }

        commentLabel.text = meal.comment
        fromLabel.text = "— \(meal.from)"
    }

    private func makeAnnotation(_ a: MealAnnotation) -> UIView {
        let bgColors: [MealAnnotationTag: String] = [
            .danger: "#FFF0EE", .success: "#F0FAF4", .warning: "#FFFBE6"
        ]
        let dotColors: [MealAnnotationTag: String] = [
            .danger: "#FF4D4F", .success: "#52B96A", .warning: "#B47300"
        ]

        let v = UIView()
        v.backgroundColor = UIColor(hexString: bgColors[a.tag] ?? "#F5F5F5")
        v.layer.cornerRadius = 8

        let dot = UIView()
        dot.backgroundColor = UIColor(hexString: dotColors[a.tag] ?? "#999")
        dot.layer.cornerRadius = 4

        let textLabel = UILabel()
        textLabel.text = a.text
        textLabel.font = .fdFont(ofSize: 13, weight: .semibold)
        textLabel.textColor = .fdText

        let tipLabel = UILabel()
        tipLabel.text = a.tip
        tipLabel.font = .fdFont(ofSize: 11)
        tipLabel.textColor = .fdSubtext

        [dot, textLabel, tipLabel].forEach(v.addSubview)
        dot.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(10)
            make.size.equalTo(8)
        }
        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(dot.snp.trailing).offset(8)
            make.centerY.equalTo(dot)
        }
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(textLabel.snp.bottom).offset(2)
            make.leading.equalTo(textLabel)
            make.trailing.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-8)
        }

        return v
    }
}
