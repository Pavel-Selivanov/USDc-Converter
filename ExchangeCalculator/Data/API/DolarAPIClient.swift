//
//  DolarAPIClient.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

final class DolarAPIClient {
    private let baseURL: URL
    private let session: URLSession

    init(
        baseURL: URL = URL(string: "https://api.dolarapp.dev/v1")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchAvailableCurrencyCodes() async throws -> [String] {
        try await request("tickers-currencies")
    }

    func fetchTickers(currencies: [String]) async throws -> [TickerDTO] {
        let codes = currencies
            .map { $0.uppercased() }
            .joined(separator: ",")

        return try await request(
            "tickers",
            queryItems: [URLQueryItem(name: "currencies", value: codes)]
        )
    }

    private func request<T: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components?.url else {
            throw DolarAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DolarAPIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw DolarAPIError.httpStatus(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw DolarAPIError.decoding(error)
        }
    }
}
