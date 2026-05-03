# 📱 Android APK Build Guide

## 🎯 Overview

This guide explains how to build an Android APK for your Foodiego app. The process you're seeing is **normal** - downloading the Android NDK (Native Development Kit) takes time, especially on first build.

---

## ⏱️ What's Happening Now

### Current Status
```
Installing NDK (Side by side) 27.0.12077973
```

**This is NORMAL!** The Android NDK is a large download (~1-2 GB) and takes time:
- **Fast Internet**: 10-20 minutes
- **Average Internet**: 20-40 minutes  
- **Slow Internet**: 40-90 minutes

### What is NDK?
The **Native Development Kit (NDK)** allows Flutter to compile native C/C++ code for Android. It's required for building release APKs.

---

## 📊 Build Process Timeline

### Phase 1: NDK Download (Current)
```
⏳ Downloading NDK... (10-40 minutes)
├─ Preparing install
├─ Downloading package (~1-2 GB)
├─ Installing to SDK folder
└─ Complete ✓
```

### Phase 2: Gradle Build
```
⏳ Running Gradle task 'assembleDebug'... (5-15 minutes)
├─ Resolving dependencies
├─ Compiling Dart code
├─ Building native libraries
├─ Packaging APK
└─ Complete ✓
```

### Phase 3: APK Ready
```
✅ APK built successfully!
Location: build/app/outputs/flutter-apk/app-release.apk
```

**Total Time: 15-55 minutes (first build)**
**Subsequent Builds: 2-5 minutes**

---

## 🚀 Complete Build Instructions

### Prerequisites

**1. Install Flutter**
```bash
# Check Flutter is installed
flutter --version

# If not installed, download from:
# https://flutter.dev/docs/get-started/install
```

**2. Install Android Studio**
```bash
# Download from:
# https://developer.android.com/studio

# Or check if already installed:
# C:\Users\hp\AppData\Local\Android\Sdk
```

**3. Accept Android Licenses**
```bash
flutter doctor --android-licenses
# Press 'y' to accept all licenses
```

---

## 🔨 Building APK

### Step 1: Update API URL for Production

**Edit: `frontend/lib/core/constants/api_constants.dart`**
```dart
class ApiConstants {
  // Change this to your production backend URL
  static const String baseUrl = 'https://your-backend.onrender.com/api';
  
  // Or use environment-based configuration
  static String get baseUrl {
    const env = String.fromEnvironment('ENV', defaultValue: 'production');
    if (env == 'development') {
      return 'http://10.0.2.2:5001/api'; // Android emulator
    }
    return 'https://your-backend.onrender.com/api'; // Production
  }
}
```

### Step 2: Clean Previous Builds
```bash
cd frontend
flutter clean
flutter pub get
```

### Step 3: Build Debug APK (Faster, for Testing)
```bash
flutter build apk --debug
```

**Output:**
```
✓ Built build/app/outputs/flutter-apk/app-debug.apk (50-80 MB)
```

### Step 4: Build Release APK (Optimized, for Distribution)
```bash
flutter build apk --release
```

**Output:**
```
✓ Built build/app/outputs/flutter-apk/app-release.apk (20-30 MB)
```

### Step 5: Build Split APKs (Smaller Size)
```bash
flutter build apk --split-per-abi
```

**Output:**
```
✓ Built build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk (15 MB)
✓ Built build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (18 MB)
✓ Built build/app/outputs/flutter-apk/app-x86_64-release.apk (20 MB)
```

---

## 📦 APK Types Explained

### Debug APK
```
Size: 50-80 MB
Speed: Fast to build (2-5 minutes)
Use: Testing and development
Performance: Slower, includes debug info
```

### Release APK
```
Size: 20-30 MB
Speed: Slower to build (10-20 minutes first time)
Use: Production distribution
Performance: Optimized, no debug info
```

### Split APKs
```
Size: 15-20 MB each
Speed: Same as release
Use: Smaller downloads per device
Performance: Optimized for specific CPU architecture
```

---

## 🎯 What to Do While Waiting

### During NDK Download (10-40 minutes)

