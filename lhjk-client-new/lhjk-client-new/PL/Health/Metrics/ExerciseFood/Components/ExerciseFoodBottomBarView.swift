import UIKit
import SnapKit

final class ExerciseFoodBottomBarView: UIView {

    var onAction: ((Int) -> Void)?

    private let stack = UIStackView()

    private let actions: [(String, String)] = [
        ("+早餐", "sun.max"),
        ("+午餐", "sun.haze"),
        ("+晚餐", "moon"),
        ("+加餐", "plus.circle"),
        ("+运动", "figure.run"),
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .fdSurface

        let line = UIView()
        line.backgroundColor = .fdBorder
        addSubview(line)
        line.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(line.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(52)
        }

        for (index, action) in actions.enumerated() {
            let button = UIButton(type: .system)
            var config = UIButton.Configuration.plain()
            config.image = UIImage(systemName: action.1)
            config.title = action.0
            config.imagePlacement = .top
            config.imagePadding = 4
            config.baseForegroundColor = .fdSubtext
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .fdMicro
                return outgoing
            }
            button.configuration = config
            button.tag = index
            button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped(_ sender: UIButton) {
        onAction?(sender.tag)
    }
}
