import CairnCore
import SwiftUI

struct TimePickerSheet: View {
    let title: String

    @Binding var startMinutes: Int
    @Binding var endMinutes: Int?

    let onDone: () -> Void

    @State private var startDate: Date
    @State private var endDate: Date

    init(
        title: String,
        startMinutes: Binding<Int>,
        endMinutes: Binding<Int?> = .constant(nil),
        onDone: @escaping () -> Void
    ) {
        self.title = title
        _startMinutes = startMinutes
        _endMinutes = endMinutes
        self.onDone = onDone
        _startDate = State(initialValue: Self.date(from: startMinutes.wrappedValue))
        _endDate = State(initialValue: Self.date(from: endMinutes.wrappedValue ?? 0))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: CairnSpacing.size4) {
                if endMinutes != nil {
                    pickerRow(label: "Start", selection: $startDate)
                    Divider().padding(.horizontal, CairnSpacing.size4)
                    pickerRow(label: "End", selection: $endDate)
                } else {
                    pickerRow(label: nil, selection: $startDate)
                }
                Spacer()
            }
            .padding(.top, CairnSpacing.size5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        commit()
                        onDone()
                    }
                    .font(.cairnLabel.weight(.semibold))
                    .foregroundStyle(Color.cairnAccentInk)
                }
            }
            .toolbarBackground(Color.cairnSurfaceOverlay, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.cairnPaper)
        .preferredColorScheme(.light)
    }

    private func pickerRow(label: String?, selection: Binding<Date>) -> some View {
        HStack {
            if let label {
                Text(label)
                    .font(.cairnLabel.weight(.medium))
                    .foregroundStyle(Color.cairnTextPrimary)
            }
            Spacer()
            DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .padding(.horizontal, CairnSpacing.size5)
    }

    private func commit() {
        startMinutes = Self.minutes(from: startDate)
        if endMinutes != nil {
            endMinutes = Self.minutes(from: endDate)
        }
    }

    private static func date(from minutes: Int) -> Date {
        let (hour, minute) = RemindersSettings.hourMinute(from: minutes)
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    private static func minutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
