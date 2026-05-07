# Audio Files for FoodieGo Kitchen Dashboard

This directory contains notification sounds for the kitchen/waiter dashboard with multi-language support.

## Supported Languages

1. **English (en)** - Default language
2. **Amharic (am)** - Ethiopian official language
3. **Oromo (om)** - Widely spoken in Ethiopia

## Audio Files Required

### Generic Sounds
- `notification.mp3` - Generic notification alert
- `bell.mp3` - Bell/ring sound for alerts

### English Sounds
- `waiter_call_en.mp3` - "Table [X] is calling for a waiter"
- `new_order_en.mp3` - "New order received"
- `order_ready_en.mp3` - "Order is ready"

### Amharic Sounds (አማርኛ)
- `waiter_call_am.mp3` - "ጠረጴዛ [X] ጠበቃ ይፈልጋል" (Table X needs a waiter)
- `new_order_am.mp3` - "አዲስ ትዕዛዝ ደርሷል" (New order has arrived)
- `order_ready_am.mp3` - "ትዕዛዝ ዝግጁ ነው" (Order is ready)

### Oromo Sounds (Afaan Oromoo)
- `waiter_call_om.mp3` - "Meshaa [X] taphaataa barbaada" (Table X needs a waiter)
- `new_order_om.mp3` - "Ajaja haaraa galmeera" (New order has arrived)
- `order_ready_om.mp3` - "Ajaja qophaa'ee jira" (Order is ready)

## How to Create Audio Files

### Option 1: Text-to-Speech Services

**Google Cloud Text-to-Speech (Recommended)**
```bash
# Install gcloud CLI and authenticate
gcloud auth login

# Generate Amharic audio
gcloud text-to-speech synthesize --text="ጠረጴዛ 1 ጠበቃ ይፈልጋል" --language=am-ET --output=waiter_call_am.mp3

# Generate Oromo audio  
gcloud text-to-speech synthesize --text="Meshaa 1 taphaataa barbaada" --language=om-ET --output=waiter_call_om.mp3
```

**Amazon Polly**
- Supports Amharic voice: "Habtamu"
- Sign up at https://aws.amazon.com/polly/
- Use AWS CLI or console to generate audio

**Microsoft Azure Speech**
- Supports multiple African languages
- https://azure.microsoft.com/en-us/services/cognitive-services/text-to-speech/

### Option 2: Record Native Speakers

Best quality option - record native speakers saying the phrases:

**Amharic Phrases:**
- "ጠረጴዛ [number] ጠበቃ ይፈልጋል" - Table [number] needs a waiter
- "አዲስ ትዕዛዝ [number] ደርሷል" - New order [number] has arrived  
- "ትዕዛዝ [number] ዝግጁ ነው" - Order [number] is ready

**Oromo Phrases:**
- "Meshaa [number] taphaataa barbaada" - Table [number] needs a waiter
- "Ajaja haaraa [number] galmeera" - New order [number] has arrived
- "Ajaja [number] qophaa'ee jira" - Order [number] is ready

### Option 3: Use Generic Alert Sounds

If language-specific audio is not available, copy the generic sounds:
```bash
cp notification.mp3 waiter_call_en.mp3
cp notification.mp3 new_order_en.mp3
...
```

## Technical Requirements

- **Format**: MP3 (MPEG-1 Audio Layer III)
- **Sample Rate**: 44.1 kHz (44100 Hz)
- **Bit Rate**: 128-192 kbps
- **Channels**: Mono (1 channel) or Stereo (2 channels)
- **Duration**: 1-3 seconds maximum
- **File Size**: < 100KB per file

## Testing Audio

Run the audio test in the app:
1. Go to Kitchen Dashboard
2. Click the language selector (top right)
3. Select a language
4. Trigger a test waiter call

## Troubleshooting

**Audio not playing on Android:**
- Check audio file format is MP3
- Verify files are listed in `pubspec.yaml`
- Run `flutter clean && flutter pub get`

**Audio not playing on Web:**
- Web browsers require user interaction before playing audio
- First click/ interaction will enable audio context
- Use Chrome/Edge for best Web Audio API support

**Low volume on mobile:**
- Check device volume settings
- Use `AudioManager` for Android volume control
- Test with headphones vs speakers

## License

Ensure all audio files have proper licensing for commercial use.
- Text-to-speech: Check service terms
- Recorded audio: Get signed releases from speakers
- Stock sounds: Verify license permits commercial use
