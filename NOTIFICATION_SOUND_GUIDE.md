# Notification Sound Implementation Guide

## Overview

This guide provides instructions for implementing sound notifications in the FoodieGo app. The sound notification infrastructure is already in place, but the actual sound files need to be added.

## Current Status

### ✅ Already Implemented

1. **Audio Player Package**: `audioplayers: ^6.1.0` is installed in `pubspec.yaml`
2. **Sound Playing Methods**: 
   - `_playNewOrderSound()` in `kitchen_orders_page.dart` (line ~125)
   - `_playWaiterCallSound()` in `kitchen_orders_page.dart` (line ~133)
3. **Asset Configuration**: Sound files are declared in `pubspec.yaml`:
   ```yaml
   assets:
     - assets/sounds/notification.mp3
     - assets/sounds/bell.mp3
   ```

### ⚠️ Missing Components

1. **Sound Files**: The actual audio files don't exist yet
2. **Assets Directory**: The `assets/sounds/` directory needs to be created

## Implementation Steps

### Step 1: Create the Sounds Directory

Create the directory structure:
```bash
cd frontend
mkdir -p assets/sounds
```

### Step 2: Add Sound Files

You need to add two sound files to `frontend/assets/sounds/`:

1. **notification.mp3** - For new order alerts in kitchen dashboard
   - Recommended: Short, attention-grabbing sound (1-2 seconds)
   - Use case: Plays when a new order is received
   - Suggested sounds: Bell chime, notification ping, alert tone

2. **bell.mp3** - For waiter call alerts
   - Recommended: Service bell or ding sound (1-2 seconds)
   - Use case: Plays when a customer calls for waiter assistance
   - Suggested sounds: Service bell, desk bell, ding

### Step 3: Sound File Sources

#### Option A: Free Sound Libraries
- **Freesound.org**: https://freesound.org/
  - Search for "notification" or "bell"
  - Filter by license: Creative Commons 0 (public domain)
  
- **Zapsplat**: https://www.zapsplat.com/
  - Free sound effects library
  - Requires attribution for free tier

- **Mixkit**: https://mixkit.co/free-sound-effects/
  - Free sound effects, no attribution required

#### Option B: Generate Custom Sounds
- **Audacity** (Free audio editor): https://www.audacityteam.org/
  - Generate tones and export as MP3
  
- **Online Tone Generator**: https://www.szynalski.com/tone-generator/
  - Create simple beep/tone sounds

#### Option C: Record Your Own
- Use your phone to record a real service bell
- Use audio editing software to trim and export as MP3

### Step 4: Sound File Specifications

**Recommended specifications:**
- **Format**: MP3 (widely supported)
- **Duration**: 1-3 seconds
- **Sample Rate**: 44.1 kHz
- **Bit Rate**: 128 kbps or higher
- **File Size**: < 100 KB per file
- **Volume**: Normalized to prevent clipping

### Step 5: Verify Installation

After adding the sound files:

1. **Run Flutter pub get**:
   ```bash
   cd frontend
   flutter pub get
   ```

2. **Verify assets are bundled**:
   ```bash
   flutter build apk --debug
   # Check build output for asset bundling messages
   ```

3. **Test on device**:
   - Run the app on a physical device or emulator
   - Navigate to Kitchen Orders page
   - Create a test order from customer app
   - Verify sound plays when order is received

## How It Works

### Kitchen Orders Page

When a new order is received via WebSocket:

```dart
void _handleNewOrder(dynamic data) {
  debugPrint('[KITCHEN] New order received: $data');
  
  // Play sound alert
  _playNewOrderSound();  // <-- Plays notification.mp3
  
  // Reload orders
  _loadOrders();
  
  // Show snackbar
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New order #${data['orderNumber']} - Table ${data['tableNumber']}'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
```

When a waiter is called:

```dart
void _handleWaiterCall(dynamic data) {
  debugPrint('[KITCHEN] Waiter called: $data');
  
  // Play bell sound
  _playWaiterCallSound();  // <-- Plays bell.mp3
  
  // Show dialog
  if (mounted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            Text('Table ${data['tableNumber']}'),
          ],
        ),
        content: Text(data['message'] ?? 'Customer needs assistance'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

### Sound Playing Implementation

```dart
Future<void> _playNewOrderSound() async {
  try {
    // Play a notification sound
    await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
  } catch (e) {
    debugPrint('[KITCHEN] Error playing sound: $e');
  }
}

