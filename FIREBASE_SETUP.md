# Firebase Setup Guide - Complete Walkthrough

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"** (or "Add project")
3. Enter project name: `Student-Support-App`
4. Click **Continue**
5. Disable Google Analytics (optional for testing) → Click **Create project**
6. Wait for project creation → Click **Continue**

---

## Step 2: Add Android App to Firebase

1. On Firebase project dashboard, click **Android icon** (🤖)
2. Enter Android package name: `com.example.student_support_app`
   - Find this in `android/app/build.gradle.kts` → `applicationId`
3. Enter app nickname: `Student Support App` (optional)
4. Click **Register app**

### Download Config File
5. Download `google-services.json`
6. Move it to: `android/app/google-services.json`

```
Student_Support_App/
└── android/
    └── app/
        └── google-services.json  ← Place here
```

7. Click **Next** → **Next** → **Continue to console**

---

## Step 3: Configure Android Build Files

### 3.1 Update `android/build.gradle.kts`

Add Google services classpath:

```kotlin
plugins {
    // ... existing plugins
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

### 3.2 Update `android/app/build.gradle.kts`

Add plugin and dependencies:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← Add this
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    
    // Firebase products (add what you need)
    implementation("com.google.firebase:firebase-analytics")
}
```

---

## Step 4: Add Flutter Firebase Packages

Run in terminal:

```powershell
cd c:\Users\70155\StudioProjects\Student_Support_App
flutter pub add firebase_core
flutter pub add firebase_auth
flutter pub add cloud_firestore
```

This adds to `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^3.x.x
  firebase_auth: ^5.x.x
  cloud_firestore: ^5.x.x
```

---

## Step 5: Initialize Firebase in App

Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const StudentSupportApp());
}

class StudentSupportApp extends StatelessWidget {
  const StudentSupportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Support',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
```

---

## Step 6: Setup Realtime Database

1. In Firebase Console → **Build** → **Realtime Database**
2. Click **Create Database**
3. Choose location (e.g., `us-central1`)
4. Select **Start in test mode** → Click **Enable**

### Import Test Data
5. Click **⋮** (three dots) → **Import JSON**
6. Select `firebase_test_data.json` from your project
7. Click **Import**

---

## Step 7: Setup Firestore (Alternative)

1. In Firebase Console → **Build** → **Firestore Database**
2. Click **Create database**
3. Select **Start in test mode** → Click **Next**
4. Choose location → Click **Enable**

---

## Step 8: Enable Authentication

1. In Firebase Console → **Build** → **Authentication**
2. Click **Get started**
3. Under **Sign-in method** tab, enable:
   - **Email/Password** → Toggle ON → Save
4. Under **Users** tab, click **Add user**:
   - Email: `john.doe@university.edu`
   - Password: `password123`

---

## Test Credentials

| AUID | Password | Name | Semester |
|------|----------|------|----------|
| `123456789` | `password123` | John Doe | 5 |
| `987654321` | `password456` | Jane Smith | 3 |
| `456789123` | `test1234` | Alex Kumar | 7 |

---

## Security Rules (Test Mode Only)

### Realtime Database Rules

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

### Firestore Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

> ⚠️ **WARNING**: These rules allow anyone to read/write. Use proper auth rules in production!

---

## Verify Setup

Run the app:

```powershell
flutter run
```

If you see **no errors** in the console, Firebase is connected! ✅

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `google-services.json` not found | Ensure file is in `android/app/` |
| Build fails with Gradle error | Run `flutter clean` then `flutter pub get` |
| Firebase initialization failed | Check internet connection and config file |
| "No Firebase app" error | Ensure `Firebase.initializeApp()` is called before `runApp()` |
