import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../utils/colors.dart';
import '../services/api_service.dart';
import 'ai_advisor_screen_enhanced.dart';

// Default to localhost (works for Flutter web and when running on the same machine
// as the backend). For Android emulator, override with:
// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
const String _defaultApiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'https://cropsenseai-mobile-app.onrender.com');

class CropHealthScannerScreen extends StatefulWidget {
  const CropHealthScannerScreen({super.key});

  @override
  State<CropHealthScannerScreen> createState() => _CropHealthScannerScreenState();
}

class _CropHealthScannerScreenState extends State<CropHealthScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _result;

  bool _isWeatherMissing(Map<String, dynamic>? weather) {
    if (weather == null) return true;
    final temp = weather['temperature'];
    final humidity = weather['humidity'];
    final wind = weather['wind_speed'];
    final time = weather['timestamp'];
    return temp == null ||
        humidity == null ||
        wind == null ||
        time == null ||
        temp.toString() == 'N/A' ||
        humidity.toString() == 'N/A' ||
        wind.toString() == 'N/A' ||
        time.toString() == 'N/A';
  }

  Future<Map<String, dynamic>?> _fetchWeatherFallback() async {
    // Use ApiService so we get the same retry/fallback behavior as other screens.
    return ApiService.getWeather(
      location: 'Rwanda',
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = picked.name;
        _result = null;
      });

      await _analyzeImage(bytes, picked.name);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _analyzeImage(Uint8List bytes, String fileName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('$_defaultApiBaseUrl/predict');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Prediction failed (${response.statusCode}): ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final weather = data['weather'] as Map<String, dynamic>?;
      if (_isWeatherMissing(weather)) {
        final fallbackWeather = await _fetchWeatherFallback();
        if (fallbackWeather != null) {
          data['weather'] = fallbackWeather;
        }
      }
      setState(() {
        _result = data;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Could not analyze image. Please check your internet connection and try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
          t.tr('cropHealthScanner'),
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
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '${t.tr('scanYourCrop')}\n${t.tr('uploadCropImage')}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _selectedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t.tr('uploadAPhoto'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  _pickImage(ImageSource.camera);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            t.tr('takePhoto'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  _pickImage(ImageSource.gallery);
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.photo_library),
                          label: Text(
                            t.tr('upload'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    Text(
                      t.tr('analyzingCrop'),
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
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
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_result != null) ...[
              Text(
                t.tr('aiResults'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildResultCard(),
              const SizedBox(height: 24),
            ],
            Text(
              t.tr('howToTakePhotos'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildTipCard(
              '1',
              t.tr('goodLighting'),
              t.tr('naturalLight'),
              AppColors.success,
            ),
            const SizedBox(height: 12),
            _buildTipCard(
              '2',
              t.tr('clearFocus'),
              t.tr('steadyCamera'),
              AppColors.info,
            ),
            const SizedBox(height: 12),
            _buildTipCard(
              '3',
              t.tr('multipleAngles'),
              t.tr('takeMultiplePhotos'),
              AppColors.purple,
            ),
            const SizedBox(height: 24),
            Text(
              t.tr('commonDiseases'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildDiseaseCard(
              'Rice Blast',
              'Causes lesions on leaves, stems, and panicles. Most severe in high humidity with moderate temperatures',
              AppColors.danger,
              'High Risk',
            ),
            const SizedBox(height: 12),
            _buildDiseaseCard(
              'Bacterial Leaf Blight',
              'Water-soaked lesions along leaf margins with yellowish halos that spread and create wilted appearance',
              AppColors.warning,
              'Medium Risk',
            ),
            const SizedBox(height: 12),
            _buildDiseaseCard(
              'Leaf Spot',
              'Small brown spots with light centers on leaves. Can affect multiple leaf margins',
              AppColors.warning,
              'Medium Risk',
            ),
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
                    child: Text(
                      '${t.tr('aiFeature')}\n${t.tr('aiPowered')}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AIAdvisorScreenEnhanced(),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.lightbulb_outline),
                label: Text(
                  t.tr('getCropAdvice'),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    if (_result == null) return const SizedBox.shrink();

    final prediction = _result!['prediction']?.toString() ?? 'Unknown';
    final confidence = _result!['confidence'];
    final weather = _result!['weather'] as Map<String, dynamic>?;
    final advice = _result!['advice'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  prediction,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (confidence != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Confidence: ${confidence.toString()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (weather != null) ...[
            Text(
              'Weather in ${weather['location']}:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Temp: ${weather['temperature'] ?? 'N/A'}°C, Humidity: ${weather['humidity'] ?? 'N/A'}%, Wind: ${weather['wind_speed'] ?? 'N/A'} km/h',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Time: ${weather['timestamp'] ?? 'N/A'}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (advice != null) ...[
            Text(
              'Agronomic Advice',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              advice['advice']?.toString() ?? '',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            if (advice['additional_tips'] is List)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (advice['additional_tips'] as List)
                    .map(
                      (tip) => Text(
                        '• $tip',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipCard(
    String number,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  fontSize: 16,
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
                  style: TextStyle(
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

  Widget _buildDiseaseCard(
    String title,
    String description,
    Color color,
    String risk,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  risk,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
