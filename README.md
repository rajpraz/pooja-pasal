# Pooja Pasal — Flutter app

Multi-vendor pooja samagri marketplace for buyers, sellers and admins,
backed by the Laravel REST API in [`../pooja_pasal_backend`](../pooja_pasal_backend).

## Tech stack

- Flutter (Material 3), Dart null-safe
- State: **Riverpod** · Navigation: **GoRouter** (auth/role guards)
- Backend: **Laravel 13 + Sanctum** token auth, over `package:http`
- Payments: Khalti (`khalti_checkout_flutter`), eSewa (WebView form), Cash on Delivery
- Push: Firebase Cloud Messaging only — no other Firebase services are used

## Features

| Buyer | Seller | Admin |
|---|---|---|
| Browse, search, filter, festival collections | Add/edit products, photos, stock | Dashboard (orders, revenue, stock) |
| Cart, wishlist, saved addresses | Activate/deactivate products | Approve/reject seller applications |
| Checkout with coupons; Khalti, eSewa, COD | Fulfil orders, cancel, confirm cash | Manage users and roles |
| Track orders, retry payment, reorder | Sales dashboard, low-stock alerts | Categories, products, orders, reviews |
| Review delivered products | | |
| Apply to become a seller | | |

## Project structure

```
lib/
  app/        # App widget, GoRouter config + guards, theme
  core/
    network/  # ApiClient (HTTP, error mapping, live `watch` streams), TokenStore, uploads
    services/ # push notifications
    constants/# API base URL, Khalti public key
  features/   # one folder per feature: data / domain / presentation
test/         # unit tests (HTTP mocked) + opt-in live-API contract test
```

Every feature keeps the same shape: a `data/datasources` class that calls
the API through `ApiClient`, a repository interface in `domain/`, and
Riverpod providers/controllers in `presentation/`. Screens never call the
API directly. Lists are streams: `ApiClient.watch` re-fetches when a related
write happens in the app (`notifyChanged`) and polls where other people
change the data (orders, notifications).

## Getting started

1. Start the API (see `../pooja_pasal_backend/README.md`):
   ```bash
   cd ../pooja_pasal_backend
   composer install && cp .env.example .env && php artisan key:generate
   touch database/database.sqlite && php artisan migrate --seed && php artisan storage:link
   php artisan serve            # http://127.0.0.1:8000
   ```
2. Run the app:
   ```bash
   flutter pub get
   flutter run
   ```
   Debug builds talk to `http://127.0.0.1:8000/api` (iOS simulator, desktop)
   or `http://10.0.2.2:8000/api` (Android emulator). For a phone or a
   deployed API pass the URL:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api   # serve with --host=0.0.0.0
   flutter build appbundle --release --dart-define=API_BASE_URL=https://shop.example.com/api
   ```
   Release builds need an **https** URL; only debug builds allow plain HTTP.

Seeded accounts (development only), password `password123`:
`admin@poojapasal.test`, `seller@poojapasal.test`, `buyer@poojapasal.test`,
`applicant@poojapasal.test` (buyer with a pending seller application).

## Configuration

| What | Where |
|---|---|
| API URL | `--dart-define=API_BASE_URL=…` (`lib/core/constants/api_config.dart`) |
| Khalti public key | `lib/core/constants/khalti_config.dart` — a `test_` key uses the sandbox; the secret key lives only on the server |
| Delivery fee shown in the cart preview | `lib/features/cart/domain/pricing_service.dart` — keep in sync with the API's `config/shop.php` |
| Push | `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`; server side needs `FCM_CREDENTIALS` |

The Android application ID is still `com.example.untitled3`, because the
Firebase app (push) is registered under it. To change it, register the new
ID in the Firebase console, re-run `flutterfire configure`, then update
`applicationId`/`namespace` in `android/app/build.gradle`.

## Code quality

`analysis_options.yaml` turns on the analyzer's strict modes
(`strict-casts`, `strict-inference`, `strict-raw-types`) and extra lints
that catch real bugs (`unawaited_futures`, `avoid_dynamic_calls`,
`cancel_subscriptions`, `close_sinks`, …). Keep `flutter analyze` at zero
issues. API JSON is read through `JsonRead` (`core/network/json_reader.dart`),
so bad data from the server becomes a default instead of a crash.

## Tests

```bash
flutter analyze
flutter test                       # unit + widget tests, no network
# Contract test against a live API on a throwaway, freshly seeded database:
API_E2E_BASE_URL=http://127.0.0.1:8000/api flutter test test/e2e
```

- `test/core` — networking (`ApiClient`, error mapping, live streams), JSON
  reading, responsive layout, product artwork.
- `test/features` — data sources against a mocked HTTP API; checkout
  (place COD order, coupons, refusals) and seller orders as widget tests
  with fake repositories (`test/support/fakes.dart`); product card; totals.
- `test/app` — routing rules (including account switching) and the theme
  setting.
- `test/e2e` — buyer → seller → admin against a running API: browse, cart,
  coupon, checkout, fulfilment, return, refund, reviews, notifications.
