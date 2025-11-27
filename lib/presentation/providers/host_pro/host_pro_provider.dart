import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/host_pro_status.dart';

/// Provider for HostPro status
class HostProNotifier extends StateNotifier<AsyncValue<HostProStatus>> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  HostProNotifier({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(const AsyncValue.loading());

  /// Evaluate HostPro status for current user
  Future<void> evaluateHostProStatus() async {
    state = const AsyncValue.loading();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        state = AsyncValue.data(HostProStatus.initial());
        return;
      }

      // Get user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userData == null) {
        state = AsyncValue.data(HostProStatus.initial());
        return;
      }

      // Calculate account age
      final createdAt = userData['createdAt'] as Timestamp?;
      final isGrandfathered = userData['grandfatheredHostPro'] == true;

      int accountAgeDays = 0;
      dynamic accountAgeValue = 0;
      bool accountAgeReqMet = false;

      if (isGrandfathered) {
        accountAgeValue = 'Grandfathered';
        accountAgeReqMet = true;
      } else if (createdAt != null) {
        accountAgeDays = DateTime.now().difference(createdAt.toDate()).inDays;
        accountAgeValue = accountAgeDays;
        accountAgeReqMet = accountAgeDays >= HostProRequirements.minAccountAgeDays;
      }

      // Get all listings by this user
      final listingsQuery = await _firestore
          .collection('listings')
          .where('hostId', isEqualTo: user.uid)
          .get();

      if (listingsQuery.docs.isEmpty) {
        // User has no listings, return initial status with just account age
        state = AsyncValue.data(HostProStatus(
          isHostProElite: false,
          averageRating: 0,
          reviewCount: 0,
          responseRate: userData['responseRate'] as int? ?? 0,
          accountAgeDays: accountAgeValue,
          ratingRequirement: const RequirementStatus(
            current: 0.0,
            required: HostProRequirements.minRating,
            met: false,
          ),
          reviewCountRequirement: const RequirementStatus(
            current: 0,
            required: HostProRequirements.minReviews,
            met: false,
          ),
          responseRateRequirement: RequirementStatus(
            current: userData['responseRate'] as int? ?? 0,
            required: 90,
            met: (userData['responseRate'] as int? ?? 0) >= 90,
          ),
          accountAgeRequirement: RequirementStatus(
            current: accountAgeValue,
            required: HostProRequirements.minAccountAgeDays,
            met: accountAgeReqMet,
          ),
        ));
        return;
      }

      // Get listing IDs
      final listingIds = listingsQuery.docs.map((doc) => doc.id).toList();

      // Get all reviews for these listings
      double totalRating = 0;
      int reviewCount = 0;

      // Query reviews for each listing (Firestore doesn't support 'in' with more than 10 items)
      for (int i = 0; i < listingIds.length; i += 10) {
        final batch = listingIds.sublist(
          i,
          i + 10 > listingIds.length ? listingIds.length : i + 10,
        );

        final reviewsQuery = await _firestore
            .collection('reviews')
            .where('listingId', whereIn: batch)
            .get();

        for (final reviewDoc in reviewsQuery.docs) {
          final reviewData = reviewDoc.data();
          final rating = reviewData['rating'];
          if (rating != null) {
            totalRating += (rating as num).toDouble();
            reviewCount++;
          }
        }
      }

      // Calculate average rating
      final averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;

      // Get response rate from user data
      final responseRate = userData['responseRate'] as int? ?? 0;

      // Evaluate requirements
      final ratingMet = averageRating >= HostProRequirements.minRating;
      final reviewsMet = reviewCount >= HostProRequirements.minReviews;
      final responseMet = responseRate >= (HostProRequirements.minResponseRate * 100);

      final isHostProElite = ratingMet && reviewsMet && responseMet && accountAgeReqMet;

      state = AsyncValue.data(HostProStatus(
        isHostProElite: isHostProElite,
        averageRating: averageRating,
        reviewCount: reviewCount,
        responseRate: responseRate,
        accountAgeDays: accountAgeValue,
        ratingRequirement: RequirementStatus(
          current: averageRating,
          required: HostProRequirements.minRating,
          met: ratingMet,
        ),
        reviewCountRequirement: RequirementStatus(
          current: reviewCount,
          required: HostProRequirements.minReviews,
          met: reviewsMet,
        ),
        responseRateRequirement: RequirementStatus(
          current: responseRate,
          required: 90,
          met: responseMet,
        ),
        accountAgeRequirement: RequirementStatus(
          current: accountAgeValue,
          required: HostProRequirements.minAccountAgeDays,
          met: accountAgeReqMet,
        ),
      ));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refresh HostPro status
  Future<void> refresh() async {
    await evaluateHostProStatus();
  }
}

/// Provider for HostPro notifier
final hostProNotifierProvider =
    StateNotifierProvider<HostProNotifier, AsyncValue<HostProStatus>>((ref) {
  final notifier = HostProNotifier();
  // Automatically evaluate status when provider is created
  notifier.evaluateHostProStatus();
  return notifier;
});
