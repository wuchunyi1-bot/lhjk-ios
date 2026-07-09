import UIKit
import SnapKit

final class ECGResultCardCell: UITableViewCell {

    static let reuseID = "result"

    let waveView = ECGChartView()
    private let gradient = CAGradientLayer()
    private weak var cardContainer: UIView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear; contentView.backgroundColor = .clear

        let card = UIView()
        cardContainer = card
        card.layer.cornerRadius = 20; card.clipsToBounds = true
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.left.right.equalToSuperview().inset(16); $0.top.bottom.equalToSuperview() }

        gradient.colors = [UIColor(hexString: "#1a5276").cgColor, UIColor(hexString: "#2e86c1").cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0); gradient.endPoint = CGPoint(x: 1, y: 1)
        card.layer.insertSublayer(gradient, at: 0)

        let edge = 18.0
        let badge = tag("最新报告", bg: UIColor.white.withAlphaComponent(0.2), fg: .white)
        let time = UILabel(); time.text = "本月 12 日"
        time.font = .fdCaption; time.textColor = UIColor.white.withAlphaComponent(0.75)

        let c = UILabel(); c.text = "窦性心律 · 正常心电图"
        c.font = UIFont.fdFont(ofSize: 20, weight: .bold); c.textColor = .white

        let h = UILabel(); h.text = "心率：76 bpm"
        h.font = .fdBody; h.textColor = UIColor.white.withAlphaComponent(0.85)

        waveView.gridLineColor = UIColor.white.withAlphaComponent(0.14)
        waveView.gridThinLineWidth = 0.3; waveView.gridBoldLineWidth = 0.6
        waveView.smallSquareSize = 4; waveView.squaresPerLargeSquare = 5
        waveView.waveformColor = UIColor(hexString: "#7DD6A0")
        waveView.waveformLineWidth = 1.2; waveView.paperSpeed = 25
        waveView.verticalRange = -1.5...1.5; waveView.pointSpacing = 0.4
        waveView.trailingMargin = 16
        waveView.layer.cornerRadius = 12
        waveView.backgroundColor = UIColor.white.withAlphaComponent(0.05)

        [badge, time, c, h, waveView].forEach { card.addSubview($0) }
        badge.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(edge) }
        time.snp.makeConstraints { $0.centerY.equalTo(badge); $0.trailing.equalToSuperview().offset(-edge) }
        c.snp.makeConstraints { $0.top.equalTo(badge.snp.bottom).offset(8); $0.leading.equalToSuperview().inset(edge) }
        h.snp.makeConstraints { $0.top.equalTo(c.snp.bottom).offset(4); $0.leading.equalToSuperview().inset(edge) }
        waveView.snp.makeConstraints { make in
            make.top.equalTo(h.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(edge)
            make.height.equalTo(150)
            make.bottom.equalToSuperview().offset(-edge)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let card = cardContainer { gradient.frame = card.bounds }
    }

    private func tag(_ t: String, bg: UIColor, fg: UIColor) -> UIView {
        let v = UIView(); v.backgroundColor = bg; v.layer.cornerRadius = 999
        let l = UILabel(); l.text = t; l.font = .fdMicro; l.textColor = fg
        v.addSubview(l); l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        return v
    }
}
