# Architecture Document
# Triply Stays Flutter Mobile Application

**Version:** 1.0
**Date:** November 26, 2025
**Author:** Winston (Architect)
**Status:** Ready for Development
**Type:** Brownfield Architecture (New Client, Existing Backend)

---

## 1. Architecture Overview

### 1.1 Architecture Pattern: Clean Architecture + Riverpod

We adopt **Clean Architecture** principles with **Riverpod** for state management, ensuring:
- Separation of concerns
- Testability
- Scalability
- Independence from Firebase implementation details

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Screens   │  │   Widgets   │  │  Providers  │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                     DOMAIN LAYER                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Entities  │  │  Use Cases  │  │ Repositories│         │
│  │  (Models)   │  │             │  │ (Abstract)  │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                      DATA LAYER                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Firebase  │  │    Local    │  │ Repository  │         │
│  │   Services  │  │   Storage   │  │   Impls     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
              ┌─────────────────────────┐
              │   FIREBASE BACKEND      │
              │   (Shared with Web)     │
              │  • Firestore            │
              │  • Auth                 │
              │  • Storage              │
              │  • Functions            │
              │  • FCM                  │
              └─────────────────────────┘
```

### 1.2 Key Architectural Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Architecture | Clean Architecture | Separation of concerns, testability |
| State Management | Riverpod 2.0 | Type-safe, testable, great DevTools |
| Navigation | GoRouter | Declarative, deep linking support |
| Local Storage | Hive + Secure Storage | Fast, encrypted for sensitive data |
| DI | Riverpod (built-in) | No additional package needed |
| Error Handling | Result Pattern | Explicit error handling |

---

## 2. Detailed Folder Structure

```
triply-stays-flutter/
├── android/                          # Android platform code
│   ├── app/
│   │   ├── src/main/
│   │   │   └── AndroidManifest.xml
│   │   ├── build.gradle
│   │   └── google-services.json      # Firebase config (gitignored)
│   └── build.gradle
│
├── ios/                              # iOS platform code
│   ├── Runner/
│   │   ├── Info.plist
│   │   ├── GoogleService-Info.plist  # Firebase config (gitignored)
│   │   └── AppDelegate.swift
│   └── Podfile
│
├── lib/
│   ├── main.dart                     # App entry point
│   │
│   ├── core/                         # Core utilities & constants
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   ├── firebase_constants.dart
│   │   │   └── ui_constants.dart
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── network/
│   │   │   └── network_info.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── app_colors.dart
│   │   │   └── app_text_styles.dart
│   │   └── utils/
│   │       ├── date_utils.dart
│   │       ├── validators.dart
│   │       └── extensions.dart
│   │
│   ├── config/                       # App configuration
│   │   ├── firebase_config.dart
│   │   ├── app_config.dart
│   │   └── environment.dart
│   │
│   ├── data/                         # Data Layer
│   │   ├── datasources/              # Remote & Local data sources
│   │   │   ├── remote/
│   │   │   │   ├── firebase_auth_datasource.dart
│   │   │   │   ├── firestore_datasource.dart
│   │   │   │   ├── firebase_storage_datasource.dart
│   │   │   │   ├── firebase_functions_datasource.dart
│   │   │   │   └── firebase_messaging_datasource.dart
│   │   │   └── local/
│   │   │       ├── hive_datasource.dart
│   │   │       └── secure_storage_datasource.dart
│   │   │
│   │   ├── models/                   # Data Transfer Objects (DTOs)
│   │   │   ├── user_model.dart
│   │   │   ├── listing_model.dart
│   │   │   ├── booking_model.dart
│   │   │   ├── chat_model.dart
│   │   │   ├── message_model.dart
│   │   │   ├── review_model.dart
│   │   │   └── notification_model.dart
│   │   │
│   │   └── repositories/             # Repository implementations
│   │       ├── auth_repository_impl.dart
│   │       ├── user_repository_impl.dart
│   │       ├── listing_repository_impl.dart
│   │       ├── booking_repository_impl.dart
│   │       ├── chat_repository_impl.dart
│   │       └── notification_repository_impl.dart
│   │
│   ├── domain/                       # Domain Layer
│   │   ├── entities/                 # Business entities
│   │   │   ├── user.dart
│   │   │   ├── listing.dart
│   │   │   ├── booking.dart
│   │   │   ├── chat.dart
│   │   │   ├── message.dart
│   │   │   ├── review.dart
│   │   │   └── notification.dart
│   │   │
│   │   ├── repositories/             # Abstract repository interfaces
│   │   │   ├── auth_repository.dart
│   │   │   ├── user_repository.dart
│   │   │   ├── listing_repository.dart
│   │   │   ├── booking_repository.dart
│   │   │   ├── chat_repository.dart
│   │   │   └── notification_repository.dart
│   │   │
│   │   └── usecases/                 # Business logic use cases
│   │       ├── auth/
│   │       │   ├── sign_in_usecase.dart
│   │       │   ├── sign_up_usecase.dart
│   │       │   ├── sign_out_usecase.dart
│   │       │   └── verify_email_usecase.dart
│   │       ├── listings/
│   │       │   ├── get_listings_usecase.dart
│   │       │   ├── get_listing_detail_usecase.dart
│   │       │   ├── create_listing_usecase.dart
│   │       │   └── toggle_like_usecase.dart
│   │       ├── bookings/
│   │       │   ├── create_booking_usecase.dart
│   │       │   └── get_bookings_usecase.dart
│   │       └── messaging/
│   │           ├── get_chats_usecase.dart
│   │           └── send_message_usecase.dart
│   │
│   ├── presentation/                 # Presentation Layer
│   │   ├── providers/                # Riverpod providers
│   │   │   ├── auth/
│   │   │   │   ├── auth_provider.dart
│   │   │   │   └── auth_state.dart
│   │   │   ├── listings/
│   │   │   │   ├── listings_provider.dart
│   │   │   │   └── listing_detail_provider.dart
│   │   │   ├── bookings/
│   │   │   │   └── bookings_provider.dart
│   │   │   ├── chat/
│   │   │   │   ├── chats_provider.dart
│   │   │   │   └── messages_provider.dart
│   │   │   ├── user/
│   │   │   │   └── user_provider.dart
│   │   │   └── core/
│   │   │       ├── firebase_providers.dart
│   │   │       └── repository_providers.dart
│   │   │
│   │   ├── screens/                  # App screens
│   │   │   ├── splash/
│   │   │   │   └── splash_screen.dart
│   │   │   ├── onboarding/
│   │   │   │   └── onboarding_screen.dart
│   │   │   ├── auth/
│   │   │   │   ├── sign_in_screen.dart
│   │   │   │   ├── sign_up_screen.dart
│   │   │   │   ├── forgot_password_screen.dart
│   │   │   │   └── email_verification_screen.dart
│   │   │   ├── home/
│   │   │   │   └── home_screen.dart
│   │   │   ├── search/
│   │   │   │   ├── search_screen.dart
│   │   │   │   └── filter_screen.dart
│   │   │   ├── map/
│   │   │   │   └── map_screen.dart
│   │   │   ├── listings/
│   │   │   │   ├── listing_detail_screen.dart
│   │   │   │   └── listings_grid_screen.dart
│   │   │   ├── booking/
│   │   │   │   ├── booking_screen.dart
│   │   │   │   ├── booking_confirmation_screen.dart
│   │   │   │   └── booking_history_screen.dart
│   │   │   ├── messages/
│   │   │   │   ├── chats_list_screen.dart
│   │   │   │   └── chat_detail_screen.dart
│   │   │   ├── profile/
│   │   │   │   ├── profile_screen.dart
│   │   │   │   ├── edit_profile_screen.dart
│   │   │   │   └── verifications_screen.dart
│   │   │   ├── host/
│   │   │   │   ├── become_host_screen.dart
│   │   │   │   ├── create_listing_screen.dart
│   │   │   │   ├── edit_listing_screen.dart
│   │   │   │   ├── my_listings_screen.dart
│   │   │   │   └── host_dashboard_screen.dart
│   │   │   └── settings/
│   │   │       └── settings_screen.dart
│   │   │
│   │   ├── widgets/                  # Reusable UI components
│   │   │   ├── common/
│   │   │   │   ├── app_button.dart
│   │   │   │   ├── app_text_field.dart
│   │   │   │   ├── loading_indicator.dart
│   │   │   │   ├── error_widget.dart
│   │   │   │   └── empty_state.dart
│   │   │   ├── listing/
│   │   │   │   ├── listing_card.dart
│   │   │   │   ├── listing_grid.dart
│   │   │   │   ├── image_gallery.dart
│   │   │   │   └── amenity_chip.dart
│   │   │   ├── booking/
│   │   │   │   ├── date_picker.dart
│   │   │   │   └── guest_counter.dart
│   │   │   ├── chat/
│   │   │   │   ├── chat_bubble.dart
│   │   │   │   └── chat_input.dart
│   │   │   └── profile/
│   │   │       ├── avatar.dart
│   │   │       └── verification_badge.dart
│   │   │
│   │   └── navigation/
│   │       ├── app_router.dart       # GoRouter configuration
│   │       ├── routes.dart           # Route names
│   │       └── guards/
│   │           └── auth_guard.dart
│   │
│   └── l10n/                         # Localization (if needed)
│       ├── app_en.arb
│       └── app_ar.arb
│
├── assets/
│   ├── images/
│   │   ├── logo.png
│   │   ├── onboarding/
│   │   └── icons/
│   ├── fonts/
│   └── animations/                   # Lottie files
│
├── test/
│   ├── unit/
│   │   ├── domain/
│   │   └── data/
│   ├── widget/
│   │   └── screens/
│   └── integration/
│
├── integration_test/
│   └── app_test.dart
│
├── pubspec.yaml
├── analysis_options.yaml
├── firebase.json
└── README.md
```

---

## 3. State Management with Riverpod

### 3.1 Provider Architecture

```dart
// lib/presentation/providers/core/firebase_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firebase instances (singleton providers)
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// Auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});
```

### 3.2 Repository Providers

```dart
// lib/presentation/providers/core/repository_providers.dart

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    functionsDataSource: ref.watch(firebaseFunctionsDataSourceProvider),
  );
});

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepositoryImpl(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
    localDataSource: ref.watch(hiveDataSourceProvider),
  );
});
```

### 3.3 Feature Providers Example

```dart
// lib/presentation/providers/listings/listings_provider.dart

