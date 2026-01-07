# FoodieGo - Flutter Frontend

Ethiopian Food Delivery App with beautiful animated UI.

## Quick Start

```bash
flutter pub get
flutter run -d edge    # Web
flutter run -d android # Android
```

## Build for Production

```bash
# Web
flutter build web --release

# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release
```

## App Icons

To generate app icons:
1. Add your icon to `assets/icons/app_icon.png` (1024x1024 recommended)
2. Add to pubspec.yaml: `flutter_launcher_icons: ^0.14.3`
3. Run: `flutter pub run flutter_launcher_icons`

## Project Structure

```
lib/
├── core/
│   ├── constants/     # App and API constants
│   ├── theme/         # App theme (colors, gradients, shadows)
│   ├── services/      # Location service
│   └── utils/         # Storage utilities
├── data/
│   ├── models/        # Data models
│   ├── repositories/  # API repositories
│   └── services/      # API service
├── presentation/
│   ├── pages/         # App screens
│   │   ├── admin/     # Admin portal pages
│   │   ├── auth/      # Login/Register pages
│   │   ├── cart/      # Shopping cart
│   │   ├── checkout/  # Checkout with payments
│   │   ├── food/      # Food detail page
│   │   ├── home/      # Home & hotel foods
│   │   ├── orders/    # Orders & tracking
│   │   └── profile/   # User profile
│   └── widgets/       # Animated UI components
└── state/             # Provider state management
```

## Features

- ✅ Beautiful animated UI
- ✅ Auto-location detection
- ✅ Ethiopian payment methods
- ✅ Real-time order tracking
- ✅ Admin portal (/admin URL)
- ✅ Hotel-isolated admin data

## Configuration

- API URL: `lib/core/constants/api_constants.dart`
- Theme: `lib/core/theme/app_theme.dart`
- App Constants: `lib/core/constants/app_constants.dart`
