
# Exchange Calculator

SwiftUI exchange calculator for converting between USDc and supported currencies.

## Product assumptions

- The app is online-first, with basic offline support.
- Available currencies are slow-moving reference data. The app attempts to load
  them from `GET /v1/tickers-currencies`, caches successful responses, and falls
  back to the pre-installed static list while that endpoint is unavailable.
- Exchange rates are volatile. The app caches the last successful quote per
  currency pair, treats cached rates as fresh for a short interval, refreshes on
  app launch, currency change, pull-to-refresh, and foreground return.
- If rate refresh fails but a cached quote exists, the calculator remains usable
  and marks the quote as offline/stale. If no cached quote exists, the UI shows a
  retryable unavailable state instead of using hardcoded rates.
- The ticker API returns `bid` and `ask`. Primary-to-quote conversion uses
  `bid`; quote-to-primary conversion uses `ask` inverse. The UI keeps this simple
  by displaying the active direction's rate and the last update time.

## Architecture

- `Domain`: currency/rate entities, repository protocols.
- `Data`: API client, DTO, disk caches, live repositories, and dependency assembly.
- `Presentation`: SwiftUI views and `Observation` framework.
- `AppCurrencyConfiguration.primaryCurrency` is the single app-level place that selects the calculator's primary currency.

## Currency refresh rate

- The app loads the available currency list once during `loadInitialData()` on
  app launch.
- It first attempts `GET /v1/tickers-currencies`.
- On success, the response is cached locally and becomes the picker list.
- On failure, the app uses the cached currency list when available.
- If neither network nor cache is available, the app falls back to the
  pre-installed task list: `MXN`, `ARS`, `BRL`, `COP`.
- The app does not refresh currencies on every foreground event or pull to
  refresh because currencies are slow-moving reference data and the endpoint is
  currently unavailable by spec.

## Exchange refresh rate

- The app refreshes the exchange rate for the selected currency on launch after
  the currency list has been resolved.
- The app also refreshes rates when:
  - the user selects another currency,
  - the app returns to the foreground,
  - the user pulls to refresh.
- A cached rate is considered fresh for `60` seconds. Fresh cached rates are used
  immediately without another network request.
- If a refresh fails and a cached rate exists, the app keeps conversion usable
  and marks the rate as stale/offline.
- If a refresh fails and no cached rate exists, the app clears the calculated
  value and shows a retryable unavailable state.

## Implemented

- Two editable `CurrencyFieldView` with bidirectional conversion.
- Currency picker bottom sheet for the non-primary currency.
- Swap button with animated field reordering.
- Real ticker fetching via `GET /v1/tickers?currencies=...`.
- Currency list fallback for the unavailable currencies endpoint.
- Local JSON cache for currencies and latest rates.
- Loading, stale/offline, last-updated, retry, launch, foreground, and pull-to-refresh states.
- Decimal-based money math, 2-fraction-digit input cap, grouping separators, and 10B input clamp.
- Unit coverage for rate math, DTO parsing, input validation, currency selection, swap behavior, and fallback currency behavior.
- Unit tests

## Out of scope
- Real-time streaming rates.
- Listen to the network connection updates (when user goes online again - we can fetch the data again)
