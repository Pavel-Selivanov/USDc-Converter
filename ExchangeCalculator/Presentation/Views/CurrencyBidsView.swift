//
//  CurrencyBidsView.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/20/26.
//

import SwiftUI

struct CurrencyBidsView: View {
    
    private let currency: Currency
    private let buy: Decimal
    private let sell: Decimal
    
    init(currency: Currency, buy: Decimal, sell: Decimal) {
        self.currency = currency
        self.buy = buy
        self.sell = sell
    }
    
    var body: some View {
        HStack {
            CurrencyView(currency: currency, style: .plain, showsChevron: false)
                .layoutPriority(1)
            
            Spacer()
            
            rateText(buy)
            rateText(sell)
        }
        .padding(.trailing, 8)
        .padding()
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
    }
    
    private func rateText(_ value: Decimal) -> some View {
        Text("\(value, format: .number.precision(.fractionLength(4)))")
            .font(.headline)
            .monospacedDigit()
            .lineLimit(1)
    }
}

#Preview {
    CurrencyBidsView(currency: .ars, buy: 3.44, sell: 3.78)
}
