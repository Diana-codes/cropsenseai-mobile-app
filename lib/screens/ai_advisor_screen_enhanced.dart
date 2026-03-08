import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utils/colors.dart';
import '../data/rwanda_locations.dart';

// Default to localhost (good for Flutter web and when backend runs on same machine).
// For Android emulator, override with:
// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
const String _advisorApiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');

class AIAdvisorScreenEnhanced extends StatefulWidget {
  const AIAdvisorScreenEnhanced({super.key});

  @override
  State<AIAdvisorScreenEnhanced> createState() => _AIAdvisorScreenEnhancedState();
}

class _AIAdvisorScreenEnhancedState extends State<AIAdvisorScreenEnhanced> {
  String _province = '';
  String _district = '';
  String _sector = '';
  String _cell = '';
  String _village = '';
  String _season = '';
  String _landType = '';
  bool _showRecommendations = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _advisorData;

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('$_advisorApiBaseUrl/advisor');
      final payload = {
        'province': _province,
        'district': _district,
        'sector': _sector,
        'cell': _cell,
        'village': _village,
        'season': _season,
        'landType': _landType.toLowerCase(),
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('Advisor request failed (${response.statusCode}): ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      setState(() {
        _advisorData = data;
        _showRecommendations = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Failed to fetch AI cultivation guide. Please make sure the backend is running and try again.\n$e';
        _showRecommendations = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: const Text(
          'AI Crop Advisor',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CropSense AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your personalized crop recommendation assistant based on your location, soil conditions, and historical data to recommend the best crops for you.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tell us about your farm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown('Province', _province, RwandaLocations.getProvinces(), (value) {
                    setState(() {
                      _province = value!;
                      _district = '';
                      _sector = '';
                      _cell = '';
                      _village = '';
                    });
                  }),
                  if (_province.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDropdown('District', _district, RwandaLocations.getDistricts(_province), (value) {
                      setState(() {
                        _district = value!;
                        _sector = '';
                        _cell = '';
                        _village = '';
                      });
                    }),
                  ],
                  if (_district.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDropdown('Sector', _sector, RwandaLocations.getSectors(_province, _district), (value) {
                      setState(() {
                        _sector = value!;
                        _cell = '';
                        _village = '';
                      });
                    }),
                  ],
                  if (_sector.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final cells = RwandaLocations.getCells(_province, _district, _sector);
                        // Debug: print cells to console
                        if (cells.isNotEmpty) {
                          print('Found ${cells.length} cells for $_province -> $_district -> $_sector: $cells');
                        } else {
                          print('No cells found for $_province -> $_district -> $_sector');
                        }
                        return _buildDropdown('Cell', _cell, cells, (value) {
                          setState(() {
                            _cell = value!;
                            _village = '';
                          });
                        });
                      },
                    ),
                  ],
                  if (_cell.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDropdown('Village', _village, RwandaLocations.getVillages(_province, _district, _sector, _cell), (value) {
                      setState(() {
                        _village = value!;
                      });
                    }),
                  ],
                  const SizedBox(height: 16),
                  _buildDropdown('Season planning season', _season, ['Season A (Sept - Jan)', 'Season B (Feb - June)'], (value) {
                    setState(() {
                      _season = value!;
                    });
                  }),
                  const SizedBox(height: 16),
                  _buildDropdown('Select land type', _landType, ['Wetland', 'Hillside', 'Valley', 'Plateau'], (value) {
                    setState(() {
                      _landType = value!;
                    });
                  }),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _province.isNotEmpty &&
                              _district.isNotEmpty &&
                              _sector.isNotEmpty &&
                              _cell.isNotEmpty &&
                              _village.isNotEmpty &&
                              _season.isNotEmpty &&
                              _landType.isNotEmpty
                          ? () {
                              _fetchRecommendations();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Get AI Cultivation Guide',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                ),
              ),
            ],
            if (_showRecommendations && _advisorData != null && _advisorData!['best_match'] != null) ...[
              const SizedBox(height: 24),
              const Text(
                'AI Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildFeaturedRecommendation(_advisorData!['best_match'] as Map<String, dynamic>),
              const SizedBox(height: 12),
              if (_advisorData!['alternatives'] is List)
                ...(_advisorData!['alternatives'] as List)
                    .take(3)
                    .map(
                      (alt) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAlternativeRecommendation(alt as Map<String, dynamic>),
                      ),
                    ),
            ],
            const SizedBox(height: 24),
            const Text(
              'How to Take Good Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildTipCard('1', 'Good Lighting', 'Take the photo in natural light; avoid dark or shaded areas for best results', AppColors.primary),
            const SizedBox(height: 12),
            _buildTipCard('2', 'Clear Focus', 'Ensure that the camera is steady and focus on the leaf clearly with sharp details', AppColors.info),
            const SizedBox(height: 12),
            _buildTipCard('3', 'Multiple Angles', 'Take 2-3 photos from different angles. AI analyzes from multiple perspectives', AppColors.purple),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Feature Coming Soon',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Automatic disease detection and treatment recommendations will be available in the next version.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Next Steps',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value.isEmpty ? null : value,
              hint: Text(
                items.isEmpty 
                    ? 'No $label available' 
                    : 'Select your $label',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              isExpanded: true,
              items: items.isEmpty
                  ? null
                  : items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
              onChanged: items.isEmpty ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedRecommendation(Map<String, dynamic> best) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  best['crop']?.toString() ?? 'Best crop',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Best Match',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Excellent match for $_landType in $_district. ${(best['reason'] ?? 'Based on Rwanda crop calendar data for your agro-ecological zone.') as String}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildDetailChip('🕐 Growing period: ${best['growingPeriod'] ?? 'N/A'}'),
              _buildDetailChip('📍 Zone: ${best['agroZone'] ?? 'N/A'}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeRecommendation(Map<String, dynamic> alt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  alt['crop']?.toString() ?? 'Alternative crop',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Alternative',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alt['reason']?.toString() ?? 'Suitable as an alternative crop option in similar conditions.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildDetailChip('🕐 Growing period: ${alt['growingPeriod'] ?? 'N/A'}'),
              _buildDetailChip('📍 Zone: ${alt['agroZone'] ?? 'N/A'}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTipCard(String number, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
