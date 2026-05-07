//
//  CurrencyRepositoryTests.swift
//  ExchangeCalculatorTests
//
//  Created by Pavel Selivanov on 5/10/26.
//

import Foundation
import Testing
@testable import ExchangeCalculator

@Suite("CurrencyRepository")
struct CurrencyRepositoryTests {

    @Test("Remote success saves currencies to cache and returns remote snapshot")
    func remoteSuccessSavesCurrenciesToCache() async throws {
        let cache = makeCache()
        let sut = CurrencyRepository(
            remoteDataSource: CurrencyRemoteDataSourceMock(result: .success(["MXN", "ARS", "USDC"])),
            cache: cache,
            baseCurrency: .usdc
        )

        let snapshot = try await sut.availableCurrencies()

        #expect(snapshot.source == .remote)
        #expect(snapshot.currencies == [.mxn, .ars])
        #expect(await cache.load()?.domainCurrencies == [.mxn, .ars])
    }

    @Test("Empty remote response returns existing cache without overwriting it")
    func emptyRemoteResponseReturnsCacheWithoutOverwriting() async throws {
        let cache = makeCache()
        let cachedAt = Date(timeIntervalSince1970: 1_800_000_000)
        await cache.save([.ars, .brl], updatedAt: cachedAt)
        let sut = CurrencyRepository(
            remoteDataSource: CurrencyRemoteDataSourceMock(result: .success([])),
            cache: cache,
            baseCurrency: .usdc
        )

        let snapshot = try await sut.availableCurrencies()

        #expect(snapshot.source == .cache)
        #expect(snapshot.currencies == [.ars, .brl])
        #expect(snapshot.updatedAt == cachedAt)
        #expect(await cache.load()?.domainCurrencies == [.ars, .brl])
    }

    @Test("Remote failure returns existing cache without overwriting it with fallback")
    func remoteFailureReturnsCacheWithoutOverwriting() async throws {
        let cache = makeCache()
        let cachedAt = Date(timeIntervalSince1970: 1_800_000_001)
        await cache.save([.mxn, .cop], updatedAt: cachedAt)
        let sut = CurrencyRepository(
            remoteDataSource: CurrencyRemoteDataSourceMock(result: .failure(DolarAPIError.invalidResponse)),
            cache: cache,
            baseCurrency: .usdc
        )

        let snapshot = try await sut.availableCurrencies()

        #expect(snapshot.source == .cache)
        #expect(snapshot.currencies == [.mxn, .cop])
        #expect(snapshot.updatedAt == cachedAt)
        #expect(await cache.load()?.domainCurrencies == [.mxn, .cop])
    }

    @Test("Remote failure without cache returns fallback without writing it to cache")
    func remoteFailureWithoutCacheReturnsFallbackWithoutWriting() async throws {
        let cache = makeCache()
        let sut = CurrencyRepository(
            remoteDataSource: CurrencyRemoteDataSourceMock(result: .failure(DolarAPIError.invalidResponse)),
            cache: cache,
            baseCurrency: .usdc
        )

        let snapshot = try await sut.availableCurrencies()

        #expect(snapshot.source == .fallback)
        #expect(snapshot.currencies == CurrencyCatalog.fallbackQuoteCurrencies)
        #expect(snapshot.updatedAt == nil)
        #expect(await cache.load() == nil)
    }

    private func makeCache() -> CurrencyCache {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = JSONFileStore<CachedCurrencyList>(
            filename: "currencies.json",
            directory: directory
        )
        return CurrencyCache(store: store)
    }
}

private struct CurrencyRemoteDataSourceMock: CurrencyRemoteDataSource {
    let result: Result<[String], Error>

    func fetchAvailableCurrencyCodes() async throws -> [String] {
        try result.get()
    }
}
