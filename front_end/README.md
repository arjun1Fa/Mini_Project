# NutriVision — Flutter App

A production-ready Flutter frontend for the NutriVision nutrition analyzer.

## Project Structure

```
lib/
├── main.dart                  # App entry point + adaptive shell
├── theme/
│   └── app_theme.dart         # Colors, typography, ThemeData
├── models/
│   └── models.dart            # Data models + sample data
├── widgets/
│   └── widgets.dart           # Shared reusable widgets
└── screens/
    ├── add_food_screen.dart    # Home / Add Food page
    ├── history_screen.dart     # History + charts
    ├── insights_screen.dart    # Score ring + recommendations
    ├── manual_entry_screen.dart# Form with live preview
    └── profile_screen.dart     # User profile + goals
```

## Setup

### Prerequisites
- Flutter SDK ≥ 3.0.0 ([flutter.dev/get-started](https://flutter.dev/get-started))
- Dart SDK ≥ 3.0.0

### Run

```bash
cd nutrivision
flutter pub get
flutter run
```

Target platforms: `flutter run -d chrome` (web), `flutter run` (iOS/Android).

## Dependencies

| Package | Purpose |
|---|---|
| `google_fonts` | DM Sans, DM Serif Display, DM Mono typefaces |
| `fl_chart` | Bar chart in History screen |
| `image_picker` | Camera / gallery (wired up for photo screens) |
| `shared_preferences` | Local persistence (ready to integrate) |

## Design System

All colors live in `AppColors` (theme/app_theme.dart):

```dart
AppColors.cream      // #F5F0E8 — background
AppColors.ink        // #1A1714 — sidebar, primary text
AppColors.leaf       // #2D6A4F — primary green
AppColors.leafLight  // #52B788 — accent green
AppColors.amber      // #E76F51 — orange accent
AppColors.gold       // #C9A84C — yellow accent
AppColors.sky        // #457B9D — blue accent
```

## Responsive Behaviour

- **≥ 720px wide** (tablet / desktop / web): fixed dark sidebar + top bar
- **< 720px** (phone): AppBar + bottom navigation bar

## Next Steps

- Wire `image_picker` to the Take Photo / Upload Photo buttons
- Connect to your backend API in place of sample data in `models.dart`
- Add `shared_preferences` saving for profile fields
- Add `go_router` for deep linking if needed
