import UIKit
import SnapKit

/// 我的设备
/// 参考 funde-client: DevicesView.vue
final class DevicesViewController: BaseViewController {

    private let scrollView = UIScrollView()

    private let pairedDevices: [(emoji: String, name: String, brand: String, model: String, lastSync: String, battery: Int, connected: Bool)] = [
        ("🩺", "上臂式血压计", "欧姆龙", "HEM-7124", "今天 07:30", 82, true),
        ("⌚", "健康手环", "华为", "Band 8", "今天 08:15", 45, false),
    ]

    override func setupUI() {
        title = "我的设备"
        view.backgroundColor = .fdBg

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 20, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        // Section title
        let titleRow = UIStackView()
        titleRow.axis = .horizontal
        titleRow.alignment = .lastBaseline
        titleRow.distribution = .equalSpacing
        let titleLbl = UILabel()
        titleLbl.text = "已配对设备"
        titleLbl.font = .fdBodySemibold
        titleLbl.textColor = .fdSubtext
        let countLbl = UILabel()
        let online = pairedDevices.filter(\.connected).count
        countLbl.text = "\(online) 台在线"
        countLbl.font = .fdCaption
        countLbl.textColor = .fdSubtext
        titleRow.addArrangedSubview(titleLbl)
        titleRow.addArrangedSubview(countLbl)
        stack.addArrangedSubview(titleRow)

        // Device cards
        for d in pairedDevices {
            stack.addArrangedSubview(buildDeviceCard(d))
        }

        // Add device button
        let addBtn = UIButton(type: .system)
        addBtn.setTitle("添加新设备", for: .normal)
        addBtn.titleLabel?.font = .fdBodySemibold
        addBtn.setTitleColor(.white, for: .normal)
        addBtn.backgroundColor = .fdPrimary
        addBtn.layer.cornerRadius = 14
        addBtn.snp.makeConstraints { $0.height.equalTo(50) }
        stack.addArrangedSubview(addBtn)

        // Tip card
        let tipCard = buildTipCard()
        stack.addArrangedSubview(tipCard)
    }

    private func buildDeviceCard(_ d: (emoji: String, name: String, brand: String, model: String, lastSync: String, battery: Int, connected: Bool)) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdBorder.cgColor
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03

        let emojiBg = UIView()
        emojiBg.backgroundColor = .fdBg2
        emojiBg.layer.cornerRadius = 12
        let emojiLbl = UILabel()
        emojiLbl.text = d.emoji
        emojiLbl.font = .fdH1
        emojiBg.addSubview(emojiLbl)
        emojiLbl.snp.makeConstraints { $0.center.equalToSuperview() }

        let nameLbl = UILabel()
        nameLbl.text = d.name
        nameLbl.font = .fdBodyBold
        nameLbl.textColor = .fdText

        let modelLbl = UILabel()
        modelLbl.text = "\(d.brand) · \(d.model)"
        modelLbl.font = .fdCaption
        modelLbl.textColor = .fdSubtext

        let syncLbl = UILabel()
        syncLbl.text = "上次同步：\(d.lastSync)"
        syncLbl.font = .fdMicro
        syncLbl.textColor = .fdSubtext

        let batteryLbl = UILabel()
        batteryLbl.text = "🔋 \(d.battery)%"
        batteryLbl.font = .fdMicroSemibold
        batteryLbl.textColor = d.battery > 50 ? .fdSuccess : d.battery > 20 ? .fdWarning : .fdDanger

        // Status dot
        let dot = UIView()
        dot.layer.cornerRadius = 5
        dot.backgroundColor = d.connected ? .fdSuccess : UIColor(hexString: "#CCCCCC")

        let statusLbl = UILabel()
        statusLbl.text = d.connected ? "已连接" : "未连接"
        statusLbl.font = .fdMicro
        statusLbl.textColor = .fdSubtext

        let unpairBtn = UIButton(type: .system)
        unpairBtn.setTitle("解绑", for: .normal)
        unpairBtn.titleLabel?.font = .fdMicro
        unpairBtn.setTitleColor(.fdSubtext, for: .normal)
        unpairBtn.layer.borderWidth = 1
        unpairBtn.layer.borderColor = UIColor.fdBorder.cgColor
        unpairBtn.layer.cornerRadius = 6
        unpairBtn.contentEdgeInsets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)

        let statusCol = UIStackView()
        statusCol.axis = .vertical
        statusCol.alignment = .center
        statusCol.spacing = 2
        statusCol.addArrangedSubview(dot)
        statusCol.addArrangedSubview(statusLbl)
        statusCol.addArrangedSubview(unpairBtn)

        card.addSubview(emojiBg)
        card.addSubview(nameLbl)
        card.addSubview(modelLbl)
        card.addSubview(syncLbl)
        card.addSubview(batteryLbl)
        card.addSubview(statusCol)

        emojiBg.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        nameLbl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalTo(emojiBg.snp.trailing).offset(12)
        }
        modelLbl.snp.makeConstraints { make in
            make.top.equalTo(nameLbl.snp.bottom).offset(2)
            make.leading.equalTo(nameLbl)
        }
        syncLbl.snp.makeConstraints { make in
            make.top.equalTo(modelLbl.snp.bottom).offset(4)
            make.leading.equalTo(nameLbl)
        }
        batteryLbl.snp.makeConstraints { make in
            make.leading.equalTo(syncLbl.snp.trailing).offset(10)
            make.centerY.equalTo(syncLbl)
            make.bottom.equalToSuperview().offset(-14)
        }
        statusCol.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(52)
        }
        dot.snp.makeConstraints { $0.size.equalTo(10) }

        return card
    }

    private func buildTipCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03

        let title = UILabel()
        title.text = "连接说明"
        title.font = .fdCaptionSemibold
        title.textColor = .fdSubtext

        let steps = ["① 确保设备已开机并开启蓝牙", "② 手机蓝牙保持开启状态", "③ 将设备靠近手机 30cm 以内", "④ 点击「添加新设备」完成配对"]
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4

        card.addSubview(title)
        card.addSubview(stack)
        title.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        stack.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        for step in steps {
            let l = UILabel()
            l.text = step
            l.font = .fdCaption
            l.textColor = .fdText2
            stack.addArrangedSubview(l)
        }

        return card
    }
}
