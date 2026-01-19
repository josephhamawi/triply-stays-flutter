import '../repositories/listing_repository.dart';

/// Parsed search intent from natural language query
class SearchIntent {
  final String originalQuery;
  final String? location;
  final String? propertyType;
  final List<String> amenities;
  final int? minBedrooms;
  final int? minBathrooms;
  final int? minGuests;
  final double? maxPrice;
  final List<String> views;
  final double confidence;

  const SearchIntent({
    required this.originalQuery,
    this.location,
    this.propertyType,
    this.amenities = const [],
    this.minBedrooms,
    this.minBathrooms,
    this.minGuests,
    this.maxPrice,
    this.views = const [],
    this.confidence = 0.0,
  });

  /// Create from JSON response
  factory SearchIntent.fromJson(Map<String, dynamic> json, String originalQuery) {
    return SearchIntent(
      originalQuery: originalQuery,
      location: json['location'] as String?,
      propertyType: json['propertyType'] as String?,
      amenities: List<String>.from(json['amenities'] ?? []),
      minBedrooms: json['minBedrooms'] as int?,
      minBathrooms: json['minBathrooms'] as int?,
      minGuests: json['minGuests'] as int?,
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      views: List<String>.from(json['views'] ?? []),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
    );
  }

  /// Convert to ListingFilter for querying
  ListingFilter toListingFilter() {
    return ListingFilter(
      city: location,
      category: propertyType,
      minBedrooms: minBedrooms,
      minBathrooms: minBathrooms,
      minGuests: minGuests,
      maxPrice: maxPrice,
      searchQuery: originalQuery,
    );
  }

  /// Check if any meaningful filters were extracted
  bool get hasFilters =>
      location != null ||
      propertyType != null ||
      amenities.isNotEmpty ||
      minBedrooms != null ||
      minBathrooms != null ||
      minGuests != null ||
      maxPrice != null ||
      views.isNotEmpty;

  @override
  String toString() {
    final parts = <String>[];
    if (location != null) parts.add('location: $location');
    if (propertyType != null) parts.add('type: $propertyType');
    if (amenities.isNotEmpty) parts.add('amenities: ${amenities.join(", ")}');
    if (minBedrooms != null) parts.add('bedrooms: $minBedrooms+');
    if (minBathrooms != null) parts.add('bathrooms: $minBathrooms+');
    if (minGuests != null) parts.add('guests: $minGuests+');
    if (maxPrice != null) parts.add('max price: \$$maxPrice');
    if (views.isNotEmpty) parts.add('views: ${views.join(", ")}');
    return 'SearchIntent(${parts.join(", ")})';
  }
}
