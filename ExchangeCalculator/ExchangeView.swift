import SwiftUI

struct ExchangeView: View {

    // MARK: - State

    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: ExchangeViewModel
    @FocusState private var focus: FieldFocus?
    private let routing: any AppRouting

    /// Namespace for the swap crossing animation.
    @Namespace private var fieldNamespace

    init(viewModel: ExchangeViewModel, routing: any AppRouting) {
        self._viewModel = State(initialValue: viewModel)
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
            await viewModel.refreshRate(forceRefresh: true)
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            Task {
                await viewModel.refreshRate(forceRefresh: false)
            }
        }
        .onChange(of: viewModel.canEditAmounts) { _, canEditAmounts in
            guard !canEditAmounts else { return }
            focus = nil
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Exchange calculator")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(viewModel.displayRate ?? " ")
                .font(.subheadline)
                .foregroundStyle(Color.contentBrand)
                .opacity(viewModel.displayRate == nil ? 0 : 1)
                .accessibilityHidden(viewModel.displayRate == nil)

            Text(rateStatusDisplayText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .opacity(rateStatusDisplayText.isEmpty ? 0 : 1)
                .accessibilityHidden(rateStatusDisplayText.isEmpty)

            if let errorText = viewModel.rateErrorText {
                HStack(spacing: 8) {
                    Text(errorText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button("Retry") {
                        Task {
                            await viewModel.refreshRate(forceRefresh: true)
                        }
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.contentBrand)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rateStatusDisplayText: String {
        if viewModel.isLoadingRate, viewModel.displayRate == nil {
            "Updating rate..."
        } else {
            viewModel.rateStatusText ?? ""
        }
    }

    // MARK: - Field stack

    /// The two roles a field can occupy. Iterating in order produces the
    /// stack; swapping the order via `viewModel.isSwapped` is what makes
    /// SwiftUI animate the views sliding between slots.
    private var orderedFocuses: [FieldFocus] {
        viewModel.isSwapped ? [.target, .source] : [.source, .target]
    }

    @ViewBuilder
    private func fieldStack(vm: Bindable<ExchangeViewModel>) -> some View {
        VStack(spacing: 8) {
            // Iterating the focus order means each `CurrencyFieldView` is
            // identified by its `focusValue` (source/target). When the order
            // flips, SwiftUI's diffing sees the same view instance moved to
            // the other slot — `matchedGeometryEffect` then interpolates its
            // frame from old position to new, producing a true slide.
            ForEach(orderedFocuses, id: \.self) { focusValue in
                fieldView(for: focusValue, vm: vm)
                    .matchedGeometryEffect(
                        id: focusValue,
                        in: fieldNamespace
                    )
            }
        }
        .overlay(alignment: .center) {
            SwapButton {
                focus = nil
                withAnimation(.smooth(duration: 0.4)) {
                    viewModel.swapCurrencies()
                }
            }
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
                onCurrencyTap: pickerTap(for: viewModel.sourceCurrency)
            )
        case .target:
            CurrencyFieldView(
                currency: viewModel.targetCurrency,
                text: vm.targetText,
                focus: $focus,
                focusValue: .target,
                isInputEnabled: viewModel.canEditAmounts,
                onTextChange: viewModel.onTargetChanged,
                onCurrencyTap: pickerTap(for: viewModel.targetCurrency)
            )
        }
    }

    /// Returns a tap handler for the currency chip when the currency is the
    /// quote side (i.e. not the fixed base). Returns `nil` for the base so the
    /// chip renders without a chevron and ignores taps.
    private func pickerTap(for currency: Currency) -> (() -> Void)? {
        guard currency != CurrencyCatalog.baseCurrency else {
            return nil
        }
        return { routing.showCurrencyPicker() }
    }
}
