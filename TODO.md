# QuranNoor - Todo List

## Task 1: Dark Theme & Onboarding Readability Issues

The onboarding flow has significant color clashes in dark theme due to hardcoded colors instead of using the theme system.

### 1.1 Fix hardcoded `.white` colors in onboarding
- [ ] `WelcomeView.swift:35` - White icon on cream/sepia background
- [ ] `ThemeSelectionView.swift:198` - White "SUGGESTED" text on accent colors
- [ ] `ValuePropositionView.swift:140` - White text in gradient banner
- [ ] `LocationAndCalculationView.swift:166,168,499` - White progress indicators and buttons
- [ ] `NotificationPrimingView.swift:209` - White text in mock notification

### 1.2 Fix demo views using hardcoded `AppColors.primary.green`
- [ ] `QuranReaderDemo.swift:65,81,179,187,276,283,287,300,338` - Replace with `themeManager.currentTheme.featureAccent`
- [ ] `PrayerTimesDemo.swift:21,35,118,162,258` - Also has hardcoded `Color.orange` for Asr
- [ ] `QiblaCompassDemo.swift:35,76,121,125,162,164` - Green fills and shadows

### 1.3 Fix priming views with hardcoded gold/green
- [ ] `LocationPrimingView.swift:74` - Hardcoded green
- [ ] `NotificationPrimingView.swift:31,49,61,81,201,209` - Hardcoded gold

### 1.4 Remove duplicate theme definitions
- [ ] `ThemeSelectionView.swift:315-360` - Has duplicated `Theme` struct with hardcoded colors instead of using `Colors.swift`

### 1.5 Replace hardcoded black shadows
- [ ] `QuranReaderDemo.swift:81,243` - `.black.opacity()` shadows
- [ ] `QiblaCompassDemo.swift:50,231` - `.black.opacity()` shadows
- [ ] `PrayerTimesDemo.swift:51,90` - `.black.opacity()` shadows

---

## Task 2: Home Screen - Replace Recent Activity with Adhkar

Remove Recent Activity from home page and add Adhkar access (currently in separate tab).

### 2.1 Remove RecentActivityFeed
- [ ] Remove `RecentActivityFeed` from `HomeView.swift`
- [ ] Delete `Views/Home/Components/RecentActivityFeed.swift`

### 2.2 Create AdhkarQuickAccessCard component
- [ ] Create new `Views/Home/Components/AdhkarQuickAccessCard.swift`
- [ ] Show adhkar categories with progress
- [ ] Display streak/statistics summary
- [ ] Quick access buttons to morning/evening adhkar
- [ ] Navigation to full Adhkar view

### 2.3 Add AdhkarQuickAccessCard to HomeView
- [ ] Add component where RecentActivityFeed was located
- [ ] Pass necessary bindings for navigation

### 2.4 Remove Adhkar tab from ContentView
- [ ] Remove Tab 4 (Adhkar with `sparkles` icon) from `ContentView.swift`
- [ ] Reduce from 6 tabs to 5 tabs (Home, Quran, Prayer, Qibla, More)
- [ ] Update tab indices accordingly

---

## Task 3: Prayer Tab Issues

The prayer tab has several UX issues with sounds, notifications, and dynamic text.

### 3.1 Fix double sound on prayer completion
**Root Cause:** Two separate sound calls for the same action:
1. `SmartPrayerRow.swift:60` calls `AudioHapticCoordinator.shared.playPrayerComplete()`
2. `PrayerTimesView.swift:284` calls `AudioHapticCoordinator.shared.playToast()`

Both play `notificationpopup.mp3` causing overlap.

- [ ] Remove `playToast()` call from `PrayerTimesView.swift:284` (keep only checkbox sound)
- [ ] OR remove sound from `SmartPrayerRow.swift:60` and keep only toast sound
- [ ] Ensure only ONE sound plays per completion action

### 3.2 Fix prayer completion toast UI/UX
- [ ] Review toast presentation in `PrayerTimesView.swift:203-218`
- [ ] Improve `EncouragingMessages.prayerComplete()` in `ToastView.swift:217-261`
- [ ] Consider more consistent/predictable messages
- [ ] Improve visual design of `.spiritual` toast style

### 3.3 Fix dynamic text changing every second
**Root Cause:** `TimelineView` in `PrayerTimesView.swift:50-52` updates every 1 second. `CurrentPrayerHeader.stateDescription` calls `.randomElement()` on each render, causing message to change every second.

Affected locations in `CurrentPrayerHeader.swift`:
- `stateDescription` property (lines 168-182)
- `getInProgressMessage()` (lines 197-232)
- `getUrgentMessage()` (lines 235-266)
- `getBetweenPrayersMessage()` (lines 268-299)
- `motivationalTip` property (lines 328-399)

Fix options:
- [ ] Memoize message selection - cache the random choice and only re-randomize on state change
- [ ] Use deterministic selection based on time period (e.g., change message every 30 seconds or on minute change)
- [ ] Store selected message in `@State` and only update when `state` changes

---

## File Reference

### Onboarding Files
- `Views/Onboarding/OnboardingContainerView.swift`
- `Views/Onboarding/WelcomeView.swift`
- `Views/Onboarding/ValuePropositionView.swift`
- `Views/Onboarding/LocationAndCalculationView.swift`
- `Views/Onboarding/NotificationPermissionView.swift`
- `Views/Onboarding/PersonalizationView.swift`
- `Views/Onboarding/ThemeSelectionView.swift`
- `Views/Onboarding/Priming/LocationPrimingView.swift`
- `Views/Onboarding/Priming/NotificationPrimingView.swift`
- `Views/Onboarding/Demos/QuranReaderDemo.swift`
- `Views/Onboarding/Demos/PrayerTimesDemo.swift`
- `Views/Onboarding/Demos/QiblaCompassDemo.swift`

### Theme Files
- `Theme/ThemeManager.swift`
- `Theme/Colors.swift`

### Home Files
- `Views/Home/HomeView.swift`
- `Views/Home/Components/RecentActivityFeed.swift`
- `Views/Home/Components/QuickActionsGrid.swift`

### Adhkar Files
- `Views/Adhkar/AdhkarView.swift`
- `Views/Adhkar/AdhkarCategoryView.swift`
- `Views/Adhkar/AdhkarDetailView.swift`
- `Services/AdhkarService.swift`
- `Models/Adhkar.swift`

### Prayer Files
- `Views/Prayer/PrayerTimesView.swift`
- `Components/Prayer/SmartPrayerRow.swift`
- `Components/Prayer/CurrentPrayerHeader.swift`
- `Services/PrayerCompletionService.swift`
- `Models/PrayerPeriod.swift`
- `Utilities/AudioHapticCoordinator.swift`
- `Services/AudioService.swift`
- `Components/Toast/ToastView.swift`

### Navigation
- `ContentView.swift`
