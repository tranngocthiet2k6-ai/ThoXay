import 'dart:math' as math;

import 'models.dart';

class TierRule {
  const TierRule({
    required this.code,
    required this.name,
    required this.minReputation,
    required this.minCompletedJobs,
    required this.minRating,
    required this.requiresKyc,
    required this.benefits,
  });
  final String code, name;
  final int minReputation, minCompletedJobs;
  final double minRating;
  final bool requiresKyc;
  final List<String> benefits;
  factory TierRule.fromJson(Map<String, dynamic> json) => TierRule(
    code: json['code'] as String,
    name: json['name'] as String,
    minReputation: (json['minReputation'] as num).toInt(),
    minCompletedJobs: (json['minCompletedJobs'] as num).toInt(),
    minRating: (json['minRating'] as num).toDouble(),
    requiresKyc: json['requiresKyc'] as bool,
    benefits: (json['benefits'] as List).cast<String>(),
  );
  double progress(UserProfile user) {
    final values = [
      if (minReputation > 0)
        math.min(user.reputationScore / minReputation, 1.0),
      if (minCompletedJobs > 0)
        math.min(user.completedJobs / minCompletedJobs, 1.0),
      if (minRating > 0)
        user.completedJobs == 0 ? 0.0 : math.min(user.rating / minRating, 1.0),
      if (requiresKyc) user.verified ? 1.0 : 0.0,
    ];
    return values.isEmpty ? 1 : values.reduce((a, b) => a + b) / values.length;
  }
}

class TierGuide {
  const TierGuide(this.tiers, this.priorityPolicy, this.feePolicy);
  final List<TierRule> tiers;
  final String priorityPolicy, feePolicy;
  factory TierGuide.fromJson(Map<String, dynamic> json) => TierGuide(
    (json['tiers'] as List)
        .map((item) => TierRule.fromJson(item as Map<String, dynamic>))
        .toList(),
    json['priorityPolicy'] as String,
    json['feePolicy'] as String,
  );
}
