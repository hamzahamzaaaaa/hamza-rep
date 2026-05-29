# Restoration and Enhancement of Premium Features

This plan outlines the steps to restore and enhance several premium features in the Medbouh Quran app, including dynamic themes, multi-source data integration, and UI/UX improvements.

## User Review Required

- **GitHub JSON Source**: We need to confirm the exact URLs for fetching JSON files from GitHub if they differ from the local ones.
- **YouTube API**: Do you have a specific YouTube API key or channel ID to use? For now, we'll use placeholder or provided logic.
- **Dynamic Tabs**: Confirm the desired list of categories for the tabs (e.g., Quran, Azkar, Dua, Special Recitations).

## Proposed Changes

### Core Constants & Models

#### [colors.dart](file:///E:/1/hamza%20rep/hamza-rep/medbouh_flutter/lib/core/constants/colors.dart)

- Update `AppColors` to support dynamic theme modes (Light/Dark).
- Add `setToLight()` and `setToDark()` methods.
- Define separate color palettes for light and dark modes.

#### [surah.dart](file:///E:/1/hamza%20rep/hamza-rep/medbouh_flutter/lib/core/models/surah.dart)

- Add a factory method to handle different JSON structures from external files.

---

### Providers

#### [NEW] [theme_provider.dart](file:///E:/1/hamza%20rep/hamza-rep/medbouh_flutter/lib/core/providers/theme_provider.dart)

- Implement `ThemeProvider` using `Riverpod`.
- Add logic to switch themes based on current time (e.g., auto-dark after 6 PM).
- Listen to system theme changes if needed.

#### [NEW] [content_provider.dart](file:///E:/1/hamza%20rep/hamza-rep/medbouh_flutter/lib/core/providers/content_provider.dart)

- Implement providers for loading local and remote JSON data.
- Handle fetching from GitHub using `dio` or `http`.
- Integrate YouTube playlist fetching if applicable.

---

### UI/UX Enhancements

#### [main.dart](file:///E:/1/hamza%20rep/hamza-rep/medbouh_flutter/lib/main.dart)

- Wrap `MaterialApp` with `ThemeProvider`'s state.
- Update `ThemeData` to use dynamic colors from `AppColors`.

#### [playlists_page.dart](file:///E:/1/hamza%20rep/hamza-rep/medbouh_flutter/lib/presentation/pages/playlists_page.dart)

- Add sections for GitHub Recitations and YouTube Playlists.
- Re-enable/Implement `githubList` and `youtubeRecitationsList`.

#### [quran_page.dart](file:///E:/1/hamza%20rep/hamza-rep/medbouh_flutter/lib/presentation/pages/quran_page.dart)

- Update the grid to include new categories: Azkar, Dua, and 2026 Recitations.
- Implement "Suggestion of the Day" button logic.

---

### Assets Management

- Move all JSON files from the root directory to `assets/json/`.
- Update `pubspec.yaml` to include the new asset paths.

## Verification Plan

### Automated Tests
- Run `flutter test` to ensure no regressions (if tests exist).
- Add simple unit tests for `ThemeProvider` and JSON parsing.

### Manual Verification
- Verify theme switching by changing the system time or adding a toggle in settings.
- Check if JSON data is correctly loaded from `assets/json/` and displayed in the app.
- Test the "Suggestion of the Day" button to ensure it picks a random track.
- Verify speed control and sleep timer in the `PlayerModal`.
