import 'package:flutter/foundation.dart';

/// Requirements for HostPro Elite status
class HostProRequirements {
  static const double minRating = 4.5;
  static const int minReviews = 3;
  static const double minResponseRate = 0.9; // 90%
  static const int minAccountAgeDays = 90;
}

/// Single requirement status
@immutable
class RequirementStatus {
  final dynamic current;
  final dynamic required;
  final bool met;

  const RequirementStatus({
    required this.current,
    required this.required,
    required this.met,
  });

  double get progress {
    if (current is String) return met ? 1.0 : 0.0;
    if (required == 0) return met ? 1.0 : 0.0;
    final currentNum = (current as num).toDouble();
    final requiredNum = (required as num).toDouble();
    return (currentNum / requiredNum).clamp(0.0, 1.0);
  }
}

/// HostPro evaluation result
@immutable
class HostProStatus {
  final bool isHostProElite;
  final double averageRating;
  final int reviewCount;
  final int responseRate; // percentage
  final dynamic accountAgeDays; // can be int or 'Grandfathered'
  final RequirementStatus ratingRequirement;
  final RequirementStatus reviewCountRequirement;
  final RequirementStatus responseRateRequirement;
  final RequirementStatus accountAgeRequirement;

  const HostProStatus({
    required this.isHostProElite,
    required this.averageRating,
    required this.reviewCount,
    required this.responseRate,
    required this.accountAgeDays,
    required this.ratingRequirement,
    required this.reviewCountRequirement,
    required this.responseRateRequirement,
    required this.accountAgeRequirement,
  });

  factory HostProStatus.initial() {
    return const HostProStatus(
      isHostProElite: false,
      averageRating: 0,
      reviewCount: 0,
      responseRate: 0,
      accountAgeDays: 0,
      ratingRequirement: RequirementStatus(
        current: 0.0,
        required: HostProRequirements.minRating,
        met: false,
      ),
      reviewCountRequirement: RequirementStatus(
        current: 0,
        required: HostProRequirements.minReviews,
        met: false,
      ),
      responseRateRequirement: RequirementStatus(
        current: 0,
        required: 90,
        met: false,
      ),
      accountAgeRequirement: RequirementStatus(
        current: 0,
        required: HostProRequirements.minAccountAgeDays,
        met: false,
      ),
    );
  }

  int get requirementsMet {
    int count = 0;
    if (ratingRequirement.met) count++;
    if (reviewCountRequirement.met) count++;
    if (responseRateRequirement.met) count++;
    if (accountAgeRequirement.met) count++;
    return count;
  }

  int get totalRequirements => 4;

  double get overallProgress => requirementsMet / totalRequirements;
}
