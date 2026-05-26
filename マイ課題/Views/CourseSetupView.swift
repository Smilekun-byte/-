import SwiftUI
import SwiftData

/// 同期後に未命名の categoryID が検出されたとき、ユーザーに課程名を付けさせるシート。
/// 保存後は同じ categoryID を持つ既存タスクを Course に自動リンクする。
struct CourseSetupView: View {
    let unknownCategoryIDs: [String]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var names: [String: String] = [:]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Moodle の同期で \(unknownCategoryIDs.count) 件の新しい課程が見つかりました。名前を入力すると以降のタスクに自動で紐付けされます。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(unknownCategoryIDs, id: \.self) { categoryID in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(categoryID)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        TextField("課程名（例：線形代数学）", text: Binding(
                            get: { names[categoryID] ?? "" },
                            set: { names[categoryID] = $0 }
                        ))
                        .autocorrectionDisabled()
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("新しい課程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("後で") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveCourses()
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveCourses() {
        for categoryID in unknownCategoryIDs {
            let trimmed = (names[categoryID] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let course = Course(categoryID: categoryID, name: trimmed)
            modelContext.insert(course)

            // 既存タスクのうち同じ categoryID を持つものを Course にリンク
            let cid = categoryID
            let descriptor = FetchDescriptor<Assignment>(
                predicate: #Predicate { $0.categoryID == cid }
            )
            if let assignments = try? modelContext.fetch(descriptor) {
                for assignment in assignments { assignment.course = course }
            }
        }
        try? modelContext.save()
    }
}
