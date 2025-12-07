import SwiftUI

struct BusTimetableView: View {
    @State private var day: BusDayType = BusTimetable.dayType()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                timetableSection(title: "新座駅南口 → 新座キャンパス", data: BusTimetable.toCampus[day] ?? [:])
                timetableSection(title: "新座キャンパス → 新座駅南口", data: BusTimetable.fromCampus[day] ?? [:])
            }
            .padding(16)
        }
        .navigationTitle("スクールバス時刻表")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Picker("", selection: $day) {
                    ForEach(BusDayType.allCases) { d in
                        Text(d.rawValue).tag(d)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
            }
        }
    }

    private func timetableSection(title: String, data: [Int: [Int]]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 4)

            VStack(spacing: 8) {
                ForEach(BusTimetable.hours, id: \.self) { hour in
                    HStack(alignment: .top) {
                        Text(String(format: "%02d", hour))
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 28, alignment: .trailing)
                            .foregroundStyle(.secondary)
                        let minutes = data[hour] ?? []
                        if minutes.isEmpty {
                            Divider()
                        } else {
                            Text(minutes.map { String(format: "%02d", $0) }.joined(separator: " "))
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// Data moved to BusTimetable in BusTimetableData.swift

struct BusTimetableView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { BusTimetableView() }
    }
}
