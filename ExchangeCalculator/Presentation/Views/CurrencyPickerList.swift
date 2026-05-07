//
//  CurrencyPickerList.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/4/26.
//

import SwiftUI

/// Vertical list of currencies for selection inside a `BottomSheet`.
///
/// This view intentionally does not scroll. `AdaptiveBottomSheet` owns scrolling
/// and enables it only when the measured sheet content exceeds the available
/// presentation height.
struct CurrencyPickerList: View {

    let currencies: [Currency]
    let selected: Currency
    let onSelect: (Currency) -> Void

    var body: some View {
        VStack(spacing: Size.Spacing.small) {
            ForEach(currencies) { currency in
                Button {
                    onSelect(currency)
                } label: {
                    row(for: currency)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Size.CornerRadius.large))
        .padding(.horizontal, Size.Spacing.large)
        .padding(.bottom, Size.Spacing.large)
    }

    private func row(for currency: Currency) -> some View {
        HStack(spacing: Size.Spacing.medium) {
            CurrencyView(currency: currency, style: .picker)
            Spacer()
            selectionIndicator(isSelected: currency == selected)
        }
        .padding(.horizontal, Size.Spacing.medium)
        .padding(.vertical, Size.Spacing.medium)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func selectionIndicator(isSelected: Bool) -> some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title2)
            .foregroundStyle(isSelected ? Color.contentBrand : Color(.systemGray3))
            .accessibilityLabel("Selected")
            .accessibilityHidden(!isSelected)
    }
}

#if DEBUG
#Preview {
    CurrencyPickerList(
        currencies: CurrencyCatalog.fallbackQuoteCurrencies,
        selected: .mxn,
        onSelect: { _ in }
    )
    .background(Color.orange)
}
#endif