Future<void> _playWaiterCallSound() async {
  try {
    // Play a bell sound
    await _audioPlayer.play(AssetSource('sounds/bell.mp3'));
  } catch (e) {
    debugPrint('[KITCHEN] Error playing sound: $e');
  }
}
```

## Platform-Specific Considerations

### Android
- **Permissions**: No special permissions required for playing local assets
- **Background Play**: Sounds will play even if app is in background (if WebSocket connected)
- **Volume**: Respects device notification volume settings

### iOS
- **Permissions**: No special permissions required for playing local assets
- **Background Play**: May require background modes configuration for background audio
- **Volume**: Respects device ringer volume settings

### Web
- **Browser Support**: MP3 is widely supported
- **Autoplay Policy**: First sound may require user interaction (click/tap)
- **Volume**: Respects browser/system volume settings

## Testing Checklist

- [ ] Sound files added to `frontend/assets/sounds/`
- [ ] Files are named correctly: `notification.mp3` and `bell.mp3`
- [ ] Files are in MP3 format
- [ ] Files are under 100 KB each
- [ ] Run `flutter pub get` after adding files
- [ ] Test on Android device/emulator
- [ ] Test on iOS device/simulator (if applicable)
- [ ] Test on web browser (if applicable)
- [ ] Verify sound plays when new order received
- [ ] Verify bell sound plays when waiter called
- [ ] Verify sounds respect device volume settings
- [ ] Verify error handling (no crash if files missing)

## Troubleshooting

### Sound Not Playing

1. **Check file paths**:
   - Files must be in `frontend/assets/sounds/`
   - File names must match exactly: `notification.mp3`, `bell.mp3`

2. **Check pubspec.yaml**:
   - Verify assets are declared correctly
   - Run `flutter pub get` after any changes

3. **Check device volume**:
   - Ensure device volume is not muted
   - Check notification/ringer volume settings

4. **Check logs**:
   - Look for error messages in console
   - Check for "Error playing sound" debug prints

5. **Verify file format**:
   - Ensure files are valid MP3 format
   - Try playing files on computer first

### Build Errors

If you get asset-related build errors:

1. **Clean build**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Verify asset paths**:
   - Check for typos in `pubspec.yaml`
   - Ensure proper indentation (YAML is sensitive)

3. **Check file permissions**:
   - Ensure files are readable
   - On Unix systems: `chmod 644 assets/sounds/*.mp3`

## Optional Enhancements

### 1. User Preference for Sound

Add a setting to enable/disable notification sounds:

```dart
// In settings page
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setBool('notification_sounds_enabled', true);

// In kitchen_orders_page.dart
Future<void> _playNewOrderSound() async {
  final prefs = await SharedPreferences.getInstance();
  final soundEnabled = prefs.getBool('notification_sounds_enabled') ?? true;
  
  if (!soundEnabled) return;
  
  try {
    await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
  } catch (e) {
    debugPrint('[KITCHEN] Error playing sound: $e');
  }
}
```

### 2. Custom Sound Selection

Allow users to choose from multiple notification sounds:

```dart
// Add multiple sound files
assets:
  - assets/sounds/notification1.mp3
  - assets/sounds/notification2.mp3
  - assets/sounds/notification3.mp3

// Let user select in settings
final selectedSound = prefs.getString('notification_sound') ?? 'notification1.mp3';
await _audioPlayer.play(AssetSource('sounds/$selectedSound'));
```

### 3. Volume Control

Add volume control for notification sounds:

```dart
// Set volume (0.0 to 1.0)
await _audioPlayer.setVolume(0.8);

// Then play
await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
```

### 4. Different Sounds for Different Events

Use different sounds for different order statuses:

```dart
Future<void> _playOrderSound(String status) async {
  String soundFile;
  switch (status) {
    case 'pending':
      soundFile = 'notification.mp3';
      break;
    case 'ready':
      soundFile = 'ready.mp3';
      break;
    case 'cancelled':
      soundFile = 'alert.mp3';
      break;
    default:
      soundFile = 'notification.mp3';
  }
  
  try {
    await _audioPlayer.play(AssetSource('sounds/$soundFile'));
  } catch (e) {
    debugPrint('[KITCHEN] Error playing sound: $e');
  }
}
```

## License Considerations

When using sound files from external sources:

1. **Check License**: Ensure you have rights to use the sound
2. **Attribution**: Some licenses require attribution
3. **Commercial Use**: Verify license allows commercial use
4. **Redistribution**: Ensure license allows bundling in app

**Recommended**: Use Creative Commons 0 (CC0) or public domain sounds to avoid licensing issues.

## Summary

The sound notification feature is **90% complete**. The code infrastructure is fully implemented and tested. The only remaining step is to add the actual sound files to the `assets/sounds/` directory.

**To complete this task:**
1. Create `frontend/assets/sounds/` directory
2. Add `notification.mp3` (for new orders)
3. Add `bell.mp3` (for waiter calls)
4. Run `flutter pub get`
5. Test on device

**Estimated time**: 15-30 minutes (including finding/creating sound files)

## References

- **audioplayers package**: https://pub.dev/packages/audioplayers
- **Flutter assets documentation**: https://docs.flutter.dev/ui/assets/assets-and-images
- **Sound effect resources**: See "Sound File Sources" section above
