# Implementation Plan - Dynamic Player Layout & Unified Styling

Implement a "Strict Conditional Layout" for the player and unify styling across the app.

## Proposed Changes

### [Player Page - Strict Layout]

#### [player_modal.dart](file:///E:/1/hamza%20rep/hamza-rep/medbouh_flutter/lib/presentation/widgets/player_modal.dart)
- **Eliminate Static Spacing**: Wrap the `SyncedLyricsWidget` container in a logic check.
    - If `hasLyrics` is false, completely remove the widget from the `Column`.
    - Use `Spacer()` or `MainAxisAlignment.center` to ensure the profile image and metadata are centered vertically in the available space.
- **Dynamic Control Positioning**: Ensure playback controls stay at the bottom, but the central content (Image/Info) expands to fill the void left by lyrics.
- **Clickable Category Link**: Add a Cyan Bold link under the Surah name.

#### [synced_lyrics_widget.dart](file:///E:/1/hamza%20rep/hamza-rep/medbouh_flutter/lib/presentation/widgets/synced_lyrics_widget.dart)
- **Extreme Font Size**: Increase active verse `fontSize` to `36` (Normal) and `52` (Zoomed).
- **Flexible Container**: Wrap in `Expanded` when present.
- **Safety Padding**: Add fixed bottom padding to the container to prevent text from drifting under the volume/playback sliders.
- **Lyrics Validation**: Implement a robust check to verify if the `.lrc` asset exists before attempting to show the container.

---

### [List Items & Data]

#### [surah_item.dart](file:///E:/1/hamza%20rep/hamza-rep/medbouh_flutter/lib/presentation/widgets/surah_item.dart)
- **Unified Subtitle Style**: Force ALL secondary texts (Duration, Category Name, Verse Count/Type, Download Status, and Playing status) to use:
    - **Color**: `Colors.cyanAccent`
    - **Weight**: `FontWeight.bold`
- **Navigation Subtitle**: Make the category name clickable for navigation.

#### [content_provider.dart](file:///E:/1/hamza%20rep/hamza-rep/medbouh_flutter/lib/core/providers/content_provider.dart)
- **Real Durations**: Replace hardcoded `30:00` by pre-loading audio metadata via `just_audio` during the content loading phase.
    - Use `AudioPlayer().setUrl(surah.url)` to fetch `duration`.
    - Implement a concurrent loading mechanism (e.g., `Future.wait` with limited concurrency) to avoid long startup times.
- **Category Consistency**: Ensure every `Surah` object has a valid `category` string.

---

## Verification Plan

### Manual Verification
1. **Dynamic Layout**:
    - Play a track with lyrics: Confirm large font and proper spacing.
    - Play a track WITHOUT lyrics: Confirm the lyrics container is GONE (not just invisible) and the remaining UI is centered.
2. **Unified Styling**: Verify Cyan Bold subtitles in "Recently Added", "Search", and all category pages.
3. **Accuracy**: Confirm the displayed duration matches the actual audio length.
4. **Navigation**: Test the Cyan links in both the list and the player header.
