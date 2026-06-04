import Foundation

/// ウィジェットとメインアプリが App Groups 経由で共有する軽量データ構造。
/// SwiftData に依存しないため、ウィジェットターゲットにそのまま追加できる。
struct AssignmentSnapshot: Codable, Identifiable {
    let id: String      // Assignment.uid と対応
    let cleanTitle: String
    let deadline: Date
    let isMidnightDeadline: Bool
    let userPriority: Double    // Matrix Widget の縦軸表示用
    let colorHex: String?       // Course.colorHex（未設定タスクは nil）

    init(id: String, cleanTitle: String, deadline: Date,
         isMidnightDeadline: Bool, userPriority: Double = 0.5,
         colorHex: String? = nil) {
        self.id = id
        self.cleanTitle = cleanTitle
        self.deadline = deadline
        self.isMidnightDeadline = isMidnightDeadline
        self.userPriority = userPriority
        self.colorHex = colorHex
    }

    // userPriority / colorHex が存在しない旧データを安全にデコードするためカスタム実装
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                 = try c.decode(String.self, forKey: .id)
        cleanTitle         = try c.decode(String.self, forKey: .cleanTitle)
        deadline           = try c.decode(Date.self,   forKey: .deadline)
        isMidnightDeadline = try c.decode(Bool.self,   forKey: .isMidnightDeadline)
        userPriority       = try c.decodeIfPresent(Double.self,  forKey: .userPriority) ?? 0.5
        colorHex           = try c.decodeIfPresent(String.self,  forKey: .colorHex)
    }
}

/// App Groups UserDefaults を介してスナップショットを保存・取得する。
enum SharedStore {
    static let appGroupID = "group.com.smilekun.maikadai"
    private static let key = "upcoming_snapshots"

    /// メインアプリが同期後に呼び出す。未完了・未来の課題のみ最大30件を保存する。
    static func save(_ snapshots: [AssignmentSnapshot]) {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data = try? JSONEncoder().encode(snapshots)
        else { return }
        defaults.set(data, forKey: key)
    }

    /// ウィジェットがタイムライン生成時に呼び出す。
    static func load() -> [AssignmentSnapshot] {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data = defaults.data(forKey: key),
            let snapshots = try? JSONDecoder().decode([AssignmentSnapshot].self, from: data)
        else { return [] }
        return snapshots
    }
}
