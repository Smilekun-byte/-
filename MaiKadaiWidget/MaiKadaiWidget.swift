import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct DeadlineEntry: TimelineEntry {
    let date: Date
    let snapshots: [AssignmentSnapshot]

    static let preview = DeadlineEntry(
        date: Date(),
        snapshots: [
            AssignmentSnapshot(id: "1", cleanTitle: "線形代数レポート",
                               deadline: Date().addingTimeInterval(86400 * 2),
                               isMidnightDeadline: false),
            AssignmentSnapshot(id: "2", cleanTitle: "英語ライティング",
                               deadline: Date().addingTimeInterval(86400),
                               isMidnightDeadline: true),
            AssignmentSnapshot(id: "3", cleanTitle: "プログラミング課題",
                               deadline: Date().addingTimeInterval(86400 * 5),
                               isMidnightDeadline: false),
        ]
    )
}

// MARK: - Timeline Provider

struct MaiKadaiWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> DeadlineEntry {
        .preview
    }

    func getSnapshot(in context: Context, completion: @escaping (DeadlineEntry) -> Void) {
        completion(context.isPreview ? .preview : makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DeadlineEntry>) -> Void) {
        let entry = makeEntry()
        // 最も近い締め切りを過ぎたタイミングで自動更新、なければ1時間後
        let nextRefresh = entry.snapshots.first?.deadline
            ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func makeEntry() -> DeadlineEntry {
        let now = Date()
        let snapshots = SharedStore.load().filter { $0.deadline > now }
        return DeadlineEntry(date: now, snapshots: snapshots)
    }
}

// MARK: - Widget（@main は MaiKadaiWidgetBundle に委譲）

struct MaiKadaiWidget: Widget {
    let kind = "MaiKadaiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MaiKadaiWidgetProvider()) { entry in
            MaiKadaiWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("マイ課題")
        .description("次の締め切りをホーム画面で確認できます。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
