//
//  AllRatesView.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/20/26.
//

import SwiftUI

struct AllRatesView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    
    private let viewModel: AllRatesViewModeling
    private let routing: any AppRouting
    
    init(viewModel: AllRatesViewModeling, routing: any AppRouting) {
        self.viewModel = viewModel
        self.routing = routing
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, 32)

                ratesTableView
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .task {
            await viewModel.loadAllRatesIfNeeded()
        }
        .refreshable {
            await viewModel.refreshAllRates()
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            Task {
                await viewModel.refreshAllRates()
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("All Rates")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var ratesTableView: some View {
        Grid(alignment: .trailing, horizontalSpacing: 12, verticalSpacing: 16) {
            GridRow {
                Text("Currency")
                    .gridColumnAlignment(.leading)
                
                Spacer()
                Text("Bid")
                Text("Ask")
            }
            
            ForEach(viewModel.availableCurrencies) { currency in
                GridRow {
                    CurrencyView(currency: currency)
                        .gridColumnAlignment(.leading)
                    
                    Spacer()
                    let (bid, ask) = viewModel.bidAskRates(currency: currency) ?? (0.0, 0.0)
                    rateText(bid)
                    rateText(ask)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    Task { await viewModel.selectQuoteCurrency(currency) }
                    routing.showExchange()
                }
            }
        }
        .padding()
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func rateText(_ value: Decimal) -> some View {
        Text("\(value, format: .number.precision(.fractionLength(4)))")
            .font(.headline)
            .monospacedDigit()
            .lineLimit(1)
    }
}
