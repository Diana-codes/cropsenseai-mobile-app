import 'package:flutter/material.dart';

import '../utils/colors.dart';
import '../data/rwanda_locations.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

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

    final data = await ApiService.getAdvisorRecommendations(
      province: _province,
      district: _district,
      sector: _sector,
      cell: _cell,
      village: _village,
      season: _season,
      landType: _landType,
    );

    setState(() {
      _isLoading = false;
      if (data != null) {
        _advisorData = data;
        _showRecommendations = true;
        _errorMessage = null;
      } else {
        _errorMessage = 'couldNotLoadRec';
        _showRecommendations = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: Text(
          t.tr('aiCropAdvisor'),
          style: const TextStyle(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.tr('appName'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.tr('personalizedAssistant'),
                          style: const TextStyle(
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
                  Text(
                    t.tr('tellAboutFarm'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(t.tr('province'), _province, RwandaLocations.getProvinces(), (value) {
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
                    _buildDropdown(t.tr('district'), _district, RwandaLocations.getDistricts(_province), (value) {
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
                    _buildDropdown(t.tr('sector'), _sector, RwandaLocations.getSectors(_province, _district), (value) {
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
                        return _buildDropdown(t.tr('cellOptional'), _cell, cells, (value) {
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
                    _buildDropdown(t.tr('villageOptional'), _village, RwandaLocations.getVillages(_province, _district, _sector, _cell), (value) {
                      setState(() {
                        _village = value!;
                      });
                    }),
                  ],
                  const SizedBox(height: 16),
                  _buildMappedDropdown(t.tr('season'), _season, {
                    'Long rainy season (Feb - May)': t.tr('longRainyFebMay'),
                    'Short rainy season (Sep - Dec)': t.tr('shortRainySepDec'),
                    'Dry season (Jun - Aug)': t.tr('dryJunAug'),
                    'Dry season (Dec - Jan)': t.tr('dryDecJan'),
                  }, (value) {
                    setState(() {
                      _season = value!;
                    });
                  }),
                  const SizedBox(height: 16),
                  _buildMappedDropdown(t.tr('landType'), _landType, {
                    'Wetland': t.tr('wetland'),
                    'Hillside': t.tr('hillside'),
                    'Valley': t.tr('valley'),
                    'Plateau': t.tr('plateau'),
                  }, (value) {
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
                      child: Text(
                        t.tr('getAiGuide'),
                        style: const TextStyle(
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
                t.tr(_errorMessage!),
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                ),
              ),
            ],
            if (_showRecommendations && _advisorData != null && _advisorData!['best_match'] != null) ...[
              const SizedBox(height: 24),
              Text(
                'Location: ${_district.isNotEmpty ? '$_district, ' : ''}${_province.isNotEmpty ? _province : 'Rwanda'}  •  Season: ${_season.isNotEmpty ? _season : 'Not set'}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.tr('aiRecommendations'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildFeaturedRecommendation(_advisorData!['best_match'] as Map<String, dynamic>, t),
              const SizedBox(height: 12),
              if (_advisorData!['alternatives'] is List)
                ...(_advisorData!['alternatives'] as List)
                    .take(3)
                    .map(
                      (alt) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAlternativeRecommendation(alt as Map<String, dynamic>, t),
                      ),
                    ),
            ],
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

  Widget _buildMappedDropdown(String label, String value, Map<String, String> items, Function(String?) onChanged) {
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
                'Select your $label',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              isExpanded: true,
              items: items.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedRecommendation(Map<String, dynamic> best, AppLocalizations t) {
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
                  t.cropName(best['crop']?.toString() ?? '').isNotEmpty
                      ? t.cropName(best['crop']?.toString() ?? '')
                      : t.tr('bestCrop'),
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
                child: Text(
                  t.tr('bestMatchLabel'),
                  style: const TextStyle(
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
              _buildDetailChip('🕐 ${t.tr('growingPeriod')}: ${best['growingPeriod'] ?? 'N/A'}'),
              _buildDetailChip('📍 ${t.tr('agroZone')}: ${best['agroZone'] ?? 'N/A'}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeRecommendation(Map<String, dynamic> alt, AppLocalizations t) {
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
                  t.cropName(alt['crop']?.toString() ?? '').isNotEmpty
                      ? t.cropName(alt['crop']?.toString() ?? '')
                      : t.tr('bestCrop'),
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
                child: Text(
                  t.tr('alternative'),
                  style: const TextStyle(
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
              _buildDetailChip('🕐 ${t.tr('growingPeriod')}: ${alt['growingPeriod'] ?? 'N/A'}'),
              _buildDetailChip('📍 ${t.tr('agroZone')}: ${alt['agroZone'] ?? 'N/A'}'),
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
