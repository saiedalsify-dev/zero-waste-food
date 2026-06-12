import 'dart:math' as math;

import '../core/config/app_constants.dart';
import '../models/donation.dart';
import '../models/matching_result.dart';

class MatchingService {
  const MatchingService();

  List<MatchingResult> rankDonations(
    List<Donation> donations, {
    bool availableOnly = true,
  }) {
    final results =
        donations
            .where((donation) => !availableOnly || donation.isAvailable)
            .map(scoreDonation)
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  MatchingResult scoreDonation(Donation donation) {
    if (donation.expiryDate.isBefore(DateTime.now())) {
      return MatchingResult(
        donation: donation,
        score: 0,
        reasons: const <String>['Expired food cannot be matched safely.'],
      );
    }

    final urgencyScore = _expiryUrgencyScore(donation.expiryDate);
    final quantityScore = _quantityScore(donation.quantity);
    final weightedScore =
        (urgencyScore * (MatchingConfig.urgencyWeight / 100)) +
        (quantityScore * (MatchingConfig.quantityWeight / 100));

    return MatchingResult(
      donation: donation,
      score: weightedScore.round().clamp(0, 100),
      reasons: <String>[
        _expiryReason(donation.expiryDate),
        _quantityReason(donation.quantity, donation.unit),
      ],
    );
  }

  double _expiryUrgencyScore(DateTime expiryDate) {
    final hours = expiryDate.difference(DateTime.now()).inHours;
    if (hours <= 6) {
      return 100;
    }
    if (hours <= 24) {
      return 85;
    }
    if (hours <= 48) {
      return 70;
    }
    if (hours <= 96) {
      return 50;
    }
    return 25;
  }

  double _quantityScore(double quantity) {
    final normalized = quantity / MatchingConfig.quantityForFullScore;
    return math.min(100, math.max(0, normalized * 100));
  }

  String _expiryReason(DateTime expiryDate) {
    final hours = expiryDate.difference(DateTime.now()).inHours;
    if (hours <= 6) {
      return 'Very urgent expiry window: pickup should happen immediately.';
    }
    if (hours <= 24) {
      return 'High expiry urgency: best handled today.';
    }
    if (hours <= 48) {
      return 'Moderate expiry urgency: can be scheduled soon.';
    }
    return 'Lower expiry urgency: safe to rank after urgent donations.';
  }

  String _quantityReason(double quantity, String unit) {
    if (quantity >= MatchingConfig.quantityForFullScore) {
      return 'Large quantity: $quantity $unit can support a major distribution.';
    }
    if (quantity >= 40) {
      return 'Medium quantity: $quantity $unit can support a focused pickup.';
    }
    return 'Small quantity: $quantity $unit is useful but lower priority than larger offers.';
  }
}
