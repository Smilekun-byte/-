import SwiftUI
import SwiftData

struct AssignmentDetailView: View {
    @Bindable var assignment: Assignment
    @Environment(\.modelContext) private var modelContext
    @State private var courseInput: String = ""
    @StateObject private var viewModel = AssignmentViewModel()

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

            estimatedTimeSection

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
        .onChange(of: assignment.isCompleted) { _, completed in
            if completed {
                NotificationManager.cancelNotifications(for: assignment)
            } else {
                NotificationManager.scheduleNotifications(for: assignment)
            }
            viewModel.flushToWidget(context: modelContext)
        }
    }

    // MARK: - 予想所要時間セクション

    @ViewBuilder
    private var estimatedTimeSection: some View {
        Section("予想所要時間") {
            if assignment.estimatedMinutes != nil {
                Stepper(
                    assignment.estimatedTimeLabel ?? "",
                    value: Binding(
                        get: { assignment.estimatedMinutes ?? 60 },
                        set: { assignment.estimatedMinutes = $0 }
                    ),
                    in: 30...480,
                    step: 30
                )
                Button("設定を削除", role: .destructive) {
                    assignment.estimatedMinutes = nil
                }
                .font(.subheadline)
            } else {
                Button("所要時間を設定する") {
                    assignment.estimatedMinutes = 60
                }
            }
        }
    }

    // MARK: - 課程名セクション

    @ViewBuilder
    private var courseSection: some View {
        if let course = assignment.course {
            // 命名済み：名前を編集可能な TextField + カラーピッカー
            // course.name はユーザー編集データ。mergeMoodleData では上書きされない。
            Section("課程名") {
                HStack {
                    TextField("課程名", text: Binding(
                        get: { course.name },
                        set: { course.name = $0 }
                    ))
                    .autocorrectionDisabled()
                    Spacer(minLength: 8)
                    ColorPicker(
                        "",
                        selection: Binding(
                            get: { Color(hex: course.colorHex) },
                            set: { course.colorHex = $0.toHex() ?? course.colorHex }
                        ),
                        supportsOpacity: false
                    )
                    .labelsHidden()
                    .frame(width: 28)
                }
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
        viewModel.flushToWidget(context: modelContext)
    }
}
