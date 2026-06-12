import 'donation.dart';

class MatchingResult {
  const MatchingResult({
    required this.donation,
    required this.score,
    required this.reasons,
  });

  final Donation donation;
  final int score;
  final List<String> reasons;
}
