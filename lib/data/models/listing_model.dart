import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/listing.dart';

/// Data model for Listing with Firestore serialization
class ListingModel extends Listing {
  const ListingModel({
    required super.id,
    required super.title,
    required super.description,
    required super.price,
    required super.city,
    super.country,
    super.address,
    required super.images,
    required super.hostId,
    super.hostName,
    super.hostPhotoURL,
    super.hostPhone,
    super.hostHasWhatsApp,
    super.category,
    super.view,
    super.amenities,
    super.rules,
    super.bedrooms,
    super.bathrooms,
    super.livingRooms,
    super.beds,
    super.maxGuests,
    super.location,
    super.latitude,
    super.longitude,
    super.status,
    required super.createdAt,
    super.likesCount,
    super.views,
    super.averageRating,
    super.reviewCount,
  });

  /// Helper to safely parse a value as double (handles String or num)
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Helper to safely parse a value as int (handles String or num)
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Create ListingModel from Firestore document
  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse coordinates
    double? lat;
    double? lng;
    if (data['coordinates'] != null) {
      lat = _parseDouble(data['coordinates']['lat']);
      lng = _parseDouble(data['coordinates']['lng']);
    }

    // Parse createdAt
    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else {
      createdAt = DateTime.now();
    }

    return ListingModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: _parseDouble(data['price']) ?? 0.0,
      city: data['city'] ?? '',
      country: data['country'] ?? 'LB',
      address: data['address'],
      images: List<String>.from(data['images'] ?? []),
      hostId: data['hostId'] ?? '',
      hostName: data['hostName'],
      hostPhotoURL: data['hostPhotoURL'],
      hostPhone: data['hostPhone'],
      hostHasWhatsApp: data['hostHasWhatsApp'] == true,
      category: data['category'],
      view: data['view'],
      amenities: List<String>.from(data['amenities'] ?? []),
      rules: data['rules'],
      bedrooms: _parseInt(data['bedrooms']) ?? 1,
      bathrooms: _parseInt(data['bathrooms']) ?? 1,
      livingRooms: _parseInt(data['livingRooms']) ?? 0,
      beds: _parseInt(data['beds']) ?? 1,
      maxGuests: _parseInt(data['maxGuests']) ?? 2,
      location: data['location'],
      latitude: lat,
      longitude: lng,
      status: data['status'] ?? 'active',
      createdAt: createdAt,
      likesCount: _parseInt(data['likesCount']) ?? 0,
      views: _parseInt(data['views']) ?? 0,
      averageRating: _parseDouble(data['averageRating']),
      reviewCount: _parseInt(data['reviewCount']) ?? 0,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'city': city,
      'country': country,
      'address': address,
      'images': images,
      'hostId': hostId,
      'hostName': hostName,
      'hostPhotoURL': hostPhotoURL,
      'hostPhone': hostPhone,
      'hostHasWhatsApp': hostHasWhatsApp,
      'category': category,
      'view': view,
      'amenities': amenities,
      'rules': rules,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'livingRooms': livingRooms,
      'beds': beds,
      'maxGuests': maxGuests,
      'location': location,
      'coordinates': latitude != null && longitude != null
          ? {'lat': latitude, 'lng': longitude}
          : null,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': likesCount,
      'views': views,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
    };
  }

  /// Create from Listing entity
  factory ListingModel.fromEntity(Listing listing) {
    return ListingModel(
      id: listing.id,
      title: listing.title,
      description: listing.description,
      price: listing.price,
      city: listing.city,
      country: listing.country,
      address: listing.address,
      images: listing.images,
      hostId: listing.hostId,
      hostName: listing.hostName,
      hostPhotoURL: listing.hostPhotoURL,
      hostPhone: listing.hostPhone,
      hostHasWhatsApp: listing.hostHasWhatsApp,
      category: listing.category,
      view: listing.view,
      amenities: listing.amenities,
      rules: listing.rules,
      bedrooms: listing.bedrooms,
      bathrooms: listing.bathrooms,
      livingRooms: listing.livingRooms,
      beds: listing.beds,
      maxGuests: listing.maxGuests,
      location: listing.location,
      latitude: listing.latitude,
      longitude: listing.longitude,
      status: listing.status,
      createdAt: listing.createdAt,
      likesCount: listing.likesCount,
      views: listing.views,
      averageRating: listing.averageRating,
      reviewCount: listing.reviewCount,
    );
  }
}