// Listings list with real-time updates
final listingsProvider = StreamProvider.family<List<Listing>, ListingFilter>(
  (ref, filter) {
    final repository = ref.watch(listingRepositoryProvider);
    return repository.watchListings(filter);
  },
);

// Single listing detail
final listingDetailProvider = FutureProvider.family<Listing, String>(
  (ref, listingId) async {
    final repository = ref.watch(listingRepositoryProvider);
    return repository.getListingById(listingId);
  },
);

// Liked listings (user-specific)
final likedListingsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  final repository = ref.watch(userRepositoryProvider);
  return repository.watchLikedListings(user.uid);
});
```

### 3.4 State Classes

```dart
// lib/presentation/providers/auth/auth_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(User user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;
}
```

---

## 4. Data Models

### 4.1 Entity (Domain Layer)

```dart
// lib/domain/entities/listing.dart

class Listing {
  final String id;
  final String title;
  final String description;
  final double price;
  final String city;
  final String address;
  final List<String> images;
  final String hostId;
  final String hostName;
  final String? hostPhotoURL;
  final List<String> amenities;
  final String propertyType;
  final int bedrooms;
  final int bathrooms;
  final int maxGuests;
  final double? latitude;
  final double? longitude;
  final String status;
  final DateTime createdAt;
  final int likesCount;
  final double? averageRating;
  final int reviewCount;

