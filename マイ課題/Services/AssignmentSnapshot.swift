import Foundation

/// ウィジェットとメインアプリが App Groups 経由で共有する軽量データ構造。
/// SwiftData に依存しないため、ウィジェットターゲットにそのまま追加できる。
struct AssignmentSnapshot: Codable, Identifiable {
    let id: String      // Assignment.uid と対応
    let cleanTitle: String
    let deadline: Date
    let isMidnightDeadline: Bool
}

/// App Groups UserDefaults を介してスナップショットを保存・取得する。
enum SharedStore {
    static let appGroupID = "group.com.smilekun.maikadai"
    private static let key = "upcoming_snapshots"

    /// メインアプリが同期後に呼び出す。未完了・未来の課題のみ最大10件を保存する。
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
