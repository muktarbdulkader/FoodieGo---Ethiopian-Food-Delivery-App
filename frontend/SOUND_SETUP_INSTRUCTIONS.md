# Quick Sound Setup Instructions

## Task 4.3.4: Add Sound to Notifications (Optional)

### Current Status
✅ Code implementation complete  
⚠️ Sound files missing

### Quick Setup (5 minutes)

#### Step 1: Create Directory
```bash
cd frontend
mkdir -p assets/sounds
```

#### Step 2: Add Sound Files

You need two MP3 files in `frontend/assets/sounds/`:
- `notification.mp3` - Plays when new order arrives
- `bell.mp3` - Plays when waiter is called

#### Step 3: Get Sound Files

**Option A: Download Free Sounds**

1. **notification.mp3** - New Order Sound
   - Visit: https://freesound.org/people/rhodesmas/sounds/320655/
   - Or search "notification beep" on freesound.org
   - Download and rename to `notification.mp3`
   - Place in `frontend/assets/sounds/`

2. **bell.mp3** - Waiter Call Sound
   - Visit: https://freesound.org/people/InspectorJ/sounds/403012/
   - Or search "service bell" on freesound.org
   - Download and rename to `bell.mp3`
   - Place in `frontend/assets/sounds/`

**Option B: Use System Sounds**

On macOS/Linux, you can convert system sounds:
```bash
# Example: Convert system sound to MP3
ffmpeg -i /System/Library/Sounds/Glass.aiff -acodec libmp3lame frontend/assets/sounds/notification.mp3
```

**Option C: Generate Simple Beep**

Use an online tone generator:
1. Visit: https://www.szynalski.com/tone-generator/
2. Set frequency to 800 Hz
3. Record for 0.5 seconds
4. Download as MP3
5. Rename and place in `frontend/assets/sounds/`

#### Step 4: Verify Setup
```bash
cd frontend
flutter pub get
flutter run
```

#### Step 5: Test

1. Open app and login as restaurant staff
2. Navigate to Kitchen Orders page
3. From another device, place a test order
4. You should hear the notification sound
5. Call waiter from customer app
6. You should hear the bell sound

### File Requirements

- **Format**: MP3
- **Duration**: 1-3 seconds
- **Size**: < 100 KB each
- **Sample Rate**: 44.1 kHz recommended

### Where Sounds Are Used

1. **Kitchen Orders Page** (`kitchen_orders_page.dart`):
   - `notification.mp3` plays when new order received
   - `bell.mp3` plays when waiter called

2. **Triggered by WebSocket events**:
   - `order:created` → notification.mp3
   - `waiter:called` → bell.mp3

### Disable Sounds (If Not Needed)

If you don't want sound notifications, you can:

1. **Remove sound files** (app will continue working, just no sound)
2. **Comment out sound calls** in `kitchen_orders_page.dart`:
   ```dart
   // _playNewOrderSound();  // Comment this line
   // _playWaiterCallSound();  // Comment this line
   ```

### Troubleshooting

**Sound not playing?**
- Check device volume is not muted
- Verify files are in correct location: `frontend/assets/sounds/`
- Check file names match exactly: `notification.mp3`, `bell.mp3`
- Run `flutter clean && flutter pub get`

**Build errors?**
- Verify `pubspec.yaml` has correct asset paths
- Check YAML indentation (use spaces, not tabs)
- Ensure files are valid MP3 format

### Next Steps

After adding sound files, you may want to:
- Add user preference to enable/disable sounds
- Add volume control
- Add different sounds for different order statuses
- Add sound preview in settings

See `NOTIFICATION_SOUND_GUIDE.md` for detailed implementation options.

---

**Note**: This is an optional feature. The app works perfectly without sound files - they just won't play if missing.
