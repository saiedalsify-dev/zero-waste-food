class ChatbotService {
  ChatbotService()
    : _intents = <_ChatbotIntent>[
        _ChatbotIntent(
          keywords: const <String>['donate', 'add', 'food', 'surplus'],
          answer:
              'To add a donation, open Add Donation, enter quantity, expiry time, city, and notes. The app will keep it pending until a charity accepts it.',
        ),
        _ChatbotIntent(
          keywords: const <String>['charity', 'accept', 'reject', 'pickup'],
          answer:
              'Charities can view pending donations, filter by city, inspect details, then accept or reject a donation. Accepted donations notify the donor.',
        ),
        _ChatbotIntent(
          keywords: const <String>[
            'matching',
            'score',
            'algorithm',
            'priority',
          ],
          answer:
              'Matching is rule-based. The score uses expiry urgency and quantity only, then sorts donations from highest to lowest priority. No machine learning or AI APIs are used.',
        ),
        _ChatbotIntent(
          keywords: const <String>['expiry', 'expired', 'urgent', 'time'],
          answer:
              'Expiry urgency is the strongest factor. Food expiring soon receives a higher score so charities can rescue it before it becomes unsafe.',
        ),
        _ChatbotIntent(
          keywords: const <String>['notification', 'alert', 'fcm', 'message'],
          answer:
              'Notifications cover new donations, accepted donations, and status updates. Firebase Cloud Messaging tokens are stored when Firebase is configured.',
        ),
        _ChatbotIntent(
          keywords: const <String>['map', 'maps', 'location', 'nearby'],
          answer:
              'Maps are intentionally disabled in this phase. Locations are stored as city text and optional coordinates so Google Maps can be added later.',
        ),
        _ChatbotIntent(
          keywords: const <String>['role', 'donor', 'admin', 'user'],
          answer:
              'The app supports three roles: donors add and track food, charities accept or reject donations, and admins review users and donations.',
        ),
        _ChatbotIntent(
          keywords: const <String>['firebase', 'login', 'register', 'account'],
          answer:
              'Authentication uses Firebase Email/Password after configuration. Without credentials, the project runs in demo mode for safe local builds.',
        ),
        _ChatbotIntent(
          keywords: const <String>['thanks', 'thank', 'good'],
          answer: 'You are welcome. Reducing waste is a practical team sport.',
        ),
      ];

  final List<_ChatbotIntent> _intents;

  String reply(String message) {
    final normalized = message.toLowerCase().trim();
    if (normalized.isEmpty) {
      return 'Ask me about donations, roles, matching, expiry, notifications, or maps.';
    }

    _ChatbotIntent? bestIntent;
    var bestScore = 0;
    for (final intent in _intents) {
      final score = intent.keywords.where(normalized.contains).length;
      if (score > bestScore) {
        bestScore = score;
        bestIntent = intent;
      }
    }

    return bestIntent?.answer ??
        'I can answer project questions about donations, charities, matching, expiry urgency, notifications, Firebase, and maps.';
  }
}

class _ChatbotIntent {
  const _ChatbotIntent({required this.keywords, required this.answer});

  final List<String> keywords;
  final String answer;
}
