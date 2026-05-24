import SwiftUI
import SwiftData

struct CustomCalendarView: View {
    @Query private var allAssignments: [Assignment]
    @StateObject private var viewModel: CalendarViewModel

    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date = Date()

    // ViewModelを外部から注入可能にする（Preview・Unit Test 対応）
    init(viewModel: CalendarViewModel = CalendarViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var cal: Calendar { CalendarProvider.shared.calendar }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthNavigationHeader
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                CalendarGridView(currentMonth: currentMonth, selectedDate: $selectedDate) { date in
                    let key  = CalendarProvider.shared.makeStringKey(from: date)
                    let heat = viewModel.heatMap[key] ?? .safe
                    CalendarDayCell(date: date, heat: heat,
                                   isSelected: cal.isDate(date, inSameDayAs: selectedDate),
                                   isToday: cal.isDateInToday(date))
                }
                .padding(.horizontal)

                Divider().padding(.top, 8)

                taskListForSelectedDay
            }
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: allAssignments, initial: true) { _, newValue in
                viewModel.precomputeHeatMap(from: newValue)
            }
        }
    }

    // MARK: - Subviews

    private var monthNavigationHeader: some View {
        HStack {
            Button {
                currentMonth = cal.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
            } label: {
                Image(systemName: "chevron.left").bold()
            }

            Spacer()

            Text(currentMonth, format: .dateTime.year().month(.wide))
                .font(.headline)

            Spacer()

            Button {
                currentMonth = cal.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
            } label: {
                Image(systemName: "chevron.right").bold()
            }
        }
    }

    private var taskListForSelectedDay: some View {
        let tasks = viewModel.getTasks(for: selectedDate)
        return List {
            if tasks.isEmpty {
                Label("この日の課題はありません", systemImage: "cup.and.saucer")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(tasks) { assignment in
                    NavigationLink {
                        AssignmentDetailView(assignment: assignment)
                    } label: {
                        AssignmentRowView(assignment: assignment)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}
