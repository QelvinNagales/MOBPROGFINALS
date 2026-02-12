# Horn-In 🎺

<p align="center">
  <img src="assets/images/Horn-In mobile app logo.png" alt="Horn-In Logo" width="200"/>
</p>

<p align="center">
  <strong>A Student Networking Platform for Asia Pacific College</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.38.5-02569B?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.10.4-0175C2?logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase" alt="Supabase"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey" alt="Platforms"/>
</p>

---

## 📱 About

**Horn-In** is a student networking platform designed to help APC students connect, collaborate, and build professional relationships. Create your profile, showcase projects, find groupmates with matching skills, and communicate seamlessly.

### Key Features

| Feature | Description |
|---------|-------------|
| 👤 **Profile Management** | Customizable profiles with avatar, cover photo, bio, and skills |
| 💼 **Project Portfolio** | Showcase your projects with descriptions and technologies |
| 🤝 **Network & Connect** | Send connection requests, manage friends, discover students |
| 💬 **Real-time Messaging** | Chat with connections individually or in groups |
| 🔍 **Skill-based Discovery** | Find students with complementary skills for projects |
| 📱 **QR Code Sharing** | Share your profile instantly via QR code |
| 🌙 **Dark Mode** | Beautiful APC-branded dark theme |

---

## 🛠️ Tech Stack

- **Frontend:** Flutter & Dart
- **Backend:** Supabase (PostgreSQL + Auth + Realtime)
- **State Management:** Provider
- **Authentication:** Supabase Auth with Row Level Security

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.38.5+
- Dart SDK 3.10.4+
- Android Studio / VS Code
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/QelvinNagales/MOBPROGFINALS.git

# Navigate to project directory
cd MOBPROGFINALS/nagales_mobprog_finals

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Run on Web

```bash
flutter run -d edge    # Microsoft Edge
flutter run -d chrome  # Google Chrome
```

---

## 📁 Project Structure

```
lib/
├── main.dart              # App entry point
├── models/                # Data models (Profile, Message, etc.)
├── screens/               # UI screens
│   ├── auth/              # Login, Register
│   ├── home_screen.dart   # Main dashboard
│   ├── profile_screen.dart
│   ├── friends_screen.dart
│   ├── messages_screen.dart
│   └── ...
├── services/              # Business logic
│   ├── supabase_service.dart
│   ├── theme_service.dart
│   └── connectivity_service.dart
└── widgets/               # Reusable UI components
```

---

## 🎨 Color Palette

| Mode | Primary | Accent | Background |
|------|---------|--------|------------|
| Light | `#1A237E` Navy | `#D4A51D` Gold | `#F8F9FA` |
| Dark | `#1A237E` Navy | `#D4A51D` Gold | `#0D1421` |

---

## 📋 Database Schema

The app uses Supabase with the following core tables:

- `profiles` - User information and skills
- `connection_requests` - Friend request management
- `friends` - Accepted connections
- `messages` - Chat messages
- `projects` - User portfolios
- `notifications` - Activity alerts

See [supabase_schema.sql](supabase_schema.sql) for the complete schema.

---

## 📄 Documentation

For detailed documentation including architecture, API reference, and screenshots, see [DOCUMENTATION.md](DOCUMENTATION.md).

---

## 👨‍💻 Author

**Qelvin Nagales**  
Mobile Programming Finals Project  
Asia Pacific College | February 2026

---

## 📝 License

This project was created for educational purposes as part of the Mobile Programming course at Asia Pacific College.

---

<p align="center">
  Made with ❤️ and Flutter
</p>
