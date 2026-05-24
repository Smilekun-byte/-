import SwiftUI

struct AssignmentDetailView: View {
    @Bindable var assignment: Assignment

    var body: some View {
        Form {
            Section("課題情報") {
                LabeledContent("タイトル", value: assignment.cleanTitle)
                LabeledContent("締め切り") {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(assignment.deadline, style: .date)
                        Text(assignment.deadline, style: .time)
                    }
                }
                if assignment.isMidnightDeadline {
                    Label("前日深夜の可能性あり", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption.bold())
                }
            }

            Section("補足メモ") {
                TextField("メモを追加...", text: $assignment.userNotes, axis: .vertical)
                    .lineLimit(3...8)
            }

            if !assignment.rawDescription.isEmpty {
                Section("Moodle 説明文") {
                    Text(assignment.rawDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Toggle("完了済み", isOn: $assignment.isCompleted)
            }
        }
        .navigationTitle(assignment.cleanTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
