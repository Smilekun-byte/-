import Foundation
import SwiftData

@Model
final class Assignment {

    // MARK: - Moodle同期データ（DBに保存するフィールド）

    /// 重複登録防止・突合用の主キー。Moodle iCal の UID に対応。
    @Attribute(.unique) var uid: String
    /// Moodle上の元タイトル（クレンジング前の生データ）
    var rawTitle: String
    /// 提出締め切り日時
    var deadline: Date
    /// Moodle上の元の説明文（提出形式・ファイル名指定などを含む）
    var rawDescription: String

    // MARK: - ユーザーカスタムデータ（DBに保存するフィールド）

    var isCompleted: Bool = false
    var userNotes: String = ""
    var lastUpdatedByUser: Date?
    /// true のとき Moodle 同期ではなくユーザーが手動で作成したタスク
    var isManualEntry: Bool = false

    // MARK: - 計算プロパティ（DBには保存しない）

    /// 画面表示用にクレンジングされたタイトル。
    /// DBを汚さずViewレイヤーで動的にトリミングするため、パーサー変更時もマイグレーション不要。
    var cleanTitle: String {
        rawTitle
            .replacingOccurrences(of: "「提出:", with: "")
            .replacingOccurrences(of: "」の提出期限", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 締め切りが0:00（前日深夜と混同しやすい罠）かどうかを検知するフラグ
    var isMidnightDeadline: Bool {
        let components = Calendar.current.dateComponents([.hour, .minute], from: deadline)
        return components.hour == 0 && components.minute == 0
    }

    // MARK: - Initializer

    init(uid: String, rawTitle: String, deadline: Date, rawDescription: String) {
        self.uid = uid
        self.rawTitle = rawTitle
        self.deadline = deadline
        self.rawDescription = rawDescription
    }
}
