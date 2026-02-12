# Horn-In - APC Student Networking Platform
## Mobile Programming Finals Project Documentation

**Student:** Qelvin Nagales  
**Course:** Mobile Programming  
**Date:** February 13, 2026  
**Version:** 1.0.0

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Features](#features)
3. [Technology Stack](#technology-stack)
4. [Architecture](#architecture)
5. [Database Schema](#database-schema)
6. [Installation & Setup](#installation--setup)
7. [Screenshots](#screenshots)
8. [APK Installation Guide](#apk-installation-guide)

---

## Project Overview

**Horn-In** is a student networking platform designed for Asia Pacific College (APC) students. The app enables students to connect, network, and socialize with fellow students, create profiles, showcase projects, manage connections, and discover compatible groupmates based on skills and interests.

### Purpose
- Facilitate networking among APC students
- Enable skill-based matching for group projects
- Provide a platform for showcasing student portfolios
- Create a community for academic collaboration

### Target Users
- APC Students
- Faculty members (view-only)
- Student organizations

---

## Features

### 1. User Authentication
- Email/password registration and login
- Secure authentication via Supabase Auth
- Password recovery functionality
- Account deletion with security confirmation

### 2. Profile Management
- Customizable user profiles with avatar and cover photo
- Bio, course, and year level information
- Skills showcase (programming languages, frameworks, tools)
- Social links (LinkedIn, Facebook, GitHub)
- QR code generation for easy profile sharing

### 3. Project Portfolio
- Create and manage project portfolios
- Add project details: name, description, technologies used
- Upload project screenshots
- Mark projects as public or private
- View other students' projects

### 4. Social Networking
- Send and receive connection requests
- View and manage friends list
- Real-time notifications for requests and updates
- Activity feed showing latest activities

### 5. Messaging System
- Real-time chat with connections
- Group chat functionality
- Message status indicators
- Chat notifications

### 6. Explore & Discover
- Browse and search for other students
- Filter by skills, course, or interests
- Skill-based matching algorithm
- Suggested connections

### 7. Dark Mode Support
- Smooth animated theme transitions
- Consistent dark mode across all screens
- APC-branded color scheme (Navy & Gold)

---

## Technology Stack

### Frontend
| Technology | Purpose |
|------------|---------|
| Flutter 3.38.5 | Cross-platform mobile framework |
| Dart 3.10.4 | Programming language |
| Provider | State management |
| Material Design 3 | UI components |

### Backend
| Technology | Purpose |
|------------|---------|
| Supabase | Backend-as-a-Service |
| PostgreSQL | Database |
| Supabase Auth | Authentication |
| Row Level Security | Data protection |
| Real-time subscriptions | Live updates |

### Key Dependencies
```yaml
dependencies:
  supabase_flutter: ^2.3.0      # Backend services
  provider: ^6.1.1              # State management
  shared_preferences: ^2.2.2    # Local storage
  cached_network_image: ^3.3.1  # Image caching
  image_picker: ^1.0.7          # Photo selection
  image_cropper: ^8.0.2         # Photo editing
  connectivity_plus: ^6.0.3     # Network monitoring
  qr_flutter: ^4.1.0            # QR code generation
  mobile_scanner: ^5.1.1        # QR code scanning
  share_plus: ^9.0.0            # Social sharing
```

---

## Architecture

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── activity.dart
│   ├── comment.dart
│   ├── connection_request.dart
│   ├── friends.dart
│   ├── message.dart
│   ├── notification_model.dart
│   ├── post.dart
│   ├── profile.dart
│   ├── project_models.dart
│   ├── repository.dart
│   ├── skill.dart
│   └── user_settings.dart
├── screens/                  # Full-page UI screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── dashboard_screen.dart
│   ├── profile_screen.dart
│   ├── edit_profile_screen.dart
│   ├── settings_screen.dart
│   ├── explore_screen.dart
│   ├── friends_screen.dart
│   ├── messages_screen.dart
│   ├── chat_screen.dart
│   ├── notifications_screen.dart
│   ├── repositories_screen.dart
│   ├── project_detail_screen.dart
│   └── ...
├── services/                 # Business logic
│   ├── supabase_service.dart
│   ├── theme_service.dart
│   └── connectivity_service.dart
└── widgets/                  # Reusable components
    ├── activity_tile.dart
    ├── friend_tile.dart
    ├── notification_tile.dart
    ├── repository_card.dart
    ├── user_card.dart
    └── ...
```

### State Management
- **ChangeNotifier** for theme management
- **Provider** for connectivity monitoring
- **Supabase Realtime** for live data updates

---

## Database Schema

### Tables

#### profiles
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key (references auth.users) |
| email | TEXT | User email |
| full_name | TEXT | Display name |
| avatar_url | TEXT | Profile photo URL |
| cover_url | TEXT | Cover photo URL |
| bio | TEXT | User biography |
| course | TEXT | Academic course |
| year_level | INTEGER | Year of study |
| skills | JSONB | Array of skills |
| created_at | TIMESTAMP | Account creation date |
| updated_at | TIMESTAMP | Last update date |

#### connection_requests
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| sender_id | UUID | Requesting user |
| receiver_id | UUID | Target user |
| status | TEXT | pending/accepted/rejected |
| created_at | TIMESTAMP | Request date |

#### friends
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | First user |
| friend_id | UUID | Second user |
| created_at | TIMESTAMP | Friendship date |

#### messages
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| sender_id | UUID | Message sender |
| receiver_id | UUID | Message recipient |
| content | TEXT | Message content |
| is_read | BOOLEAN | Read status |
| created_at | TIMESTAMP | Send time |

#### projects
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Project owner |
| name | TEXT | Project name |
| description | TEXT | Project description |
| is_public | BOOLEAN | Visibility |
| technologies | JSONB | Tech stack array |
| screenshots | JSONB | Screenshot URLs |
| created_at | TIMESTAMP | Creation date |

---

## Installation & Setup

### Prerequisites
- Flutter SDK 3.38.5 or higher
- Dart SDK 3.10.4 or higher
- Android Studio (for Android builds)
- Xcode (for iOS builds, macOS only)

### Steps
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Supabase credentials in the app
4. Run `flutter run` to start the app

### Building APK
```bash
flutter build apk --release
```
The APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

### Building for iOS
```bash
flutter build ios --release
```
Requires macOS with Xcode installed.

---

## Screenshots

Include screenshots of the following screens:
1. **Splash Screen** - App launch with Horn-In branding
2. **Login Screen** - Email/password authentication
3. **Register Screen** - New user registration
4. **Home/Dashboard** - Main activity feed
5. **Profile Screen** - User profile with skills
6. **Explore Screen** - Discover other students
7. **Friends Screen** - Connections list
8. **Messages Screen** - Chat conversations
9. **Chat Screen** - Individual chat view
10. **Projects Screen** - Portfolio showcase
11. **Settings Screen** - App preferences (light/dark mode)
12. **QR Code Modal** - Profile sharing via QR

---

## APK Installation Guide

### For Android
1. Enable "Install from Unknown Sources" in Settings > Security
2. Transfer the APK file to your Android device
3. Tap the APK file to install
4. Open Horn-In from your app drawer

### For iOS (Without Mac)
iOS deployment requires:
- A Mac computer with Xcode
- Apple Developer account ($99/year for App Store)
- OR use TestFlight for beta distribution

**Alternative: Web Version**
The app can be accessed via web browser:
```bash
flutter run -d edge  # or chrome
```

---

## Security Features

- **Row Level Security (RLS):** All database tables protected
- **Secure Authentication:** Supabase Auth with encrypted passwords
- **Password Confirmation:** Required for account deletion
- **Real-time data validation:** Server-side validation

---

## Color Scheme

### Light Mode
- Primary Navy: #1A237E
- Primary Gold: #D4A51D
- Background: #F8F9FA
- Text Primary: #1F2937

### Dark Mode
- Background: #0D1421
- Surface: #1E1E2E
- Card: #2D2D3A
- Text Primary: #F3F4F6

---

## Future Enhancements
- Push notifications
- Video chat integration
- Event calendar
- Study group matching
- Grade tracking integration

---

## Contact
For questions or support regarding this project:
- **Developer:** Qelvin Nagales
- **Institution:** Asia Pacific College

---

*This documentation was prepared for Mobile Programming Finals submission.*
