# FoodieGo Deployment Guide

## Step 1: Deploy Backend (Free on Render)

### 1.1 Create MongoDB Atlas Database (Free)
1. Go to [mongodb.com/atlas](https://www.mongodb.com/atlas)
2. Create free account → Create free cluster (M0)
3. Create database user with password
4. Get connection string: `mongodb+srv://username:password@cluster.mongodb.net/foodiego`

### 1.2 Deploy to Render
1. Go to [render.com](https://render.com) → Sign up free
2. Click "New" → "Web Service"
3. Connect your GitHub repo (or use "Public Git repository")
4. Configure:
   - **Name**: `foodiego-api`
   - **Root Directory**: `backend`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
5. Add Environment Variables:
   - `MONGODB_URI` = your MongoDB Atlas connection string
   - `JWT_SECRET` = any-random-secret-string-here
   - `JWT_EXPIRES_IN` = 7d
   - `NODE_ENV` = production
6. Click "Create Web Service"
7. Wait for deploy → Copy your URL (e.g., `https://foodiego-api.onrender.com`)

## Step 2: Update Flutter App

### 2.1 Update API URL
Edit `frontend/lib/core/constants/api_constants.dart`:
```dart
static const String productionUrl = 'https://foodiego-api.onrender.com/api';
```

## Step 3: Build APK

### 3.1 Build Release APK
```bash
cd frontend
flutter build apk --release --dart-define=PRODUCTION=true
```

### 3.2 Find your APK
```
frontend/build/app/outputs/flutter-apk/app-release.apk
```

## Step 4: Distribute APK

### Option A: Direct Share (Free)
- Share APK file via WhatsApp, Telegram, Google Drive, etc.
- Users enable "Install from unknown sources" to install

### Option B: Firebase App Distribution (Free)
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create project → App Distribution
3. Upload APK → Add testers by email

### Option C: Google Play Store ($25 one-time)
1. Go to [play.google.com/console](https://play.google.com/console)
2. Pay $25 registration fee
3. Create app → Upload signed APK/AAB

## Build Commands Summary

```bash
# Development (localhost)
cd frontend
flutter run

# Production APK
flutter build apk --release --dart-define=PRODUCTION=true

# Production App Bundle (for Play Store)
flutter build appbundle --release --dart-define=PRODUCTION=true
```

## Free Tier Limits

| Service | Free Limit |
|---------|------------|
| Render | 750 hours/month, sleeps after 15min idle |
| MongoDB Atlas | 512MB storage |
| Firebase App Distribution | Unlimited |

## Notes
- Render free tier sleeps after 15 minutes of inactivity (first request takes ~30 seconds to wake up)
- For production, consider upgrading to paid tier ($7/month) for always-on service
