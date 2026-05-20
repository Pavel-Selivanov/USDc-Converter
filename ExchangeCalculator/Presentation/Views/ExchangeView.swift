import SwiftUI

struct ExchangeView: View {

    // MARK: - State

    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var focus: FieldFocus?
    @State private var fieldHeight: CGFloat = 0
    @State private var delayedAmountRecomputeTask: Task<Void, Never>?
    private var viewModel: ExchangeViewModel
    private let routing: any AppRouting

    private static let amountRecomputeDelay: Duration = .milliseconds(100)

    init(viewModel: ExchangeViewModel, routing: any AppRouting) {
        self.viewModel = viewModel
        self.routing = routing
    }

    // MARK: - Body

    var body: some View {
        @Bindable var vm = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, 32)

                fieldStack(vm: $vm)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .task {
            await viewModel.loadInitialData()
        }
        .refreshable {
            await viewModel.refreshData()
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            Task {
                await viewModel.refreshData()
            }
        }
        .onChange(of: viewModel.canEditAmounts) { _, canEditAmounts in
            guard !canEditAmounts else { return }
            focus = nil
        }
        .onDisappear {
            delayedAmountRecomputeTask?.cancel()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Exchange calculator")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                historyButton
            }

            Text(viewModel.displayRate ?? " ")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.contentBrand)
                .opacity(viewModel.displayRate == nil ? 0 : 1)
                .accessibilityHidden(viewModel.displayRate == nil)

            Label(
                viewModel.rateStatusText ?? "Online.",
                systemImage: viewModel.rateStatusIconName ?? "icloud.slash"
            )
            .font(.footnote)
            .foregroundStyle(rateStatusColor)
            .opacity(viewModel.rateStatusText == nil ? 0 : 1)

            if let errorText = viewModel.rateErrorText {
                HStack(spacing: 8) {
                    Text(errorText)
                        .font(.footnote)
                        .foregroundStyle(.red)

                    if viewModel.showsManualRefresh {
                        Button("Refresh") {
                            Task {
                                await viewModel.refreshData()
                            }
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.contentBrand)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var historyButton: some View {
        Button {
            routing.showHistoryView()
        } label: {
            Image(systemName: "clock")
                .font(.system(.title3))
                .foregroundStyle(Color.primary)
        }
        .frame(width: 44, height: 44)
    }

    private var rateStatusColor: Color {
        switch viewModel.rateStatusTone {
        case .hidden:
            .secondary
        case .warning:
            .orange
        }
    }

    // MARK: - Field stack

    private var fieldSwapDistance: CGFloat {
        fieldHeight + Size.Spacing.large
    }

    @ViewBuilder
    private func fieldStack(vm: Bindable<ExchangeViewModel>) -> some View {
        VStack(spacing: Size.Spacing.large) {
            fieldView(for: .source, vm: vm)
                .readFieldHeight()
                .offset(y: viewModel.isSwapped ? fieldSwapDistance : 0)
                .zIndex(viewModel.isSwapped ? 0 : 1)

            fieldView(for: .target, vm: vm)
                .readFieldHeight()
                .offset(y: viewModel.isSwapped ? -fieldSwapDistance : 0)
                .zIndex(viewModel.isSwapped ? 1 : 0)
        }
        .onPreferenceChange(FieldHeightPreferenceKey.self) { height in
            fieldHeight = height
        }
        .overlay(alignment: .center) {
            SwapButton {
                focus = nil
                delayedAmountRecomputeTask?.cancel()

                withAnimation(.smooth(duration: 0.4)) {
                    viewModel.swapCurrencies(recomputesAmounts: false)
                }

                delayedAmountRecomputeTask = Task { @MainActor in
                    do {
                        try await Task.sleep(for: Self.amountRecomputeDelay)
                    } catch {
                        return
                    }

                    guard !Task.isCancelled else { return }
                    recomputeAmountsWithoutAnimation()
                }
            }
        }
    }

    private func recomputeAmountsWithoutAnimation() {
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            viewModel.recomputeAmountsForCurrentState()
        }
    }

    @ViewBuilder
    private func fieldView(
        for focusValue: FieldFocus,
        vm: Bindable<ExchangeViewModel>
    ) -> some View {
        switch focusValue {
        case .source:
            CurrencyFieldView(
                currency: viewModel.sourceCurrency,
                text: vm.sourceText,
                focus: $focus,
                focusValue: .source,
                isInputEnabled: viewModel.canEditAmounts,
                onTextChange: viewModel.onSourceChanged,
                onCurrencyTap: nil
            )
        case .target:
            CurrencyFieldView(
                currency: viewModel.targetCurrency,
                text: vm.targetText,
                focus: $focus,
                focusValue: .target,
                isInputEnabled: viewModel.canEditAmounts,
                onTextChange: viewModel.onTargetChanged,
                onCurrencyTap: { routing.showCurrencyPicker() }
            )
        }
    }
}

private struct FieldHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension View {
    func readFieldHeight() -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: FieldHeightPreferenceKey.self,
                    value: proxy.size.height
                )
            }
        }
    }
}
