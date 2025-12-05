import SwiftUI

struct DashboardView: View {
    let mode: CommuteMode

    private var data: DashboardData {
        switch mode {
        case .toSchool:
            return .init(
                title: "Rionized",
                weather: .init(uvIndex: 3, temperatureC: 22, humidityPercent: 55, rainWithinHour: false, forecast: [
                    .init(hour: "09", symbol: "cloud.sun", tempC: 21),
                    .init(hour: "12", symbol: "sun.max", tempC: 24),
                    .init(hour: "15", symbol: "cloud.sun.fill", tempC: 23),
                    .init(hour: "18", symbol: "cloud.rain", tempC: 19)
                ]),
                bus: .init(nextDeparture: "08:12", line: "キャンパス急行"),
                cycle: .init(
                    departureName: "中央駅",
                    destinationName: "北キャンパス",
                    availableAtDeparture: 6,
                    availableAtDestination: 12
                )
            )
        case .toHome:
            return .init(
                title: "Rionized",
                weather: .init(uvIndex: 1, temperatureC: 18, humidityPercent: 68, rainWithinHour: true, forecast: [
                    .init(hour: "17", symbol: "cloud", tempC: 18),
                    .init(hour: "19", symbol: "cloud.drizzle", tempC: 17),
                    .init(hour: "21", symbol: "cloud.moon.rain", tempC: 16),
                    .init(hour: "23", symbol: "moon.stars", tempC: 15)
                ]),
                bus: .init(nextDeparture: "18:03", line: "シティリンク"),
                cycle: .init(
                    departureName: "北キャンパス",
                    destinationName: "中央駅",
                    availableAtDeparture: 3,
                    availableAtDestination: 7
                )
            )
        }
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    weatherCard
                    busCard
                    cycleCard
                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
    }

    private var header: some View {
        GlassText(text: data.title)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)
    }

    private var weatherCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Weather", systemImage: "sun.max.fill")
                        .font(.headline)
                        .foregroundStyle(AppTheme.accent)
                    Spacer()
                }
                HStack(spacing: 24) {
                    metric(title: "UV指数", value: "\(data.weather.uvIndex)")
                    Divider().frame(height: 32)
                    metric(title: "気温", value: "\(data.weather.temperatureC)°C")
                    Divider().frame(height: 32)
                    metric(title: "湿度", value: "\(data.weather.humidityPercent)%")
                }
                Divider()
                HStack(spacing: 10) {
                    Image(systemName: data.weather.rainWithinHour ? "cloud.rain" : "cloud.sun")
                        .foregroundStyle(AppTheme.accent)
                    Text(data.weather.rainWithinHour ? "1時間以内に雨が降ります" : "1時間以内に雨は降りません")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var busCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Next Bus", systemImage: "bus")
                    .font(.headline)
                    .foregroundStyle(AppTheme.accent)
                HStack(alignment: .firstTextBaseline) {
                    Text(data.bus.nextDeparture)
                        .font(.system(size: 34, weight: .bold))
                        .monospacedDigit()
                    Spacer()
                    Text(data.bus.line)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var cycleCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Rental Cycles", systemImage: "bicycle")
                    .font(.headline)
                    .foregroundStyle(AppTheme.accent)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        stationPill(name: data.cycle.departureName, available: data.cycle.availableAtDeparture, role: "出発")
                        Spacer()
                    }
                    HStack {
                        stationPill(name: data.cycle.destinationName, available: data.cycle.availableAtDestination, role: "目的地")
                        Spacer()
                    }
                }
            }
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }

    

    private func stationPill(name: String, available: Int, role: String) -> some View {
        GlassPill {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(role)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(name)
                        .font(.subheadline)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                HStack(spacing: 6) {
                    Image(systemName: "bicycle")
                    Text("\(available)")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - GlassPill helper
struct GlassPill<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(Capsule(style: .continuous).fill(.white.opacity(0.06)))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(LinearGradient(colors: [Color.white.opacity(0.5), Color.white.opacity(0.05)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
    }
}

// MARK: - Dummy Models
private struct DashboardData {
    var title: String
    var weather: Weather
    var bus: Bus
    var cycle: Cycle

    struct Weather {
        var uvIndex: Int
        var temperatureC: Int
        var humidityPercent: Int
        var rainWithinHour: Bool
        var forecast: [ForecastItem]
    }

    struct ForecastItem: Identifiable {
        let id = UUID()
        var hour: String
        var symbol: String
        var tempC: Int
    }

    struct Bus {
        var nextDeparture: String
        var line: String
    }

    struct Cycle {
        var departureName: String
        var destinationName: String
        var availableAtDeparture: Int
        var availableAtDestination: Int
    }
}
