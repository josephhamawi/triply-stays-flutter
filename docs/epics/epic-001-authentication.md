# Epic 001: Authentication System

## Overview
Implement the complete authentication flow for Triply Stays Flutter app, connecting to the existing Firebase Auth backend used by the web application.

## Dependencies
- Firebase Core (configured)
- Firebase Auth
- Existing Cloud Functions: `sendEmailVerification`, `verifyEmailCode`

## Stories

### Story 1.1: Project Authentication Infrastructure
**Priority:** P0 (Critical)
**Estimate:** Foundation setup

**Description:**
Set up the authentication data layer with Firebase Auth integration.

**Acceptance Criteria:**
- [ ] Create `AuthRepository` interface in domain layer
- [ ] Implement `FirebaseAuthRepository` in data layer
- [ ] Create `User` entity in domain layer
- [ ] Create `UserModel` in data layer with Firestore mapping
- [ ] Set up authentication state provider with Riverpod
- [ ] Handle auth state changes (signed in/out/loading)

**Technical Notes:**
- Use `firebase_auth` package
- Map Firebase User to domain User entity
- Store auth state in `StateNotifierProvider`

---

### Story 1.2: Email/Password Sign Up
**Priority:** P0 (Critical)

**Description:**
Implement user registration with email and password.

**Acceptance Criteria:**
- [ ] Create sign up screen UI matching brand design
- [ ] Email validation (format check)
- [ ] Password validation (min 8 chars, complexity)
- [ ] Password confirmation field
- [ ] Display name input
- [ ] Terms & conditions checkbox
- [ ] Error handling with user-friendly messages
- [ ] Loading state during registration
- [ ] Create user document in Firestore `users` collection
- [ ] Navigate to email verification on success

**UI Components:**
- `SignUpScreen`
- `AuthTextField` (reusable)
- `PasswordStrengthIndicator`

---

### Story 1.3: Email Verification
**Priority:** P0 (Critical)

**Description:**
Implement 6-digit code email verification using existing Cloud Functions.

**Acceptance Criteria:**
- [ ] Create email verification screen
- [ ] Call `sendEmailVerification` Cloud Function on screen load
- [ ] 6-digit code input with auto-focus between fields
- [ ] Resend code functionality with cooldown timer (60s)
- [ ] Call `verifyEmailCode` Cloud Function on submit
- [ ] Handle verification success/failure
- [ ] Update Firestore user document on success
- [ ] Navigate to main app on verified

**Technical Notes:**
- Use existing Cloud Functions (same as web app)
- Store verification state in Firestore

---

### Story 1.4: Email/Password Sign In
**Priority:** P0 (Critical)

**Description:**
Implement user login with email and password.

**Acceptance Criteria:**
- [ ] Create sign in screen UI
- [ ] Email input field
- [ ] Password input field with show/hide toggle
- [ ] "Remember me" checkbox (optional)
- [ ] "Forgot password?" link
- [ ] Error handling (invalid credentials, user not found, etc.)
- [ ] Loading state during authentication
- [ ] Check email verification status after sign in
- [ ] Navigate to appropriate screen based on verification status

---

### Story 1.5: Password Reset
**Priority:** P1 (High)

**Description:**
Allow users to reset their password via email.

**Acceptance Criteria:**
- [ ] Create forgot password screen
- [ ] Email input with validation
- [ ] Send password reset email via Firebase Auth
- [ ] Success confirmation screen
- [ ] Error handling
- [ ] Back to sign in navigation

---

### Story 1.6: Google Sign In
**Priority:** P1 (High)

**Description:**
Implement Google OAuth sign in for quick authentication.

**Acceptance Criteria:**
- [ ] Configure Google Sign In for iOS (GoogleService-Info.plist)
- [ ] Configure Google Sign In for Android (google-services.json)
- [ ] Google sign in button on sign in/up screens
- [ ] Handle first-time Google users (create Firestore document)
- [ ] Handle returning Google users
- [ ] Link Google account to existing email account if same email
- [ ] Error handling

**Technical Notes:**
- Use `google_sign_in` package
- iOS requires URL schemes configuration
- Android requires SHA-1 fingerprint in Firebase console

---

### Story 1.7: Apple Sign In (iOS)
**Priority:** P1 (High)

**Description:**
Implement Apple Sign In for iOS users (required for App Store).

**Acceptance Criteria:**
- [ ] Configure Apple Sign In capability in Xcode
- [ ] Apple sign in button (only shown on iOS)
- [ ] Handle first-time Apple users
- [ ] Handle returning Apple users
- [ ] Handle email hiding (relay email)
- [ ] Error handling

**Technical Notes:**
- Use `sign_in_with_apple` package
- Required for apps with third-party sign in on iOS

---

### Story 1.8: Auth State Navigation
**Priority:** P0 (Critical)

**Description:**
Implement navigation guards based on authentication state.

**Acceptance Criteria:**
- [ ] Create `AuthGuard` for GoRouter
- [ ] Redirect unauthenticated users to sign in
- [ ] Redirect unverified users to verification screen
- [ ] Redirect authenticated users away from auth screens
- [ ] Handle deep links with auth state
- [ ] Persist auth state across app restarts

**Technical Notes:**
- Use GoRouter redirect functionality
- Listen to Firebase Auth state stream

---

### Story 1.9: Sign Out
**Priority:** P0 (Critical)

**Description:**
Implement user sign out functionality.

**Acceptance Criteria:**
- [ ] Sign out option in profile/settings
- [ ] Confirmation dialog before sign out
- [ ] Clear local cached data on sign out
- [ ] Clear FCM token association
- [ ] Navigate to sign in screen
- [ ] Handle sign out errors gracefully

---

### Story 1.10: Session Management
**Priority:** P2 (Medium)

**Description:**
Handle session persistence and token refresh.

**Acceptance Criteria:**
- [ ] Persist auth session across app restarts
- [ ] Handle token refresh automatically
- [ ] Handle expired sessions gracefully
- [ ] Force sign out on security events
- [ ] Handle multiple device sessions

---

## Definition of Done
- [ ] All acceptance criteria met
- [ ] Unit tests for repository and use cases
- [ ] Widget tests for screens
- [ ] No lint warnings
- [ ] Code reviewed
- [ ] Tested on iOS simulator
- [ ] Tested on Android emulator
- [ ] Connected to existing Firebase backend

## Out of Scope
- Phone number authentication (future epic)
- Biometric authentication (future epic)
- Multi-factor authentication (future epic)

## File Structure
```
lib/
├── domain/
│   ├── entities/
│   │   └── user.dart
│   ├── repositories/
│   │   └── auth_repository.dart
│   └── usecases/
│       └── auth/
│           ├── sign_in_usecase.dart
│           ├── sign_up_usecase.dart
│           ├── sign_out_usecase.dart
│           ├── verify_email_usecase.dart
│           └── reset_password_usecase.dart
├── data/
│   ├── models/
│   │   └── user_model.dart
│   ├── repositories/
│   │   └── firebase_auth_repository.dart
│   └── datasources/
│       └── remote/
│           └── firebase_auth_datasource.dart
└── presentation/
    ├── providers/
    │   └── auth/
    │       ├── auth_provider.dart
    │       └── auth_state.dart
    ├── screens/
    │   └── auth/
    │       ├── sign_in_screen.dart
    │       ├── sign_up_screen.dart
    │       ├── email_verification_screen.dart
    │       └── forgot_password_screen.dart
    └── widgets/
        └── auth/
            ├── auth_text_field.dart
            ├── social_sign_in_button.dart
            └── verification_code_input.dart
```
