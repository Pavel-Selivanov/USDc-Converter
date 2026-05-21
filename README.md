# Exchange Calculator

SwiftUI exchange calculator for converting between USDc and supported currencies.

## Product details

- The app is always responsive to the user upon initial successful sync with the server
- App has basic offline support by caching currencies and rates. Indicating to the user when data is stale.
- EUR is not supported by the API, so we don't have it for now in the app.


## Architecture
- `Domain`: currency/rate entities, repository protocols.
- `Data`: API client, DTOs, device caches, repositories, and dependency assembly.
- `Presentation`: SwiftUI views and `Observation` framework.
- `ExchangeViewModel` depends on a function-shaped use case to keep presentation independent from repositories and make tests lightweight.

## Implemented
- App uses 2 types of data: array of available currencies and exchange rates.
- App has two editable `CurrencyFieldView`. Each has decimal-based input field, 2-fraction-digit input cap, grouping separators, and a 10B USDC-equivalent input clamp.
- `.decimalPad` may have `,` instead of `.` in some locales, so we handle both gracefully.
- Swap button with smooth offset-based reordering animation.
- Currency picker bottom sheet for the non-primary currency (with trully adaptive height).
- App refreshed data:
  a) on app launch.
  b) on pull-to-refresh.
  c) on foreground return.
  d) on `Refresh` button tap.
- App refreshed data flow:
  a) fetch supporting currencies.
  b) fetch exchage rates using list of currencies.
  If neither network nor cache is available for list of currencies, the app falls back to the pre-installed list: `MXN`, `ARS`, `BRL`, `COP`.
- The ticker API returns `bid` and `ask`. Primary-to-quote conversion uses `bid`; quote-to-primary conversion uses `ask` inverse. The header keeps the Figma convention of displaying `1 USDc = X quote`: bid before swap, ask after swap.
- App uses local JSON cache for currencies and latest rates.
- Network Availability:
  - Listen to the network connection updates (when user goes online again - we can fetch the data again)
  - avoid calls while offline, show it to the user.
- Unit tests (coverage for rate math, DTO parsing, input validation, currency selection, swap behavior, and fallback currency behavior.)


## Out of scope
- Dark mode
- Exponential backoff retry for remote data sync
- Real-time streaming rates (should we decide to use the code into money transfer module where exact rate is crucial).

## All-rates-tab
1. Add second tab, keep using AppRouter as a single source of truth for navigation.
2. Add AllRatesView with empty state.
3. Reuse the currency view to show a list of them.
4. Reuse repository to display all available rates. Кeuse "ExchangeRate" for now, yet for the further enhancement - we can use a protocol.
5. A trade off I see right now is that we keep data refreshed on each tab initial appearance, so 
6. All rates screen has search bar to search and filter by either currency name or currency code.
7. All rates screen has sorting.
