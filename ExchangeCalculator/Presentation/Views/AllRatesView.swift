//
//  AllRatesView.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/20/26.
//

import SwiftUI

private enum SortSetting: Hashable {
    case fromAtoZ
    case fromZtoA
}

struct AllRatesView: View {
    
    @State private var searchTerm: String = ""
    @State private var sortSetting: SortSetting = .fromAtoZ
    
    @Environment(\.scenePhase) private var scenePhase
    
    private let viewModel: AllRatesViewModeling
    private let routing: any AppRouting
    
    private var filteredCurrencies: [Currency] {
        let searchTerm = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        if searchTerm.isEmpty {
            return viewModel.availableCurrencies
        } else {
            return viewModel.availableCurrencies.filter {
                $0.name.localizedCaseInsensitiveContains(searchTerm) || $0.code.localizedCaseInsensitiveContains(searchTerm)
            }
        }
    }
    
    private var sortedCurrencies: [Currency] {
        filteredCurrencies.sorted { currencyOne, currencyTwo in
            switch sortSetting {
            case .fromAtoZ:
                currencyOne.code < currencyTwo.code
            case .fromZtoA:
                currencyOne.code > currencyTwo.code
            }
        }
    }
    
    init(viewModel: AllRatesViewModeling, routing: any AppRouting) {
        self.viewModel = viewModel
        self.routing = routing
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ratesTableView
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .animation(.snappy, value: sortSetting)
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
            .navigationTitle("All Rates")
            .searchable(text: $searchTerm, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("Currency code"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        sortingPickerView
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
        }
    }
    
    private var sortingPickerView: some View {
        Picker("Sort", selection: $sortSetting) {
            Text("A -> Z").tag(SortSetting.fromAtoZ)
            Text("Z -> A").tag(SortSetting.fromZtoA)
        }
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
            
            ForEach(sortedCurrencies) { currency in
                GridRow {
                    CurrencyView(currency: currency)
                        .gridColumnAlignment(.leading)
                    
                    Spacer()
                    let (bid, ask) = viewModel.bidAskRates(currency: currency)
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
    
    private func rateText(_ value: Decimal?) -> some View {
        Group {
            if let value {
                Text("\(value, format: .number.precision(.fractionLength(4)))")
            } else {
                Text("-")
            }
        }
        .font(.headline)
        .monospacedDigit()
        .lineLimit(1)
    }
}
