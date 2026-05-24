import Foundation
import Combine
import SwiftData

@MainActor
class AssignmentViewModel: ObservableObject {

    @Published var isSyncing = false
    @Published var lastSyncError: String?

    /// Keychain から URL を取得し Moodle iCal をフェッチしてローカル DB にマージする。
    func syncFromMoodle(context: ModelContext) async {
        guard let urlString = KeychainManager.loadURL(),
              let url = URL(string: urlString) else {
            lastSyncError = "Moodle URL が未設定です。設定画面から登録してください。"
            return
        }

        isSyncing = true
        lastSyncError = nil
        defer { isSyncing = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let icalString = String(data: data, encoding: .utf8) else {
                lastSyncError = "データのデコードに失敗しました。"
                return
            }
            let fetched = ICalParser.parse(icalString)
            mergeMoodleData(fetchedItems: fetched, context: context)
        } catch {
            lastSyncError = "同期に失敗しました: \(error.localizedDescription)"
        }
    }

    /// ユーザーの変更（isCompleted・userNotes）を保護しながら Moodle データをマージする。
    /// UID を主キーとして突合し、既存レコードは Moodle 側の変更だけを上書きする。
    func mergeMoodleData(fetchedItems: [NetworkAssignmentItem], context: ModelContext) {
        for item in fetchedItems {
            let currentUID = item.uid
            let descriptor = FetchDescriptor<Assignment>(
                predicate: #Predicate { $0.uid == currentUID }
            )

            if let existing = (try? context.fetch(descriptor))?.first {
                // 既存タスク: Moodle 側が更新した可能性のある項目だけ上書きする
                existing.deadline       = item.deadline
                existing.rawTitle       = item.rawTitle
                existing.rawDescription = item.rawDescription
            } else {
                // 新規タスク: レコードを作成して挿入する
                context.insert(Assignment(
                    uid: item.uid,
                    rawTitle: item.rawTitle,
                    deadline: item.deadline,
                    rawDescription: item.rawDescription
                ))
            }
        }

        do {
            try context.save()
            flushToWidget(context: context)
        } catch {
            lastSyncError = "保存に失敗しました: \(error.localizedDescription)"
        }
    }

    /// 未完了・未来の課題をスナップショットに変換して App Groups に書き出し、
    /// ウィジェットのタイムラインを非同期でリフレッシュする。
    func flushToWidget(context: ModelContext) {
        let now = Date()
        let descriptor = FetchDescriptor<Assignment>(
            predicate: #Predicate { !$0.isCompleted && $0.deadline > now },
            sortBy: [SortDescriptor(\.deadline)]
        )
        guard let all = try? context.fetch(descriptor) else { return }

        let snapshots = all.prefix(10).map { a in
            AssignmentSnapshot(
                id: a.uid,
                cleanTitle: a.cleanTitle,
                deadline: a.deadline,
                isMidnightDeadline: a.isMidnightDeadline
            )
        }
        SharedStore.save(Array(snapshots))
        WidgetRefreshManager.scheduleRefresh()
    }
}
