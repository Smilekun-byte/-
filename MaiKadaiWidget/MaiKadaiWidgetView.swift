import SwiftUI
import WidgetKit

// MARK: - ルートビュー（サイズ別にレイアウトを切り替える）

struct MaiKadaiWidgetView: View {
    let entry: DeadlineEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumMatrixWidgetView(entry: entry)
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

// MARK: - Medium（Matrix 散布図・読み取り専用）

private struct MediumMatrixWidgetView: View {
    let entry: DeadlineEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Matrix", systemImage: "chart.scatter")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            MatrixCanvasView(snapshots: entry.snapshots)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // タップで App 内の Matrix タブへ遷移（要 URL スキーム登録: maikadai://）
        .widgetURL(URL(string: "maikadai://matrix"))
    }
}

// MARK: - Matrix 散布図（Canvas で描画）

private struct MatrixCanvasView: View {
    let snapshots: [AssignmentSnapshot]
    private let maxDays: Double = 28

    var body: some View {
        Canvas { ctx, size in
            let now = Date()
            let pad: CGFloat = 4
            let cw = size.width - pad * 2
            let ch = size.height - pad * 2

            // グリッド線
            for frac in [0.33, 0.67] as [Double] {
                let y = pad + CGFloat(frac) * ch
                var p = Path(); p.move(to: CGPoint(x: pad, y: y))
                p.addLine(to: CGPoint(x: size.width - pad, y: y))
                ctx.stroke(p, with: .color(.gray.opacity(0.15)), lineWidth: 0.5)
            }
            for frac in [0.25, 0.5, 0.75] as [Double] {
                let x = pad + CGFloat(frac) * cw
                var p = Path(); p.move(to: CGPoint(x: x, y: pad))
                p.addLine(to: CGPoint(x: x, y: size.height - pad))
                ctx.stroke(p, with: .color(.gray.opacity(0.15)), lineWidth: 0.5)
            }

            // タスクドット
            for snapshot in snapshots.prefix(20) {
                let days = snapshot.deadline.timeIntervalSince(now) / 86400
                guard days > 0, days <= maxDays else { continue }
                let x = pad + CGFloat(days / maxDays) * cw
                let y = pad + CGFloat(1.0 - snapshot.userPriority) * ch
                let r: CGFloat = 5
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                    with: .color(urgencyColor(deadline: snapshot.deadline, now: now))
                )
            }
        }
    }

    private func urgencyColor(deadline: Date, now: Date) -> Color {
        let hours = deadline.timeIntervalSince(now) / 3600
        if hours < 24 { return .red }
        if hours < 72 { return .orange }
        return .blue
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
