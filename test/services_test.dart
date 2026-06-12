import 'package:flutter_test/flutter_test.dart';
import 'package:zero_waste_food/models/donation.dart';
import 'package:zero_waste_food/services/chatbot_service.dart';
import 'package:zero_waste_food/services/matching_service.dart';

void main() {
  group('MatchingService', () {
    test('ranks urgent donations before less urgent donations', () {
      final now = DateTime.now();
      final service = MatchingService();
      final donations = <Donation>[
        _donation(
          id: 'later',
          quantity: 90,
          expiryDate: now.add(const Duration(days: 3)),
        ),
        _donation(
          id: 'urgent',
          quantity: 40,
          expiryDate: now.add(const Duration(hours: 4)),
        ),
      ];

      final results = service.rankDonations(donations);

      expect(results.first.donation.id, 'urgent');
      expect(results.first.score, greaterThan(results.last.score));
    });

    test('expired donations receive zero score', () {
      final service = MatchingService();
      final donation = _donation(
        id: 'expired',
        quantity: 100,
        expiryDate: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final result = service.scoreDonation(donation);

      expect(result.score, 0);
    });
  });

  group('ChatbotService', () {
    test('answers matching questions without AI APIs', () {
      final service = ChatbotService();

      final answer = service.reply('How does the matching score work?');

      expect(answer.toLowerCase(), contains('rule-based'));
      expect(answer.toLowerCase(), contains('no machine learning'));
    });
  });
}

Donation _donation({
  required String id,
  required double quantity,
  required DateTime expiryDate,
}) {
  return Donation(
    id: id,
    donorId: 'donor',
    donorName: 'Donor',
    title: 'Donation $id',
    description: 'Food donation',
    quantity: quantity,
    unit: 'Meals',
    expiryDate: expiryDate,
    city: 'Cairo',
    status: DonationStatus.pending,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
