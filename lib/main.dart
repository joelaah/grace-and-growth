import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(const GraceAndGrowthApp());
}

class GraceAndGrowthApp extends StatelessWidget {
  const GraceAndGrowthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grace & Growth - Daily Sanctuary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'serif',
      ),
      home: const SplashScreen(),
    );
  }
}
