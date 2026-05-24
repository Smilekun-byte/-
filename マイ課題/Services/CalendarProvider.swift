import Foundation

/// カレンダー操作の共有基盤。
/// DateFormatter は生成コストが高いためシングルトンで保持し、全コンポーネントで再利用する。
final class CalendarProvider {
    static let shared = CalendarProvider()
    private init() {}

    /// 月曜始まり・JST・日本ロケールで固定したカレンダー
    let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "ja_JP")
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        cal.firstWeekday = 2 // 月曜始まり
        return cal
    }()

    private let keyFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return fmt
    }()

    /// Date を "yyyy-MM-dd" 文字列に正規化する。
    /// タイムゾーンズレやミリ秒単位のブレによるキー不一致を完全に排除する。
    func makeStringKey(from date: Date) -> String {
        keyFormatter.string(from: date)
    }
}
