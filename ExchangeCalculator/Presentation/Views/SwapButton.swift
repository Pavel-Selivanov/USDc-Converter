//
//  SwapButton.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/4/26.
//

import SwiftUI

struct SwapButton: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.down")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.contentBrand, in: Circle())
                .padding(Size.Spacing.smallPlus)
                .background(Color.contentBackground, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    SwapButton {}
}
#endif
