import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/listing.dart';
import '../../domain/repositories/listing_repository.dart';
import '../models/listing_model.dart';

/// Firebase implementation of ListingRepository
class FirebaseListingRepository implements ListingRepository {
  final FirebaseFirestore _firestore;

  FirebaseListingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _listingsRef => _firestore.collection('listings');
  CollectionReference get _usersRef => _firestore.collection('users');
  CollectionReference get _settingsRef => _firestore.collection('settings');

  @override
  Stream<List<Listing>> watchListings({ListingFilter? filter}) {
    // Fetch all listings, filter client-side for moderation
    // This matches the web app's approach
    Query query = _listingsRef.limit(200);

    return query.snapshots().map((snapshot) {
      var listings = snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Filter for verified listings only (matching web app logic)
          // Hide if needsReview is true or verified is explicitly false
          final needsReview = data['needsReview'] as bool? ?? false;
          final verified = data['verified'] as bool?;

          if (needsReview == true) return null;
          if (verified == false) return null;

          return ListingModel.fromFirestore(doc);
        } catch (e) {
          // Log error but don't crash - skip this listing
          return null;
        }
      }).whereType<ListingModel>().toList();

      // Sort by createdAt descending
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply all filters client-side to avoid composite index requirements
      if (filter?.country != null && filter!.country!.isNotEmpty) {
        listings = listings
            .where((l) => l.country == filter.country)
            .toList();
      }
      if (filter?.city != null && filter!.city!.isNotEmpty) {
        listings = listings
            .where((l) => l.city.toLowerCase() == filter.city!.toLowerCase())
            .toList();
      }
      if (filter?.category != null && filter!.category!.isNotEmpty) {
        listings = listings
            .where((l) => l.category?.toLowerCase() == filter.category!.toLowerCase())
            .toList();
      }
      if (filter?.minPrice != null) {
        listings =
            listings.where((l) => l.price >= filter!.minPrice!).toList();
      }
      if (filter?.maxPrice != null) {
        listings =
            listings.where((l) => l.price <= filter!.maxPrice!).toList();
      }
      if (filter?.minBedrooms != null) {
        listings =
            listings.where((l) => l.bedrooms >= filter!.minBedrooms!).toList();
      }
      if (filter?.minBathrooms != null) {
        listings = listings
            .where((l) => l.bathrooms >= filter!.minBathrooms!)
            .toList();
      }
      if (filter?.minGuests != null) {
        listings =
            listings.where((l) => l.maxGuests >= filter!.minGuests!).toList();
      }
      if (filter?.searchQuery != null && filter!.searchQuery!.isNotEmpty) {
        final q = filter.searchQuery!.toLowerCase();
        listings = listings.where((l) {
          return l.title.toLowerCase().contains(q) ||
              l.description.toLowerCase().contains(q) ||
              l.city.toLowerCase().contains(q);
        }).toList();
      }

      // Sort client-side
      switch (filter?.sortBy) {
        case 'price-low':
          listings.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price-high':
          listings.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'oldest':
          listings.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case 'latest':
        default:
          // Already sorted by createdAt desc from Firestore
          break;
      }

      return listings;
    });
  }

  @override
  Future<Listing?> getListingById(String id) async {
    final doc = await _listingsRef.doc(id).get();
    if (!doc.exists) return null;
    return ListingModel.fromFirestore(doc);
  }

  @override
  Stream<List<Listing>> watchHostListings(String hostId) {
    return _listingsRef
        .where('hostId', isEqualTo: hostId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList());
  }

  @override
  Future<List<Listing>> getLikedListings(List<String> listingIds) async {
    if (listingIds.isEmpty) return [];

    // Firestore limits 'whereIn' to 30 items, so we batch
    final List<Listing> listings = [];
    for (var i = 0; i < listingIds.length; i += 30) {
      final batch = listingIds.skip(i).take(30).toList();
      final snapshot =
          await _listingsRef.where(FieldPath.documentId, whereIn: batch).get();
      listings.addAll(
          snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)));
    }

    return listings;
  }

  @override
  Future<void> toggleLike({
    required String listingId,
    required String userId,
    required bool isLiked,
  }) async {
    final batch = _firestore.batch();

    // Update user's liked listings
    final userRef = _usersRef.doc(userId);
    if (isLiked) {
      batch.update(userRef, {
        'likedListings': FieldValue.arrayRemove([listingId])
      });
    } else {
      batch.update(userRef, {
        'likedListings': FieldValue.arrayUnion([listingId])
      });
    }

    // Update listing's like count
    final listingRef = _listingsRef.doc(listingId);
    batch.update(listingRef, {
      'likesCount': FieldValue.increment(isLiked ? -1 : 1),
    });

    await batch.commit();
  }

  @override
  Future<void> incrementViews(String listingId) async {
    await _listingsRef.doc(listingId).update({
      'views': FieldValue.increment(1),
    });
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final doc = await _settingsRef.doc('appSettings').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['categories'] ?? []);
      }
    } catch (e) {
      // Return default categories if settings not found
    }
    return [
      'Apartment',
      'Villa',
      'House',
      'Chalet',
      'Cabin',
      'Studio',
      'Condo',
    ];
  }

  @override
  Future<List<String>> getViews() async {
    try {
      final doc = await _settingsRef.doc('appSettings').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['views'] ?? []);
      }
    } catch (e) {
      // Return default views if settings not found
    }
    return [
      'Mountain',
      'Sea',
      'City',
      'Garden',
      'Pool',
      'Lake',
      'Forest',
    ];
  }

  @override
  Future<List<String>> getAmenities() async {
    try {
      final doc = await _settingsRef.doc('appSettings').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['amenities'] ?? []);
      }
    } catch (e) {
      // Return default amenities if settings not found
    }
    return [
      'WiFi',
      'Pool',
      'Kitchen',
      'AC',
      'Parking',
      'TV',
      'Washer',
      'Dryer',
      'Heating',
      'Workspace',
      'Balcony',
      'Garden',
      'BBQ',
      'Gym',
      'Hot Tub',
    ];
  }

  @override
  Future<List<String>> getCitiesForCountry(String countryCode) async {
    // Get unique cities from listings for this country
    final snapshot = await _listingsRef
        .where('country', isEqualTo: countryCode)
        .get();

    final cities = snapshot.docs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Filter for verified listings only
          final needsReview = data['needsReview'] as bool? ?? false;
          final verified = data['verified'] as bool?;
          return needsReview != true && verified != false;
        })
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['city'] as String?;
        })
        .where((city) => city != null && city.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    cities.sort();
    return cities;
  }

  @override
  Future<String> createListing(Listing listing) async {
    // Create a new document reference to get the ID
    final docRef = _listingsRef.doc();

    // Build the listing data with the generated ID
    final listingWithId = listing.copyWith(id: docRef.id);
    final model = ListingModel.fromEntity(listingWithId);

    // Prepare data for Firestore
    final data = model.toFirestore();

    // Add additional fields for new listings
    data['createdAt'] = FieldValue.serverTimestamp();
    data['status'] = 'pending'; // New listings need review
    data['likesCount'] = 0;
    data['views'] = 0;
    data['needsReview'] = true;
    data['verified'] = false;

    await docRef.set(data);

    return docRef.id;
  }

  @override
  Future<void> updateListing(Listing listing) async {
    final model = ListingModel.fromEntity(listing);
    final data = model.toFirestore();

    // Remove fields that shouldn't be updated
    data.remove('createdAt');
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _listingsRef.doc(listing.id).update(data);
  }
}
