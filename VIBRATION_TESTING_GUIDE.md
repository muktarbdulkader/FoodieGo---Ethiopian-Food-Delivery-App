# Vibration Alerts Testing Guide

## Overview
This guide provides step-by-step instructions for testing the vibration alerts feature on Android and iOS devices. The vibration functionality has been implemented in the Order Status Page and triggers on specific order status changes.

## Prerequisites

### General Requirements
- Physical Android or iOS device (vibration cannot be tested on emulators/simulators)
- Device with vibration motor capability
- FoodieGo app installed on the device
- Active internet connection
- Access to the backend server

### Android Requirements (Task 4.2.3)
- Android device running Android 5.0 (API 21) or higher
- USB debugging enabled (for installation via Android Studio)
- OR APK file for direct installation

### iOS Requirements (Task 4.2.4)
- iOS device running iOS 12.0 or higher
- Device registered in Apple Developer account (for testing)
- Xcode installed on Mac (for building and deploying)

## Vibration Implementation Details

The app implements two types of vibration patterns:

### 1. Pattern Vibration (Order Ready)
- **Trigger**: When order status changes to "ready"
- **Pattern**: 200ms on → 100ms off → 200ms on
- **Purpose**: Alert customer that their order is ready for pickup

### 2. Long Vibration (Order Cancelled)
- **Trigger**: When order status changes to "cancelled"
- **Duration**: 500ms continuous vibration
- **Purpose**: Alert customer of order cancellation

## Testing Procedure

### Task 4.2.3: Test Vibration on Android Device

#### Step 1: Prepare the Device
1. Ensure your Android device has vibration enabled:
   - Go to **Settings** → **Sound & vibration**
   - Verify that vibration is enabled
   - Test vibration works (try typing on keyboard with haptic feedback)

2. Install the FoodieGo app:
   ```bash
   # From the frontend directory
   cd frontend
   flutter build apk --release
   # Install the APK on your device
   flutter install
   ```

#### Step 2: Set Up Test Environment
1. Launch the FoodieGo app on your Android device
2. Log in or create a test account
3. Navigate to a restaurant and scan a QR code for dine-in
4. Place a test order with at least one item
5. Navigate to the Order Status page

#### Step 3: Test Pattern Vibration (Order Ready)
1. Keep your Android device in hand to feel the vibration
2. From the kitchen dashboard (on another device or web browser):
   - Log in as admin/kitchen staff
   - Navigate to Kitchen Orders page
   - Find your test order
   - Update the order status through these stages:
     - **Pending** → **Confirmed** (no vibration expected)
     - **Confirmed** → **Preparing** (no vibration expected)
     - **Preparing** → **Ready** ✅ **VIBRATION SHOULD OCCUR HERE**

3. **Expected Result**:
   - Device should vibrate with pattern: buzz-pause-buzz
   - Pattern should be: 200ms vibration, 100ms pause, 200ms vibration
   - A snackbar notification should appear: "Order #XXX is ready! Please collect from counter"
   - Order status should update to "Ready" in the UI

4. **Verification Checklist**:
   - [ ] Vibration occurred when status changed to "ready"
   - [ ] Vibration pattern felt like two distinct buzzes with a pause
   - [ ] Snackbar notification appeared
   - [ ] UI updated to show "Ready" status
   - [ ] No app crashes or errors

#### Step 4: Test Long Vibration (Order Cancelled)
1. Place another test order
2. Keep your Android device in hand
3. From the kitchen dashboard:
   - Find your new test order
   - Cancel the order (change status to "Cancelled")

4. **Expected Result**:
   - Device should vibrate with a single long buzz (500ms)
   - A dialog should appear: "Order Cancelled"
   - Dialog message: "Your order #XXX has been cancelled. Please contact the waiter for assistance."

5. **Verification Checklist**:
   - [ ] Vibration occurred when order was cancelled
   - [ ] Vibration felt like one continuous buzz (longer than pattern vibration)
   - [ ] Cancellation dialog appeared
   - [ ] Dialog had correct message and styling
   - [ ] No app crashes or errors

#### Step 5: Test Edge Cases (Android)
1. **Test with vibration disabled**:
   - Go to device Settings → Sound & vibration
   - Disable vibration
   - Trigger order status changes
   - **Expected**: No vibration, but notifications should still appear

2. **Test with app in background**:
   - Place an order
   - Press home button (app goes to background)
   - Change order status from kitchen dashboard
   - **Expected**: Vibration should still work when app receives WebSocket event

