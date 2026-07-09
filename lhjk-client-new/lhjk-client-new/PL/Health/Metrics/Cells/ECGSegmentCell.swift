import UIKit
import SnapKit

final class ECGSegmentCell: UITableViewCell {

    static let reuseID = "segment"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear; contentView.backgroundColor = .clear

        let seg = UISegmentedControl(items: ["日", "周", "月"]); seg.selectedSegmentIndex = 2
        seg.selectedSegmentTintColor = .fdPrimary; seg.backgroundColor = .fdBg2
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.fdCaptionSemibold], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.fdCaption], for: .normal)
        contentView.addSubview(seg)
        seg.snp.makeConstraints { $0.top.equalToSuperview(); $0.leading.trailing.equalToSuperview().inset(16); $0.height.equalTo(36) }

        let (l, rng, r) = (UIButton(type: .system), UILabel(), UIButton(type: .system))
        [l, r].forEach { b in b.setTitleColor(.fdSubtext, for: .normal); b.titleLabel?.font = UIFont.fdFont(ofSize: 18, weight: .medium) }
        l.setTitle("‹", for: .normal); r.setTitle("›", for: .normal)
        rng.text = "04/01 – 05/17"; rng.font = .fdCaption; rng.textColor = .fdSubtext

        [l, rng, r].forEach { contentView.addSubview($0) }
        l.snp.makeConstraints { $0.left.equalToSuperview().offset(16); $0.top.equalTo(seg.snp.bottom).offset(10); $0.bottom.equalToSuperview().offset(-4) }
        rng.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.centerY.equalTo(l) }
        r.snp.makeConstraints { $0.right.equalToSuperview().offset(-16); $0.centerY.equalTo(l) }
    }

    required init?(coder: NSCoder) { fatalError() }
}
