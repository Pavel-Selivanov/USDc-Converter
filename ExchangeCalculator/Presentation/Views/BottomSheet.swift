//
//  BottomSheet.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/4/26.
//

import SwiftUI

/// Presentation behavior such as detents, drag indicator, and scrolling belongs
/// to `AdaptiveBottomSheet` so this view can stay focused on layout and controls.
struct BottomSheet<Content: View>: View {

    let title: String
    let onClose: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            header
            content()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var header: some View {
        ZStack(alignment: .leading) {
            Text(title)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(Size.Spacing.base)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
        }
        .padding(.horizontal, Size.Spacing.large)
        .padding(.vertical, Size.Spacing.xlarge)
    }
}
