import SwiftUI

struct DashboardView: View {
    let mode: CommuteMode

    @State private var data: DashboardData = .placeholder
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                    weatherCard
                    busCard
                    cycleCard
                    HStack {
                        Spacer()
                        Button {
                            Task { await loadData(force: true) }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                Text("再読み込み")
                            }
                            .font(.subheadline.weight(.semibold))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(.ultraThinMaterial, in: Capsule())
                        }
                        .accessibilityLabel("Reload")
                        Spacer()
                    }
                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .overlay(alignment: .bottom) {
                if isLoading {
                    ProgressView()
                        .padding(.bottom, 16)
                }
            }
        }
        .task { await loadData() }
    }

    private var header: some View {
        HStack {
            Spacer()
            HStack(spacing: 12) {
                Image("not-kitty")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                GlassText(text: data.title)
            }
            Spacer()
        }
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
                    metric(title: "UV指数", value: formatNumber(data.weather.uvIndex, decimals: 1))
                    Divider().frame(height: 32)
                    metric(title: "気温", value: "\(formatNumber(data.weather.temperatureC, decimals: 1))°C")
                    Divider().frame(height: 32)
                    metric(title: "湿度", value: "\(data.weather.humidityPercent)%")
                }
                Divider()
                HStack(spacing: 10) {
                    Image(systemName: data.weather.precip10Min > 0 ? "cloud.rain" : "cloud.sun")
                        .foregroundStyle(AppTheme.accent)
                    Text("10分後の降水量: \(formatPrecip(data.weather.precip10Min)) mm")
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

    private func formatPrecip(_ value: Double) -> String {
        let formatted = String(format: "%.1f", value)
        return formatted
    }

    private func formatNumber(_ value: Double, decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f", value)
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
        var uvIndex: Double
        var temperatureC: Double
        var humidityPercent: Int
        var precip10Min: Double
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

    static var placeholder: DashboardData {
        .init(
            title: "Rionized",
            weather: .init(uvIndex: 0, temperatureC: 0, humidityPercent: 0, precip10Min: 0, forecast: []),
            bus: .init(nextDeparture: "--:--", line: "--"),
            cycle: .init(departureName: "--", destinationName: "--", availableAtDeparture: 0, availableAtDestination: 0)
        )
    }
}

// MARK: - Networking
extension DashboardView {
    func loadData(force: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let api = ApiClient()
            let resp: AppResponse
            if force {
                resp = try await api.fetchAppFresh(mode: mode, units: "metric", lang: "ja")
            } else {
                let result = try await api.fetchAppWithCache(mode: mode, units: "metric", lang: "ja")
                resp = result.0
            }
            self.data = .init(
                title: resp.title,
                weather: .init(
                    uvIndex: resp.weather.uvIndex,
                    temperatureC: resp.weather.temperatureC,
                    humidityPercent: resp.weather.humidityPercent,
                    precip10Min: resp.weather.precip10min,
                    forecast: []
                ),
                bus: .init(nextDeparture: resp.bus.nextDeparture, line: resp.bus.line),
                cycle: .init(
                    departureName: resp.cycle.departureName,
                    destinationName: resp.cycle.destinationName,
                    availableAtDeparture: resp.cycle.availableAtDeparture,
                    availableAtDestination: resp.cycle.availableAtDestination
                )
            )
            // Always refresh live cycle data to ensure real-time values
            if let live = try? await api.fetchCycle(mode: mode) {
                self.data.cycle = .init(
                    departureName: live.departureName,
                    destinationName: live.destinationName,
                    availableAtDeparture: live.availableAtDeparture,
                    availableAtDestination: live.availableAtDestination
                )
            }
            errorMessage = nil
        } catch ApiError.badStatus(let code) {
            errorMessage = "Server error: \(code)"
        } catch ApiError.decoding {
            errorMessage = "データの解析に失敗しました"
        } catch {
            errorMessage = "通信エラーが発生しました"
        }
    }
}
