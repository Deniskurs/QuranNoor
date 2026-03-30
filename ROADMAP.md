# Quran Noor — Feature Roadmap

Future features planned for Quran Noor, organized by priority and complexity.

---

## High Priority

### Spaced Repetition Hifz Mode
**Difficulty:** High | **Impact:** High

Intelligent memorization system using spaced repetition algorithms (SM-2 or similar). Tracks which verses the user has memorized, schedules review sessions at optimal intervals, and adjusts difficulty based on recall accuracy. Includes progress dashboard with memorization streaks and mastery levels per surah.

### Reading Streak Gamification
**Difficulty:** Medium | **Impact:** High

GitHub-style contribution heatmap showing daily Quran reading activity. Named achievement tiers (e.g., "Hafiz in Training", "Consistent Reader", "Devoted Scholar"). Badges for milestones like completing a juz, finishing the entire Quran, or maintaining a 30-day streak. Weekly/monthly reading summaries with shareable stats cards.

### Tafsir Integration (Ibn Kathir, Tabari)
**Difficulty:** High | **Impact:** High

Verse-level Quran commentary from classical scholars. Start with Ibn Kathir (most popular) and Al-Tabari. Accessible via long-press on any verse or a dedicated "Tafsir" toggle in the reader. Support offline download of complete tafsir texts. Display alongside translation with expandable sections.

---

## Medium Priority

### Verse Notes & Reflections
**Difficulty:** Low | **Impact:** Medium

Allow users to write personal notes and reflections on any verse. Notes stored locally via SwiftData with iCloud sync (Phase 3). Searchable note library. Export notes as PDF or markdown. Integration with bookmark system — bookmarked verses can have attached reflections.

### Word-by-Word Audio Playback
**Difficulty:** Medium | **Impact:** Medium

Play audio for individual words (not just full verses). Uses Quran.com word-level audio URLs. Tap a word in word-by-word mode to hear its pronunciation. Auto-play mode that highlights and speaks each word sequentially. Essential companion to the word morphology feature.

### Thematic Verse Coloring
**Difficulty:** Medium | **Impact:** Medium

Color-code verses by topic/theme (e.g., green for paradise descriptions, blue for stories of prophets, gold for divine attributes, red for warnings). Uses a pre-built topic mapping database. Toggleable overlay that doesn't interfere with tajweed colors. Theme legend accessible from reader controls.

### Mushaf Page Layout (15-line Madani)
**Difficulty:** High | **Impact:** Medium

Display the Quran in traditional mushaf page format — exactly 15 lines per page matching the Madinah Mushaf layout. Page-turn animations. Dual-page landscape mode on iPad. Requires precise text layout engine and pre-computed page break data. Uses the King Fahd Complex standard pagination.

---

## Lower Priority (Phase 3+)

### AI Voice Recognition (Tarteel-style)
**Difficulty:** Very High | **Impact:** High

On-device speech recognition for Quran recitation practice. User recites a verse and the app evaluates pronunciation accuracy, highlights mistakes, and provides feedback. Requires training or integrating a specialized Arabic/Quran speech model. Could use Apple's Speech framework as a starting point with custom post-processing.

### Live Activity & Dynamic Island
**Difficulty:** Medium | **Impact:** Low

Show current prayer time countdown and next prayer name in the Dynamic Island and Lock Screen Live Activity. Update in real-time. Minimal battery impact using ActivityKit push updates. Also show Quran reading progress during active reading sessions.

### CarPlay Integration
**Difficulty:** Medium | **Impact:** Low

Quran audio playback interface for CarPlay. Browse surahs, select reciters, and control playback from the car's infotainment screen. Simple list-based UI following CarPlay design guidelines. Background audio already supported — this adds the dedicated CarPlay UI.

### Apple Watch Complications & App
**Difficulty:** High | **Impact:** Low

Standalone watchOS app showing prayer times, Qibla direction (using watch compass), and tasbih counter with haptic feedback. Complications for watch faces showing next prayer time and countdown. Watch Connectivity for syncing settings and prayer completion status with the iPhone app.
