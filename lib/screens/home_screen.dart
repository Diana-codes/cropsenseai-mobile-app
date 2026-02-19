import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/weather_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/alert_card.dart';
import '../widgets/recommendation_card.dart';
import 'ai_advisor_screen_enhanced.dart';
import 'crop_health_scanner_screen.dart';
import 'season_planning_screen.dart';
import 'process_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllRecommendations = false;
  final _authService = AuthService();
  Map<String, dynamic>? _profile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getUserProfile();
    setState(() {
      _profile = profile;
      _isLoadingProfile = false;
    });
  }

  final List<Map<String, dynamic>> _allRecommendations = [
    {
      'icon': Icons.grass,
      'title': 'Rice (DMIS variety)',
      'subtitle': 'Best choice for current season conditions',
      'duration': '120-140 days',
      'confidence': 'High confidence',
    },
    {
      'icon': Icons.grain,
      'title': 'Maize (Hybrid variety)',
      'subtitle': 'Good alternative with lower water needs',
      'duration': '90-110 days',
      'confidence': 'Medium confidence',
    },
    {
      'icon': Icons.local_florist,
      'title': 'Beans (Climbing variety)',
      'subtitle': 'Excellent for intercropping and soil health',
      'duration': '75-90 days',
      'confidence': 'High confidence',
    },
    {
      'icon': Icons.spa,
      'title': 'Irish Potato',
      'subtitle': 'High demand and good market prices',
      'duration': '90-120 days',
      'confidence': 'Medium confidence',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final userName = _profile?['full_name'] ?? 'User';
    final district = _profile?['district'] ?? '';
    final province = _profile?['province'] ?? '';
    final locationText = district.isNotEmpty && province.isNotEmpty
        ? '$district, $province'
        : 'Location not set';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        locationText,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              WeatherCard(
                location: district.isNotEmpty ? '$district, Rwanda' : 'Rwanda',
                temperature: 24,
                condition: '☁️ Partly Cloudy',
                humidity: 65,
                windSpeed: 12,
                forecast: [
                  WeatherForecast(day: 'Mon', icon: '☀️', temp: 24),
                  WeatherForecast(day: 'Tue', icon: '⛅', temp: 23),
                  WeatherForecast(day: 'Wed', icon: '🌤️', temp: 25),
                  WeatherForecast(day: 'Thu', icon: '☀️', temp: 26),
                  WeatherForecast(day: 'Fri', icon: '⛅', temp: 27),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  QuickActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'New Season',
                    subtitle: 'Start planning',
                    color: Colors.white,
                    iconColor: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SeasonPlanningScreen(),
                        ),
                      );
                    },
                  ),
                  QuickActionButton(
                    icon: Icons.local_florist_outlined,
                    label: 'Crop Health',
                    subtitle: 'Scan crops',
                    color: Colors.white,
                    iconColor: Colors.amber,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CropHealthScannerScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  QuickActionButton(
                    icon: Icons.lightbulb_outline,
                    label: 'Get Advice',
                    subtitle: 'AI advisor',
                    color: Colors.purple.shade50,
                    iconColor: AppColors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AIAdvisorScreenEnhanced(),
                        ),
                      );
                    },
                  ),
                  QuickActionButton(
                    icon: Icons.wysiwyg_rounded,
                    label: 'My Process',
                    subtitle: 'View stages',
                    color: Colors.blue.shade50,
                    iconColor: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProcessScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Alerts & Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const AlertCard(
                icon: Icons.warning_amber_rounded,
                title: 'Heavy rainfall expected',
                subtitle: 'This week: Postpone planting until water...',
                actionText: 'Prepare field',
                color: AppColors.warning,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recommended for',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllRecommendations = !_showAllRecommendations;
                      });
                    },
                    child: Text(
                      _showAllRecommendations ? 'Show less' : 'See all',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'This season',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ...(_showAllRecommendations
                      ? _allRecommendations
                      : _allRecommendations.take(2))
                  .map((rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RecommendationCard(
                          icon: rec['icon'] as IconData,
                          title: rec['title'] as String,
                          subtitle: rec['subtitle'] as String,
                          duration: rec['duration'] as String,
                          confidence: rec['confidence'] as String,
                        ),
                      ))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }
}
