import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/weather_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/alert_card.dart';
import 'ai_advisor_screen_enhanced.dart';
import 'crop_health_scanner_screen.dart';
import 'season_planning_screen.dart';
import 'process_screen.dart';
import '../services/api_service.dart';
import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../services/local_profile_service.dart';
import '../services/connectivity_service.dart';
import '../utils/weather_numeric.dart';

/// Returns the current Rwanda agricultural season based on the calendar month.
String _currentRwandaSeason() {
  final month = DateTime.now().month;
  if (month >= 2 && month <= 5) return 'Long rainy season (Feb - May)';
  if (month >= 9 && month <= 12) return 'Short rainy season (Sep - Dec)';
  if (month >= 6 && month <= 8) return 'Dry season (Jun - Aug)';
  return 'Dry season (Dec - Jan)';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onProfileTap});

  final VoidCallback? onProfileTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllRecommendations = false;
  final _profileService = LocalProfileService();
  Map<String, dynamic>? _profile;
  bool _isLoadingProfile = true;
  bool _isFetchingData = true;
  Map<String, dynamic>? _weather;
  Map<String, dynamic>? _advisorData;
  Map<String, dynamic>? _activeSeasonPlan;
  bool _serverWaking = false;
  bool _isOffline = false;
  Timer? _wakeTimer;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkConnectivity();
    ConnectivityService.onConnectivityChanged.listen((online) {
      if (mounted) setState(() => _isOffline = !online);
    });
  }

  Future<void> _checkConnectivity() async {
    final online = await ConnectivityService.isOnline();
    if (mounted) setState(() => _isOffline = !online);
  }

  @override
  void dispose() {
    _wakeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getProfile();

    // Show cached weather immediately so the home screen isn't blank
    final cached = await ApiService.getCachedWeather();
    setState(() {
      _profile = profile;
      _isLoadingProfile = false;
      if (cached != null) _weather = cached;
    });

    _fetchWeatherAndRecommendations(profile);
  }

  Future<void> _fetchWeatherAndRecommendations(Map<String, dynamic>? profile) async {
    final province = profile?['province'] ?? '';
    final district = profile?['district'] ?? '';
    final location = district.isNotEmpty && province.isNotEmpty
        ? '$district, $province'
        : 'Rwanda';

    // Show a "server is waking up" banner if first response takes > 5 seconds
    _wakeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _weather == null) {
        setState(() => _serverWaking = true);
      }
    });

    final token = await AuthService().getToken();
    final activePlan = (token != null && token.isNotEmpty)
        ? await ApiService.getActiveSeasonPlan(token)
        : null;

    final weather = await ApiService.getWeather(
      location: location,
      province: province,
      district: district,
    );

    _wakeTimer?.cancel();
    if (weather != null) await ApiService.saveWeatherCache(weather);
    if (mounted) {
      setState(() {
        _weather = weather ?? _weather; // keep cached if fresh fetch failed
        _activeSeasonPlan = activePlan;
        _serverWaking = false;
        _isFetchingData = false;
      });
    }

    final seasonLabel = (activePlan != null &&
            (activePlan['season']?.toString().trim().isNotEmpty ?? false))
        ? activePlan['season'].toString()
        : _currentRwandaSeason();
    final landTypeLabel = (activePlan != null &&
            (activePlan['land_type']?.toString().trim().isNotEmpty ?? false))
        ? ApiService.normalizeLandType(activePlan['land_type'].toString())
        : 'Wetland';
    final sectorHint = (profile?['sector'] ?? activePlan?['sector'] ?? '').toString();

    if (province.isNotEmpty && district.isNotEmpty) {
      final advisor = await ApiService.getAdvisorRecommendations(
        province: province,
        district: district,
        sector: sectorHint,
        season: seasonLabel,
        landType: landTypeLabel,
      );
      if (advisor != null) await ApiService.saveAdvisorCache(advisor);
      final advisorToShow = advisor ?? await ApiService.getCachedAdvisor();
      if (mounted) setState(() => _advisorData = advisorToShow);
    } else if (mounted) {
      setState(() => _advisorData = null);
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
              if (_isOffline) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You\'re offline. Showing last saved data.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_serverWaking) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Connecting to server, please wait a moment...',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                  GestureDetector(
                    onTap: widget.onProfileTap,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
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
                  const SizedBox(width: 12),
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
                  const SizedBox(width: 12),
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
              if (_activeSeasonPlan != null &&
                  (_activeSeasonPlan!['primary_crop']?.toString().trim().isNotEmpty ??
                      false)) ...[
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
                        'My current plan (saved)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Crop: ${_activeSeasonPlan!['primary_crop']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Location: ${_activeSeasonPlan!['district']}, ${_activeSeasonPlan!['province']} • ${_activeSeasonPlan!['season']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else if (_advisorData != null && _advisorData!['best_match'] != null) ...[
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
                        'Location: $locationText • Season: ${_currentRwandaSeason()}',
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
              ValueListenableBuilder<bool>(
                valueListenable: AppSettings.notificationsNotifier,
                builder: (context, notificationsOn, __) {
                  if (!notificationsOn) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alerts & Recommendations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._buildAlerts(locationText),
                    ],
                  );
                },
              ),
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

  List<Widget> _buildAlerts(String locationText) {
    if (!AppSettings.notificationsEnabled) return [const SizedBox(height: 8)];

    final alerts = <Widget>[];

    // ── Alert 1: Sowing window reminder from active plan ──────────────────
    final advisorJson = _activeSeasonPlan?['advisor_json'] as Map<String, dynamic>?;
    final bestMatch = advisorJson?['best_match'] as Map<String, dynamic>?;
    final sowingWindow = bestMatch?['sowingWindow']?.toString() ?? '';
    final crop = _activeSeasonPlan?['primary_crop']?.toString()
        ?? _advisorData?['best_match']?['crop']?.toString()
        ?? '';

    if (sowingWindow.isNotEmpty && crop.isNotEmpty) {
      alerts.add(AlertCard(
        icon: Icons.agriculture,
        title: 'Sowing window open',
        subtitle: '$crop sowing period: $sowingWindow. Prepare your land now to be ready in time.',
        actionText: 'View stages',
        color: AppColors.primary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProcessScreen()),
        ),
      ));
      alerts.add(const SizedBox(height: 12));
    } else if (crop.isNotEmpty) {
      // ── Alert 2: Crop recommendation (no sowing window in plan) ──────────
      alerts.add(AlertCard(
        icon: Icons.lightbulb,
        title: 'Recommended for $locationText',
        subtitle: '$crop is the best match for your location and the current season.',
        actionText: 'Get advice',
        color: AppColors.primary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIAdvisorScreenEnhanced()),
        ),
      ));
      alerts.add(const SizedBox(height: 12));
    }

    // ── Alert 3: Weather risk (high humidity = disease risk) ───────────────
    final humidity = WeatherNumeric.parseIntRounded(_weather?['humidity']);
    if (humidity != null && humidity >= 75) {
      alerts.add(AlertCard(
        icon: Icons.water_drop,
        title: 'High humidity warning',
        subtitle: 'Humidity is at $humidity%. High risk of fungal disease. Inspect crops and apply preventive treatment.',
        actionText: 'Scan crops',
        color: Colors.orange.shade700,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CropHealthScannerScreen()),
        ),
      ));
      alerts.add(const SizedBox(height: 12));
    }

    // ── Alert 4: No plan yet — nudge to create one ─────────────────────────
    if (!_isFetchingData && _activeSeasonPlan == null && crop.isEmpty) {
      alerts.add(AlertCard(
        icon: Icons.calendar_today,
        title: 'Plan your season',
        subtitle: 'No active plan found. Get personalized crop recommendations for ${_currentRwandaSeason()}.',
        actionText: 'Plan now',
        color: AppColors.info,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SeasonPlanningScreen()),
        ),
      ));
      alerts.add(const SizedBox(height: 12));
    }

    if (alerts.isEmpty) return [const SizedBox(height: 8)];

    alerts.add(const SizedBox(height: 4));
    return alerts;
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
