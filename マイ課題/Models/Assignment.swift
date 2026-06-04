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
    /// iCal CATEGORIES フィールドの値（課程の一意ID、例：2026_99FE210）
    var categoryID: String?
    /// 紐付けられた Course エンティティ（同じ categoryID の Course に自動リンクされる）
    @Relationship var course: Course?
    /// 主観的重要度（0.0=低、0.5=中、1.0=高）。Matrix View の縦軸に対応。
    var userPriority: Double = 0.5
    /// 将来の手動色付け機能用（Phase 3 予定。今は UI なし）
    var manualColor: String?
    /// 予想所要時間（分）。未設定は nil。
    var estimatedMinutes: Int?

    // MARK: - 計算プロパティ（DBには保存しない）

    /// 画面表示用にクレンジングされたタイトル。
    /// DBを汚さずViewレイヤーで動的にトリミングするため、パーサー変更時もマイグレーション不要。
    var cleanTitle: String {
        rawTitle
            .replacingOccurrences(of: "「提出:", with: "")
            .replacingOccurrences(of: "」の提出期限", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 予想所要時間の表示文字列（例：「約1時間30分」）。未設定は nil。
    var estimatedTimeLabel: String? {
        guard let m = estimatedMinutes else { return nil }
        if m < 60 { return "約\(m)分" }
        let h = m / 60
        let rem = m % 60
        return rem == 0 ? "約\(h)時間" : "約\(h)時間\(rem)分"
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
