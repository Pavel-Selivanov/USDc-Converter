//
//  CurrencyFieldView.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/4/26.
//

import SwiftUI

struct CurrencyFieldView: View {
    
    let currency: Currency
    @Binding var text: String
    var focus: FocusState<FieldFocus?>.Binding  /// Passed from the parent's @FocusState to wire keyboard focus.
    let focusValue: FieldFocus
    let isInputEnabled: Bool
    let onTextChange: (String) -> Void
    let onCurrencyTap: (() -> Void)?

    private var isFocused: Bool {
        focus.wrappedValue == focusValue
    }

    private var isPickable: Bool {
        onCurrencyTap != nil
    }

    var body: some View {
        HStack(spacing: 12) {
            CurrencyView(currency: currency, showsChevron: isPickable)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard let onCurrencyTap else { return }
                    focus.wrappedValue = nil
                    onCurrencyTap()
                }

            Spacer()
            ZStack(alignment: .trailing) {
                Text(text.isEmpty ? "$0.00" : "$\(text)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(text.isEmpty ? Color.secondary.opacity(0.35) : Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsHitTesting(false)

                TextField("", text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.clear)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .focused(focus, equals: focusValue)
                    .disabled(!isInputEnabled)
                    // Only propagate changes the user typed, not programmatic writes.
                    .onChange(of: text) { _, newValue in
                        guard focus.wrappedValue == focusValue else { return }
                        guard isInputEnabled else { return }
                        onTextChange(newValue)
                    }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture {
            guard isInputEnabled else { return }
            focus.wrappedValue = focusValue
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Size.Spacing.large))
        .opacity(isInputEnabled ? 1 : 0.6)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .animation(.easeInOut(duration: 0.15), value: isInputEnabled)
    }
}
