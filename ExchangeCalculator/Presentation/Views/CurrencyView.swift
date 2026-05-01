//
//  CurrencyView.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/3/26.
//

import SwiftUI

struct CurrencyView: View {
    
    enum CurrencyViewStyle {
        case plain
        case picker /// brings additional background underneath of the flag's view
    }
    
    private let currency: Currency
    private let style: CurrencyViewStyle
    /// Shows a trailing `chevron.down` to advertise that the view is tappable.
    private let showsChevron: Bool

    @ScaledMetric private var compactFlagDiameter = 16
    @ScaledMetric private var regularFlagDiameter = 28
    @ScaledMetric private var compactFlagBackgroundSize = 32
    @ScaledMetric private var regularFlagBackgroundSize = 40

    init(
        currency: Currency,
        style: CurrencyViewStyle = .plain,
        showsChevron: Bool = false
    ) {
        self.currency = currency
        self.style = style
        self.showsChevron = showsChevron
    }
    
    var body: some View {
        HStack(spacing: Size.Spacing.medium) {
            flagContainer
            
            Text(currency.code)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var flagContainer: some View {
        flagGraphic
            .frame(width: flagDiameter, height: flagDiameter)
            .clipShape(Circle())
            .frame(width: flagBackgroundSize, height: flagBackgroundSize)
            .background(
                currencyFlagBackground,
                in: RoundedRectangle(
                    cornerRadius: Size.CornerRadius.basePlus,
                    style: .continuous
                )
            )
    }

    @ViewBuilder
    private var flagGraphic: some View {
        if let assetName = CurrencyFlagResolver.assetName(for: currency) {
            Image(assetName)
                .resizable()
                .scaledToFill()
        } else {
            Text(CurrencyFlagResolver.flag(for: currency))
                .font(.system(size: flagEmojiSize))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
    }
    
    private var currencyFlagBackground: Color {
        switch style {
        case .plain:
            Color.clear
        case .picker:
            Color(.systemGray6)
        }
    }
    
    private var flagDiameter: CGFloat {
        switch style {
        case .plain:
            compactFlagDiameter
        case .picker:
            regularFlagDiameter
        }
    }

    private var flagBackgroundSize: CGFloat {
        switch style {
        case .plain:
            compactFlagBackgroundSize
        case .picker:
            regularFlagBackgroundSize
        }
    }

    private var flagEmojiSize: CGFloat {
        switch style {
        case .plain:
            20
        case .picker:
            34
        }
    }
}

#if DEBUG
#Preview {
    VStack {
        CurrencyView(currency: .usdc)
        CurrencyView(currency: .mxn, style: .picker)
        CurrencyView(currency: .brl, style: .picker, showsChevron: true)
    }
    .padding()
}
#endif
