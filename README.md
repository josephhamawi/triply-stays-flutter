# Triply Stays - Flutter Mobile App

Cross-platform mobile application for the Triply Stays vacation rental marketplace.

## Project Overview

This Flutter app connects to the **same Firebase backend** as the Triply Stays web application, providing a native mobile experience for iOS and Android users.

| Component | Repository |
|-----------|------------|
| Web App (React) | [MVP-vacation-rental](https://github.com/josephhamawi/MVP-vacation-rental) |
| Mobile App (Flutter) | This repository |
| Backend | Shared Firebase project: `mvp-vacation-rental` |

## Features

### Guest Features
- Browse vacation rental listings
- Search with filters (location, price, dates, property type)
- Interactive map view
- Like/save favorite listings
- Contact hosts via in-app messaging
- Book properties
- Leave reviews

### Host Features
- Create and manage property listings
- View booking requests
- Chat with guests
- Host dashboard with analytics
- Identity verification

## Tech Stack

- **Framework**: Flutter 3.16+
- **State Management**: Riverpod
- **Backend**: Firebase (Firestore, Auth, Storage, Functions, FCM)
- **Maps**: Google Maps Flutter
- **Navigation**: GoRouter

## Getting Started

### Prerequisites
- Flutter SDK 3.16.0 or higher
- Dart 3.0.0 or higher
- Xcode (for iOS development)
- Android Studio (for Android development)
- Firebase CLI

### Setup

1. Clone the repository:
```bash
git clone https://github.com/josephhamawi/triply-stays-flutter.git
cd triply-stays-flutter
```

2. Install dependencies:
```bash
flutter pub get
```

3. Firebase Configuration:
   - Download `GoogleService-Info.plist` from Firebase Console (iOS)
   - Download `google-services.json` from Firebase Console (Android)
   - Place files in appropriate directories

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart
├── config/
├── models/
├── services/
├── providers/
├── screens/
├── widgets/
└── utils/
```

## Firebase Project

**Project ID**: `mvp-vacation-rental`

This app uses the same Firebase project as the web application. No backend modifications are required.

## Documentation

- [PRD (Product Requirements Document)](../MVP-vacation-rental/docs/prd-triply-stays-flutter-app.md)
- [Architecture Document](./docs/architecture.md) *(To be created)*

## Related Repositories

- **Web App**: https://github.com/josephhamawi/MVP-vacation-rental
- **Mobile App**: This repository

---

*Built with Flutter*
