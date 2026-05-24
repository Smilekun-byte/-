import SwiftUI

/// カレンダーの各マスを型安全に表現するエンティティ
enum CalendarSlot: Hashable {
    case placeholder(id: UUID)
    case date(Date)
}

/// 月曜始まりの暦法アルゴリズムを内包した汎用カレンダーグリッド。
/// セルの描画ロジックはクロージャで外部から注入し、再利用性を確保する。
struct CalendarGridView<CellContent: View>: View {
    let currentMonth: Date
    @Binding var selectedDate: Date
    @ViewBuilder let content: (Date) -> CellContent

    private let weekdayHeaders = ["月", "火", "水", "木", "金", "土", "日"]

    private var slots: [CalendarSlot] {
        generateSlots()
    }

    var body: some View {
        VStack(spacing: 8) {
            // 曜日ヘッダー（月曜始まり固定）
            HStack(spacing: 0) {
                ForEach(weekdayHeaders, id: \.self) { label in
                    Text(label)
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(
                            label == "土" ? Color.blue :
                            label == "日" ? Color.red  : Color.primary
                        )
                }
            }

            // 日付グリッド
            Grid(alignment: .center, horizontalSpacing: 2, verticalSpacing: 4) {
                ForEach(0..<slots.count / 7, id: \.self) { row in
                    GridRow {
                        ForEach(0..<7, id: \.self) { col in
                            let slot = slots[row * 7 + col]
                            switch slot {
                            case .placeholder:
                                Color.clear.frame(minHeight: 44)

                            case .date(let date):
                                content(date)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(
                                        CalendarProvider.shared.calendar
                                            .isDate(date, inSameDayAs: selectedDate)
                                            ? Color.blue.opacity(0.12) : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture { selectedDate = date }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 暦法ロジック

    private func generateSlots() -> [CalendarSlot] {
        let cal = CalendarProvider.shared.calendar
        guard
            let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth)),
            let range    = cal.range(of: .day, in: .month, for: firstDay)
        else { return [] }

        // 月曜始まりへのシフト演算（weekday: 1=日, 2=月 ... 7=土）
        let weekdayOfFirst = cal.component(.weekday, from: firstDay)
        let leadingBlanks  = (weekdayOfFirst + 5) % 7

        var slots: [CalendarSlot] = []

        // 前月の余白
        for _ in 0..<leadingBlanks {
            slots.append(.placeholder(id: UUID()))
        }
        // 今月の日付
        for day in 0..<range.count {
            if let date = cal.date(byAdding: .day, value: day, to: firstDay) {
                slots.append(.date(date))
            }
        }
        // 末尾の余白（7の倍数に揃える）
        while slots.count % 7 != 0 {
            slots.append(.placeholder(id: UUID()))
        }

        return slots
    }
}
