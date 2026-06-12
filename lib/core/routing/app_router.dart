import 'package:flutter/material.dart';

import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/chatbot/presentation/chatbot_screen.dart';
import '../../features/donations/presentation/add_donation_screen.dart';
import '../../features/donations/presentation/donation_details_screen.dart';
import '../../features/donations/presentation/donation_list_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/splash_screen.dart';
import '../../features/maps/presentation/maps_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../models/donation.dart';
import '../config/app_constants.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _route(const SplashScreen(), settings);
      case AppRoutes.login:
        return _route(const LoginScreen(), settings);
      case AppRoutes.register:
        return _route(const RegisterScreen(), settings);
      case AppRoutes.home:
        return _route(const HomeScreen(), settings);
      case AppRoutes.addDonation:
        return _route(const AddDonationScreen(), settings);
      case AppRoutes.donations:
        return _route(const DonationListScreen(), settings);
      case AppRoutes.donationDetails:
        final arguments = settings.arguments;
        if (arguments is Donation) {
          return _route(
            DonationDetailsScreen(
              donationId: arguments.id,
              initialDonation: arguments,
            ),
            settings,
          );
        }
        if (arguments is! String || arguments.isEmpty) {
          return _route(const HomeScreen(), settings);
        }
        return _route(DonationDetailsScreen(donationId: arguments), settings);
      case AppRoutes.notifications:
        return _route(const NotificationsScreen(), settings);
      case AppRoutes.chatbot:
        return _route(const ChatbotScreen(), settings);
      case AppRoutes.map:
        return _route(const MapsScreen(), settings);
      case AppRoutes.profile:
        return _route(const ProfileScreen(), settings);
      case AppRoutes.admin:
        return _route(const AdminDashboardScreen(), settings);
      default:
        return _route(const SplashScreen(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _route(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<dynamic>(builder: (_) => page, settings: settings);
  }
}
