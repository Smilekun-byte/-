import SwiftUI
import SwiftData

// MARK: - 8色パレット（Course のデフォルト/凡例で使用）

enum CoursePalette {
    static let colors: [String] = [
        "#D85A30", "#378ADD", "#1D9E75", "#7F77DD",
        "#BA7517", "#D4537E", "#888780", "#639922"
    ]
}

// MARK: - Matrix View

struct MatrixView: View {
    @Query(filter: #Predicate<Assignment> { !$0.isCompleted },
           sort: \Assignment.deadline)
    private var assignments: [Assignment]

    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = AssignmentViewModel()

    @State private var selectedAssignment: Assignment?

    private let maxDays: Double = 21        // 3週間表示
    private let padL: CGFloat = 36          // 縦軸ラベル用
    private let padR: CGFloat = 16
    private let padT: CGFloat = 12
    private let padB: CGFloat = 28          // 横軸ラベル用

    private var visible: [Assignment] {
        let now = Date()
        let horizon = now.addingTimeInterval(maxDays * 86400)
        return assignments.filter { $0.deadline > now && $0.deadline <= horizon }
    }

    /// 表示中課題の週ごと件数（0=今週, 1=1週後, 2=2週後）
    private var weekClusters: [(week: Int, count: Int)] {
        let now = Date()
        var buckets: [Int: Int] = [:]
        for a in visible {
            let days = a.deadline.timeIntervalSince(now) / 86400
            let week = min(2, Int(days / 7))
            buckets[week, default: 0] += 1
        }
        return (0...2).map { (week: $0, count: buckets[$0] ?? 0) }
    }

