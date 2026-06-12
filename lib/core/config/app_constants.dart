class AppConstants {
  const AppConstants._();

  static const String appName = 'ZeroWaste Food';
  static const String appTagline =
      'Share surplus food with the people who need it.';
  static const String defaultCity = 'Cairo';
  static const int minimumPasswordLength = 6;

  static const List<String> donationUnits = <String>[
    'Meals',
    'Kg',
    'Boxes',
    'Portions',
  ];
}

class FirebaseCollections {
  const FirebaseCollections._();

  static const String rootCollection = 'zerowaste';
  static const String rootDocument = 'app';
  static const String users = '$rootCollection/$rootDocument/users';
  static const String donations = '$rootCollection/$rootDocument/donations';
  static const String notifications =
      '$rootCollection/$rootDocument/notifications';
}

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String addDonation = '/add-donation';
  static const String donations = '/donations';
  static const String donationDetails = '/donation-details';
  static const String notifications = '/notifications';
  static const String chatbot = '/chatbot';
  static const String map = '/map';
  static const String profile = '/profile';
  static const String admin = '/admin';
}

class MatchingConfig {
  const MatchingConfig._();

  static const double urgencyWeight = 60;
  static const double quantityWeight = 40;
  static const double quantityForFullScore = 100;
}