3. **Test with device in silent mode**:
   - Enable silent/vibrate mode on device
   - Trigger order status changes
   - **Expected**: Vibration should still work

#### Step 6: Document Results (Android)
Record your findings:
- Device model and Android version
- All test cases passed/failed
- Any issues or unexpected behavior
- Screenshots or screen recordings (optional)

---

### Task 4.2.4: Test Vibration on iOS Device

#### Step 1: Prepare the Device
1. Ensure your iOS device has vibration enabled:
   - Go to **Settings** → **Sounds & Haptics**
   - Verify that vibration is enabled for alerts
   - Test vibration works (try toggling silent mode switch)

2. Build and install the FoodieGo app:
   ```bash
   # From the frontend directory
   cd frontend
   flutter build ios --release
   # Open in Xcode and deploy to device
   open ios/Runner.xcworkspace
   ```

3. In Xcode:
   - Select your iOS device as the target
   - Click Run to build and install on device

#### Step 2: Set Up Test Environment
1. Launch the FoodieGo app on your iOS device
2. Log in or create a test account
3. Navigate to a restaurant and scan a QR code for dine-in
4. Place a test order with at least one item
5. Navigate to the Order Status page

#### Step 3: Test Pattern Vibration (Order Ready)
1. Keep your iOS device in hand to feel the vibration
2. From the kitchen dashboard (on another device or web browser):
   - Log in as admin/kitchen staff
   - Navigate to Kitchen Orders page
   - Find your test order
   - Update the order status through these stages:
     - **Pending** → **Confirmed** (no vibration expected)
     - **Confirmed** → **Preparing** (no vibration expected)
     - **Preparing** → **Ready** ✅ **VIBRATION SHOULD OCCUR HERE**

3. **Expected Result**:
   - Device should vibrate with pattern: buzz-pause-buzz
   - Pattern should be: 200ms vibration, 100ms pause, 200ms vibration
   - A snackbar notification should appear: "Order #XXX is ready! Please collect from counter"
   - Order status should update to "Ready" in the UI

4. **Verification Checklist**:
   - [ ] Vibration occurred when status changed to "ready"
   - [ ] Vibration pattern felt like two distinct buzzes with a pause
   - [ ] Snackbar notification appeared
   - [ ] UI updated to show "Ready" status
   - [ ] No app crashes or errors

#### Step 4: Test Long Vibration (Order Cancelled)
1. Place another test order
2. Keep your iOS device in hand
3. From the kitchen dashboard:
   - Find your new test order
   - Cancel the order (change status to "Cancelled")

4. **Expected Result**:
   - Device should vibrate with a single long buzz (500ms)
   - A dialog should appear: "Order Cancelled"
   - Dialog message: "Your order #XXX has been cancelled. Please contact the waiter for assistance."

5. **Verification Checklist**:
   - [ ] Vibration occurred when order was cancelled
   - [ ] Vibration felt like one continuous buzz (longer than pattern vibration)
   - [ ] Cancellation dialog appeared
   - [ ] Dialog had correct message and styling
   - [ ] No app crashes or errors

#### Step 5: Test Edge Cases (iOS)
1. **Test with vibration disabled**:
   - Go to device Settings → Sounds & Haptics
   - Disable vibration for alerts
   - Trigger order status changes
   - **Expected**: No vibration, but notifications should still appear

2. **Test with app in background**:
   - Place an order
   - Press home button (app goes to background)
   - Change order status from kitchen dashboard
   - **Expected**: Vibration should still work when app receives WebSocket event

3. **Test with silent mode enabled**:
   - Enable silent mode using the physical switch
   - Trigger order status changes
   - **Expected**: Vibration should still work (iOS vibrates in silent mode)

4. **Test with Do Not Disturb enabled**:
   - Enable Do Not Disturb mode
   - Trigger order status changes
   - **Expected**: Vibration should still work (app is in foreground)

#### Step 6: Document Results (iOS)
Record your findings:
- Device model and iOS version
- All test cases passed/failed
- Any issues or unexpected behavior
- Screenshots or screen recordings (optional)

---

## Common Issues and Troubleshooting

### Issue 1: No Vibration Occurs
**Possible Causes**:
- Device vibration is disabled in system settings
- Device doesn't have a vibration motor (rare)
- App doesn't have permission to vibrate (Android only)
- WebSocket connection is not established

**Solutions**:
1. Check device vibration settings
2. Verify `VIBRATE` permission in AndroidManifest.xml (Android)
3. Check WebSocket connection status indicator in app
4. Review app logs for errors

