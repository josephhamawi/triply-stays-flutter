import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/listing.dart';
import '../../../domain/entities/search_intent.dart';
import '../listings/listings_provider.dart';
import 'ai_providers.dart';

/// State for AI-powered search
class AISearchState {
  final String query;
  final SearchIntent? intent;
  final List<Listing> results;
  final bool isLoading;
  final bool isParsingIntent;
  final String? error;
  final bool usedAI;

  const AISearchState({
    this.query = '',
    this.intent,
    this.results = const [],
    this.isLoading = false,
    this.isParsingIntent = false,
    this.error,
    this.usedAI = false,
  });

  AISearchState copyWith({
    String? query,
    SearchIntent? intent,
    List<Listing>? results,
    bool? isLoading,
    bool? isParsingIntent,
    String? error,
    bool? usedAI,
    bool clearIntent = false,
    bool clearError = false,
  }) {
    return AISearchState(
      query: query ?? this.query,
      intent: clearIntent ? null : (intent ?? this.intent),
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      isParsingIntent: isParsingIntent ?? this.isParsingIntent,
      error: clearError ? null : (error ?? this.error),
      usedAI: usedAI ?? this.usedAI,
    );
  }
}

/// Notifier for AI-powered search functionality
class AISearchNotifier extends StateNotifier<AISearchState> {
  final Ref _ref;

  AISearchNotifier(this._ref) : super(const AISearchState());

  /// Perform an AI-powered search
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AISearchState();
      return;
    }

    state = state.copyWith(
      query: query,
      isLoading: true,
      isParsingIntent: true,
      clearError: true,
    );

    try {
      final aiRepository = _ref.read(aiRepositoryProvider);

      // Parse the search query with AI
      final intent = await aiRepository.parseSearchQuery(query);

      state = state.copyWith(
        intent: intent,
        isParsingIntent: false,
        usedAI: true,
      );

      // Convert intent to filter and fetch results
      final filter = intent.toListingFilter();
      final listingRepository = _ref.read(listingRepositoryProvider);

      // Get listings stream and convert to list
      final listingsStream = listingRepository.watchListings(filter: filter);
      final listings = await listingsStream.first;

      // If we got few results and have amenities/views in intent, do client-side filtering
      List<Listing> filteredResults = listings;

      if (intent.amenities.isNotEmpty) {
        filteredResults = filteredResults.where((listing) {
          return intent.amenities.any((amenity) =>
              listing.amenities.any((a) =>
                  a.toLowerCase().contains(amenity.toLowerCase())));
        }).toList();
      }

      if (intent.views.isNotEmpty) {
        filteredResults = filteredResults.where((listing) {
          return intent.views.any((view) =>
              listing.listingViews.any((v) =>
                  v.toLowerCase().contains(view.toLowerCase())));
        }).toList();
      }

      state = state.copyWith(
        results: filteredResults,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to search: ${e.toString()}',
        isLoading: false,
        isParsingIntent: false,
      );
    }
  }

  /// Clear the search
  void clear() {
    state = const AISearchState();
  }

  /// Update query without searching (for text field)
  void updateQuery(String query) {
    state = state.copyWith(query: query);
  }
}

/// Provider for AI search state and notifier
final aiSearchProvider =
    StateNotifierProvider<AISearchNotifier, AISearchState>((ref) {
  return AISearchNotifier(ref);
});

/// Quick search suggestions
final searchSuggestionsProvider = Provider<List<String>>((ref) {
  return [
    'Beach villa with pool',
    'Mountain cabin for family',
    'Apartment in city center',
    'Cozy chalet with sea view',
    'Pet-friendly house with garden',
    'Luxury villa under \$200',
  ];
});
