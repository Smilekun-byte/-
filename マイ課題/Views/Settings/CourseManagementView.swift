import SwiftUI
import SwiftData

struct CourseManagementView: View {
    @Query(sort: \Course.name) private var courses: [Course]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = AssignmentViewModel()

    var body: some View {
        Form {
            if courses.isEmpty {
                ContentUnavailableView(
                    "課程がありません",
                    systemImage: "books.vertical",
                    description: Text("課題を同期して課程名を登録すると、ここに表示されます。")
                )
            } else {
                Section {
                    ForEach(courses) { course in
                        courseRow(course)
                    }
                } footer: {
                    Text("課程名はタップで編集できます。色は同じ課程のすべての課題に反映されます。")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("課程管理")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func courseRow(_ course: Course) -> some View {
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
                    set: {
                        course.colorHex = $0.toHex() ?? course.colorHex
                        viewModel.flushToWidget(context: modelContext)
                    }
                ),
                supportsOpacity: false
            )
            .labelsHidden()
            .frame(width: 28)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                modelContext.delete(course)
                viewModel.flushToWidget(context: modelContext)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}
