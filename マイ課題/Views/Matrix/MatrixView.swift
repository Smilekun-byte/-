import SwiftUI
import SwiftData

// MARK: - Matrix View（新タブ）

struct MatrixView: View {
    @Query(filter: #Predicate<Assignment> { !$0.isCompleted },
           sort: \Assignment.deadline)
    private var assignments: [Assignment]

    private let maxDays: Double = 28
    private let pad: CGFloat    = 44

    private var visible: [Assignment] {
        let now = Date()
        let horizon = now.addingTimeInterval(maxDays * 86400)
        return assignments.filter { $0.deadline > now && $0.deadline <= horizon }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color(.systemGroupedBackground).ignoresSafeArea()
                    MatrixGrid(size: geo.size, pad: pad, maxDays: maxDays)
                    MatrixAxisLabels(size: geo.size, pad: pad, maxDays: maxDays)
                    ForEach(visible) { assignment in
                        TaskDotView(
                            assignment: assignment,
                            canvas: geo.size,
                            maxDays: maxDays,
                            pad: pad
                        )
                    }
                    if visible.isEmpty { emptyState }
                }
            }
            .navigationTitle("Matrix")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.scatter")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("4週間以内の課題なし")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - グリッド（Canvas で描画）

private struct MatrixGrid: View {
    let size: CGSize
    let pad: CGFloat
    let maxDays: Double

    var body: some View {
        Canvas { ctx, _ in
            let cw = size.width - pad * 2
            let ch = size.height - pad * 2

            // 横線（優先度 0.25 / 0.5 / 0.75）
            for p in [0.25, 0.5, 0.75] as [Double] {
                let y = pad + CGFloat(1.0 - p) * ch
                var path = Path()
                path.move(to: CGPoint(x: pad, y: y))
                path.addLine(to: CGPoint(x: size.width - pad, y: y))
                ctx.stroke(path, with: .color(.secondary.opacity(0.2)), lineWidth: 0.5)
            }

            // 縦線（1 / 2 / 3 週目）
            for week in [1, 2, 3] as [Int] {
                let x = pad + CGFloat(Double(week) * 7.0 / maxDays) * cw
                var path = Path()
                path.move(to: CGPoint(x: x, y: pad))
                path.addLine(to: CGPoint(x: x, y: size.height - pad))
                ctx.stroke(path, with: .color(.secondary.opacity(0.15)), lineWidth: 0.5)
            }

            // 外枠
            var border = Path()
            border.addRect(CGRect(x: pad, y: pad, width: cw, height: ch))
            ctx.stroke(border, with: .color(.secondary.opacity(0.3)), lineWidth: 1)
        }
    }
}

// MARK: - 軸ラベル

private struct MatrixAxisLabels: View {
    let size: CGSize
    let pad: CGFloat
    let maxDays: Double

    private var cw: CGFloat { size.width - pad * 2 }
    private var ch: CGFloat { size.height - pad * 2 }

    var body: some View {
        ZStack {
            // Y 軸（優先度）
            let yLabels: [(Double, String)] = [(1.0, "高"), (0.5, "中"), (0.0, "低")]
            ForEach(yLabels, id: \.1) { priority, label in
                Text(label)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .position(x: pad / 2, y: pad + CGFloat(1.0 - priority) * ch)
            }

            // X 軸（残り日数）
            let xLabels: [(Double, String)] = [
                (0.0, "今日"), (0.25, "1週"), (0.5, "2週"), (0.75, "3週"), (1.0, "4週")
            ]
            ForEach(xLabels, id: \.1) { ratio, label in
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .position(x: pad + CGFloat(ratio) * cw,
                              y: size.height - pad / 2)
            }
        }
    }
}

// MARK: - タスクドット（縦ドラッグで userPriority を変更）

private struct TaskDotView: View {
    @Bindable var assignment: Assignment
    let canvas: CGSize
    let maxDays: Double
    let pad: CGFloat

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    private var cw: CGFloat { canvas.width - pad * 2 }
    private var ch: CGFloat { canvas.height - pad * 2 }

    private var dotX: CGFloat {
        let days = assignment.deadline.timeIntervalSinceNow / 86400
        return pad + CGFloat(min(days / maxDays, 1.0)) * cw
    }

    private var baseDotY: CGFloat {
        pad + CGFloat(1.0 - assignment.userPriority) * ch
    }

    private var currentDotY: CGFloat {
        max(pad, min(canvas.height - pad, baseDotY + dragOffset))
    }

    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(dotColor)
                .frame(width: isDragging ? 16 : 10,
                       height: isDragging ? 16 : 10)
                .shadow(color: isDragging ? dotColor.opacity(0.4) : .clear, radius: 6)
                .animation(.spring(duration: 0.15), value: isDragging)

            Text(assignment.cleanTitle)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: 64)
        }
        .position(x: dotX, y: currentDotY)
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    isDragging = true
                    dragOffset = value.translation.height
                }
                .onEnded { _ in
                    let newPriority = 1.0 - Double(currentDotY - pad) / Double(ch)
                    assignment.userPriority = max(0, min(1, newPriority))
                    dragOffset = 0
                    isDragging = false
                    WidgetRefreshManager.scheduleRefresh()
                }
        )
    }

    private var dotColor: Color {
        let hours = assignment.deadline.timeIntervalSinceNow / 3600
        if hours < 24 { return .red }
        if hours < 72 { return .orange }
        return .blue
    }
}
