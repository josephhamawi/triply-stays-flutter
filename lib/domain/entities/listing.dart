/// Listing entity representing a vacation rental property
class Listing {
  final String id;
  final String title;
  final String description;
  final double price;
  final double? weekendPrice;
  final String city;
  final String country;
  final String? address;
  final List<String> images;
  final String hostId;
  final String? hostName;
  final String? hostPhotoURL;
  final String? hostPhone;
  final bool hostHasWhatsApp;
  final String? category;
  final List<String> listingViews;  // Multi-select views (sea, mountain, city, etc.)
  final List<String> amenities;
  final String? rules;
  final int bedrooms;
  final int bathrooms;
  final int livingRooms;
  final int beds;
  final int maxGuests;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String status;
  final DateTime createdAt;
  final int likesCount;
  final int viewCount;  // Renamed to avoid conflict with listingViews
  final double? averageRating;
  final int reviewCount;

  const Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.weekendPrice,
    required this.city,
    this.country = 'LB',
    this.address,
    required this.images,
    required this.hostId,
    this.hostName,
    this.hostPhotoURL,
    this.hostPhone,
    this.hostHasWhatsApp = false,
    this.category,
    this.listingViews = const [],
    this.amenities = const [],
    this.rules,
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.livingRooms = 0,
    this.beds = 1,
    this.maxGuests = 2,
    this.location,
    this.latitude,
    this.longitude,
    this.status = 'active',
    required this.createdAt,
    this.likesCount = 0,
    this.viewCount = 0,
    this.averageRating,
    this.reviewCount = 0,
  });

  /// Get the primary image or a placeholder
  String get primaryImage =>
      images.isNotEmpty ? images.first : 'https://via.placeholder.com/400x300';

  /// Check if listing has coordinates for map
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Format price as currency
  String get formattedPrice => '\$${price.toStringAsFixed(0)}';

  /// Create a copy with updated fields
  Listing copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    double? weekendPrice,
    String? city,
    String? country,
    String? address,
    List<String>? images,
    String? hostId,
    String? hostName,
    String? hostPhotoURL,
    String? hostPhone,
    bool? hostHasWhatsApp,
    String? category,
    List<String>? listingViews,
    List<String>? amenities,
    String? rules,
    int? bedrooms,
    int? bathrooms,
    int? livingRooms,
    int? beds,
    int? maxGuests,
    String? location,
    double? latitude,
    double? longitude,
    String? status,
    DateTime? createdAt,
    int? likesCount,
    int? viewCount,
    double? averageRating,
    int? reviewCount,
  }) {
    return Listing(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      weekendPrice: weekendPrice ?? this.weekendPrice,
      city: city ?? this.city,
      country: country ?? this.country,
      address: address ?? this.address,
      images: images ?? this.images,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostPhotoURL: hostPhotoURL ?? this.hostPhotoURL,
      hostPhone: hostPhone ?? this.hostPhone,
      hostHasWhatsApp: hostHasWhatsApp ?? this.hostHasWhatsApp,
      category: category ?? this.category,
      listingViews: listingViews ?? this.listingViews,
      amenities: amenities ?? this.amenities,
      rules: rules ?? this.rules,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      livingRooms: livingRooms ?? this.livingRooms,
      beds: beds ?? this.beds,
      maxGuests: maxGuests ?? this.maxGuests,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      viewCount: viewCount ?? this.viewCount,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
