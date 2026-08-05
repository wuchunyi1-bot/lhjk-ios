import UIKit
import SnapKit

/// 健康陪伴整卡 — 对齐 Figma：卡内标题 + 文章列表（68 缩略图）
final class HomeArticleCell: UITableViewCell {

    static let reuseID = "HomeArticleCell"

    struct Article {
        let tag: String
        let tagType: String
        let title: String
        let author: String
        let reads: String
        let imageName: String?
    }

    var onTapped: ((Int) -> Void)?
    var onMoreTapped: (() -> Void)?

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdSurface
        v.layer.cornerRadius = 16
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "健康陪伴"
        l.font = .fdFont(ofSize: 16, weight: .medium)
        l.textColor = .fdText
        return l
    }()

    private let moreButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("更多 ›", for: .normal)
        b.titleLabel?.font = .fdFont(ofSize: 12, weight: .regular)
        b.setTitleColor(.fdSubtext, for: .normal)
        return b
    }()

    private let listStack: UIStackView = {
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
        cardView.addSubview(listStack)

        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16).priority(750)
            $0.bottom.equalToSuperview().offset(-12)
        }
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(15)
        }
        moreButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(8)
        }
        listStack.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(8)
        }

        moreButton.addTarget(self, action: #selector(moreTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(articles: [Article]) {
        listStack.arrangedSubviews.forEach {
            listStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for (idx, article) in articles.enumerated() {
            listStack.addArrangedSubview(makeRow(article, index: idx))
            if idx < articles.count - 1 {
                let wrap = UIView()
                let div = UIView()
                div.backgroundColor = UIColor.fdBorder.withAlphaComponent(0.8)
                wrap.addSubview(div)
                div.snp.makeConstraints {
                    $0.leading.trailing.equalToSuperview().inset(11)
                    $0.height.equalTo(0.5)
                    $0.top.bottom.equalToSuperview()
                }
                listStack.addArrangedSubview(wrap)
            }
        }
    }

    private func makeRow(_ article: Article, index: Int) -> UIView {
        let row = UIView()
        row.tag = index

        let thumb = UIImageView()
        thumb.backgroundColor = UIColor(hexString: "#AFAFAF")
        thumb.layer.cornerRadius = 8
        thumb.clipsToBounds = true
        thumb.contentMode = .scaleAspectFill
        if let name = article.imageName {
            thumb.image = UIImage(named: name)
        }

        let title = UILabel()
        title.text = article.title
        title.font = .fdFont(ofSize: 14, weight: .medium)
        title.textColor = .fdText
        title.numberOfLines = 2

        let tag = UILabel()
        tag.text = " \(article.tag) "
        tag.font = .fdFont(ofSize: 11, weight: .regular)
        tag.textColor = UIColor(hexString: "#A1733E")
        tag.backgroundColor = UIColor(hexString: "#FAF5EE")
        tag.layer.cornerRadius = 2
        tag.clipsToBounds = true

        let author = UILabel()
        author.text = article.author.replacingOccurrences(of: " ", with: "｜")
        author.font = .fdFont(ofSize: 12, weight: .regular)
        author.textColor = .fdSubtext

        let reads = UILabel()
        reads.text = article.reads
        reads.font = .fdFont(ofSize: 12, weight: .regular)
        reads.textColor = .fdSubtext
        reads.textAlignment = .right

        row.addSubview(thumb)
        row.addSubview(title)
        row.addSubview(tag)
        row.addSubview(author)
        row.addSubview(reads)

        thumb.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().offset(-12)
            $0.size.equalTo(68)
        }
        title.snp.makeConstraints {
            $0.top.equalTo(thumb)
            $0.leading.equalTo(thumb.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(12)
        }
        tag.snp.makeConstraints {
            $0.leading.equalTo(title)
            $0.bottom.equalTo(thumb)
        }
        author.snp.makeConstraints {
            $0.leading.equalTo(tag.snp.trailing).offset(6)
            $0.centerY.equalTo(tag)
        }
        reads.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalTo(tag)
            $0.leading.greaterThanOrEqualTo(author.snp.trailing).offset(4)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(rowTapped(_:)))
        row.addGestureRecognizer(tap)
        return row
    }

    @objc private func rowTapped(_ g: UITapGestureRecognizer) {
        guard let idx = g.view?.tag else { return }
        onTapped?(idx)
    }

    @objc private func moreTap() { onMoreTapped?() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTapped = nil
        onMoreTapped = nil
    }
}