  const Listing({
    required this.id,
    required this.title,
    // ... all fields
  });
}
```

### 4.2 Model (Data Layer - Firestore DTO)

```dart
// lib/data/models/listing_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/listing.dart';

class ListingModel extends Listing {
  const ListingModel({
    required super.id,
    required super.title,
    // ... all fields
  });

  // From Firestore document
  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListingModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      city: data['city'] ?? '',
      address: data['address'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      hostId: data['hostId'] ?? '',
      hostName: data['hostName'] ?? '',
      hostPhotoURL: data['hostPhotoURL'],
      amenities: List<String>.from(data['amenities'] ?? []),
      propertyType: data['propertyType'] ?? '',
      bedrooms: data['bedrooms'] ?? 0,
      bathrooms: data['bathrooms'] ?? 0,
      maxGuests: data['maxGuests'] ?? 1,
      latitude: data['coordinates']?['lat']?.toDouble(),
      longitude: data['coordinates']?['lng']?.toDouble(),
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: data['likesCount'] ?? 0,
      averageRating: data['averageRating']?.toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  // To Firestore map (for creating/updating)
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'city': city,
      'address': address,
      'images': images,
      'hostId': hostId,
      'hostName': hostName,
      'hostPhotoURL': hostPhotoURL,
      'amenities': amenities,
      'propertyType': propertyType,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'maxGuests': maxGuests,
      'coordinates': latitude != null && longitude != null
          ? {'lat': latitude, 'lng': longitude}
          : null,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
```

---

## 5. Firebase Integration Layer

### 5.1 Firestore Data Source

```dart
// lib/data/datasources/remote/firestore_datasource.dart

class FirestoreDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDataSource(this._firestore);

  // Collections
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get listings => _firestore.collection('listings');
  CollectionReference get bookings => _firestore.collection('bookings');
  CollectionReference get chats => _firestore.collection('chats');
  CollectionReference get reviews => _firestore.collection('reviews');
  CollectionReference get notifications => _firestore.collection('notifications');

  // Stream of listings with filters
  Stream<List<ListingModel>> watchListings(ListingFilter filter) {
    Query query = listings.where('status', isEqualTo: 'active');

    if (filter.city != null) {
      query = query.where('city', isEqualTo: filter.city);
    }
    if (filter.propertyType != null) {
      query = query.where('propertyType', isEqualTo: filter.propertyType);
    }
    if (filter.maxPrice != null) {
      query = query.where('price', isLessThanOrEqualTo: filter.maxPrice);
    }

    query = query.orderBy('createdAt', descending: true).limit(50);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList();
    });
  }

  // Real-time chat messages
  Stream<List<MessageModel>> watchMessages(String chatId) {
    return chats
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
        });
  }
}
```

### 5.2 Firebase Functions Integration

```dart
// lib/data/datasources/remote/firebase_functions_datasource.dart

