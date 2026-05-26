import Foundation
#if canImport(iCalKit)
import iCalKit
#endif

/// iCal パーサーアダプター。
/// iCalKit パッケージ追加前はネイティブ実装で動作し、追加後は自動的にライブラリに委譲する。
enum ICalParser {

    static func parse(_ icalString: String) -> [NetworkAssignmentItem] {
        #if canImport(iCalKit)
        return parseWithLibrary(icalString)
        #else
        return parseNative(icalString)
        #endif
    }

    // MARK: - iCalKit 実装（パッケージ追加後に自動で有効化）

    #if canImport(iCalKit)
    private static func parseWithLibrary(_ icalString: String) -> [NetworkAssignmentItem] {
        guard let data = icalString.data(using: .utf8) else { return [] }
        let calendars = iCalKit.parse(icsData: data)
        return calendars
            .flatMap { $0.events }
            .compactMap { event in
                guard
                    let uid      = event.uid,
                    let summary  = event.summary,
                    let deadline = event.dtEnd
                else { return nil }
                return NetworkAssignmentItem(
                    uid:            uid,
                    rawTitle:       summary,
                    deadline:       deadline,
                    rawDescription: event.description ?? "",
                    categoryID:     nil  // iCalKit 経由では CATEGORIES は native path で補完
                )
            }
    }
    #endif

    // MARK: - ネイティブフォールバック（iCalKit 追加前の暫定実装）

    private static func parseNative(_ icalString: String) -> [NetworkAssignmentItem] {
        // RFC5545 の折り畳み行を展開する
        let unfolded = icalString
            .replacingOccurrences(of: "\r\n ", with: "")
            .replacingOccurrences(of: "\r\n\t", with: "")
            .replacingOccurrences(of: "\n ",  with: "")
            .replacingOccurrences(of: "\n\t", with: "")

        var items: [NetworkAssignmentItem] = []
        var uid = "", summary = "", description = ""
        var categoryID: String?
        var deadline: Date?
        var inEvent = false

        for line in unfolded.components(separatedBy: .newlines) {
            if line.hasPrefix("BEGIN:VEVENT") {
                inEvent = true
                uid = ""; summary = ""; description = ""; deadline = nil; categoryID = nil
            } else if line.hasPrefix("END:VEVENT") {
                inEvent = false
                if !uid.isEmpty, let dl = deadline {
                    items.append(NetworkAssignmentItem(
                        uid: uid, rawTitle: summary,
                        deadline: dl, rawDescription: description,
                        categoryID: categoryID
                    ))
                }
            } else if inEvent {
                let name = String(line.prefix(while: { $0 != ":" && $0 != ";" }))
                let value = valueAfterColon(line)
                switch name {
                case "UID":         uid = value
                case "SUMMARY":     summary = value
                case "DESCRIPTION": description = value
                case "DTEND":       deadline = parseDate(value)
                case "CATEGORIES":  categoryID = value.isEmpty ? nil : value
                default: break
                }
            }
        }
        return items
    }

    private static func valueAfterColon(_ line: String) -> String {
        guard let idx = line.firstIndex(of: ":") else { return "" }
        return String(line[line.index(after: idx)...])
    }

    /// UTC (末尾Z) / 浮動時刻 / 日付のみ の3パターンを JST に統一して返す
    private static func parseDate(_ raw: String) -> Date? {
        let jst = TimeZone(identifier: "Asia/Tokyo")!
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")

        if raw.hasSuffix("Z") {
            fmt.timeZone = TimeZone(abbreviation: "UTC")
            fmt.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        } else if raw.count == 15 {
            fmt.timeZone = jst
            fmt.dateFormat = "yyyyMMdd'T'HHmmss"
        } else if raw.count == 8 {
            fmt.timeZone = jst
            fmt.dateFormat = "yyyyMMdd"
        } else {
            return nil
        }
        return fmt.date(from: raw)
    }
}
