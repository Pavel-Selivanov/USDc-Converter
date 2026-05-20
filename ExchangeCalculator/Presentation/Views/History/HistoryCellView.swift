//
//  HistoryCellView.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/19/26.
//

import SwiftUI

struct HistoryCellConfiguration: Codable, Equatable {
    let currency: Currency
    let value: String
}

struct HistoryCellView: View {
    
    let source: HistoryCellConfiguration
    let target: HistoryCellConfiguration
    
    init(historyRecord: HistoryRecord) {
        self.source = .init(currency: historyRecord.sourceCurrency, value: historyRecord.sourceValue)
        self.target = .init(currency: historyRecord.targetCurrency, value: historyRecord.targetValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CurrencyHistoryView(currency: source.currency, text: source.value)
            CurrencyHistoryView(currency: target.currency, text: target.value)
        }
        .clipShape(RoundedRectangle(cornerRadius: Size.Spacing.large))
    }
}

private struct CurrencyHistoryView: View {
    let currency: Currency
    let text: String
    
    init(currency: Currency, text: String) {
        self.currency = currency
        self.text = text
    }

    var body: some View {
        HStack(spacing: 12) {
            CurrencyView(currency: currency, showsChevron: false)
                .padding(.vertical, 4)
                .contentShape(Rectangle())

            Spacer()
            Text(text.isEmpty ? "$0.00" : "$\(text)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(text.isEmpty ? Color.secondary.opacity(0.35) : Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .background(Color(.systemBackground))
    }
}

#Preview {
    let historyRecord = HistoryRecord(
        id: UUID(),
        sourceCurrency: .usdc, sourceValue: "100",
        targetCurrency: .brl, targetValue: "270"
    )
        
    
    VStack {
        Spacer()
        HistoryCellView(historyRecord: historyRecord)
        Spacer()
    }
    .background(Color(.systemGroupedBackground).ignoresSafeArea())
}
