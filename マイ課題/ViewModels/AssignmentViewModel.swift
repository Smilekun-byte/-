import Foundation
import Combine
import SwiftData

@MainActor
class AssignmentViewModel: ObservableObject {

    @Published var isSyncing = false
    @Published var lastSyncError: String?
    /// 同期後に Course が未命名の categoryID 一覧。CourseSetupView 表示トリガー。
    @Published var unknownCategoryIDs: [String] = []

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
    /// UID を主キーとして突合し、categoryID が一致する Course を自動リンクする。
    func mergeMoodleData(fetchedItems: [NetworkAssignmentItem], context: ModelContext) {
        var newCategoryIDs = Set<String>()

        for item in fetchedItems {
            let currentUID = item.uid
            let descriptor = FetchDescriptor<Assignment>(
                predicate: #Predicate { $0.uid == currentUID }
            )

            if let existing = (try? context.fetch(descriptor))?.first {
                existing.deadline       = item.deadline
                existing.rawTitle       = item.rawTitle
                existing.rawDescription = item.rawDescription
                existing.categoryID     = item.categoryID
                if existing.course == nil, let cid = item.categoryID {
                    if let course = fetchCourse(categoryID: cid, context: context) {
                        existing.course = course
                    } else {
                        newCategoryIDs.insert(cid)
                    }
                }
            } else {
                let assignment = Assignment(
                    uid: item.uid,
                    rawTitle: item.rawTitle,
                    deadline: item.deadline,
                    rawDescription: item.rawDescription
                )
                assignment.categoryID = item.categoryID
                if let cid = item.categoryID {
                    if let course = fetchCourse(categoryID: cid, context: context) {
                        assignment.course = course
                    } else {
                        newCategoryIDs.insert(cid)
                    }
                }
                context.insert(assignment)
            }
        }

        do {
            try context.save()
            unknownCategoryIDs = newCategoryIDs.sorted()
            flushToWidget(context: context)
        } catch {
            lastSyncError = "保存に失敗しました: \(error.localizedDescription)"
        }
    }

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

    // MARK: - Private

    private func fetchCourse(categoryID: String, context: ModelContext) -> Course? {
        let cid = categoryID
        let descriptor = FetchDescriptor<Course>(predicate: #Predicate { $0.categoryID == cid })
        return (try? context.fetch(descriptor))?.first
    }
}
