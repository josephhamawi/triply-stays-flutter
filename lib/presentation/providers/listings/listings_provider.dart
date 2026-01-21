import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/firebase_listing_repository.dart';
import '../../../domain/entities/listing.dart';
import '../../../domain/repositories/listing_repository.dart';
import '../../../main.dart' show firebaseInitialized;
import '../auth/auth_provider.dart';

/// Provider for the listing repository
final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  if (!firebaseInitialized) {
    return _NoOpListingRepository();
  }
  return FirebaseListingRepository(firestore: FirebaseFirestore.instance);
});

/// No-op listing repository for when Firebase isn't available
class _NoOpListingRepository implements ListingRepository {
  @override
  Stream<List<Listing>> watchListings({ListingFilter? filter}) => Stream.value([]);

  @override
  Future<Listing?> getListingById(String id) async => null;

  @override
  Stream<List<Listing>> watchHostListings(String userId) => Stream.value([]);

  @override
  Future<void> toggleLike({
    required String listingId,
    required String userId,
    required bool isLiked,
  }) async {}

  @override
  Future<List<Listing>> getLikedListings(List<String> ids) async => [];

  @override
  Future<List<String>> getCategories() async => [];

  @override
  Future<List<String>> getViews() async => [];

  @override
  Future<List<String>> getAmenities() async => [];

  @override
  Future<List<String>> getCitiesForCountry(String countryCode) async => [];

  @override
  Future<String> createListing(Listing listing) async => '';

  @override
  Future<void> updateListing(Listing listing) async {}

  @override
  Future<void> incrementViews(String listingId) async {}
}

/// Provider for listing filters
final listingFilterProvider = StateProvider<ListingFilter>((ref) {
  return const ListingFilter(); // Load all listings by default
});

/// Provider for listings stream with current filter
final listingsProvider = StreamProvider<List<Listing>>((ref) {
  final repository = ref.watch(listingRepositoryProvider);
  final filter = ref.watch(listingFilterProvider);
  return repository.watchListings(filter: filter);
});

/// Provider for a single listing by ID
final listingDetailProvider =
    FutureProvider.family<Listing?, String>((ref, listingId) async {
  final repository = ref.watch(listingRepositoryProvider);
  return repository.getListingById(listingId);
});

/// Provider for categories
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(listingRepositoryProvider);
  return repository.getCategories();
});

/// Provider for views (mountain, sea, etc.)
final viewsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(listingRepositoryProvider);
  return repository.getViews();
});

/// Provider for amenities
final amenitiesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(listingRepositoryProvider);
  return repository.getAmenities();
});

/// Provider for cities in a country
final citiesProvider =
    FutureProvider.family<List<String>, String>((ref, countryCode) async {
  final repository = ref.watch(listingRepositoryProvider);
  return repository.getCitiesForCountry(countryCode);
});

/// Provider for user's liked listing IDs
final likedListingIdsProvider = StreamProvider<List<String>>((ref) {
  // Check if Firebase is available
  if (!firebaseInitialized) {
    return Stream.value([]);
  }

  final authState = ref.watch(authNotifierProvider);
  if (authState.user == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(authState.user!.id)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return <String>[];
    final data = doc.data() as Map<String, dynamic>;
    return List<String>.from(data['likedListings'] ?? []);
  });
});

/// Provider for user's liked listings
final likedListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final likedIdsAsync = ref.watch(likedListingIdsProvider);
  final repository = ref.watch(listingRepositoryProvider);

  return likedIdsAsync.when(
    data: (ids) => repository.getLikedListings(ids),
    loading: () => <Listing>[],
    error: (_, __) => <Listing>[],
  );
});

/// Provider to check if a listing is liked
final isListingLikedProvider = Provider.family<bool, String>((ref, listingId) {
  final likedIdsAsync = ref.watch(likedListingIdsProvider);
  return likedIdsAsync.when(
    data: (ids) => ids.contains(listingId),
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for toggling like status
final toggleLikeProvider =
    Provider.family<Future<void> Function(), String>((ref, listingId) {
  return () async {
    final authState = ref.read(authNotifierProvider);
    if (authState.user == null) return;

    final repository = ref.read(listingRepositoryProvider);
    final isLiked = ref.read(isListingLikedProvider(listingId));

    await repository.toggleLike(
      listingId: listingId,
      userId: authState.user!.id,
      isLiked: isLiked,
    );
  };
});

/// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Selected category provider
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Provider for user's own listings (as a host)
final myListingsProvider = StreamProvider<List<Listing>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState.user == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(listingRepositoryProvider);
  return repository.watchHostListings(authState.user!.id);
});
