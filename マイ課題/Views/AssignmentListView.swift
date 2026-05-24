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
            .alert("同期エラー", isPresented: .constant(viewModel.lastSyncError != nil)) {
                Button("OK") { viewModel.lastSyncError = nil }
            } message: {
                Text(viewModel.lastSyncError ?? "")
            }
        }
    }

    private var list: some View {
        List {
            ForEach(assignments) { assignment in
                NavigationLink {
                    AssignmentDetailView(assignment: assignment)
                } label: {
                    AssignmentRowView(assignment: assignment)
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        withAnimation { assignment.isCompleted.toggle() }
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

    private func delete(at offsets: IndexSet) {
        withAnimation {
            for index in offsets { modelContext.delete(assignments[index]) }
        }
    }
}

#Preview {
    AssignmentListView()
        .modelContainer(for: Assignment.self, inMemory: true)
}
