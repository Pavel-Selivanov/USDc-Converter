//
//  HistoryView.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/19/26.
//

import SwiftUI

struct HistoryView: View {
    
    private var viewModel: HistoryViewModel
    
    init(viewModel: HistoryViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            content
        }
        /*.listStyle(.insetGrouped)
        .listRowSeparator(.hidden)
        .scrollContentBackground(.hidden)*/
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            viewModel.reloadHistoryData()
        }
    }
    
    private var content: some View {
        Group {
            switch viewModel.historyRecords.isEmpty {
            case true:
                Spacer()
                Text("There're no records yet.")
                Spacer()
            case false:
                deleteAllRecordsView
                ForEach(viewModel.historyRecords) {
                    HistoryCellView(historyRecord: $0)
                        /*.listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)*/
                        .padding()
                }
                Spacer()
            }
        }
    }
    
    private var deleteAllRecordsView: some View {
        HStack {
            Spacer()
            Button {
                withAnimation(.smooth) { viewModel.clearRecords() }
            } label: {
                Text("Clear All")
                    .foregroundStyle(Color.primary)
            }
        }
        .padding(.trailing)
    }
}

#Preview {
    let viewModel = HistoryViewModel(loadHistoryData: {
        [HistoryRecord(
           id: UUID(), sourceCurrency: .usdc, sourceValue: "90",
           targetCurrency: .brl, targetValue: "370"),
        HistoryRecord(
            id: UUID(), sourceCurrency: .usdc, sourceValue: "9000",
            targetCurrency: .ars, targetValue: "3900")
        ]
        }, deleteAllHistoryRecords: {
    })
    
    HistoryView(viewModel: viewModel)
}
