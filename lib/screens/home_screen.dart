import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/weather_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/recommendation_card.dart';
import 'ai_advisor_screen_enhanced.dart';
import 'crop_health_scanner_screen.dart';
import 'season_planning_screen.dart';
import 'process_screen.dart';
import '../services/api_service.dart';
import '../services/app_settings.dart';
import '../services/local_profile_service.dart';
import '../utils/weather_numeric.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllRecommendations = false;
  final _profileService = LocalProfileService();
  Map<String, dynamic>? _profile;
  bool _isLoadingProfile = true;
  Map<String, dynamic>? _weather;
  Map<String, dynamic>? _advisorData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getProfile();
    setState(() {
      _profile = profile;
      _isLoadingProfile = false;
    });
    _fetchWeatherAndRecommendations(profile);
  }

  Future<void> _fetchWeatherAndRecommendations(Map<String, dynamic>? profile) async {
    final province = profile?['province'] ?? '';
    final district = profile?['district'] ?? '';
    final location = district.isNotEmpty && province.isNotEmpty
        ? '$district, $province'
        : 'Rwanda';

    final weather = await ApiService.getWeather(
      location: location,
      province: province,
      district: district,
    );
    if (mounted) setState(() => _weather = weather);

    if (province.isNotEmpty && district.isNotEmpty) {
      final advisor = await ApiService.getAdvisorRecommendations(
        province: province,
        district: district,
        sector: profile?['sector'] ?? '',
        season: 'Season A (Sept - Jan)',
        landType: 'Wetland',
      );
      if (mounted) setState(() => _advisorData = advisor);
    }
  }

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
                temperatureC: WeatherNumeric.parseIntRounded(_weather?['temperature']),
                condition: _weather != null && _weather!['weather_code'] != null
                    ? _weatherCondition(_weather!['weather_code'])
                    : '☁️ Loading...',
                humidityPct: WeatherNumeric.parseIntRounded(_weather?['humidity']),
                windSpeedKmh: WeatherNumeric.parseIntRounded(_weather?['wind_speed']),
                forecast: null,
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
              if (_advisorData != null && _advisorData!['best_match'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My current plan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Crop: ${_advisorData!['best_match']['crop']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Location: $locationText • Season: Season A (Sept - Jan)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                const SizedBox(height: 24),
              ],
              Text(
                'Alerts & Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (AppSettings.notificationsEnabled && _advisorData != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notifications_active, color: AppColors.info),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _advisorData!['best_match']?['crop'] != null
                              ? 'Season reminder for $locationText • Recommended crop: ${_advisorData!['best_match']['crop']}'
                              : 'Season reminder for $locationText based on your latest AI analysis.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const SizedBox(height: 8),
              ],
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
              ..._buildRecommendationList().map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RecommendationCard(
                    icon: rec['icon'] as IconData,
                    title: rec['title'] as String,
                    subtitle: rec['subtitle'] as String,
                    duration: rec['duration'] as String,
                    confidence: rec['confidence'] as String,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _weatherCondition(dynamic code) {
    if (code == null) return '☁️ —';
    final c = code is num ? code.toInt() : 0;
    if (c == 0) return '☀️ Clear';
    if (c < 4) return '⛅ Partly cloudy';
    if (c < 50) return '☁️ Cloudy';
    if (c < 70) return '🌧️ Rain';
    return '🌤️ Variable';
  }

  List<Map<String, dynamic>> _buildRecommendationList() {
    final list = <Map<String, dynamic>>[];
    if (_advisorData != null) {
      final best = _advisorData!['best_match'] as Map<String, dynamic>?;
      final alts = _advisorData!['alternatives'] as List? ?? [];
      if (best != null) {
        list.add(_recFromApi(best, Icons.grass, 'Best match'));
      }
      for (final a in alts.take(3)) {
        list.add(_recFromApi(a as Map<String, dynamic>, Icons.grain, 'Alternative'));
      }
    }
    if (list.isEmpty) {
      list.addAll([
        {
          'icon': Icons.lightbulb_outline,
          'title': 'Get personalized recommendations',
          'subtitle': 'Complete your profile and use AI Advisor for crop suggestions.',
          'duration': '—',
          'confidence': 'Tap Get Advice',
        },
      ]);
    }
    return _showAllRecommendations ? list : list.take(2).toList();
  }

  Map<String, dynamic> _recFromApi(Map<String, dynamic> r, IconData icon, String confidence) {
    return {
      'icon': icon,
      'title': r['crop']?.toString() ?? 'Crop',
      'subtitle': r['reason']?.toString() ?? '',
      'duration': r['growingPeriod']?.toString() ?? '—',
      'confidence': confidence,
    };
  }
}
