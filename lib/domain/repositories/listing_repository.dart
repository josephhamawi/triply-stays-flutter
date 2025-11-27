import '../entities/listing.dart';

/// Filter parameters for listing queries
class ListingFilter {
  final String? country;
  final String? city;
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final int? minBedrooms;
  final int? minBathrooms;
  final int? minGuests;
  final String? searchQuery;
  final String sortBy;

  const ListingFilter({
    this.country,
    this.city,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.minBedrooms,
    this.minBathrooms,
    this.minGuests,
    this.searchQuery,
    this.sortBy = 'latest',
  });

  ListingFilter copyWith({
    String? country,
    String? city,
    String? category,
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    int? minBathrooms,
    int? minGuests,
    String? searchQuery,
    String? sortBy,
  }) {
    return ListingFilter(
      country: country ?? this.country,
      city: city ?? this.city,
      category: category ?? this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      minBathrooms: minBathrooms ?? this.minBathrooms,
      minGuests: minGuests ?? this.minGuests,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

/// Abstract repository interface for listings
abstract class ListingRepository {
  /// Get all active listings with optional filter
  Stream<List<Listing>> watchListings({ListingFilter? filter});

  /// Get a single listing by ID
  Future<Listing?> getListingById(String id);

  /// Get listings by host ID
  Stream<List<Listing>> watchHostListings(String hostId);

  /// Get liked listings for a user
  Future<List<Listing>> getLikedListings(List<String> listingIds);

  /// Toggle like on a listing
  Future<void> toggleLike({
    required String listingId,
    required String userId,
    required bool isLiked,
  });

  /// Increment view count
  Future<void> incrementViews(String listingId);

  /// Get available categories
  Future<List<String>> getCategories();

  /// Get available views (mountain, sea, etc.)
  Future<List<String>> getViews();

  /// Get available amenities
  Future<List<String>> getAmenities();

  /// Get available cities for a country
  Future<List<String>> getCitiesForCountry(String countryCode);

  /// Create a new listing
  Future<String> createListing(Listing listing);

  /// Update an existing listing
  Future<void> updateListing(Listing listing);
}
