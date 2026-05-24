import SwiftUI
import WidgetKit

// MARK: - ルートビュー（サイズ別にレイアウトを切り替える）

struct MaiKadaiWidgetView: View {
    let entry: DeadlineEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        default:            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small（次の締め切り1件）

private struct SmallWidgetView: View {
    let entry: DeadlineEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("マイ課題", systemImage: "graduationcap.fill")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            if let next = entry.snapshots.first {
                Spacer()

                Text(next.cleanTitle)
                    .font(.subheadline.bold())
                    .lineLimit(2)

                if next.isMidnightDeadline {
                    Label("前日深夜注意", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                }

                Text(next.deadline, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .monospacedDigit()
            } else {
                Spacer()
                Text("課題なし ☕️")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Medium（直近3件のリスト）

private struct MediumWidgetView: View {
    let entry: DeadlineEntry

    private var upcoming: [AssignmentSnapshot] {
        Array(entry.snapshots.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("マイ課題", systemImage: "graduationcap.fill")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.bottom, 6)

            if upcoming.isEmpty {
                Spacer()
                Text("提出予定の課題はありません ☕️")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(upcoming) { snapshot in
                    DeadlineRow(snapshot: snapshot)
                    if snapshot.id != upcoming.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - 1行コンポーネント

private struct DeadlineRow: View {
    let snapshot: AssignmentSnapshot

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if snapshot.isMidnightDeadline {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .imageScale(.small)
                    }
                    Text(snapshot.cleanTitle)
                        .font(.caption.bold())
                        .lineLimit(1)
                }
                Text(snapshot.deadline, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(snapshot.deadline, style: .relative)
                .font(.caption2.bold())
                .foregroundStyle(urgencyColor)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 5)
    }

    private var urgencyColor: Color {
        let hours = snapshot.deadline.timeIntervalSinceNow / 3600
        if hours < 24 { return .red }
        if hours < 72 { return .orange }
        return .secondary
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    MaiKadaiWidget()
} timeline: {
    DeadlineEntry.preview
}

#Preview(as: .systemMedium) {
    MaiKadaiWidget()
} timeline: {
    DeadlineEntry.preview
}
