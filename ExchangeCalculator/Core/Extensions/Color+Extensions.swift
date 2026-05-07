//
//  Color+Extensions.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/3/26.
//

import SwiftUI

extension Color {
    static let contentBrand = Color.Content.contentBrand
    static let contentBackground = Color.Content.contentBackground
}

#if DEBUG
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