**Option 1: Take a Break**
- ☕ Get coffee
- 🍕 Have lunch
- 🚶 Take a walk

**Option 2: Prepare Other Things**
- 📝 Write app description
- 📸 Take screenshots
- 🎨 Design app icon
- 📄 Prepare privacy policy

**Option 3: Work on Backend**
- 🚀 Deploy backend to Render.com
- 🗄️ Seed production database
- 🔐 Configure environment variables
- 🧪 Test API endpoints

### During Gradle Build (5-15 minutes)

**Option 1: Monitor Progress**
```bash
# Watch the build output
# You'll see:
# - Resolving dependencies
# - Compiling Dart code
# - Building native libraries
# - Packaging APK
```

**Option 2: Prepare Distribution**
- 📱 Set up Google Play Console account
- 📋 Prepare app listing
- 🖼️ Create promotional graphics
- 📝 Write release notes

---

## 🐛 Troubleshooting

### Problem 1: NDK Download Stuck

**Symptoms:**
```
Installing NDK... (stuck for >1 hour)
```

**Solutions:**

**A. Check Internet Connection**
```bash
# Test download speed
# Visit: https://fast.com
# Minimum recommended: 5 Mbps
```

**B. Restart Download**
```bash
# Cancel current build (Ctrl+C)
# Delete partial download
rm -rf C:\Users\hp\AppData\Local\Android\Sdk\ndk\27.0.12077973

# Restart build
flutter build apk
```

**C. Manual NDK Installation**
```bash
# Open Android Studio
# Tools → SDK Manager → SDK Tools
# Check "NDK (Side by side)"
# Click "Apply" to download
```

### Problem 2: Build Fails

**Error: Gradle build failed**
```
FAILURE: Build failed with an exception
```

**Solutions:**

**A. Clean and Rebuild**
```bash
cd frontend
flutter clean
flutter pub get
flutter build apk --release
```

**B. Update Dependencies**
```bash
flutter pub upgrade
flutter build apk --release
```

**C. Check Android SDK**
```bash
flutter doctor -v
# Fix any issues shown
```

### Problem 3: APK Too Large

**Problem:**
```
APK size: 80 MB (too large for sharing)
```

**Solutions:**

**A. Build Split APKs**
```bash
flutter build apk --split-per-abi
# Results in 3 smaller APKs (15-20 MB each)
```

**B. Enable Proguard (Shrink Code)**

Edit `android/app/build.gradle`:
```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android.txt')
    }
}
```

**C. Remove Unused Resources**
```bash
flutter build apk --release --target-platform android-arm64
```

### Problem 4: APK Won't Install

**Error: App not installed**

**Solutions:**

**A. Enable Unknown Sources**
```
Settings → Security → Unknown Sources → Enable
```

**B. Uninstall Old Version**
```
Settings → Apps → Foodiego → Uninstall
# Then install new APK
```

**C. Check Signature**
```bash
# Debug and release APKs have different signatures
# Uninstall debug version before installing release
```

---

## 📱 Testing APK

### Step 1: Transfer APK to Phone

**Method A: USB Cable**
```bash
# Connect phone via USB
# Copy APK to phone storage
# Open file manager on phone
# Tap APK to install
```

**Method B: Cloud Storage**
```bash
# Upload APK to Google Drive/Dropbox
# Open link on phone
# Download and install
```

**Method C: ADB Install**
```bash
# Connect phone via USB
# Enable USB debugging on phone
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Step 2: Test Features

**Basic Tests:**
- [ ] App opens without crashing
- [ ] Splash screen shows
- [ ] Language selection works
- [ ] Can register/login
- [ ] Home page loads restaurants
- [ ] Images load correctly
- [ ] Can add items to cart
- [ ] Checkout works
- [ ] QR scanner works (requires camera permission)

**Network Tests:**
- [ ] API calls work (check backend URL)
- [ ] Can fetch restaurants
- [ ] Can place orders
- [ ] Can view order history
- [ ] Real-time updates work

**Permission Tests:**
- [ ] Camera permission (for QR scanner)
- [ ] Location permission (for delivery)
- [ ] Notification permission
- [ ] Storage permission (for images)

---

## 🚀 Distribution Options

### Option 1: Direct APK Sharing (Easiest)

**Pros:**
- ✅ Instant distribution
- ✅ No approval process
- ✅ Free

**Cons:**
- ❌ Users must enable "Unknown Sources"
- ❌ No automatic updates
- ❌ Less trustworthy

**How to Share:**
```bash
# Upload APK to:
# - Google Drive
# - Dropbox
# - Your website
# - WhatsApp/Telegram

