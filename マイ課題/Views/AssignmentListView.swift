import SwiftUI
import SwiftData

struct AssignmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Assignment.deadline) private var assignments: [Assignment]
    @StateObject private var viewModel = AssignmentViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if assignments.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("マイ課題")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await viewModel.syncFromMoodle(context: modelContext) }
                    } label: {
                        if viewModel.isSyncing {
                            ProgressView().controlSize(.small)
                        } else {
                            Label("同期", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(viewModel.isSyncing)
                }
            }
            .alert("同期エラー", isPresented: Binding(
                get: { viewModel.lastSyncError != nil },
                set: { if !$0 { viewModel.lastSyncError = nil } }
            )) {
                Button("OK") { viewModel.lastSyncError = nil }
            } message: {
                Text(viewModel.lastSyncError ?? "")
            }
        }
    }

    // v9: 同一週内に3件以上の締め切りがある週を検出する
    private var conflictedWeeks: [(weekStart: Date, count: Int)] {
        let now = Date()
        let cal = Calendar.current
        var weekCounts: [Date: Int] = [:]
        for a in assignments where !a.isCompleted && a.deadline > now {
            if let start = cal.dateInterval(of: .weekOfYear, for: a.deadline)?.start {
                weekCounts[start, default: 0] += 1
            }
        }
        return weekCounts
            .filter { $0.value >= 3 }
            .map { (weekStart: $0.key, count: $0.value) }
            .sorted { $0.weekStart < $1.weekStart }
    }

    private var list: some View {
        List {
            if !conflictedWeeks.isEmpty {
                Section {
                    ForEach(conflictedWeeks, id: \.weekStart) { item in
                        Label {
                            Text(weekRangeLabel(item.weekStart) + " に \(item.count) 件集中")
                                .font(.subheadline)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text("締め切り集中警告")
                }
            }
            ForEach(assignments) { assignment in
                NavigationLink {
                    AssignmentDetailView(assignment: assignment)
                } label: {
                    AssignmentRowView(assignment: assignment)
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        withAnimation {
                            assignment.isCompleted.toggle()
                            if assignment.isCompleted {
                                NotificationManager.cancelNotifications(for: assignment)
                            } else {
                                NotificationManager.scheduleNotifications(for: assignment)
                            }
                        }
                    } label: {
                        Label(
                            assignment.isCompleted ? "未完了に戻す" : "完了",
                            systemImage: assignment.isCompleted ? "arrow.uturn.backward" : "checkmark"
                        )
                    }
                    .tint(assignment.isCompleted ? .gray : .green)
                }
            }
            .onDelete(perform: delete)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("課題がありません")
                .font(.title3)
            Text("右上のボタンで Moodle から同期してください。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func weekRangeLabel(_ weekStart: Date) -> String {
        let cal = Calendar.current
        let end = cal.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ja_JP")
        fmt.dateFormat = "M/d"
        return "\(fmt.string(from: weekStart))〜\(fmt.string(from: end))"
    }

    private func delete(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let target = assignments[index]
                NotificationManager.cancelNotifications(for: target)
                modelContext.delete(target)
            }
        }
    }
}

#Preview {
    AssignmentListView()
        .modelContainer(for: Assignment.self, inMemory: true)
}
