# TipsyTheoryy App (Flutter)

TipsyTheoryy is a Flutter mobile application for discovering stores/products, viewing active offers, and placing orders. The app uses a network API client with auth support, caching, and platform services like location and notifications.

## Features (high level)

- **Browse stores & products** (store detail screen with product grid)
- **Promotions / offers** carousel per store
- **Cart & checkout flow** (including delivery fee handling)
- **Favorites**
- **Support & legal content** (support links + in-app legal pages)
- **Location-aware experience** (distance calculation using `geolocator`)
- **Authentication** (Firebase Auth + Google Sign-In + Sign in with Apple)
- **Push notifications** (Firebase Cloud Messaging + local notifications)
- **AI/voice support** (AI assistant provider + voice service)

## Tech Stack

- **Flutter / Dart**
- **Networking**: `dio` + `dio_cache_interceptor`
- **Auth & secure storage**: `firebase_auth`, `google_sign_in`, `sign_in_with_apple`, `flutter_secure_storage`
- **Maps/Location**: `geolocator`, `location`, `google_maps_flutter`, `geocoding`
- **Messaging**: `firebase_core`, `firebase_messaging`, `flutter_local_notifications`
- **State management**: `provider`
- **UI**: `cached_network_image`, `shimmer`, `lottie`, `flutter_svg`
- **Utilities**: `flutter_dotenv` for environment configuration

## Local Setup

### 1) Prerequisites

- Flutter installed (includes Dart)
- A device/emulator (Android/iOS/macOS/Windows/Linux depending on your setup)

### 2) Configure environment variables (`.env`)

The app uses `flutter_dotenv` and expects an environment file included in Flutter assets.

- Create a file named **`.env`** at the project root.
- At minimum, set **`API_BASE_URL`** (optional; defaults to `https://api.tipsytheoryy.com/api/v1/`).

Example `.env`:

```env
API_BASE_URL=https://api.tipsytheoryy.com/api/v1/
```

> Note: API authentication is handled by the API client reading an `access_token` from `flutter_secure_storage`.

### 3) Install dependencies

```bash
flutter pub get
```

## Run the App

### Debug (recommended)

```bash
flutter run
```

To run on a specific device/emulator:

```bash
flutter run -d <device-id>
```

## Build / Clean Commands

```bash
flutter clean
flutter pub get
flutter run
```

## Project Structure (summary)

- `lib/core/`
  - `api_client.dart`: REST client (base URL from `.env`, adds auth header from secure storage, enables caching + logging)
  - `theme.dart`, `legal_texts.dart`
- `lib/models/`: app data models (store, product, order, etc.)
- `lib/providers/`: `provider`-based state management
- `lib/screens/`: UI screens (customer + rider + landing + auth)
- `lib/services/`: notification and AI/voice services
- `lib/widgets/`: reusable UI components

## Security Notes

- The API client attaches `Authorization: Bearer <token>` using `access_token` stored in **`flutter_secure_storage`**.
- Ensure your backend validates tokens and implements proper refresh/expiry handling (token refresh logic is currently marked as a placeholder in the API client).

## License

Add your project license here.

## Acknowledgements

This app uses common open-source Flutter/Dart packages listed in `pubspec.yaml`.

