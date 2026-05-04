# Vibration Testing Quick Checklist

## Task 4.2.3: Android Device Testing

### Setup
- [ ] Android device with vibration enabled
- [ ] FoodieGo app installed on device
- [ ] Logged in to app
- [ ] Test order placed

### Pattern Vibration Test (Order Ready)
- [ ] Order status changed from "Preparing" to "Ready"
- [ ] Device vibrated with pattern (buzz-pause-buzz)
- [ ] Snackbar notification appeared
- [ ] UI updated correctly
- [ ] No crashes or errors

### Long Vibration Test (Order Cancelled)
- [ ] Order cancelled from kitchen dashboard
- [ ] Device vibrated with long buzz (500ms)
- [ ] Cancellation dialog appeared
- [ ] Dialog message correct
- [ ] No crashes or errors

### Edge Cases
- [ ] Vibration disabled: No vibration, notifications still work
- [ ] App in background: Vibration still works
- [ ] Silent mode: Vibration still works

### Documentation
- [ ] Device model and Android version recorded
- [ ] Test results documented
- [ ] Issues logged (if any)
- [ ] Screenshots/recordings captured (optional)

---

## Task 4.2.4: iOS Device Testing

### Setup
- [ ] iOS device with vibration enabled
- [ ] FoodieGo app installed on device
- [ ] Logged in to app
- [ ] Test order placed

### Pattern Vibration Test (Order Ready)
- [ ] Order status changed from "Preparing" to "Ready"
- [ ] Device vibrated with pattern (buzz-pause-buzz)
- [ ] Snackbar notification appeared
- [ ] UI updated correctly
- [ ] No crashes or errors

### Long Vibration Test (Order Cancelled)
- [ ] Order cancelled from kitchen dashboard
- [ ] Device vibrated with long buzz (500ms)
- [ ] Cancellation dialog appeared
- [ ] Dialog message correct
- [ ] No crashes or errors

### Edge Cases
- [ ] Vibration disabled: No vibration, notifications still work
- [ ] App in background: Vibration still works
- [ ] Silent mode: Vibration still works
- [ ] Do Not Disturb: Vibration still works

### Documentation
- [ ] Device model and iOS version recorded
- [ ] Test results documented
- [ ] Issues logged (if any)
- [ ] Screenshots/recordings captured (optional)

---

## Quick Test Summary

| Test Case | Android | iOS | Notes |
|-----------|---------|-----|-------|
| Pattern Vibration (Ready) | ⬜ | ⬜ | Should feel like buzz-pause-buzz |
| Long Vibration (Cancelled) | ⬜ | ⬜ | Should feel like one long buzz |
| Vibration Disabled | ⬜ | ⬜ | No vibration, UI still updates |
| Background Mode | ⬜ | ⬜ | Vibration works when app backgrounded |
| Silent Mode | ⬜ | ⬜ | Vibration still works |
| Do Not Disturb | N/A | ⬜ | iOS only |

**Legend**: ✅ Pass | ❌ Fail | ⬜ Not Tested | N/A Not Applicable

---

## Quick Commands

### Build and Install on Android
```bash
cd frontend
flutter build apk --release
flutter install
```

### Build and Install on iOS
```bash
cd frontend
flutter build ios --release
open ios/Runner.xcworkspace
# Then run from Xcode
```

### View Logs (Android)
```bash
flutter logs
# or
adb logcat | grep -i flutter
```

### View Logs (iOS)
```bash
flutter logs
# or check Xcode console
```

---

## Expected Behavior Summary

### When Order Status Changes to "Ready"
1. ✅ Pattern vibration: 200ms → pause 100ms → 200ms
2. ✅ Snackbar: "Order #XXX is ready! Please collect from counter"
3. ✅ UI updates to show "Ready" status with green badge
4. ✅ Status timeline advances to "Ready" step

### When Order is Cancelled
1. ✅ Long vibration: 500ms continuous
2. ✅ Dialog appears: "Order Cancelled"
3. ✅ Dialog message: "Your order #XXX has been cancelled. Please contact the waiter for assistance."
4. ✅ UI updates to show cancelled state with red icon

---

## Common Issues Quick Reference

| Issue | Likely Cause | Quick Fix |
|-------|--------------|-----------|
| No vibration at all | Device settings disabled | Check Settings → Sound & vibration |
| Pattern not distinct | Timing too fast | Test on different device |
| App crashes | WebSocket event error | Check logs for stack trace |
| Works on Android, not iOS | Platform differences | Verify vibration package iOS support |
| Vibration in emulator | Not supported | Must test on physical device |

---

## Test Report Quick Template

```
VIBRATION TESTING RESULTS

Android (Task 4.2.3):
- Device: [Model]
- Version: [Android X]
- Pattern Vibration: PASS/FAIL
- Long Vibration: PASS/FAIL
- Edge Cases: PASS/FAIL
- Issues: [None / List issues]

iOS (Task 4.2.4):
- Device: [Model]
- Version: [iOS X]
- Pattern Vibration: PASS/FAIL
- Long Vibration: PASS/FAIL
- Edge Cases: PASS/FAIL
- Issues: [None / List issues]

Overall: READY FOR PRODUCTION / NEEDS FIXES
```
