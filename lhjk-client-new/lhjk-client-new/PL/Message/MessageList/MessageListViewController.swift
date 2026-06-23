import UIKit
import SnapKit

/// 消息模块入口页
final class MessageListViewController: BaseViewController {
    override func setupUI() {
        title = "消息"
        view.backgroundColor = .fdBg

        let convList = ConversationListViewController()
        addChild(convList)
        view.addSubview(convList.view)
        convList.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        convList.didMove(toParent: self)
    }
}
