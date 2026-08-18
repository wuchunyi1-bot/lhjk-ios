import Foundation

/// 对齐融云 Web SDK `RongIMLib.RongIMEmoji`（RongEmoji-2.2.11）。
/// 规则来源：https://cdn.ronghub.com/RongEmoji-2.2.11.min.js
///
/// - `symbolToEmoji`：`[色迷迷]` → 😍（查找 zh / en 名）
/// - `emojiToSymbol`：😍 → `[色迷迷]`（发送侧，lang = zh）
/// - 未收录的 `[xxx]` / Unicode 原样保留
///
/// iOS 用系统 emoji 渲染，不使用官方 sprite（`emojis-hd.png`）。
enum RongEmoji {

    static func symbolToEmoji(_ text: String) -> String {
        guard text.contains("[") else { return text }
        let ns = text as NSString
        let matches = symbolRegex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return text }
        var result = text
        for match in matches.reversed() {
            let name = ns.substring(with: match.range(at: 1))
            if let emoji = nameToEmoji[name] {
                result = (result as NSString).replacingCharacters(in: match.range, with: emoji)
            }
        }
        return result
    }

    static func emojiToSymbol(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        var result = text
        for tag in tagsByLength {
            guard result.contains(tag), let zh = emojiToZh[tag] else { continue }
            result = result.replacingOccurrences(of: tag, with: "[\(zh)]")
        }
        return result
    }

    // MARK: - RongEmoji-2.2.11 `I` 表（zh / en / tag）

    private static let table: [(zh: String, en: String, tag: String)] = [
        ("笑脸", "Smiley Face", "😃"),
        ("笑嘻嘻", "Grinning Face", "😀"),
        ("微笑", "Smiley", "😊"),
        ("萌萌哒", "Cute", "☺"),
        ("眨眼", "Winking Face", "😉"),
        ("色迷迷", "Heart Eyes", "😍"),
        ("飞吻", "Blowing Kiss", "😘"),
        ("么么哒", "Kiss Face", "😚"),
        ("调皮", "Crazy Face", "😜"),
        ("吐舌头", "Tongue Out", "😝"),
        ("脸红", "Flushed Face", "😳"),
        ("露齿而笑", "Grinning With Smiling", "😁"),
        ("沉思", "Pensive", "😔"),
        ("满意", "Pleased", "😌"),
        ("不满", "Dissatisfied", "😒"),
        ("苦瓜脸", "Worried Face", "😟"),
        ("失望", "Disappointed Face", "😞"),
        ("无助", "Helpless Face", "😣"),
        ("伤心", "Crying", "😢"),
        ("喜极而泣", "Laughing Tears", "😂"),
        ("哭泣", "Sobbing", "😭"),
        ("困", "Sleepy Face", "😪"),
        ("冷汗", "Cold Sweat", "😰"),
        ("尴尬", "Happy Sweat", "😅"),
        ("汗", "Sweat", "😓"),
        ("抓狂", "Tired Face", "😫"),
        ("疲惫", "Weary Face", "😩"),
        ("可怕", "Fearful Face", "😨"),
        ("尖叫", "Scream", "😱"),
        ("生气", "Angry Face", "😡"),
        ("怒气冲冲", "Mad Face", "😤"),
        ("蒙羞", "Confounded Face", "😖"),
        ("大笑", "Big Grin", "😆"),
        ("馋", "Hungry", "😋"),
        ("口罩", "Mask Face", "😷"),
        ("墨镜", "Sunglasses", "😎"),
        ("睡眠", "Sleeping", "😴"),
        ("头晕眼花", "Dizzy Face", "😵"),
        ("震惊", "Shocked Face", "😲"),
        ("小恶魔", "Purple Devil", "😈"),
        ("恶魔", "Devil", "👿"),
        ("惊呆", "Surprised Face", "😯"),
        ("扮鬼脸", "Grimacing Face", "😬"),
        ("困惑", "Confused", "😕"),
        ("无口", "Mouthless", "😶"),
        ("天使光环", "Halo", "😇"),
        ("傻笑", "Smirking Face", "😏"),
        ("面无表情", "Expressionless Face", "😑"),
        ("不看", "See No Monkey", "🙈"),
        ("不听", "Hear No Monkey", "🙉"),
        ("闭嘴", "No Speaking", "🙊"),
        ("外星人", "Alien", "👽"),
        ("便便", "Pile Of Poo", "💩"),
        ("心碎", "Broken Heart", "💔"),
        ("火", "Fire", "🔥"),
        ("愤怒", "Anger", "💢"),
        ("ZZZ", "Zzz", "💤"),
        ("禁止", "Prohibited", "🚫"),
        ("星星", "Star", "⭐"),
        ("闪电", "Lightning Bolt", "⚡"),
        ("弯月", "Drescent Moon", "🌙"),
        ("晴朗", "Sunny", "☀"),
        ("多云", "Cloudy", "⛅"),
        ("云彩", "Cloud", "☁"),
        ("雪花", "Snowflake", "❄"),
        ("雨伞", "Umbrella", "☔"),
        ("雪人", "Snowman", "⛄"),
        ("赞", "Thumbs Up", "👍"),
        ("喝倒彩", "Thumbs Down", "👎"),
        ("握手", "Handshake", "🤝"),
        ("没问题", "Ok Hand", "👌"),
        ("举起拳头", "Raised Fist", "✊"),
        ("击拳", "Oncoming Fist", "👊"),
        ("耶", "Victory Hand", "✌"),
        ("举手", "Raised Hand", "✋"),
        ("祈祷", "Folded Hands", "🙏"),
        ("第一", "Pointing Up", "☝"),
        ("鼓掌", "Clapping Hands", "👏"),
        ("肌肉", "Flexed Biceps", "💪"),
        ("家庭", "Family", "👪"),
        ("情侣", "Couple", "👫"),
        ("宝贝天使", "Baby Angel", "👼"),
        ("马", "Horse", "🐴"),
        ("狗", "Dog", "🐶"),
        ("猪", "Pig", "🐷"),
        ("鬼", "Ghost", "👻"),
        ("玫瑰", "Rose", "🌹"),
        ("向日葵", "Sunflower", "🌻"),
        ("松树", "Pine Tree", "🌲"),
        ("圣诞树", "Christmas Tree", "🎄"),
        ("礼物", "Wrapped Gift", "🎁"),
        ("聚会礼花", "Party Popper", "🎉"),
        ("钱袋", "Money Bag", "💰"),
        ("生日蛋糕", "Birthday Cake", "🎂"),
        ("BBQ", "Barbecue", "🍖"),
        ("米饭", "Cooked Rice", "🍚"),
        ("冰淇淋", "Ice Cream", "🍦"),
        ("巧克力", "Chocolate Bar", "🍫"),
        ("西瓜", "Watermelon", "🍉"),
        ("红酒", "Wine Glass", "🍷"),
        ("干杯", "Cheers", "🍻"),
        ("咖啡", "Coffee", "☕"),
        ("篮球", "Basketball", "🏀"),
        ("足球", "Soccer Ball", "⚽"),
        ("单板滑雪", "Snowboarder", "🏂"),
        ("麦克风", "Microphone", "🎤"),
        ("音乐", "Musical Note", "🎵"),
        ("骰子", "Game Die", "🎲"),
        ("麻将", "Mahjong Red Dragon", "🀄"),
        ("王冠", "Crown", "👑"),
        ("口红", "Lipstick", "💄"),
        ("吻", "Kiss", "💋"),
        ("戒指", "Ring", "💍"),
        ("书籍", "Books", "📚"),
        ("毕业帽", "Graduation Cap", "🎓"),
        ("铅笔", "Pencil", "✏"),
        ("房子", "House With Garden", "🏡"),
        ("淋浴", "Shower", "🚿"),
        ("灯泡", "Light Bulb", "💡"),
        ("电话听筒", "Telephone Receiver", "📞"),
        ("扩音器", "Loudspeaker", "📢"),
        ("表", "Clock", "🕖"),
        ("闹钟", "Alarm Clock", "⏰"),
        ("沙漏", "Hourglass", "⏳"),
        ("炸弹", "Bomb", "💣"),
        ("手枪", "Pistol", "🔫"),
        ("药", "Capsule", "💊"),
        ("火箭", "Rocket", "🚀"),
        ("地球", "Globe", "🌏"),
    ]

    private static let symbolRegex = try! NSRegularExpression(pattern: #"\[([^\[\]]+?)\]"#, options: [])

    private static let nameToEmoji: [String: String] = {
        var map: [String: String] = [:]
        map.reserveCapacity(table.count * 2)
        for item in table {
            map[item.zh] = item.tag
            map[item.en] = item.tag
        }
        return map
    }()

    private static let emojiToZh: [String: String] = {
        var map: [String: String] = [:]
        map.reserveCapacity(table.count * 2)
        let vs = "\u{FE0F}"
        for item in table {
            map[item.tag] = item.zh
            if !item.tag.contains(vs) {
                map[item.tag + vs] = item.zh
            }
        }
        return map
    }()

    private static let tagsByLength: [String] = emojiToZh.keys.sorted { $0.utf16.count > $1.utf16.count }
}
