import 'package:flutter/material.dart';
import 'screens/home_stage_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const HomeStageScreen(),
    );
  }
}
