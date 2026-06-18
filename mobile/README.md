# 📱 Iqamah Mobile — Offline Salah & Qaza Tracker (Flutter)

Welcome to the mobile client for **Iqamah (إقامة)**. This is a local-first, offline-ready companion application built using Flutter. It is designed to run on Android (and other mobile systems) to track your daily prayers and manage Qaza debts securely in sandbox storage.

---

## 🎨 Rich Emerald Design & UI Features

The application leverages the **Islamic Emerald Black** aesthetic matching the web dashboard:
- **Reactive Dashboard**: Select dates on a calendar strip and log your five daily prayers. Attach parameters like `Jamaah` (congregation), `Traveling` (Qasr), `Jummah`, `Home`, `Tasbih`, and custom `Quran Notes`.
- **Excuse Engine**: Missed reasons differentiate between excused (menstruation, sleep, forgetfulness) and unexcused actions (laziness, distractions), calculating Qaza debt automatically.
- **Qaza Ledger**: View all outstanding make-up prayers and tap to discharge debts instantly.
- **7 & 30 Days Analytics**: Deep dive into your punctuality split, offered percentage ratio, and unexcused reason breakdown.
- **Local Sandbox Policy**: The database is stored completely locally. If you uninstall the application, all data is automatically deleted.

---

## 🏗️ Technical Architecture

- **State Management**: Built reactive workflows using the `Provider` architecture pattern.
- **Database**: Employs `sqflite` (SQLite) with strict database transactions to guarantee domain model invariants.
- **File Portability**: Features a custom JSON backup exporter and parser to import data on other devices.

---

## ⚙️ Development & Setup

### Prerequisites
- [Flutter SDK (stable channel)](https://docs.flutter.dev/get-started/install)
- [Java Development Kit (JDK 17)](https://adoptium.net/)
- Android SDK / Android Studio (for emulator or device execution)

### 1. Get Dependencies
Run this command from the `mobile` workspace directory:
```bash
flutter pub get
```

### 2. Run the App
Launch on an active emulator or connected device:
```bash
flutter run
```

### 3. Generate App Launcher Icons
If you make changes to the source app icon (`assets/icon/app_icon.png`), regenerate the mipmap directories for Android using:
```bash
dart run flutter_launcher_icons
```

---

## 🧪 Unit & Widget Testing

The project maintains critical domain validations in its test suite:
- **`test/prayer_domain_test.dart`**: Validates the Dart state transitions, checking that `requiresQaza` and excused reasons follow correct canonical Islamic rulings.
- **`test/widget_test.dart`**: Ensures basic widget integration smoke tests pass correctly.

Execute the test runner:
```bash
flutter test
```

---

## 📦 Building Releases & GitHub Actions

### Custom Build Commands
To compile release APK packages locally:
- **Universal Release APK**:
  ```bash
  flutter build apk
  ```
- **Split ABIs Release APKs** (for optimization per device architecture):
  ```bash
  flutter build apk --split-per-abi
  ```

### CI/CD Integration
On pushes and pull requests to `main`, the GitHub Actions workflow automatically:
1. Installs Flutter and JDK 17 environments.
2. Validates package configurations and executes tests.
3. Compiles both the universal fat APK and split-ABI packages.
4. Uploads them as the `iqamah-apks` zip artifact ready for distribution.
