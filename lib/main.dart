import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  await Supabase.initialize(
    url: 'https://cdwkuzqsjyuzonufixji.supabase.co',
    publishableKey: 'sb_publishable_IqnKDG9zDsuGoYiw4bW4vw_sf2Pod-F',
  );
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
