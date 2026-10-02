# YAN360 modular Flutter frontend

## File structure

```text
lib/
├── main.dart
├── screens/
│   ├── bosh_sahifa_page.dart
│   ├── tarix_page.dart
│   ├── hujjatlar_page.dart
│   └── profil_page.dart
└── shared/
    ├── dashboard_background.dart
    └── dashboard_navigation.dart
```

## Important setup

Copy these files into an existing Flutter project that contains `pubspec.yaml`.
Then run these commands from the project root:

```bash
flutter clean
flutter pub get
flutter analyze
```

In VS Code, if `package:flutter/...` is still red:

1. Open the folder that contains `pubspec.yaml`, not only the `lib` folder.
2. Select **Dart: Restart Analysis Server** from the Command Palette.
3. Select **Flutter: Change SDK** and choose the installed Flutter SDK.
4. Run `flutter doctor` and fix any Flutter SDK issues.

The split code uses `withOpacity` and avoids newer optional Flutter APIs for broader SDK compatibility. The existing `assets/logo.png` must remain in the project because the intro screen uses it.
