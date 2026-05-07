//
//  Task.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/2/26.
//


Currency Input Fields
   - Two input fields: one for USDc and one for the selected currency


User Experience
- The application should provide a good user experience
- Consider edge cases and how users will interact with the app


Exchange Rate API
GET: https://api.dolarapp.dev/v1/tickers?currencies=MXN,ARS

[
  {
    "ask": "18.4105000000",
    "bid": "18.4069700000",
    "book": "usdc_mxn",
    "date": "2025-10-20T20:14:57.361483956"

  },

  {
    "ask": "1551.0000000000",
    "bid": "1539.4290300000",
    "book": "usdc_ars",
    "date": "2025-10-21T09:44:18.512194175"
  }
]

Note: This API is not yet available. You can expect it to have the following structure when implemented:
GET: https://api.dolarapp.dev/v1/tickers-currencies
[
  "MXN",
  "ARS",
  "BRL",
  "COP"
]
