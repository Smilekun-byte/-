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
            Label("課題マップ", systemImage: "chart.scatter")
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

// MARK: - Medium（直近の課題リスト・最大3件）

struct MediumListWidgetView: View {
    let entry: DeadlineEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("直近の課題", systemImage: "list.bullet")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            if entry.snapshots.isEmpty {
                Spacer()
                Text("課題なし ☕️")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(entry.snapshots.prefix(3)) { snapshot in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(dotColor(snapshot))
                            .frame(width: 8, height: 8)

                        Text(snapshot.cleanTitle)
                            .font(.subheadline)
                            .lineLimit(1)

                        if snapshot.isMidnightDeadline {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }

                        Spacer(minLength: 4)

                        Text(snapshot.deadline, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // タップで App 内の課題一覧タブへ遷移
        .widgetURL(URL(string: "maikadai://list"))
    }

    private func dotColor(_ snapshot: AssignmentSnapshot) -> Color {
        let hours = snapshot.deadline.timeIntervalSinceNow / 3600
        if hours < 24 { return .red }
        if hours < 72 { return .orange }
        if let hex = snapshot.colorHex { return Color(hex: hex) }
        return .blue
    }
}

// MARK: - Matrix 散布図（Canvas + テキストオーバーレイ）

private struct MatrixCanvasView: View {
    let snapshots: [AssignmentSnapshot]
    private let maxDays: Double = 28
    private let padL: CGFloat = 12   // 左（矢印用）
    private let padR: CGFloat = 4
    private let padT: CGFloat = 8    // 上（矢印先端用）
    private let padB: CGFloat = 14   // 下（横軸ラベル用）

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let cw = size.width - padL - padR
            let ch = size.height - padT - padB

            ZStack {
                // Canvas：グリッド + 矢印 + ドット
                Canvas { ctx, _ in
                    let now = Date()

                    // グリッド横線
                    for frac in [0.33, 0.67] as [Double] {
                        let y = padT + CGFloat(frac) * ch
                        var p = Path()
                        p.move(to: CGPoint(x: padL, y: y))
                        p.addLine(to: CGPoint(x: size.width - padR, y: y))
                        ctx.stroke(p, with: .color(.gray.opacity(0.15)), lineWidth: 0.5)
                    }

                    // グリッド縦線
                    for frac in [0.25, 0.5, 0.75] as [Double] {
                        let x = padL + CGFloat(frac) * cw
                        var p = Path()
                        p.move(to: CGPoint(x: x, y: padT))
                        p.addLine(to: CGPoint(x: x, y: size.height - padB))
                        ctx.stroke(p, with: .color(.gray.opacity(0.15)), lineWidth: 0.5)
                    }

                    // 左端の矢印（下：細 → 上：太）
                    let arrowX = padL / 2
                    let segments = 12
                    for i in 0..<segments {
                        let t0 = CGFloat(i) / CGFloat(segments)
                        let t1 = CGFloat(i + 1) / CGFloat(segments)
                        let y0 = (size.height - padB) - t0 * ch
                        let y1 = (size.height - padB) - t1 * ch
                        let lw = CGFloat(0.5) + t1 * CGFloat(1.5)
                        var seg = Path()
                        seg.move(to: CGPoint(x: arrowX, y: y0))
                        seg.addLine(to: CGPoint(x: arrowX, y: y1))
                        ctx.stroke(seg, with: .color(.secondary.opacity(0.5)), lineWidth: lw)
                    }

                    // 矢印の先端（上向き三角）
                    var head = Path()
                    head.move(to: CGPoint(x: arrowX, y: padT - 2))
                    head.addLine(to: CGPoint(x: arrowX - 3, y: padT + 6))
                    head.addLine(to: CGPoint(x: arrowX + 3, y: padT + 6))
                    head.closeSubpath()
                    ctx.fill(head, with: .color(.secondary.opacity(0.5)))

                    // タスクドット（半径 7）
                    for snapshot in snapshots.prefix(30) {
                        let days = snapshot.deadline.timeIntervalSince(now) / 86400
                        guard days > 0, days <= maxDays else { continue }
                        let x = padL + CGFloat(days / maxDays) * cw
                        let y = padT + CGFloat(1.0 - snapshot.userPriority) * ch
                        let r: CGFloat = 7
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: x - r, y: y - r,
                                                   width: r * 2, height: r * 2)),
                            with: .color(dotColor(snapshot: snapshot, now: now))
                        )
                    }
                }

                // 横軸ラベル（Widget 下端）
                let xLabels: [(Double, String)] = [
                    (0.0, "今日"), (0.25, "1週"), (0.5, "2週"), (0.75, "3週"), (1.0, "4週")
                ]
                ForEach(0..<xLabels.count, id: \.self) { i in
                    let (ratio, label) = xLabels[i]
                    Text(label)
                        .font(.system(size: 7))
                        .foregroundStyle(.secondary)
                        .position(
                            x: padL + CGFloat(ratio) * cw,
                            y: size.height - padB / 2
                        )
                }
            }
        }
    }

    private func dotColor(snapshot: AssignmentSnapshot, now: Date) -> Color {
        let hours = snapshot.deadline.timeIntervalSince(now) / 3600
        if hours < 24 { return .red }
        if hours < 72 { return .orange }
        if let hex = snapshot.colorHex { return Color(hex: hex) }
        return .blue
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    SmallDeadlineWidget()
} timeline: {
    DeadlineEntry.preview
}

#Preview(as: .systemMedium) {
    MaiKadaiMatrixWidget()
} timeline: {
    DeadlineEntry.preview
}

#Preview(as: .systemMedium) {
    MaiKadaiListWidget()
} timeline: {
    DeadlineEntry.preview
}
