import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/listing.dart';
import '../auth/auth_provider.dart';
import '../listings/listings_provider.dart';
import 'ai_providers.dart';

/// State for AI recommendations
class AIRecommendationsState {
  final List<Listing> recommendations;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const AIRecommendationsState({
    this.recommendations = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  AIRecommendationsState copyWith({
    List<Listing>? recommendations,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
    bool clearError = false,
  }) {
    return AIRecommendationsState(
      recommendations: recommendations ?? this.recommendations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Notifier for AI-powered recommendations
class AIRecommendationsNotifier extends StateNotifier<AIRecommendationsState> {
  final Ref _ref;

  AIRecommendationsNotifier(this._ref) : super(const AIRecommendationsState());

  /// Load personalized recommendations
  Future<void> loadRecommendations() async {
    final authState = _ref.read(authNotifierProvider);
    if (authState.user == null) {
      state = state.copyWith(error: 'Please sign in to see recommendations');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final aiRepository = _ref.read(aiRepositoryProvider);
      final listingRepository = _ref.read(listingRepositoryProvider);

      // Get user's liked listings
      final likedIdsAsync = _ref.read(likedListingIdsProvider);
      final likedIds = likedIdsAsync.when(
        data: (ids) => ids,
        loading: () => <String>[],
        error: (_, __) => <String>[],
      );

      if (likedIds.isEmpty) {
        // No likes yet, show popular listings instead
        final allListings = await listingRepository.watchListings().first;
        final popular = allListings
            .where((l) => l.status == 'active')
            .toList()
          ..sort((a, b) => b.likesCount.compareTo(a.likesCount));

        state = state.copyWith(
          recommendations: popular.take(10).toList(),
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
        return;
      }

      // Get AI-powered recommendations based on likes
      final recommendedIds = await aiRepository.getRecommendedListingIds(
        userId: authState.user!.id,
        likedListingIds: likedIds,
      );

      if (recommendedIds.isEmpty) {
        // Fallback to similar listings by category
        final likedListings = await listingRepository.getLikedListings(likedIds.take(3).toList());
        final categories = likedListings.map((l) => l.category).whereType<String>().toSet();

        final allListings = await listingRepository.watchListings().first;
        final similar = allListings
            .where((l) =>
                l.status == 'active' &&
                !likedIds.contains(l.id) &&
                (categories.isEmpty || categories.contains(l.category)))
            .take(10)
            .toList();

        state = state.copyWith(
          recommendations: similar,
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
        return;
      }

      // Fetch the recommended listings
      final recommendations = await listingRepository.getLikedListings(recommendedIds);

      state = state.copyWith(
        recommendations: recommendations,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load recommendations: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// Refresh recommendations
  Future<void> refresh() async {
    await loadRecommendations();
  }
}

/// Provider for AI recommendations state and notifier
final aiRecommendationsProvider =
    StateNotifierProvider<AIRecommendationsNotifier, AIRecommendationsState>((ref) {
  return AIRecommendationsNotifier(ref);
});

/// Provider for "For You" section title based on personalization status
final forYouTitleProvider = Provider<String>((ref) {
  final likedIdsAsync = ref.watch(likedListingIdsProvider);
  return likedIdsAsync.when(
    data: (ids) => ids.isEmpty ? 'Popular Stays' : 'For You',
    loading: () => 'For You',
    error: (_, __) => 'Popular Stays',
  );
});

/// Provider for recommendation explanation text
final recommendationExplanationProvider = Provider<String>((ref) {
  final likedIdsAsync = ref.watch(likedListingIdsProvider);
  return likedIdsAsync.when(
    data: (ids) => ids.isEmpty
        ? 'Like some listings to get personalized recommendations!'
        : 'Based on your liked properties',
    loading: () => 'Loading your preferences...',
    error: (_, __) => 'Discover popular stays',
  );
});