import 'package:cloud_functions/cloud_functions.dart';

class FirebaseFunctionsDataSource {
  final FirebaseFunctions _functions;

  FirebaseFunctionsDataSource(this._functions);

  // Send email verification code
  Future<void> sendEmailVerificationCode(String email, String code) async {
    final callable = _functions.httpsCallable('sendEmailVerification');
    await callable.call({'email': email, 'code': code});
  }

  // Verify email code
  Future<bool> verifyEmailCode(String email, String code) async {
    final callable = _functions.httpsCallable('verifyEmailCode');
    final result = await callable.call({'email': email, 'code': code});
    return result.data['success'] == true;
  }

  // Send WhatsApp verification
  Future<void> sendWhatsAppVerification(String phoneNumber, String code) async {
    final callable = _functions.httpsCallable('sendTwilioWhatsAppVerification');
    await callable.call({'phoneNumber': phoneNumber, 'code': code});
  }
}
```

### 5.3 Push Notifications Service

```dart
// lib/data/datasources/remote/firebase_messaging_datasource.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseMessagingDataSource {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  FirebaseMessagingDataSource(this._messaging, this._firestore);

  // Initialize FCM and request permissions
  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveToken);
    }
  }

  // Save FCM token to user document
  Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    }
  }

  // Remove token on logout
  Future<void> removeToken() async {
    final token = await _messaging.getToken();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    }
  }

  // Handle foreground messages
  void setupForegroundHandler(Function(RemoteMessage) onMessage) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }
}
```

---

## 6. Navigation with GoRouter

### 6.1 Router Configuration

```dart
// lib/presentation/navigation/app_router.dart

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authState),
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) {
        return '/auth/sign-in';
      }
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/auth',
        builder: (context, state) => const SignInScreen(),
        routes: [
          GoRoute(
            path: 'sign-in',
            builder: (context, state) => const SignInScreen(),
          ),
          GoRoute(
            path: 'sign-up',
            builder: (context, state) => const SignUpScreen(),
          ),
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: 'verify-email',
            builder: (context, state) => const EmailVerificationScreen(),
          ),
        ],
      ),

      // Main app (with bottom navigation)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const ChatsListScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Listing detail (full screen)
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) => ListingDetailScreen(
          listingId: state.pathParameters['id']!,
        ),
      ),

      // Chat detail
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) => ChatDetailScreen(
          chatId: state.pathParameters['chatId']!,
        ),
      ),

      // Booking flow
      GoRoute(
        path: '/booking/:listingId',
        builder: (context, state) => BookingScreen(
          listingId: state.pathParameters['listingId']!,
        ),
      ),

      // Host routes
      GoRoute(
        path: '/host',
        routes: [
          GoRoute(
            path: 'dashboard',
            builder: (context, state) => const HostDashboardScreen(),
          ),
          GoRoute(
            path: 'create-listing',
            builder: (context, state) => const CreateListingScreen(),
          ),
          GoRoute(
            path: 'edit-listing/:id',
            builder: (context, state) => EditListingScreen(
              listingId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  );
});
```

---

## 7. Error Handling Strategy

### 7.1 Result Pattern

```dart
// lib/core/errors/result.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

@freezed
class Result<T> with _$Result<T> {
  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = FailureResult<T>;
}

// Usage in repository
Future<Result<User>> signIn(String email, String password) async {
  try {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return Result.success(credential.user!);
  } on FirebaseAuthException catch (e) {
    return Result.failure(AuthFailure(e.message ?? 'Sign in failed'));
  } catch (e) {
    return Result.failure(UnexpectedFailure(e.toString()));
  }
}
```

### 7.2 Failure Types

```dart
// lib/core/errors/failures.dart

abstract class Failure {
  final String message;
  const Failure(this.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
```

---

## 8. Caching Strategy

### 8.1 Hive Local Storage

```dart
// lib/data/datasources/local/hive_datasource.dart

import 'package:hive_flutter/hive_flutter.dart';

class HiveDataSource {
  static const String listingsBox = 'listings_cache';
  static const String userBox = 'user_cache';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(listingsBox);
    await Hive.openBox<Map>(userBox);
  }

  // Cache listings
  Future<void> cacheListings(List<ListingModel> listings) async {
    final box = Hive.box<Map>(listingsBox);
    await box.clear();
    for (final listing in listings) {
      await box.put(listing.id, listing.toJson());
    }
  }

  // Get cached listings
  List<ListingModel> getCachedListings() {
    final box = Hive.box<Map>(listingsBox);
    return box.values
        .map((json) => ListingModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  // Cache expiry check
  bool isCacheValid(String key, Duration maxAge) {
    final box = Hive.box<Map>(userBox);
    final timestamp = box.get('${key}_timestamp');
    if (timestamp == null) return false;

    final cachedAt = DateTime.parse(timestamp['value']);
    return DateTime.now().difference(cachedAt) < maxAge;
  }
}
```

### 8.2 Secure Storage for Sensitive Data

```dart
// lib/data/datasources/local/secure_storage_datasource.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageDataSource {
  final FlutterSecureStorage _storage;

  SecureStorageDataSource() : _storage = const FlutterSecureStorage();

  // Store auth token (if needed for any custom auth)
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: 'auth_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // Clear all secure data on logout
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

---

## 9. App Entry Point

```dart
// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'config/firebase_config.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local/hive_datasource.dart';
import 'presentation/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  await Hive.initFlutter();
  await HiveDataSource().init();

  runApp(
    const ProviderScope(
      child: TriplyStaysApp(),
    ),
  );
}

class TriplyStaysApp extends ConsumerWidget {
  const TriplyStaysApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Triply Stays',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

---

## 10. Testing Strategy

### 10.1 Test Structure

```
test/
├── unit/
│   ├── domain/
│   │   └── usecases/
│   │       ├── sign_in_usecase_test.dart
│   │       └── get_listings_usecase_test.dart
│   └── data/
│       └── repositories/
│           ├── auth_repository_test.dart
│           └── listing_repository_test.dart
├── widget/
│   └── screens/
│       ├── home_screen_test.dart
│       └── listing_detail_screen_test.dart
├── mocks/
│   ├── mock_auth_repository.dart
│   └── mock_firestore.dart
└── fixtures/
    └── listing_fixtures.dart
```

### 10.2 Mock Example

```dart
// test/mocks/mock_auth_repository.dart

import 'package:mockito/mockito.dart';
import 'package:triply_stays/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

// Usage in test
void main() {
  late MockAuthRepository mockAuthRepository;
  late SignInUseCase signInUseCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    signInUseCase = SignInUseCase(mockAuthRepository);
  });

  test('should return user when sign in is successful', () async {
    // Arrange
    when(mockAuthRepository.signIn(any, any))
        .thenAnswer((_) async => Result.success(testUser));

    // Act
    final result = await signInUseCase('test@example.com', 'password');

    // Assert
    expect(result, isA<Success<User>>());
  });
}
```

---

## 11. CI/CD Pipeline

### 11.1 GitHub Actions Workflow

```yaml
# .github/workflows/flutter.yml

name: Flutter CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2

      - name: Build APK
        run: flutter build apk --release

      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: app-release.apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2

      - name: Build iOS
        run: flutter build ios --release --no-codesign
```

---

## 12. Firebase Configuration Checklist

### 12.1 Setup Steps

- [ ] **Firebase Console**: Add iOS app
  - Bundle ID: `com.triplystays.app`
  - Download `GoogleService-Info.plist`
  - Place in `ios/Runner/`

- [ ] **Firebase Console**: Add Android app
  - Package name: `com.triplystays.app`
  - SHA-1 fingerprint (for Google Sign-In)
  - Download `google-services.json`
  - Place in `android/app/`

- [ ] **Enable FCM**:
  - iOS: Upload APNs key
  - Android: Enabled by default

- [ ] **Configure FlutterFire CLI**:
  ```bash
  dart pub global activate flutterfire_cli
  flutterfire configure --project=mvp-vacation-rental
  ```

---

## 13. Security Considerations

### 13.1 Security Checklist

- [ ] All API keys in environment variables (not hardcoded)
- [ ] `GoogleService-Info.plist` and `google-services.json` in `.gitignore`
- [ ] Sensitive data stored in `flutter_secure_storage`
- [ ] Firebase security rules enforced (already configured for web)
- [ ] Certificate pinning for production builds
- [ ] ProGuard/R8 enabled for Android release builds
- [ ] Biometric authentication for sensitive actions

---

## 14. Next Steps

1. **Initialize Flutter Project**:
   ```bash
   cd /Users/mac/Development/triply-stays-flutter
   flutter create . --org com.triplystays --project-name triply_stays
   ```

2. **Configure Firebase**:
   - Add apps in Firebase Console
   - Run `flutterfire configure`

3. **Install Dependencies**:
   - Copy `pubspec.yaml` dependencies from PRD
   - Run `flutter pub get`

4. **Create Initial Structure**:
   - Set up folder structure as defined
   - Create base classes and providers

5. **Begin Development**:
   - Start with Auth module (Sprint 1)
   - Follow feature priority from PRD

---

*Document prepared by: Winston (Architect)*
*Ready for: Development Team*
