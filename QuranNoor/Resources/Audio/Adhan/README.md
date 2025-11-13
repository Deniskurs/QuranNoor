# Adhan Audio Files

This directory contains the Adhan (call to prayer) audio files used in the QuranNoor app.

## Required Audio Files

Please add the following MP3 files to this directory:

1. **makkah.mp3** - Adhan from Masjid al-Haram (Makkah)
   - Duration: ~3 minutes
   - Beautiful, traditional Adhan from the Grand Mosque

2. **madinah.mp3** - Adhan from Masjid an-Nabawi (Madinah)
   - Duration: ~3.5 minutes
   - Serene Adhan from the Prophet's Mosque

3. **abdul_basit.mp3** - Adhan by Abdul Basit Abdul Samad
   - Duration: ~2.5 minutes
   - Renowned Egyptian Qari with powerful voice

4. **mishary.mp3** - Adhan by Mishary Rashid Alafasy
   - Duration: ~2.75 minutes
   - Popular Kuwaiti Qari with melodious style

5. **local.mp3** - Traditional Local Mosque Style
   - Duration: ~2 minutes
   - Traditional neighborhood mosque style Adhan

## Audio Specifications

- **Format**: MP3
- **Sample Rate**: 44.1 kHz (recommended)
- **Bit Rate**: 128 kbps or higher
- **Channels**: Stereo or Mono
- **Quality**: High quality, clear audio without background noise

## Where to Find Adhan Audio Files

### Free Sources:
1. **Internet Archive** (archive.org) - Search for "Adhan" or "Azan"
2. **YouTube** - Download using youtube-dl (ensure proper licensing)
3. **Islamic Audio Libraries** - Many Islamic websites offer free Adhan audio
4. **Creative Commons** - Search for CC-licensed Adhan recordings

### Recommended Searches:
- "Makkah Adhan audio download"
- "Madinah Adhan mp3"
- "Abdul Basit Adhan"
- "Mishary Alafasy Adhan"
- "Traditional Adhan mp3"

## Copyright and Licensing

**IMPORTANT**: Ensure you have the right to use these audio files in your app before distribution.

- Check license terms for commercial use
- Attribute creators if required
- For App Store submission, ensure compliance with copyright laws
- Consider purchasing licensed Adhan audio from Islamic content providers

## How to Add Files

1. Download the MP3 files from legitimate sources
2. Rename them according to the naming convention above
3. Add them to this directory in Xcode:
   - Right-click on "Adhan" folder in Xcode
   - Select "Add Files to 'QuranNoor'..."
   - Select all 5 MP3 files
   - Ensure "Copy items if needed" is checked
   - Click "Add"
4. Verify the files appear in the project navigator
5. Test playback in the Adhan Settings view

## Testing

After adding the files:

1. Run the app
2. Go to Settings → Prayer Settings → Adhan Audio
3. Test each Adhan using the "Preview" button
4. Verify volume control works
5. Test actual playback at prayer times

## Fallback Behavior

If audio files are missing, the app will:
- Not play any sound (graceful degradation)
- Continue to show notifications
- Log a warning in the console
- Not crash

## Future Improvements

- Add more muezzin options
- Support for custom user-uploaded Adhans
- Streaming option for high-quality audio
- Regional Adhan variations (Turkish, Indonesian, etc.)

---

**Note**: This app does not include Adhan audio files by default. You must add them manually before building for release.