# Share link with users
```

### Option 2: Google Play Store (Recommended)

**Pros:**
- ✅ Trusted source
- ✅ Automatic updates
- ✅ Better discovery
- ✅ Analytics included

**Cons:**
- ❌ $25 one-time fee
- ❌ Review process (1-3 days)
- ❌ Must follow policies

**Steps:**
1. Create Google Play Console account ($25)
2. Create app listing
3. Upload APK
4. Fill out store listing
5. Submit for review
6. Wait 1-3 days for approval

### Option 3: Alternative App Stores

**Options:**
- Amazon Appstore
- Samsung Galaxy Store
- Huawei AppGallery
- APKPure
- F-Droid (for open source)

---

## 🔐 Signing APK (For Play Store)

### Step 1: Generate Keystore

```bash
keytool -genkey -v -keystore foodiego-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias foodiego
```

**Enter details:**
```
Password: [your-secure-password]
Name: Your Name
Organization: Your Company
City: Addis Ababa
State: Addis Ababa
Country: ET
```

### Step 2: Configure Signing

**Create: `android/key.properties`**
```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=foodiego
storeFile=../foodiego-key.jks
```

**Edit: `android/app/build.gradle`**
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### Step 3: Build Signed APK

```bash
flutter build apk --release
```

**⚠️ IMPORTANT: Keep keystore safe!**
- Backup `foodiego-key.jks` file
- Never commit to Git
- Store password securely
- You cannot update app without it!

---

## 📊 Build Size Optimization

### Current Size Breakdown
```
Total APK: ~25 MB
├─ Flutter Engine: 8 MB
├─ Dart Code: 5 MB
├─ Assets (images): 8 MB
├─ Native Libraries: 3 MB
└─ Other: 1 MB
```

### Optimization Techniques

**1. Compress Images**
```bash
# Use TinyPNG or similar
# Reduce image quality to 80%
# Convert PNG to WebP
```

**2. Remove Unused Packages**
```yaml
# pubspec.yaml
# Comment out unused dependencies
# Run: flutter pub get
```

**3. Enable Obfuscation**
```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

**4. Use Split APKs**
```bash
flutter build apk --split-per-abi
# Reduces size by 40-50%
```

---

## ✅ Final Checklist

### Before Building
- [ ] API URL updated to production
- [ ] All features tested locally
- [ ] No console errors
- [ ] App icon configured
- [ ] App name configured
- [ ] Version number updated

### After Building
- [ ] APK installs successfully
- [ ] All features work on real device
- [ ] Network requests work
- [ ] Permissions granted correctly
- [ ] No crashes
- [ ] Performance acceptable

### Before Distribution
- [ ] APK signed (for Play Store)
- [ ] Privacy policy created
- [ ] Terms of service created
- [ ] App screenshots taken
- [ ] Store listing prepared
- [ ] Support email configured

---

## 🎉 Success!

Once your APK is built and tested, you're ready to distribute your app!

**Next Steps:**
1. ✅ Test APK thoroughly
2. 📱 Share with beta testers
3. 🐛 Fix any issues
4. 🚀 Upload to Play Store
5. 📣 Announce launch!

---

## 📞 Need Help?

**Common Issues:**
- NDK download slow → Normal, just wait
- Build fails → Run `flutter clean` and retry
- APK too large → Use split APKs
- Won't install → Enable Unknown Sources

**Resources:**
- [Flutter Android Build Docs](https://flutter.dev/docs/deployment/android)
- [Google Play Console](https://play.google.com/console)
- [Android Studio](https://developer.android.com/studio)

**Your build is in progress! Just wait for it to complete. ⏳**
