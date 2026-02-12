# Horn-In APK Build & Deployment Guide

## Current Status
✅ **Web Build:** Complete - Located at `build/web/`  
⏳ **Android APK:** Requires Android SDK installation  
ℹ️ **iOS Build:** Requires macOS with Xcode

---

## Step-by-Step: Building the Android APK

### Step 1: Install Android Studio
1. Download from: https://developer.android.com/studio
2. Run the installer
3. During setup, check these components:
   - Android SDK
   - Android SDK Platform-Tools
   - Android Virtual Device (optional)
4. Complete the installation wizard

### Step 2: Set Environment Variable
After installing, set the ANDROID_HOME environment variable:
1. Open **Settings** > **System** > **About** > **Advanced system settings**
2. Click **Environment Variables**
3. Under **User variables**, click **New**:
   - Variable name: `ANDROID_HOME`
   - Variable value: `C:\Users\User\AppData\Local\Android\Sdk`
4. Click OK and restart your terminal

### Step 3: Accept Licenses
Open a **new** terminal and run:
```powershell
flutter doctor --android-licenses
```
Press 'y' to accept all licenses.

### Step 4: Verify Setup
```powershell
flutter doctor
```
You should see a green checkmark next to "Android toolchain"

### Step 5: Build the APK
```powershell
cd "C:\Users\User\Desktop\MOBPROG_FINALS\nagales_mobprog_finals"
flutter build apk --release
```

### Step 6: Find Your APK
The APK will be located at:
```
build\app\outputs\flutter-apk\app-release.apk
```

---

## Installing APK on Android Phone

### Method 1: USB Transfer
1. Connect your phone via USB cable
2. Enable **File Transfer** mode on phone
3. Copy `app-release.apk` to your phone's Downloads folder
4. On your phone, open **Settings** > **Security**
5. Enable **Install from Unknown Sources** (or install when prompted)
6. Use a file manager to tap on the APK and install

### Method 2: Cloud Transfer
1. Upload `app-release.apk` to Google Drive
2. On your phone, open Google Drive
3. Tap the APK file
4. Allow installation from this source
5. Install the app

### Method 3: Direct ADB Install
With phone connected and USB debugging enabled:
```powershell
adb install build\app\outputs\flutter-apk\app-release.apk
```

---

## iOS Deployment Options

### ⚠️ Requirements
iOS deployment requires:
- **macOS computer** (mandatory)
- **Xcode** installed
- **Apple Developer Account** ($99/year for distribution)

### Option A: TestFlight (Beta Testing)
1. Build on Mac: `flutter build ios --release`
2. Archive in Xcode
3. Upload to App Store Connect
4. Invite testers via TestFlight

### Option B: Direct Device Install (Dev Account)
1. Connect iPhone to Mac
2. Run: `flutter run --release -d <device-id>`
3. Trust the developer certificate on your iPhone

### Option C: Alternative for iPhone
Since you're on Windows, you can:
1. **Use the Web Version** - Access via Safari on iPhone
2. **Use a Cloud Build Service** like Codemagic or GitHub Actions
3. **Ask a friend with Mac** to build the IPA for you

---

## Using the Web Version

The web version is already built! To test locally:
```powershell
cd "C:\Users\User\Desktop\MOBPROG_FINALS\nagales_mobprog_finals"
flutter run -d edge
```

To host online (for mobile access):
1. Upload `build/web/` contents to any web hosting:
   - GitHub Pages (free)
   - Netlify (free)
   - Firebase Hosting (free tier)
   - Vercel (free)

---

## File Locations Summary

| File | Location |
|------|----------|
| Source Code | `nagales_mobprog_finals/lib/` |
| Web Build | `nagales_mobprog_finals/build/web/` |
| APK (after build) | `nagales_mobprog_finals/build/app/outputs/flutter-apk/app-release.apk` |
| Documentation | `nagales_mobprog_finals/DOCUMENTATION.md` |
| This Guide | `nagales_mobprog_finals/BUILD_GUIDE.md` |

---

## Troubleshooting

### "Android SDK not found"
- Ensure Android Studio completed its setup wizard
- Set ANDROID_HOME environment variable
- Restart your terminal/VS Code

### "Gradle build failed"
```powershell
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

### APK won't install - "App not installed"
- Enable "Install from Unknown Sources"
- Check if an older version needs to be uninstalled first
- Ensure enough storage space

---

## Quick Commands Reference

```powershell
# Build Android APK
flutter build apk --release

# Build Android App Bundle (for Play Store)
flutter build appbundle --release

# Build Web
flutter build web --release

# Build iOS (Mac only)
flutter build ios --release

# Run on connected device
flutter run --release

# List connected devices
flutter devices

# Check Flutter setup
flutter doctor -v
```

---

*Last Updated: February 13, 2026*
