import UIKit
import SnapKit

/// 健康文章行 Cell — 缩略图 + 标签 + 标题 + 元信息
final class HomeArticleCell: UITableViewCell {

    static let reuseID = "HomeArticleCell"

    // MARK: - Data types

    struct Article {
        let tag: String
        let tagType: String // "warning" / "success" / "primary" / "info"
        let title: String
        let author: String
        let reads: String
    }

    // MARK: - UI

    private let thumbnailView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdBg2
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.fdBorderStrong.cgColor
        v.layer.cornerRadius = 12
        return v
    }()

    private let thumbnailLabel: UILabel = {
        let l = UILabel()
        l.text = "文章\n封面"
        l.font = .systemFont(ofSize: 11)
        l.textColor = .fdMuted
        l.numberOfLines = 0
        l.textAlignment = .center
        return l
    }()

    private let tagLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .semibold)
        l.layer.cornerRadius = 999
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .fdText
        l.numberOfLines = 2
        return l
    }()

    private let metaLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = .fdMuted
        return l
    }()

    private let dividerView: UIView = {
        let v = UIView()
        v.backgroundColor = .fdBorder
        return v
    }()

    // MARK: - Callback

    var onTapped: (() -> Void)?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .fdBg
        selectionStyle = .none
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        thumbnailView.addSubview(thumbnailLabel)
        thumbnailLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        contentView.addSubview(thumbnailView)
        contentView.addSubview(tagLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(metaLabel)
        contentView.addSubview(dividerView)

        thumbnailView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().inset(16)
            make.size.equalTo(84)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        tagLabel.snp.makeConstraints { make in
            make.top.equalTo(thumbnailView)
            make.leading.equalTo(thumbnailView.snp.trailing).offset(12)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(tagLabel.snp.bottom).offset(6)
            make.leading.equalTo(tagLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
        metaLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.equalTo(tagLabel)
            make.bottom.equalToSuperview().offset(-12)
        }
        dividerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview().inset(16)
            make.height.equalTo(1)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        contentView.addGestureRecognizer(tap)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 确保多行 label 能正确计算 intrinsic content size
        let maxWidth = contentView.bounds.width - 16 /* thumbnail leading */ - 84 /* thumbnail */ - 12 /* gap */ - 16 /* trailing */
        if maxWidth > 0 && titleLabel.preferredMaxLayoutWidth != maxWidth {
            titleLabel.preferredMaxLayoutWidth = maxWidth
        }
    }

    // MARK: - Configure

    func configure(article: Article, isLast: Bool) {
        let tagColors: [String: (bg: UIColor, fg: UIColor)] = [
            "warning": (.fdWarningSoft, UIColor(hexString: "#B47300")),
            "success": (.fdSuccessSoft, .fdSuccess),
            "primary": (.fdPrimarySoft, .fdPrimary),
            "info":    (.fdInfoSoft, .fdInfo),
        ]
        let tc = tagColors[article.tagType] ?? (.fdBg2, .fdSubtext)
        tagLabel.text = " \(article.tag) "
        tagLabel.textColor = tc.fg
        tagLabel.backgroundColor = tc.bg

        titleLabel.text = article.title
        metaLabel.text = "\(article.author) · \(article.reads)"
        dividerView.isHidden = isLast
    }

    @objc private func cellTapped() {
        onTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        dividerView.isHidden = false
        onTapped = nil
    }
}
