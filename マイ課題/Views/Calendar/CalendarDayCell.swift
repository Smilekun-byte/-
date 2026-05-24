import SwiftUI

/// カレンダーの1日分セル。選択状態・今日・熱量ドットを表示する。
struct CalendarDayCell: View {
    let date: Date
    let heat: DeadlineHeat
    let isSelected: Bool
    let isToday: Bool

    private var dayNumber: Int {
        CalendarProvider.shared.calendar.component(.day, from: date)
    }

    var body: some View {
        VStack(spacing: 3) {
            Text("\(dayNumber)")
                .font(.system(.body, design: .rounded))
                .bold(isSelected || isToday)
                .foregroundStyle(
                    isSelected ? Color.white :
                    isToday    ? Color.blue  : Color.primary
                )

            heatDot
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(isSelected ? Color.blue : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var heatDot: some View {
        if let rgb = heat.dotColor {
            Circle()
                .fill(Color(red: rgb.red, green: rgb.green, blue: rgb.blue))
                .frame(width: 6, height: 6)
        } else {
            Spacer().frame(height: 6)
        }
    }
}
