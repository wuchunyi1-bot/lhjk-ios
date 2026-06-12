import UIKit
import SnapKit

/// 消息模块入口 — 会话列表
final class MessageListViewController: BaseViewController {
    override func setupUI() {
        title = "消息"

        let label = UILabel()
        label.text = "消息"
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        view.addSubview(label)

        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-30)
        }

        let conversationButton = UIButton(type: .system)
        conversationButton.setTitle("进入会话列表", for: .normal)
        conversationButton.titleLabel?.font = .systemFont(ofSize: 16)
        conversationButton.addAction(UIAction { [weak self] _ in
            let vc = ConversationListViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }, for: .touchUpInside)
        view.addSubview(conversationButton)

        conversationButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(label.snp.bottom).offset(20)
        }
    }
}
