//
//  Color+Extensions.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/3/26.
//

import SwiftUI

extension Color {
    /// The green used to display the live exchange rate.
    /// Source: Colors.xcassets / Content / contentBrand (#22D081).
    static let contentBrand = Color.Content.contentBrand
    
    static let contentBackground = Color.Content.contentBackground
}

#if DEBUG

// MARK: Color to debug views

extension Color {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}
#endif
