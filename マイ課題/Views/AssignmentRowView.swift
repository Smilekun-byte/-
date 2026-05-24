import SwiftUI

struct AssignmentRowView: View {
    let assignment: Assignment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(assignment.cleanTitle)
                .font(.headline)
                .strikethrough(assignment.isCompleted)
                .foregroundStyle(assignment.isCompleted ? .secondary : .primary)

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .imageScale(.small)
                Text(assignment.deadline, style: .date)
                Text(assignment.deadline, style: .time)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // 0:00 トラップを検知した場合に警告バナーを表示する
            if assignment.isMidnightDeadline {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("注意：締め切りは前日深夜の可能性があります！")
                }
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.2))
                .foregroundStyle(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            if !assignment.userNotes.isEmpty {
                Text(assignment.userNotes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
