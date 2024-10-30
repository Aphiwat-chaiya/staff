import 'package:flutter/material.dart';
import 'package:flutter_application_12/screens_officer/add_new.dart';
import 'package:flutter_application_12/screens_officer/manage_images.dart';
import 'screens_officer/redemtion_deleted.dart';
import 'screens_employer/login_FuelTransaction.dart'; // Staff login screen
import 'screens_employer/record_page.dart';
import 'screens_officer/login_officer.dart'; // Officer login screen
import 'screens_officer/search_transaction.dart'; // Search transactions
import 'screens_officer/redeem_items.dart'; // Redeem items
import 'screens_officer/search_edit_reward.dart'; // Search reward
import 'screens_employer/get_rewarded.dart';
import 'screens_officer/history_of_year.dart';
import 'screens_officer/FuelTypeStats.dart';
import 'screens_officer/Home_officer.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login', // Initial route can be set as needed
      routes: {
        '/login': (context) => const Login(), // Staff login page

        '/sales': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          final staffId = args?['staff_id'] ?? ''; // Receive staffId
          return FuelTransactionScreen(staff_id: staffId);
        },
        '/get_rewarded': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          final staffId = args?['staff_id'] ?? ''; // Receive staffId
          return GetRewardedScreen(staff_id: staffId);
        },
        '/login_officer': (context) =>
            const OfficerLogin(), // Officer login screen
        '/officer_home': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          final officerId = args?['officer_id'] ?? ''; // Receive officerId
          return OfficerHomeScreen(officer_id: officerId);
        },
        '/search_transaction': (context) {
          final String officerId =
              ModalRoute.of(context)!.settings.arguments as String;
          return SearchTransactionScreen(officer_id: officerId);
        },
        '/search_edit_reward': (context) {
          final String officerId =
              ModalRoute.of(context)!.settings.arguments as String;
          return SearchAndEditRewardPage(officer_id: officerId);
        },
        '/manage_images': (context) {
          final String officerId =
              ModalRoute.of(context)!.settings.arguments as String;
          return ImageManagementPage(officer_id: officerId);
        },

        '/redeem_items': (context) => const RewardManagementPage(),
        '/redemption_deleted': (context) =>
            const Search_deleteRedemptionsScreen(),
        '/history_of_year': (context) => const AnnualProcessingScreen(),
        '/FuelTypeStats': (context) => const FuelTypeStatsPage(),
        '/image_for_new': (context) => ImageUploadPage(),
      },
    );
  }
}