    private var legendCourses: [Course] {
        let unique = Set(visible.compactMap { $0.course })
        return unique.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                clusterSummary
                    .padding(.horizontal)
                    .padding(.top, 8)

                GeometryReader { geo in
                    ZStack {
                        Color(.systemGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        MatrixGrid(size: geo.size,
                                   padL: padL, padR: padR,
                                   padT: padT, padB: padB,
                                   maxDays: maxDays)

                        MatrixAxisLabels(size: geo.size,
                                         padL: padL, padR: padR,
                                         padT: padT, padB: padB,
                                         maxDays: maxDays)

                        ForEach(visible) { assignment in
                            TaskDotView(
                                assignment: assignment,
                                canvas: geo.size,
                                maxDays: maxDays,
                                padL: padL, padR: padR,
                                padT: padT, padB: padB,
                                onPriorityChanged: {
                                    viewModel.flushToWidget(context: modelContext)
                                },
                                onTap: { selectedAssignment = assignment }
                            )
                        }

                        if visible.isEmpty { emptyState }
                    }
                }
                .frame(height: containerHeight)
                .padding(.horizontal)

                legendStrip
                    .padding(.bottom, 8)

                Spacer(minLength: 0)
            }
            .navigationTitle("課題マップ")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedAssignment) { assignment in
                NavigationStack {
                    AssignmentDetailView(assignment: assignment)
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - 子ビュー

    private var clusterSummary: some View {
        HStack(spacing: 12) {
            ForEach(weekClusters, id: \.week) { item in
                clusterChip(label: weekLabel(item.week), count: item.count)
            }
            Spacer()
            Text("計 \(visible.count) 件")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
    }

    private func clusterChip(label: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.caption2.bold())
            Text("\(count)").font(.caption.monospacedDigit().bold())
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            Capsule().fill(Color.secondary.opacity(count >= 3 ? 0.25 : 0.10))
        )
        .foregroundStyle(count >= 3 ? Color.orange : Color.secondary)
    }

    private var legendStrip: some View {
        Group {
            if legendCourses.isEmpty {
                EmptyView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(legendCourses) { course in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: course.colorHex))
                                    .frame(width: 10, height: 10)
                                Text(course.name)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                Capsule().fill(Color.secondary.opacity(0.10))
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.scatter")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("3週間以内の課題なし")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var containerHeight: CGFloat {
        UIScreen.main.bounds.height * 0.50
    }

    private func weekLabel(_ week: Int) -> String {
        switch week {
        case 0:  return "今週"
        case 1:  return "1週後"
        default: return "2週後"
        }
    }
}

// MARK: - グリッド（薄いガイド線）

private struct MatrixGrid: View {
    let size: CGSize
    let padL: CGFloat
    let padR: CGFloat
    let padT: CGFloat
    let padB: CGFloat
    let maxDays: Double

    var body: some View {
        Canvas { ctx, _ in
            let cw = size.width - padL - padR
            let ch = size.height - padT - padB

            // 横線（優先度 0.25 / 0.5 / 0.75）
            for p in [0.25, 0.5, 0.75] as [Double] {
                let y = padT + CGFloat(1.0 - p) * ch
                var path = Path()
                path.move(to: CGPoint(x: padL, y: y))
                path.addLine(to: CGPoint(x: size.width - padR, y: y))
                ctx.stroke(path, with: .color(.secondary.opacity(0.06)), lineWidth: 0.5)
            }

            // 縦線（1 / 2 週目）
            for week in [1, 2] as [Int] {
                let x = padL + CGFloat(Double(week) * 7.0 / maxDays) * cw
                var path = Path()
                path.move(to: CGPoint(x: x, y: padT))
                path.addLine(to: CGPoint(x: x, y: size.height - padB))
                ctx.stroke(path, with: .color(.secondary.opacity(0.06)), lineWidth: 0.5)
            }

            // 左端の上向き矢印（Widget と統一: 細い縦線 + 三角ヘッド）
            let arrowX = padL / 2
            let arrowColor = GraphicsContext.Shading.color(.gray.opacity(0.6))

            var shaft = Path()
            shaft.move(to: CGPoint(x: arrowX, y: size.height - padB))
            shaft.addLine(to: CGPoint(x: arrowX, y: padT + 4))
            ctx.stroke(shaft, with: arrowColor, lineWidth: 1.25)

            var head = Path()
            head.move(to: CGPoint(x: arrowX, y: padT - 2))
            head.addLine(to: CGPoint(x: arrowX - 3.5, y: padT + 5))
            head.addLine(to: CGPoint(x: arrowX + 3.5, y: padT + 5))
            head.closeSubpath()
            ctx.fill(head, with: arrowColor)
        }
    }
}

// MARK: - 軸ラベル（縦=矢印アイコン、横=今日/1週/2週/3週）

private struct MatrixAxisLabels: View {
    let size: CGSize
    let padL: CGFloat
    let padR: CGFloat
    let padT: CGFloat
    let padB: CGFloat
    let maxDays: Double

    private var cw: CGFloat { size.width - padL - padR }
    private var ch: CGFloat { size.height - padT - padB }

    var body: some View {
        ZStack {
            // 縦軸ラベルは Widget と統一して非表示（矢印1本のみ・MatrixGrid 側で描画）
            // X 軸：今日 / 1週 / 2週 / 3週
            let xLabels: [(Double, String)] = [
                (0.0, "今日"), (1.0 / 3.0, "1週"),
                (2.0 / 3.0, "2週"), (1.0, "3週")
            ]
            ForEach(xLabels, id: \.1) { ratio, label in
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .position(x: padL + CGFloat(ratio) * cw,
                              y: size.height - padB / 2)
            }
        }
    }
}

// MARK: - タスクドット（縦ドラッグ=優先度変更、タップ=詳細）

private struct TaskDotView: View {
    @Bindable var assignment: Assignment
    let canvas: CGSize
    let maxDays: Double
    let padL: CGFloat
    let padR: CGFloat
    let padT: CGFloat
    let padB: CGFloat
    let onPriorityChanged: () -> Void
    let onTap: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    private var cw: CGFloat { canvas.width - padL - padR }
    private var ch: CGFloat { canvas.height - padT - padB }

    private var dotX: CGFloat {
        let days = assignment.deadline.timeIntervalSinceNow / 86400
        return padL + CGFloat(min(days / maxDays, 1.0)) * cw
    }

    private var baseDotY: CGFloat {
        padT + CGFloat(1.0 - assignment.userPriority) * ch
    }

    private var currentDotY: CGFloat {
        max(padT, min(canvas.height - padB, baseDotY + dragOffset))
    }

    private var dotSize: CGFloat { isDragging ? 18 : 14 }

    var body: some View {
        ZStack {
            // ラベル：ドット右側に独立配置・ヒットテスト透過
            Text(courseLabel)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Capsule().fill(.background.opacity(0.85)))
                .alignmentGuide(.leading) { _ in 0 }
                .position(x: dotX + dotSize / 2 + 22, y: currentDotY)
                .allowsHitTesting(false)

            // ドット：中心を正しく (dotX, currentDotY) に置き、ヒット領域は円形のみ
            Circle()
                .fill(dotColor)
                .frame(width: dotSize, height: dotSize)
                .shadow(color: isDragging ? dotColor.opacity(0.4) : .clear, radius: 6)
                .animation(.spring(duration: 0.15), value: isDragging)
                .contentShape(Circle())
                .position(x: dotX, y: currentDotY)
                .onTapGesture { onTap() }
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { value in
                            isDragging = true
                            dragOffset = value.translation.height
                        }
                        .onEnded { _ in
                            let newPriority = 1.0 - Double(currentDotY - padT) / Double(ch)
                            assignment.userPriority = max(0, min(1, newPriority))
                            dragOffset = 0
                            isDragging = false
                            onPriorityChanged()
                        }
                )
        }
    }

    private var courseLabel: String {
        assignment.course?.name ?? assignment.cleanTitle
    }

    private var dotColor: Color {
        let hours = assignment.deadline.timeIntervalSinceNow / 3600
        if hours < 24 { return .red }
        if hours < 72 { return .orange }
        if let hex = assignment.course?.colorHex { return Color(hex: hex) }
        return .blue
    }
}