### Issue 2: Vibration Pattern Not Distinct
**Possible Causes**:
- Device vibration motor is weak
- Pattern timing is too fast to distinguish

**Solutions**:
1. Test on a different device
2. Adjust pattern timing in code if needed (increase pause duration)

### Issue 3: App Crashes on Status Change
**Possible Causes**:
- Null pointer exception in vibration code
- WebSocket event handling error

**Solutions**:
1. Check app logs for stack trace
2. Verify order data structure matches expected format
3. Test with different order scenarios

### Issue 4: Vibration Works on Android but Not iOS
**Possible Causes**:
- iOS vibration API differences
- iOS permissions or entitlements missing

**Solutions**:
1. Verify `vibration` package supports iOS
2. Check iOS build settings and capabilities
3. Test on different iOS versions

---

## Test Report Template

Use this template to document your testing results:

```markdown
## Vibration Testing Report

### Test Environment
- **Date**: [Date of testing]
- **Tester**: [Your name]
- **App Version**: 1.0.1+2

### Android Testing (Task 4.2.3)
- **Device**: [Model and manufacturer]
- **Android Version**: [e.g., Android 13]
- **Test Results**:
  - Pattern Vibration (Order Ready): ✅ PASS / ❌ FAIL
  - Long Vibration (Order Cancelled): ✅ PASS / ❌ FAIL
  - Vibration Disabled Test: ✅ PASS / ❌ FAIL
  - Background Test: ✅ PASS / ❌ FAIL
  - Silent Mode Test: ✅ PASS / ❌ FAIL
- **Issues Found**: [List any issues]
- **Notes**: [Additional observations]

### iOS Testing (Task 4.2.4)
- **Device**: [Model]
- **iOS Version**: [e.g., iOS 17.2]
- **Test Results**:
  - Pattern Vibration (Order Ready): ✅ PASS / ❌ FAIL
  - Long Vibration (Order Cancelled): ✅ PASS / ❌ FAIL
  - Vibration Disabled Test: ✅ PASS / ❌ FAIL
  - Background Test: ✅ PASS / ❌ FAIL
  - Silent Mode Test: ✅ PASS / ❌ FAIL
  - Do Not Disturb Test: ✅ PASS / ❌ FAIL
- **Issues Found**: [List any issues]
- **Notes**: [Additional observations]

### Overall Assessment
- **Status**: ✅ All tests passed / ⚠️ Some issues found / ❌ Major issues
- **Recommendation**: [Ready for production / Needs fixes / Needs further testing]
```

---

## Code Reference

The vibration implementation can be found in:
- **File**: `frontend/lib/presentation/pages/dine_in/order_status_page.dart`
- **Methods**:
  - `_vibratePattern()` - Lines 177-182 (Pattern vibration for order ready)
  - `_vibrateLong()` - Lines 185-190 (Long vibration for order cancelled)
  - `_handleOrderUpdate()` - Lines 56-95 (Event handler that triggers vibrations)

### Pattern Vibration Code
```dart
Future<void> _vibratePattern() async {
  // Pattern: 200ms on, 100ms off, 200ms on
  final hasVibrator = await Vibration.hasVibrator();
  if (hasVibrator == true) {
    Vibration.vibrate(pattern: [0, 200, 100, 200]);
  }
}
```

### Long Vibration Code
```dart
Future<void> _vibrateLong() async {
  // Long vibration: 500ms
  final hasVibrator = await Vibration.hasVibrator();
  if (hasVibrator == true) {
    Vibration.vibrate(duration: 500);
  }
}
```

---

## Next Steps

After completing the testing:

1. **Document Results**: Fill out the test report template above
2. **Report Issues**: If any issues are found, create detailed bug reports
3. **Update Tasks**: Mark tasks 4.2.3 and 4.2.4 as complete in the task list
4. **Proceed to Next Phase**: Continue with Phase 4.3 (Enhance In-App Notifications)

---

## Additional Resources

- **Vibration Package Documentation**: https://pub.dev/packages/vibration
- **Flutter Platform Channels**: https://flutter.dev/docs/development/platform-integration/platform-channels
- **Android Vibration API**: https://developer.android.com/reference/android/os/Vibrator
- **iOS Haptic Feedback**: https://developer.apple.com/design/human-interface-guidelines/haptics

---

## Contact

If you encounter any issues during testing or need clarification, please contact the development team.
