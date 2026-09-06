# Frontend Setup (Flutter + Drift)

This is the frontend for the Billing Software project.

## Prerequisites
- Flutter SDK (>=3.2.0 <4.0.0)
- Dart SDK

## Getting Started

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Generate Code (Drift / Riverpod)**
   This project uses `drift` for local SQLite database and requires code generation.
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
   *Note: Run this anytime you change your Drift database tables or Riverpod providers.*

3. **Running the App**
   ```bash
   flutter run
   ```

## Checking Drift Database
To analyze your Drift database for issues without building:
```bash
flutter pub run drift_dev analyze
```
flutter run -d chrome