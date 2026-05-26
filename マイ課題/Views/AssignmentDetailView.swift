import SwiftUI
import SwiftData

struct AssignmentDetailView: View {
    @Bindable var assignment: Assignment
    @Environment(\.modelContext) private var modelContext
    @State private var courseInput: String = ""

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

            courseSection

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

    // MARK: - 課程名セクション

    @ViewBuilder
    private var courseSection: some View {
        if let course = assignment.course {
            // 命名済み：テキスト表示
            Section("課程名") {
                Text(course.name)
            }
        } else if assignment.categoryID != nil {
            // Moodle 由来だが未命名：入力フィールドを表示
            Section("課程名") {
                TextField("課程名を入力...", text: $courseInput)
                    .autocorrectionDisabled()

                if !courseInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button("保存して同じ課程のタスク全てに反映") {
                        saveCourse()
                    }
                }
            }
        }
        // categoryID がない（手動追加タスク）はセクション非表示
    }

    // MARK: - 保存

    private func saveCourse() {
        guard let cid = assignment.categoryID else { return }
        let trimmed = courseInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let course = Course(categoryID: cid, name: trimmed)
        modelContext.insert(course)

        // 同じ categoryID を持つ全タスクに Course をリンク
        let descriptor = FetchDescriptor<Assignment>(
            predicate: #Predicate { $0.categoryID == cid }
        )
        if let all = try? modelContext.fetch(descriptor) {
            for a in all { a.course = course }
        }
        try? modelContext.save()
        courseInput = ""
    }
}
