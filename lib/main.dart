import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/recommendations/recommendation_screen.dart';
import 'screens/process/process_screen.dart';
import 'screens/advisor/advisor_screen.dart';
import 'screens/scanner/scanner_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/crop_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/disease_detection_provider.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['VITE_SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['VITE_SUPABASE_ANON_KEY'] ?? '',
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const CropSenseApp());
}

class CropSenseApp extends StatelessWidget {
  const CropSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CropProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => DiseaseDetectionProvider()),
      ],
      child: MaterialApp(
        title: 'CropSense AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/recommendations': (context) => const RecommendationScreen(),
          '/process': (context) => const ProcessScreen(),
          '/advisor': (context) => const AdvisorScreen(),
          '/scanner': (context) => const ScannerScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
