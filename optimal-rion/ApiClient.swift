import Foundation

struct AppResponse: Decodable {
    struct Weather: Decodable {
        let uvIndex: Double
        let temperatureC: Double
        let humidityPercent: Int
        let precip10min: Double
    }
    struct Bus: Decodable {
        let nextDeparture: String
        let line: String
    }
    struct Cycle: Decodable {
        let departureName: String
        let destinationName: String
        let availableAtDeparture: Int
        let availableAtDestination: Int
    }

    let title: String
    let weather: Weather
    let bus: Bus
    let cycle: Cycle
}

enum ApiError: Error { case invalidURL, badStatus(Int), decoding }

final class ApiClient {
    // Adjust for your server base URL if different
    var baseURL: URL = URL(string: "http://localhost:8080")!
    private static var cache: [String: (date: Date, value: AppResponse)] = [:]
    private let cacheTTL: TimeInterval = 60

    func fetchApp(units: String = "metric", lang: String = "ja") async throws -> AppResponse {
        var comps = URLComponents(url: baseURL.appendingPathComponent("/api/app"), resolvingAgainstBaseURL: false)
        comps?.queryItems = [
            URLQueryItem(name: "units", value: units),
            URLQueryItem(name: "lang", value: lang)
        ]
        guard let url = comps?.url else { throw ApiError.invalidURL }

        var req = URLRequest(url: url)
        req.timeoutInterval = 10

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw ApiError.invalidURL }
        guard (200..<300).contains(http.statusCode) else { throw ApiError.badStatus(http.statusCode) }
        do {
            return try JSONDecoder().decode(AppResponse.self, from: data)
        } catch {
            throw ApiError.decoding
        }
    }

    func fetchApp(mode: CommuteMode, units: String = "metric", lang: String = "ja") async throws -> AppResponse {
        let path: String
        switch mode {
        case .toSchool: path = "/api/app/to-school"
        case .toHome:   path = "/api/app/to-home"
        }
        var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        comps?.queryItems = [
            URLQueryItem(name: "units", value: units),
            URLQueryItem(name: "lang", value: lang)
        ]
        guard let url = comps?.url else { throw ApiError.invalidURL }
        var req = URLRequest(url: url)
        req.timeoutInterval = 10
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw ApiError.invalidURL }
        guard (200..<300).contains(http.statusCode) else { throw ApiError.badStatus(http.statusCode) }
        do {
            return try JSONDecoder().decode(AppResponse.self, from: data)
        } catch {
            throw ApiError.decoding
        }
    }

    func fetchAppWithCache(mode: CommuteMode, units: String = "metric", lang: String = "ja") async throws -> (AppResponse, Bool) {
        let key = "\(mode.rawValue)-\(units)-\(lang)"
        if let entry = ApiClient.cache[key], Date().timeIntervalSince(entry.date) < cacheTTL {
            return (entry.value, true)
        }
        let fresh = try await fetchApp(mode: mode, units: units, lang: lang)
        ApiClient.cache[key] = (date: Date(), value: fresh)
        return (fresh, false)
    }

    func fetchAppFresh(mode: CommuteMode, units: String = "metric", lang: String = "ja") async throws -> AppResponse {
        let resp = try await fetchApp(mode: mode, units: units, lang: lang)
        let key = "\(mode.rawValue)-\(units)-\(lang)"
        ApiClient.cache[key] = (date: Date(), value: resp)
        return resp
    }

    struct CycleResponse: Decodable {
        let departureName: String
        let destinationName: String
        let availableAtDeparture: Int
        let availableAtDestination: Int
    }

    func fetchCycle(mode: CommuteMode) async throws -> CycleResponse {
        let path: String
        switch mode {
        case .toSchool: path = "/api/cycle/to-school"
        case .toHome:   path = "/api/cycle/to-home"
        }
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.timeoutInterval = 8
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw ApiError.invalidURL }
        guard (200..<300).contains(http.statusCode) else { throw ApiError.badStatus(http.statusCode) }
        do {
            return try JSONDecoder().decode(CycleResponse.self, from: data)
        } catch {
            throw ApiError.decoding
        }
    }
}
