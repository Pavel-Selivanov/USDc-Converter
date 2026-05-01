//
//  AdaptiveBottomSheet.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/4/26.
//

import SwiftUI
import UIKit

struct AdaptiveBottomSheet: ViewModifier {
    private let animation: Animation
    private let maxHeightRatio: CGFloat
    private let verticalScreenPadding: CGFloat

    @State private var contentHeight: CGFloat = 0
    @State private var windowHeight: CGFloat = 0

    public init(
        animation: Animation = .smooth(duration: 0.25),
        maxHeightRatio: CGFloat = 0.9,
        verticalScreenPadding: CGFloat = 48
    ) {
        self.animation = animation
        self.maxHeightRatio = maxHeightRatio
        self.verticalScreenPadding = verticalScreenPadding
    }

    public func body(content: Content) -> some View {
        let maxSheetHeight = maximumSheetHeight
        let sheetHeight = min(contentHeight, maxSheetHeight)
        let shouldScroll = contentHeight > maxSheetHeight

        ScrollView {
            measuredContent(content)
                .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollDisabled(!shouldScroll)
        .scrollBounceBehavior(.basedOnSize)
        .background(WindowHeightReader { windowHeight = $0 })
        .presentationDetents(contentHeight == 0 ? [.medium] : [.height(sheetHeight)])
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
        .presentationBackground(Color(.systemGroupedBackground))
        .animation(animation, value: sheetHeight)
    }

    private func measuredContent(_ content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                updateContentHeight(height)
            }
    }

    private func updateContentHeight(_ height: CGFloat) {
        guard height.isFinite, height > 0 else { return }
        guard abs(height - contentHeight) > 0.5 else { return }

        if contentHeight == 0 {
            contentHeight = height
        } else {
            withAnimation(animation) {
                contentHeight = height
            }
        }
    }

    private var maximumSheetHeight: CGFloat {
        guard windowHeight > 0 else {
            return .greatestFiniteMagnitude
        }

        let cappedRatio = min(max(maxHeightRatio, 0), 1)
        let paddedWindowHeight = windowHeight - max(verticalScreenPadding, 0)

        return max(
            1,
            min(
                windowHeight * cappedRatio,
                paddedWindowHeight
            )
        )
    }
}

private struct WindowHeightReader: UIViewRepresentable {
    let onChange: (CGFloat) -> Void

    func makeUIView(context: Context) -> WindowHeightReaderView {
        let view = WindowHeightReaderView()
        view.onChange = onChange
        return view
    }

    func updateUIView(_ uiView: WindowHeightReaderView, context: Context) {
        uiView.onChange = onChange
        uiView.reportWindowHeight()
    }
}

private final class WindowHeightReaderView: UIView {
    var onChange: ((CGFloat) -> Void)?
    private var lastHeight: CGFloat = 0

    override func didMoveToWindow() {
        super.didMoveToWindow()
        reportWindowHeight()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        reportWindowHeight()
    }

    func reportWindowHeight() {
        guard let height = window?.bounds.height, height > 0 else { return }
        guard abs(height - lastHeight) > 0.5 else { return }

        lastHeight = height
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.onChange?(height)
        }
    }
}

public extension View {
    func adaptiveBottomSheet(
        animation: Animation = .smooth(duration: 0.25),
        maxHeightRatio: CGFloat = 0.9,
        verticalScreenPadding: CGFloat = 48
    ) -> some View {
        modifier(
            AdaptiveBottomSheet(
                animation: animation,
                maxHeightRatio: maxHeightRatio,
                verticalScreenPadding: verticalScreenPadding
            )
        )
    }
}
